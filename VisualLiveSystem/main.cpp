#include <QApplication>
#include <QDir>
#include <QFile>
#include <QMessageBox>
#include <QTextStream>
#include "mainwindow.h"
#include "core.h"

#include <cstdlib>
#include <iostream>
#include <map>

int main(int argc, char *argv[])
{

    std::map<int, std::string> apiMap;
    apiMap[RtAudio::MACOSX_CORE] = "OS-X Core Audio";
    apiMap[RtAudio::WINDOWS_ASIO] = "Windows ASIO";
    apiMap[RtAudio::WINDOWS_DS] = "Windows Direct Sound";
    apiMap[RtAudio::WINDOWS_WASAPI] = "Windows WASAPI";
    apiMap[RtAudio::UNIX_JACK] = "Jack Client";
    apiMap[RtAudio::LINUX_ALSA] = "Linux ALSA";
    apiMap[RtAudio::LINUX_PULSE] = "Linux PulseAudio";
    apiMap[RtAudio::LINUX_OSS] = "Linux OSS";
    apiMap[RtAudio::RTAUDIO_DUMMY] = "RtAudio Dummy";
    std::vector< RtAudio::Api > apis;
    RtAudio :: getCompiledApi( apis );

    std::cout << "\nRtAudio Version " << RtAudio::getVersion() << std::endl;

    std::cout << "\nCompiled APIs:\n";
    for ( unsigned int i=0; i<apis.size(); i++ )
      std::cout << "  " << apiMap[ apis[i] ] << std::endl;


    QApplication a(argc, argv);

    const QString applicationDirectory = QCoreApplication::applicationDirPath();
    if (!QDir::setCurrent(applicationDirectory))
    {
        QMessageBox::critical(NULL,
                              "Startup directory error",
                              QString("Visual Live System could not use its application directory.\n\n"
                                      "Directory: %1\n\n"
                                      "The data files cannot be loaded.")
                                  .arg(QDir::toNativeSeparators(applicationDirectory)));
        return EXIT_FAILURE;
    }

    // Some OpenGL widgets initialize while MainWindow is still being built.
    // A diagnostic dialog must not make Qt quit before the main window is shown.
    a.setQuitOnLastWindowClosed(false);

    QCoreApplication::setOrganizationName("Razor 1911");
    QCoreApplication::setOrganizationDomain("http://razor1911.com/");
    QCoreApplication::setApplicationName("Visual Live System");

    QFile f(":qdarkstyle/style.qss");
    f.open(QFile::ReadOnly | QFile::Text);
    QTextStream ts(&f);
    a.setStyleSheet(ts.readAll());

    MainWindow w;
    w.showMaximized();
    a.setQuitOnLastWindowClosed(true);
    
    return a.exec();
}
