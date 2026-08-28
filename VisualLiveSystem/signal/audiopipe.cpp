#include "audiopipe.hpp"

#include "core.h"
#include <QMessageBox>
#include <algorithm>

#define BPM_MIN 30.0

namespace {

RtAudio::Api availableApiOrDefault(RtAudio::Api api)
{
    if (api == RtAudio::UNSPECIFIED)
        return api;

    std::vector<RtAudio::Api> compiledApis;
    RtAudio::getCompiledApi(compiledApis);
    if (std::find(compiledApis.begin(), compiledApis.end(), api) != compiledApis.end())
        return api;

    return RtAudio::UNSPECIFIED;
}

int availableDeviceOrDefault(const std::vector<unsigned int>& devices, int configured, unsigned int fallback)
{
    if (configured >= 0 &&
        std::find(devices.begin(), devices.end(), static_cast<unsigned int>(configured)) != devices.end())
        return configured;

    return static_cast<int>(fallback);
}

}

QString RtAudioApiToQString(RtAudio::Api api)
{
    switch (api) {
        case RtAudio::UNSPECIFIED: return "Default";
        case RtAudio::UNIX_JACK: return "Jack";
        case RtAudio::LINUX_ALSA: return "ALSA";
        case RtAudio::LINUX_OSS: return "OSS";
        case RtAudio::LINUX_PULSE: return "PulseAudio";
        case RtAudio::MACOSX_CORE: return "OSX Audio Core";
        case RtAudio::WINDOWS_ASIO: return "ASIO";
        case RtAudio::WINDOWS_DS: return "DirectSound";
        case RtAudio::WINDOWS_WASAPI: return "WASAPI";
        default: break;
    }
    return "Error";
}

RtAudio::Api QStringToRtAudioApi(const QString& api)
{
    if (api=="Default") return RtAudio::UNSPECIFIED;
    else if (api=="Jack") return RtAudio::UNIX_JACK;
    else if (api=="ALSA") return RtAudio::LINUX_ALSA;
    else if (api=="OSS") return RtAudio::LINUX_OSS;
    else if (api=="PulseAudio") return RtAudio::LINUX_PULSE;
    else if (api=="OSX Audio Core") return RtAudio::MACOSX_CORE;
    else if (api=="ASIO") return RtAudio::WINDOWS_ASIO;
    else if (api=="DirectSound") return RtAudio::WINDOWS_DS;
    else if (api=="WASAPI") return RtAudio::WINDOWS_WASAPI;
    else return RtAudio::UNSPECIFIED;
}

AudioPipe::AudioPipe(QObject *parent) :
    QThread(parent),
    _mixer(NULL),
    _stopThread(false)
{
    const RtAudio::Api configuredApi = QStringToRtAudioApi(
        Core::instance()->settings.value("Audio/Driver", "Default").toString());
    const RtAudio::Api api = availableApiOrDefault(configuredApi);
    if (api != configuredApi)
        Core::instance()->settings.setValue("Audio/Driver", "Default");

    _driver = new RtAudio(api);
    _driver->showWarnings();

    const std::vector<unsigned int> devices = _driver->getDeviceIds();
    _deviceOutId = availableDeviceOrDefault(
        devices,
        Core::instance()->settings.value("Audio/DeviceOutId", -1).toInt(),
        _driver->getDefaultOutputDevice());
    _deviceInId = availableDeviceOrDefault(
        devices,
        Core::instance()->settings.value("Audio/DeviceInId", -1).toInt(),
        _driver->getDefaultInputDevice());

    connect(this,SIGNAL(critical_error(QString,QString)),SLOT(show_critical(QString,QString)));


    _latencySignalsR.resize(Signal::refreshRate * 60 / BPM_MIN);
    _latencySignalsL.resize(Signal::refreshRate * 60 / BPM_MIN);
    _latencyTimeBuffer = 0;
    _latencyCurrentBuffer = 0;

}

void AudioPipe::stop() {
    _stopThread=true;
    if (isRunning()) wait();
    _stopThread=false;
}

