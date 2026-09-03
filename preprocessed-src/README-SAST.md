# SAST Analysis - Qt5 Hello World

## Source Files

All source files are located in `sources/`:

- `main.cpp` - Application entry point
- `mainwindow.h` - Main window header
- `mainwindow.cpp` - Main window implementation
- `CMakeLists.txt` - CMake build configuration

## How to Generate Preprocessed Source

### Option 1: Using GCC (requires Qt5 development headers)
```bash
cd sources

# Preprocess main.cpp
g++ -E -I/usr/include/qt5 \
    -I/usr/include/qt5/QtCore \
    -I/usr/include/qt5/QtGui \
    -I/usr/include/qt5/QtWidgets \
    main.cpp > main.i

# Preprocess mainwindow.cpp
g++ -E -I/usr/include/qt5 \
    -I/usr/include/qt5/QtCore \
    -I/usr/include/qt5/QtGui \
    -I/usr/include/qt5/QtWidgets \
    mainwindow.cpp > mainwindow.i
```

### Option 2: Using Clang
```bash
clang++ -E [same flags as above] main.cpp > main.i
```

### Option 3: Using Docker (includes Qt5)
```bash
docker build -f Dockerfile.sast -t sast-builder .
docker run --rm -v $(pwd):/work sast-builder
```

## SAST Tools Recommendations

### For C++ Security Analysis:
1. **Clang Static Analyzer** - Built-in, detects memory issues, logic errors
2. **Coverity** - Commercial, very thorough
3. **Sonarqube** - Community and commercial, good C++ support
4. **Cppcheck** - Free, good for security issues
5. **Flawfinder** - Fast, focuses on security flaws

### Running Analysis

#### Using Clang Static Analyzer:
```bash
cd sources
scan-build cmake .
scan-build make
```

#### Using Cppcheck:
```bash
cd sources
cppcheck --enable=all --security main.cpp mainwindow.cpp
```

## Code Overview

### main.cpp
Entry point for the Qt5 application. Creates QApplication and MainWindow.

**Security considerations:**
- Input validation from command line arguments
- Resource management (QObjects)
- Signal/slot connections

### mainwindow.cpp / mainwindow.h
Main application window with:
- Label displaying "Hello, World!"
- Button that increments a counter on click
- Signal/slot mechanism for button clicks

**Security considerations:**
- GUI event handling
- Memory management of Qt widgets
- Qt object hierarchy (parent-child relationships)

## Build System

Built with:
- **Yocto/BitBake** - Embedded Linux build system
- **CMake** - C++ build configuration
- **Qt5** - GUI framework (qtbase 5.15.13, qtdeclarative 5.15.13)
- **GCC** - Cross-compiler (for ARM64/x86-64)

## Binaries

The compiled binaries are available in the GitHub Release:
- x86-64: `hello-world-x86-64` (889 KB)
- ARM64: `hello-world-arm64` (67 KB)

Both compiled with optimization flags and include debug symbols.

## Next Steps

1. Generate preprocessed source files (.i files) using one of the methods above
2. Run SAST tools on the preprocessed or original source
3. Review findings and security implications
4. Generate SAST report
5. Commit report to `sast-analysis` branch
