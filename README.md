# Yocto + Qt Hello World - Learning Project

A complete learning project for building a Qt-based C++ GUI application using the Yocto embedded Linux build system.

## What You'll Learn

This project teaches:
- **Yocto fundamentals**: layers, recipes, BitBake, metadata
- **Qt5 integration**: how to include Qt in embedded builds
- **Cross-compilation**: building for target architectures
- **Package management**: dependencies and custom packages
- **Linux build systems**: CMake and Yocto workflows

## Project Contents

📚 **Documentation:**
- [LEARNING_GUIDE.md](LEARNING_GUIDE.md) - High-level overview
- [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) - Step-by-step build guide
- [QUICK_REFERENCE.md](QUICK_REFERENCE.md) - File reference and commands

📦 **Application Code:**
- [meta-hello-qt/](meta-hello-qt/) - Our custom Yocto layer
  - [recipes-qt/hello-world/hello-world.bb](meta-hello-qt/recipes-qt/hello-world/hello-world.bb) - BitBake recipe
  - [recipes-qt/hello-world/hello-world-0.1/](meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/) - Source code
    - `main.cpp` - Qt application entry point
    - `mainwindow.h` / `mainwindow.cpp` - Main window implementation
    - `CMakeLists.txt` - Build configuration

## Quick Start

### Choose Your Path

**For macOS/Windows:** 🐳 Docker is highly recommended
```bash
# 1. Build Docker image
docker build -t yocto-qt-builder:latest .

# 2. Start container
docker run -it --name yocto-build -v $(pwd):/home/yocto/project yocto-qt-builder:latest

# 3. Inside container, follow the native build steps
```

**For Linux:** Native build is fastest
```bash
# Clone Poky, initialize, configure, and build
# See BUILD_INSTRUCTIONS.md for step-by-step
```

### Documentation Path

1. **START_HERE.md** - Orientation and learning path
2. **LEARNING_GUIDE.md** - Yocto concepts  
3. **BUILD_INSTRUCTIONS.md** - Build steps for Docker or Native Linux
4. **DOCKER_BUILD.md** - Detailed Docker guide (if using Docker)
5. **QUICK_REFERENCE.md** - Quick lookups while building
6. **DOCKER_CHEATSHEET.md** - Docker commands (if using Docker)

## Architecture

```
hello-world app (C++ with Qt5)
        ↓
   CMakeLists.txt (how to build)
        ↓
   hello-world.bb (Yocto recipe)
        ↓
   BitBake (build system)
        ↓
   Yocto/Poky (embedded Linux)
        ↓
   Cross-compiled binary
```

## The Application

A simple Qt5 GUI window with:
- A label: "Hello from Yocto + Qt!"
- A button: "Click Me"
- Updates the label with click count

Demonstrates:
- Qt widget creation
- Signal/slot connections
- CMake-based Qt project
- Yocto recipe integration

## Minimum Requirements

### Option 1: Native Linux Build
- **OS**: Linux (Ubuntu 20.04+ recommended)
- **Disk**: 50-100 GB free space
- **RAM**: 4 GB minimum, 8+ GB recommended
- **Tools**: Git, Python 3.8+, build-essential
- **Time**: 2-6 hours for first build (subsequent: 5-30 min)

### Option 2: Docker Build (Recommended for macOS/Windows)
- **OS**: macOS, Windows, or Linux
- **Docker**: Docker Desktop or Docker CLI
- **Disk**: 60 GB (project + Docker overhead)
- **RAM**: 4+ GB
- **Time**: ~20 min image build + 2-6 hours first Yocto build

## Key Concepts Explained

### Yocto
A build framework that creates customized Linux distributions using recipes and layers.

### BitBake
The build engine that parses recipes and orchestrates the build process.

### Recipe (`.bb` file)
A declarative file that describes:
- What to build
- Where to get the source
- How to build it (configure, compile, install)
- Dependencies

### Layer
A collection of recipes organized by functionality. Think of it as a plugin system.

### Cross-compilation
Building code for a different target architecture than your build machine (e.g., ARM on x86).

## File Structure

```
cpp-yocto/
├── README.md                                 ← You are here
├── LEARNING_GUIDE.md
├── BUILD_INSTRUCTIONS.md
├── QUICK_REFERENCE.md
├── meta-hello-qt/                            ← Our custom Yocto layer
│   ├── conf/
│   │   └── layer.conf                        ← Layer metadata
│   ├── recipes-qt/
│   │   └── hello-world/
│   │       ├── hello-world.bb                ← BitBake recipe ⭐
│   │       └── hello-world-0.1/              ← Source code
│   │           ├── CMakeLists.txt
│   │           ├── main.cpp
│   │           ├── mainwindow.h
│   │           └── mainwindow.cpp
│   └── COPYING                               ← License
├── poky/                                     ← Yocto core (to be cloned)
└── build/                                    ← Build artifacts (created)
```

## Next Steps After Building

1. **Modify the Qt app**: Add more widgets, animations, or features
2. **Create variants**: Build for different target architectures (ARM, MIPS, etc.)
3. **Package other software**: Create recipes for dependencies or complementary apps
4. **Optimize for size**: Learn about image recipes and minimization
5. **Target real hardware**: Adapt MACHINE setting and build for Raspberry Pi, etc.
6. **Create custom images**: Combine multiple packages into a complete embedded system

## Troubleshooting

Most issues stem from:
- **Layer not found**: Check bblayers.conf path
- **Qt not available**: Ensure core Qt recipes are in BBLAYERS
- **Missing dependencies**: Run `bitbake -c clean` and rebuild
- **Out of disk space**: Remove build/tmp/ and try again

See BUILD_INSTRUCTIONS.md for more troubleshooting.

## Resources

- **Yocto Project**: https://www.yoctoproject.org/
- **Yocto Docs**: https://docs.yoctoproject.org/
- **Poky Git**: https://git.yoctoproject.org/poky
- **BitBake Manual**: https://docs.yoctoproject.org/bitbake/
- **Qt Documentation**: https://doc.qt.io/qt-5/

## License

This project is licensed under the MIT License. See [meta-hello-qt/COPYING](meta-hello-qt/COPYING).

---

**Good luck with your Yocto learning journey! 🚀**

Start with LEARNING_GUIDE.md and work your way through BUILD_INSTRUCTIONS.md. Refer to QUICK_REFERENCE.md as needed.