void AudioPipe::prepare()
{
    RtAudio::StreamParameters iParams, oParams;
    if ( _deviceInId != -1 ) {
        iParams.deviceId = _deviceInId;
        iParams.nChannels = 2;
        iParams.firstChannel = 0;
    }
    if ( _deviceOutId != -1 ) {
        oParams.deviceId = _deviceOutId;
        oParams.nChannels = 2;
        oParams.firstChannel = 0;
    }

    RtAudioErrorType error = RTAUDIO_NO_ERROR;
    if ( _deviceInId != -1 && _deviceOutId != -1 )
        error = _driver->openStream( &oParams, &iParams, RTAUDIO_FLOAT32, Signal::frequency,
                                    (unsigned int*)&Signal::size, &AudioPipe::rtaudio_callback, this );
    else if (_deviceInId != -1)
        error = _driver->openStream( 0, &iParams, RTAUDIO_FLOAT32, Signal::frequency,
                                    (unsigned int*)&Signal::size, &AudioPipe::rtaudio_callback, this );
    else if (_deviceOutId != -1)
        error = _driver->openStream( &oParams, 0, RTAUDIO_FLOAT32, Signal::frequency,
                                    (unsigned int*)&Signal::size, &AudioPipe::rtaudio_callback, this );
    else {
        emit critical_error("Error in AudioPipe thread", "No devices selected !");
        return;
    }

    if (error != RTAUDIO_NO_ERROR)
    {
        emit critical_error("Error in AudioPipe : open stream", QString::fromStdString(_driver->getErrorText()));
        if ( _driver->isStreamOpen() ) _driver->closeStream();
        return;
    }
}

void AudioPipe::run() {


    _leftOut.reset();
    _rightOut.reset();
    _leftIn.reset();
    _rightIn.reset();

    //Creating local variables to work on it
    Signal left;
    Signal right;

    if (_driver->startStream() != RTAUDIO_NO_ERROR)
    {
        emit critical_error("Error in AudioPipe : start stream", QString::fromStdString(_driver->getErrorText()));
        if ( _driver->isStreamOpen() ) _driver->closeStream();
        return;
    }

    emit computedLatency(getStreamLatency() + Signal::size*3);

    const bool isPow2 = Signal::isPow2;
    const unsigned int signal_size = Signal::size;
    Core* core = Core::instance();
    FFT* fft = core->fft;

    while (!_stopThread) //Normalement pas besoin de mutex
    {
        _mutexIO.lock();
        //En utilisant cette stratégie je suis sur de faire au mieu un calcul
        //à chaque fois que j'ai réelement une entrée et au pire moins de fois
        //(si je n'ai pas les performances suffisantes)
        _contidionIO.wait(&_mutexIO);
        //Il y aura une latence max de Signal::size + hardware pour l'entrée
        left =_leftOut;
        right = _rightOut;

        //Au pour reboucler la sortie on aura une latence
        // 3*Signal::size + hardwareIn + hardwareOut
        //Ici on comprend donc qu'il nous faut un Signal::size le plus petit possible,
        //et c'est loin d'être évident...
        _mutexIO.unlock();


        //Dans la suite Out contient le signal qui va sortir sur les HP (donc un signal non modifié)
        // et In est le signal qui va se faire analyser (et qui parfois peut-être modifié...)

        //Analyse FFT
        fft->mutex.lock();
        if (isPow2)
            fft->compute(left.samples,signal_size);
        else
            fft->pushSignal(left);
        fft->computeModule();
        fft->mutex.unlock();

        float bass=0;
        const unsigned int cut=core->bassCutoff;
        for (unsigned int i=0; i < cut; i++) {
            bass = std::max(fft->getModule()[i],bass);
        }
        bass *= 1.25; //on dynamise
        if (bass > 1.f) bass = 1.f; //Normalisé entre 0 et 1

        //Analyse du bruit (Noise)
        core->visualSignal->update(left);
        core->setNoise((float) core->visualSignal->noise / (80.f*200.f));


        core->setBass(bass);
    }

    _driver->stopStream();
    _driver->closeStream();
}

void AudioPipe::setApi(RtAudio::Api api)
{
    stop();
    delete _driver;
    _driver = new RtAudio(availableApiOrDefault(api));
    _driver->showWarnings();

    const std::vector<unsigned int> devices = _driver->getDeviceIds();
    _deviceOutId = availableDeviceOrDefault(devices, _deviceOutId, _driver->getDefaultOutputDevice());
    _deviceInId = availableDeviceOrDefault(devices, _deviceInId, _driver->getDefaultInputDevice());
}


void AudioPipe::setLatenyTime(float sec)
{
  int n = (int)(sec*(float)Signal::refreshRate);
  if (n > _latencySignalsL.size())
  {
    n = _latencySignalsL.size()-1;
  }
  else if (n <= 0.f)
  {
    n = 0;
  }
  _latencyTimeBuffer = n;

}

