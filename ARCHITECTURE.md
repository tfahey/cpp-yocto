# Architecture and Build Flow

## High-Level Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Your Development Machine                  │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │ meta-hello-qt│         │    poky      │                 │
│  │   (our code) │         │ (Yocto core) │                 │
│  └──────┬───────┘         └──────┬───────┘                 │
│         │                        │                          │
│         └────────────┬───────────┘                          │
│                      │                                       │
│              ┌───────▼────────┐                             │
│              │    BitBake     │                             │
│              │  (build engine)│                             │
│              └───────┬────────┘                             │
│                      │                                       │
│           ┌──────────┴──────────┐                           │
│           ▼                     ▼                           │
│    ┌────────────┐        ┌────────────┐                   │
│    │  Download  │        │   Cross    │                   │
│    │  Qt, deps  │  ──→   │  Compile   │                   │
│    └────────────┘        └────────────┘                   │
│           │                     │                          │
│           └──────────┬──────────┘                          │
│                      ▼                                      │
│           ┌─────────────────┐                              │
│           │  Linked Binary  │ (hello-world)               │
│           └────────┬────────┘                              │
│                    │                                        │
│  ┌─────────────────▼──────────────────┐                   │
│  │         build/tmp/deploy/          │                   │
│  │  (all build artifacts and images)  │                   │
│  └────────────────────────────────────┘                   │
│                                                               │
└─────────────────────────────────────────────────────────────┘
```

## BitBake Task Flow

When you run `bitbake hello-world`, this happens:

```
START: bitbake hello-world
  │
  ├─ Parse recipes
  │  ├─ Find hello-world.bb
  │  ├─ Load meta-hello-qt/layer.conf
  │  └─ Load dependencies (Qt5)
  │
  ├─ FETCH task
  │  └─ Download sources to tmp/work/
  │
  ├─ EXTRACT task
  │  └─ Unpack/copy sources
  │
  ├─ PATCH task
  │  └─ Apply any patches (none in our case)
  │
  ├─ CONFIGURE task
  │  └─ Run CMake with cross-compiler settings
  │      set(CMAKE_CXX_COMPILER arm-linux-...)
  │      set(CMAKE_SYSTEM_NAME Linux)
  │
  ├─ COMPILE task
  │  └─ Run make (cross-compilation)
  │      arm-linux-g++ ← compiles to ARM binary (example)
  │
  ├─ INSTALL task
  │  └─ Install to tmp/sysroots/staging/
  │
  ├─ PACKAGE task
  │  └─ Create .ipk (ARM package)
  │
  └─ END: Binary ready in tmp/deploy/
```

## Our Custom Layer Structure

```
meta-hello-qt/
├── conf/layer.conf
│   └─ Tells Yocto: "This is a layer called meta-hello-qt"
│
├── recipes-qt/
│   └─ Directory following Yocto naming convention
│       └─ hello-world/
│           ├─ hello-world.bb         ← The BitBake recipe
│           │                          (Yocto downloads and uses this)
│           │
│           └─ hello-world-0.1/        ← Source code directory
│               │                       (version matches PV in recipe)
│               ├─ main.cpp
│               ├─ mainwindow.h
│               ├─ mainwindow.cpp
│               └─ CMakeLists.txt
│
└── COPYING                            ← License file
```

## How Yocto Finds Files

When BitBake processes `hello-world.bb`:

```
1. Looks for SRC_URI entries:
   SRC_URI = "file://CMakeLists.txt \
              file://main.cpp \
              file://mainwindow.h \
              file://mainwindow.cpp"

2. Searches in the recipe's directory:
   meta-hello-qt/recipes-qt/hello-world/
   
3. Finds version directory:
   meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/
   
4. Copies all file:// sources to build's tmp/work/
```

The version number matters! If your `.bb` file says `hello-world.bb`:
- Yocto infers version 0.1 (no explicit PV)
- Looks for `hello-world-0.1/` directory
- Version also controls recipe versioning/updates

## Qt Integration Points

```
QApplication
    ↓
  Qt5 Libraries (from qt5-base, qt5-gui, qt5-widgets)
    ↓
  Cross-compiled for target architecture
    ↓
  Depends specified in hello-world.bb:
  DEPENDS = "qt5-qmake-native qt5-base ..."
  RDEPENDS = "qt5-core qt5-gui qt5-widgets"
    ↓
  BitBake finds Qt recipes in:
  poky/meta/recipes-qt/
    ↓
  Qt5 built for target, linked into our binary
```

## Recipe Dependencies

### DEPENDS (Build-time)

```
hello-world.bb
  DEPENDS = "qt5-qmake-native qt5-base qt5-declarative"
             │                  │                   │
             ├─ Tools for build machine     ├─ Libraries for target
             │                  │                   │
             Runs on: x86-64    Runs on: ARM (example)
             (your computer)    (target device)
