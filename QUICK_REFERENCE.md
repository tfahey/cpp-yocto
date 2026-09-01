# Quick Reference: Key Files and Their Purpose

## File Structure Recap

```
cpp-yocto/
├── meta-hello-qt/
│   ├── conf/
│   │   └── layer.conf              ← Tells Yocto about this layer
│   ├── recipes-qt/
│   │   └── hello-world/
│   │       ├── hello-world.bb       ← BitBake recipe (THE MAIN FILE)
│   │       └── hello-world-0.1/     ← Source code
│   │           ├── CMakeLists.txt   ← How to build the app (CMake)
│   │           ├── main.cpp         ← Entry point
│   │           ├── mainwindow.h     ← Header
│   │           └── mainwindow.cpp   ← Implementation
│   └── COPYING                       ← License file
├── poky/                            ← Cloned from Git (Yocto core)
├── build/                           ← Created by Yocto build system
├── LEARNING_GUIDE.md
├── BUILD_INSTRUCTIONS.md
└── QUICK_REFERENCE.md
```

## The BitBake Recipe (hello-world.bb) - Explained Line by Line

```bash
SUMMARY = "Hello World Qt Application"
# A one-line description shown by bitbake-layers

DESCRIPTION = "A simple Qt5 GUI application for learning Yocto"
# Longer description

HOMEPAGE = "https://github.com/example/hello-world"
# Project URL

LICENSE = "MIT"
# Software license

LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=..."
# Checksum to verify license file hasn't been tampered with

SRC_URI = "file://CMakeLists.txt \
           file://main.cpp \
           file://mainwindow.h \
           file://mainwindow.cpp"
# Where to get source files
# "file://" means files from the hello-world-0.1/ directory

S = "${WORKDIR}"
# Source directory (where files are copied)

inherit cmake
# Use CMake build system (instead of Autotools, Meson, etc.)

DEPENDS = "qt5-qmake-native qt5-base qt5-declarative"
# Packages needed to BUILD this package
# "native" means tools for the build machine (not target)

RDEPENDS:${PN} = "qt5-core qt5-gui qt5-widgets"
# Packages needed to RUN this package on the target
# ${PN} = package name (hello-world)
```

## Important Yocto Variables

### In Recipes:

| Variable | Meaning |
|----------|---------|
| `${PN}` | Package Name |
| `${PV}` | Package Version |
| `${S}` | Source directory |
| `${WORKDIR}` | Working directory |
| `${D}` | Destination (installation root) |
| `${DEPENDS}` | Build-time dependencies |
| `${RDEPENDS}` | Runtime dependencies |

### In Configuration:

| Variable | File | Meaning |
|----------|------|---------|
| `MACHINE` | local.conf | Target architecture (qemux86-64, raspberrypi4, etc.) |
| `BBLAYERS` | bblayers.conf | Paths to all layers |
| `IMAGE_INSTALL` | local.conf | Packages to include in image |
| `BB_DISKMON_DIRS` | local.conf | Disk space monitoring |

## Common BitBake Tasks (Built-in)

Every recipe goes through these tasks:

```bash
fetch      → Download sources
extract    → Unpack archives
patch      → Apply patches
configure  → Run configure scripts (or CMake)
compile    → Run make
install    → Install to ${D}
package    → Split into binary packages
```

You can run individual tasks:

```bash
bitbake -c fetch hello-world      # Just download
bitbake -c compile hello-world    # Just compile
bitbake -c clean hello-world      # Remove build artifacts
bitbake -c clean -f hello-world   # Force clean
```

## CMakeLists.txt Explained

```cmake
cmake_minimum_required(VERSION 3.16)    # Require CMake 3.16+
project(hello-world)                     # Project name

set(CMAKE_CXX_STANDARD 11)               # Use C++11
set(CMAKE_AUTOMOC ON)                    # Auto-run Qt's moc tool
set(CMAKE_AUTORCC ON)                    # Auto-compile resources
set(CMAKE_AUTOUIC ON)                    # Auto-compile UI files

find_package(Qt5 COMPONENTS ...)         # Find Qt5
add_executable(hello-world ...)          # Create executable
target_link_libraries(...)               # Link against Qt5 libraries
install(TARGETS hello-world ...)         # Install binary to /usr/bin
```

## The Qt Application (main.cpp, mainwindow.*)

**main.cpp**: 
- Creates QApplication (the event loop)
- Creates MainWindow widget
- Shows it
- Runs the event loop

**mainwindow.h/cpp**:
- Subclass of QMainWindow (main application window)
- Creates a label and button
- Connects button clicks to slot handler
- Updates label when clicked

## Key Directories (After Building)

```bash
build/
├── conf/                           # Build configuration
│   ├── bblayers.conf              # Which layers to use
│   └── local.conf                 # Build settings
├── tmp/
│   ├── deploy/images/             # Final images/binaries
│   ├── work/                       # Build artifacts
│   │   └── qemux86-64/            # Per-machine builds
│   │       └── hello-world-0.1/   # Our package's build
│   └── sysroots/                  # Staging/root filesystems
└── cache/                          # BitBake cache
```

## To Build and Test

```bash
# 1. Clone Poky
git clone git://git.yoctoproject.org/poky -b scarthgap

# 2. Initialize environment
source poky/oe-init-build-env build

# 3. Add layer to bblayers.conf
# (edit build/conf/bblayers.conf)

# 4. Build our recipe
bitbake hello-world

# 5. Find the binary
find tmp -name "hello-world" -type f -executable

# 6. Build full image (optional)
# (set IMAGE_INSTALL in local.conf first)
bitbake core-image-minimal
```

## Troubleshooting Checklist

- [ ] Layer path in bblayers.conf is absolute and correct
- [ ] layer.conf exists in meta-hello-qt/conf/
- [ ] Filename is exactly `hello-world.bb` (matches version)
- [ ] Source files match SRC_URI in recipe
- [ ] No trailing whitespace in recipe
- [ ] Qt5 packages exist (run `bitbake-layers show-recipes | grep qt5`)
- [ ] Disk space available (run `df -h`)
- [ ] Read full error in `tmp/work/.../temp/log.do_*`

## More Information

- **Yocto Manual**: https://docs.yoctoproject.org/
- **BitBake Manual**: https://docs.yoctoproject.org/bitbake/
- **Poky Repositories**: https://git.yoctoproject.org/
- **Meta-Openembedded**: Common layers for packages