int AudioPipe::rtaudio_callback( void *outputBuffer, void *inputBuffer, unsigned int nBufferFrames,
                                 double streamTime, RtAudioStreamStatus status, void *data )
{
    (void) streamTime; (void) status;
    AudioPipe* pipe = (AudioPipe*) data;
    const unsigned int size = nBufferFrames > Signal::size ? Signal::size : nBufferFrames;


    if (pipe->_latencyTimeBuffer)
    {

      unsigned int k=0;
      unsigned int rb=(pipe->_latencyCurrentBuffer+pipe->_latencyTimeBuffer)%pipe->_latencySignalsL.size();
      if (inputBuffer)
      {

        //On enregistre le signal recu pour le diffuser plus tard
        Signal* recordR = &(pipe->_latencySignalsR[rb]);
        Signal* recordL = &(pipe->_latencySignalsL[rb]);
        for (unsigned int i=0; i< size; ++i) {

          recordR->samples[i] = ((sample*) inputBuffer)[k++];
          recordL->samples[i] = ((sample*) inputBuffer)[k++];
        }

        //On envois le signal retarder pour traitment fft etc...
        pipe->_mutexIO.lock();
        Signal* playR = &(pipe->_latencySignalsR[pipe->_latencyCurrentBuffer]);
        Signal* playL = &(pipe->_latencySignalsL[pipe->_latencyCurrentBuffer]);
        if (inputBuffer) {
          for (unsigned int i=0; i< size; ++i) {
            pipe->_leftOut.samples[i] = playL->samples[i];
            pipe->_rightOut.samples[i] = playR->samples[i];
          }
        }
        pipe->_mutexIO.unlock();


        //Trash fix du coup j'ai la flemme de comprendre le code de tt
        //facons tu n'as pas besoin de son
        //donc j,envois du silence dans les hp ;-)
        if (outputBuffer) {
          k=0;
          for (unsigned int i=0; i< size; ++i) {
            ((sample*) outputBuffer)[k++] = 0.0;
            ((sample*) outputBuffer)[k++] = 0.0;
          }
        }

        //On avance dans le temp.
        pipe->_latencyCurrentBuffer++;
        if (pipe->_latencyCurrentBuffer>=static_cast<int>(pipe->_latencySignalsL.size()))
        {
          pipe->_latencyCurrentBuffer=0;
        }
      }
    }
    else  //Normalement y a plein de trucs a gerer pour pouvoir jouer la music depuis
       /// la playlist mais bon pour le concert on s'en fou...
    {
      pipe->_mutexMixer.lock();
      if (pipe->_mixer) {//A t'on quelque chose à mixer avec le signal sonnore de sortie ?
        unsigned int k=0;
        if (inputBuffer) {
          for (unsigned int i=0; i< size; ++i) {
            pipe->_leftIn.samples[i] = ((sample*) inputBuffer)[k++];
            pipe->_rightIn.samples[i] = ((sample*) inputBuffer)[k++];
          }
        }
        pipe->_mutexIO.lock();
        pipe->_mixer->step(pipe->_leftIn,pipe->_rightIn,pipe->_leftOut,pipe->_rightOut);
        pipe->_mutexIO.unlock();
        pipe->_mutexMixer.unlock();
        if (outputBuffer) {
          k=0;
          for (unsigned int i=0; i< size; ++i) {
            ((sample*) outputBuffer)[k++] = pipe->_leftOut.samples[i];
            ((sample*) outputBuffer)[k++] = pipe->_rightOut.samples[i];
          }
        }
      } else {
        pipe->_mutexMixer.unlock();
        unsigned int k=0;
        pipe->_mutexIO.lock();
        if (inputBuffer) {
          for (unsigned int i=0; i< size; ++i) {
            pipe->_leftOut.samples[i] = ((sample*) inputBuffer)[k++];
            pipe->_rightOut.samples[i] = ((sample*) inputBuffer)[k++];
          }
        }
        pipe->_mutexIO.unlock();

        //Dans le cas ou je n'ai pas de mixage autant balancer directement la sortie
        // on gagne Signal::size de latence
        if (outputBuffer && inputBuffer && !pipe->_mixer) {
          unsigned long bytes = nBufferFrames * 2 * sizeof(float);
          memcpy( outputBuffer, inputBuffer, bytes);
        }
      }
    }
    pipe->_contidionIO.wakeAll();
    return 0;
}

bool AudioPipe::setInputDeviceId(int id) {
    if (isRunning()) return false;
    const std::vector<unsigned int> devices = getDeviceIds();
    if (id < 0 || std::find(devices.begin(), devices.end(), (unsigned int)id) == devices.end()) return false;
    _deviceInId = id;
    Core::instance()->settings.setValue("Audio/DeviceInId",id);
    return true;
}

bool AudioPipe::setOutputDeviceId(int id) {
    if (isRunning()) return false;
    const std::vector<unsigned int> devices = getDeviceIds();
    if (id < 0 || std::find(devices.begin(), devices.end(), (unsigned int)id) == devices.end()) return false;
    _deviceOutId = id;
    Core::instance()->settings.setValue("Audio/DeviceOutId",id);
    return true;
}

void AudioPipe::setMixer(AbstractStereoSignalMixer* mixer)
{
    _mutexMixer.lock();
    _mixer = mixer; //Il est possible de changer le Mixer en temps réel
    _mutexMixer.unlock();
}

void AudioPipe::show_critical(QString caption, QString error)
{
    QMessageBox::critical(NULL, caption, error); //Because QMessageBox must be created in GUI Thread so...
}
