# VisualLiveSystem
Visual Live System is a new visual jockey software for professional live performance.
Compatible with Mac and PC, he is able to render complex real time 3D scene fully based on the sound.
He have an intuitive interface thinked like a DJ solution, 2 channels of real time effects and a master pannel for mixing theses.
Midi controllers is supported.


<img src="http://www.aduprat.com/pub/vls.jpg">

More details soon.

## Setup

The Linux build targets Qt 5.15 and uses the project-local RtAudio, PortMidi,
BASS, and BASSFLAC files under `third_party`. The system must provide a C++
compiler, qmake, Make, Qt 5 Core/Gui/Widgets/OpenGL/XML, GLEW, and GLU. On
Arch/CachyOS these are supplied by `base-devel`, `qt5-base`, `glew`, and `glu`.

Build both applications from a separate build directory:

```bash
mkdir -p build-qt5
cd build-qt5
qmake ../VisualLiveSystem.pro CONFIG+=release
make -j"$(nproc)"
```

The executables are written to `release`. They automatically use that directory
for `data` and `settings.ini`, so they can be launched by absolute path or from
another working directory.

```bash
/home/mk2k/Data/Code/CPP/VisualLiveSystem/release/VisualLiveSystem
# or
/home/mk2k/Data/Code/CPP/VisualLiveSystem/release/SceneEditor
```

If a scene configuration or shader is invalid, the dialog identifies the
scene, exact file path, and reason. Shader dialogs include the OpenGL compiler
output under **Show Details**; the failing effect is skipped so the main window
can remain open.


## Usage:

Visual Live System
 * If you have a midi controller just go to the midi controller view, make a new profil and assign yours faders like of you want.
 * After that, open the visual manager select some few scenes and drag'n'drop of the channels A and B. Apply.
 * Go to the post processing tabulation, and add some post fx (the order change the result). Apply.
 * Get the output audio of your DJ on input of your computer (if you just want to make a test, the microphone should be correct).
 * Now, open the projector's window, move them to the projector screen and double clik for the fullscreen mode.
 * Enjoy by making beautiful transition between the channels when you have a drop :) !
