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
1. **Veracode** - Enterprise-grade SaaS platform, comprehensive security analysis
2. **Clang Static Analyzer** - Built-in, detects memory issues, logic errors
3. **Coverity** - Commercial, very thorough
4. **Sonarqube** - Community and commercial, good C++ support
5. **Cppcheck** - Free, good for security issues
6. **Flawfinder** - Fast, focuses on security flaws

### Running Analysis

#### Using Veracode (Enterprise)
```bash
# 1. Create a .veracode_profile file in home directory (~/.veracode_profile)
[DEFAULT]
veracode_api_key_id = <YOUR_API_ID>
veracode_api_key_secret = <YOUR_API_SECRET>
veracode_base_url = https://api.veracode.com

# 2. Package the source code (see "Packaging for Veracode" section below)
# 3. Upload to Veracode platform
# 4. Monitor scan results in Veracode dashboard
```

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

## Packaging for Veracode (and other Enterprise SAST)

Veracode and similar enterprise SAST tools require source code to be packaged in a specific format. Here's how to package this Qt5 application for analysis:

### Step 1: Gather Source Files
```bash
# Create a clean package directory
mkdir -p veracode-package/cpp-yocto-qt5

# Copy all source files
cp -r sources/* veracode-package/cpp-yocto-qt5/

# Copy build configuration
cp -r ../build/conf veracode-package/cpp-yocto-qt5/

# Copy Yocto recipe for context
cp -r ../meta-hello-qt veracode-package/cpp-yocto-qt5/
```

### Step 2: Generate Preprocessed Files (Optional but Recommended)
```bash
cd veracode-package/cpp-yocto-qt5

# Generate preprocessed source for better analysis
g++ -E -I/usr/include/qt5 \
    -I/usr/include/qt5/QtCore \
    -I/usr/include/qt5/QtGui \
    -I/usr/include/qt5/QtWidgets \
    -dD main.cpp > main.i

g++ -E -I/usr/include/qt5 \
    -I/usr/include/qt5/QtCore \
    -I/usr/include/qt5/QtGui \
    -I/usr/include/qt5/QtWidgets \
    -dD mainwindow.cpp > mainwindow.i
```

### Step 3: Create Build Directory Structure (Important for Veracode)
```bash
# Veracode needs to understand the build structure
# Create a mock build directory with instructions

mkdir -p veracode-package/cpp-yocto-qt5/BUILD_INSTRUCTIONS

cat > veracode-package/cpp-yocto-qt5/BUILD_INSTRUCTIONS/README.txt << 'EOF'
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
EOF

cat > veracode-package/cpp-yocto-qt5/BUILD_INSTRUCTIONS/COMPILATION_DATABASE.json << 'EOF'
[
  {
    "directory": "/work/cpp-yocto-qt5",
    "command": "g++ -c -I/usr/include/qt5 -I/usr/include/qt5/QtCore -I/usr/include/qt5/QtGui -I/usr/include/qt5/QtWidgets -O2 main.cpp -o main.o",
    "file": "main.cpp"
  },
  {
    "directory": "/work/cpp-yocto-qt5",
    "command": "g++ -c -I/usr/include/qt5 -I/usr/include/qt5/QtCore -I/usr/include/qt5/QtGui -I/usr/include/qt5/QtWidgets -O2 mainwindow.cpp -o mainwindow.o",
    "file": "mainwindow.cpp"
  }
]
EOF
```

### Step 4: Create Metadata File for Analysis
```bash
# Create a metadata file for the SAST scanner

cat > veracode-package/cpp-yocto-qt5/.veracode_metadata.txt << 'EOF'
PROJECT_NAME=Qt5-HelloWorld-Yocto
VERSION=1.0
LANGUAGE=C++
BUILD_SYSTEM=CMake/Yocto
FRAMEWORKS=Qt5
ARCHITECTURE=Multi-arch (x86-64, ARM64)
COMPILATION_UNITS=2 (main.cpp, mainwindow.cpp)
HEADER_FILES=1 (mainwindow.h)
THIRD_PARTY=Qt5 libraries (included in framework)
BUILD_DATE=2026-09-03
BUILD_STATUS=Production Ready
EOF
```

### Step 5: Create Archive for Upload
```bash
# Create a zip archive for uploading to Veracode

cd veracode-package
zip -r cpp-yocto-qt5-veracode.zip cpp-yocto-qt5/

# For large projects, can also use tar.gz:
# tar -czf cpp-yocto-qt5-veracode.tar.gz cpp-yocto-qt5/

# Verify archive contents
unzip -l cpp-yocto-qt5-veracode.zip | head -20
```

### Step 6: Upload to Veracode
```bash
# Using Veracode Python API wrapper

pip install veracode-python-api

# Set up authentication
export VERACODE_API_ID=<your_api_id>
export VERACODE_API_KEY=<your_api_key>

# Create application profile (if not exists)
veracode create-app --app-name "Qt5-HelloWorld" --business-unit "Security"

# Upload for scanning
veracode upload-app \
  --app-name "Qt5-HelloWorld" \
  --file cpp-yocto-qt5-veracode.zip \
  --scan-name "Automated Qt5 Scan $(date +%Y-%m-%d)" \
  --auto-scan
```

### Step 7: Monitor Results
```bash
# Check scan status
veracode get-app-info --app-name "Qt5-HelloWorld"

# View detailed results
veracode get-detailed-report --app-name "Qt5-HelloWorld" --format csv > results.csv
```

### Expected Analysis Results for Qt5 Hello World

**Typical findings to expect (baseline):**

1. **Memory Management** - Qt uses garbage collection for QObjects, generally safe
2. **Signal/Slot Connections** - Type-safe, compile-time checked by Qt's moc
3. **GUI Input Handling** - Button clicks are safe, no direct user input parsing
4. **Resource Leaks** - Low risk due to Qt's parent-child object model

**Best Practices for Production C++ Code:**
- ✅ Qt's object model provides automatic memory management
- ✅ Signals/slots are type-safe
- ✅ No low-level pointer manipulation in this example
- ✅ No direct buffer operations (buffer overflow risk)
- ✅ No SQL/database queries (injection risk)
- ✅ No network operations (protocol parsing risk)

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