```

### RDEPENDS (Runtime)

```
Built binary hello-world needs:
  RDEPENDS = "qt5-core qt5-gui qt5-widgets"
  
When you run: ./hello-world
  ↓
  Loads: libQt5Core.so
  Loads: libQt5Gui.so
  Loads: libQt5Widgets.so
  
These must be on the target device!
```

## The Yocto Build Workflow

```
┌──────────────────────────────────────────────────────────┐
│ Layer Configuration (bblayers.conf)                      │
│ ✓ poky/meta                    (core recipes)            │
│ ✓ poky/meta-poky               (Poky-specific)           │
│ ✓ meta-hello-qt                (our custom layer) ← NEW! │
└──────────────────────────────────────────────────────────┘
                        ▼
        ┌───────────────────────────────────┐
        │  BitBake Recipe Parser            │
        │  Reads: *.bb, *.bbappend files    │
        └───────────────────────────────────┘
                        ▼
        ┌───────────────────────────────────┐
        │  Dependency Resolver              │
        │  Figures out build order          │
        │  hello-world needs:               │
        │  ├─ qt5-base                      │
        │  ├─ qt5-base needs: glib, zlib   │
        │  └─ ... (recursively)             │
        └───────────────────────────────────┘
                        ▼
        ┌───────────────────────────────────┐
        │  Build Each Package               │
        │  In dependency order:             │
        │  1. zlib                          │
        │  2. glib (depends on zlib)        │
        │  3. qt5-base (depends on glib)    │
        │  4. hello-world (depends on qt5)  │
        └───────────────────────────────────┘
                        ▼
        ┌───────────────────────────────────┐
        │  Final Binary Output              │
        │  tmp/deploy/ipk/.../hello-world   │
        └───────────────────────────────────┘
```

## Directory Tree During Build

```
cpp-yocto/
├── meta-hello-qt/              ← Our layer (we created)
│   └── recipes-qt/hello-world/
│       ├── hello-world.bb
│       └── hello-world-0.1/
│           └── (source files)
│
├── poky/                       ← Cloned from git
│   ├── meta/                   ← Core recipes (Qt, glib, etc.)
│   ├── meta-poky/
│   ├── meta-yocto-bsp/
│   └── oe-init-build-env       ← Initialization script
│
├── build/                      ← Created by oe-init-build-env
│   ├── conf/
│   │   ├── bblayers.conf       ← Our layer added here!
│   │   └── local.conf          ← Build settings
│   │
│   ├── tmp/                    ← Build artifacts
│   │   ├── work/
│   │   │   └── qemux86-64/
│   │   │       ├── qt5-base-*/
│   │   │       ├── qt5-gui-*/
│   │   │       └── hello-world-0.1/
│   │   │           ├── source files copied here
│   │   │           ├── temp/ (build logs)
│   │   │           └── image/ (compiled binary)
│   │   │
│   │   ├── deploy/
│   │   │   └── images/
│   │   │       └── qemux86-64/
│   │   │           ├── core-image-minimal-*.rootfs.*
│   │   │           └── ... (various image files)
│   │   │
│   │   └── sysroots/           ← Staging area
│   │       ├── qemux86-64/     ← Target root fs
│   │       └── x86_64-linux/   ← Build tools
│   │
│   └── cache/                  ← BitBake cache files
│
└── (other docs)
```

## Cross-Compilation Example

```
Input Files (our app):
  main.cpp, mainwindow.cpp

                    ↓

CMake configures for cross-compilation:
  CMAKE_CXX_COMPILER = arm-linux-gnueabihf-g++
  CMAKE_SYSTEM_NAME = Linux
  CMAKE_SYSTEM_PROCESSOR = arm

                    ↓

Cross-compiler toolchain runs:
  arm-linux-gnueabihf-g++ -c main.cpp -o main.o
  arm-linux-gnueabihf-g++ main.o mainwindow.o -o hello-world
  
                    ↓

Output:
  Binary: hello-world (ARM executable)
  Cannot run on x86-64 machine directly!
  Can only run on ARM target device

                    ↓

To test:
  - Use QEMU emulator (ARM emulation on x86-64)
  - Flash to actual ARM device (Raspberry Pi, etc.)
  - Use rootfs from tmp/deploy/
```

## Summary: How It All Connects

1. **You write**: C++ Qt app (main.cpp, mainwindow.cpp)
2. **You configure**: CMakeLists.txt (how to build it)
3. **You describe**: hello-world.bb (Yocto metadata)
4. **BitBake reads**: hello-world.bb + layer configuration
5. **BitBake finds**: Dependencies (Qt5, etc.)
6. **BitBake downloads**: All sources
7. **BitBake cross-compiles**: For target architecture
8. **Result**: hello-world binary (ARM-specific)
9. **Deployment**: Can go into image or extracted standalone

Everything revolves around that one `.bb` file—it's the bridge between your application and Yocto!
