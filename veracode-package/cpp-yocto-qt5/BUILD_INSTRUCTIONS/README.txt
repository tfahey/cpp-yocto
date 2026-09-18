BUILD INFORMATION FOR VERACODE SAST ANALYSIS
=============================================

Project: Qt5 Hello World with Yocto
Language: C++
Build System: CMake + Yocto BitBake
Framework: Qt5 (qtbase 5.15.13, qtdeclarative 5.15.13)

COMPILATION COMMANDS:
===================

To build this project (for reference, Veracode doesn't need to compile):

1. Using CMake directly:
   cd cpp-yocto-qt5
   mkdir build
   cd build
   cmake ..
   make

2. Using Yocto BitBake:
   cd ..
   bitbake hello-world

ARCHITECTURE SUPPORT:
====================
- x86-64: ELF 64-bit LSB pie executable
- ARM64 (aarch64): ELF 64-bit LSB executable

DEPENDENCIES:
=============
- Qt5 Core (qtbase 5.15.13)
- Qt5 GUI (qtbase 5.15.13)
- Qt5 Widgets (qtbase 5.15.13)
- Qt5 Declarative (qtdeclarative 5.15.13)

COMPILER FLAGS (from production build):
=======================================
- Optimization: -O2
- Debug symbols: Included
- Cross-compilation: Enabled for ARM64/x86-64
- Standard: C++11 (implicit in Qt5)

SOURCE FILES:
=============
- main.cpp: Entry point, creates QApplication and MainWindow
- mainwindow.h/cpp: Main GUI window with button/counter
- CMakeLists.txt: CMake build configuration

PREPROCESSED FILES:
===================
- main.i: Preprocessed main.cpp (all includes expanded)
- mainwindow.i: Preprocessed mainwindow.cpp (all includes expanded)

These .i files are generated with -E flag to expand all includes,
useful for deep static analysis without header file dependencies.
