# START HERE - Yocto + Qt Learning Project

Welcome! This is a complete learning project for building a C++ Qt GUI application with Yocto. Follow this guide to get started.

## 📖 Read These in Order

### 1. **README.md** (5 min) - Overview
Read the [README.md](README.md) for a complete project overview, requirements, and what you'll learn.

### 2. **LEARNING_GUIDE.md** (10 min) - Concepts
Read the [LEARNING_GUIDE.md](LEARNING_GUIDE.md) to understand what Yocto is and the high-level architecture.

### 3. **ARCHITECTURE.md** (15 min) - Deep Dive
Read the [ARCHITECTURE.md](ARCHITECTURE.md) to see how everything connects with diagrams and flow charts.

### 4. **BUILD_INSTRUCTIONS.md** (follow along) - Build It!
Follow the [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md) step-by-step to actually build the project.

### 5. **QUICK_REFERENCE.md** (bookmark) - Lookup
Keep the [QUICK_REFERENCE.md](QUICK_REFERENCE.md) handy while building for quick answers.

---

## 🗂️ Project Structure

```
cpp-yocto/
├── Documentation (📚 start with START_HERE.md)
│   ├── README.md                    ← Project overview
│   ├── LEARNING_GUIDE.md            ← Yocto concepts
│   ├── ARCHITECTURE.md              ← Build flow & diagrams
│   ├── BUILD_INSTRUCTIONS.md        ← Step-by-step build guide
│   ├── QUICK_REFERENCE.md           ← Quick lookup
│   └── START_HERE.md               ← You are here
│
└── Application & Layer (📦 follow BUILD_INSTRUCTIONS.md)
    └── meta-hello-qt/              ← Your custom Yocto layer
        ├── conf/
        │   └── layer.conf          ← Layer metadata
        ├── recipes-qt/hello-world/
        │   ├── hello-world.bb      ← BitBake recipe (KEY FILE!)
        │   └── hello-world-0.1/    ← Source code
        │       ├── CMakeLists.txt
        │       ├── main.cpp
        │       ├── mainwindow.h
        │       └── mainwindow.cpp
        └── COPYING                 ← License
```

---

## ⚡ Quick Start (tldr)

### Option A: Docker (Works on macOS, Windows, Linux)

```bash
# 1. Build Docker image (one-time, ~20 min)
cd /Users/tfahey/github/cpp-yocto
docker build -t yocto-qt-builder:latest .

# 2. Clone Poky on your Mac (this works reliably!)
git clone https://git.yoctoproject.org/poky -b scarthgap

# 3. Start container (Poky is auto-shared via volume mount)
docker run -it \
  --name yocto-build \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest

# 4-6: Inside container, follow Option B steps 2-5 below!
```

**Pro tip:** If `git clone` hangs inside container, clone Poky on your Mac first. The volume mount shares it automatically! See [DOCKER_HOST_SETUP.md](DOCKER_HOST_SETUP.md)

**For detailed Docker instructions:** See [DOCKER_BUILD.md](DOCKER_BUILD.md)

### Option B: Native Linux Build

```bash
# 1. Clone Yocto
cd /Users/tfahey/github/cpp-yocto
git clone git://git.yoctoproject.org/poky -b scarthgap

# 2. Initialize
source poky/oe-init-build-env build
cd build

# 3. Add our layer to build/conf/bblayers.conf
#    (add this line to BBLAYERS:)
#    /Users/tfahey/github/cpp-yocto/meta-hello-qt

# 4. Edit build/conf/local.conf:
#    IMAGE_INSTALL:append = " hello-world"

# 5. Build!
bitbake core-image-minimal
```

**For detailed native build instructions:** See [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md)

**Recommendation:** Use Docker if on macOS/Windows, native build if on Linux.

---

## 🎯 Learning Path

### Beginner (New to Yocto)
1. Read: README.md
2. Read: LEARNING_GUIDE.md (understand concepts)
3. Read: ARCHITECTURE.md (see how it works)
4. Follow: BUILD_INSTRUCTIONS.md

### Intermediate (Familiar with Linux build systems)
1. Skim: LEARNING_GUIDE.md
2. Reference: QUICK_REFERENCE.md
3. Follow: BUILD_INSTRUCTIONS.md
4. Refer: ARCHITECTURE.md for questions

### Advanced (Want to modify/extend)
1. Scan: All documentation
2. Modify: Application code (main.cpp, etc.)
3. Update: CMakeLists.txt and hello-world.bb
4. Build: `bitbake hello-world -f` (force rebuild)

---

## 📝 Key Files Explained

| File | Purpose |
|------|---------|
| `hello-world.bb` | **BitBake Recipe** - Tells Yocto how to build our app |
| `layer.conf` | Registers our layer with Yocto |
| `CMakeLists.txt` | Configures the C++ build (CMake) |
| `main.cpp` | Qt application entry point |
| `mainwindow.h/cpp` | Main GUI window implementation |

The `.bb` file is the **most important**—it's the bridge between your app and Yocto!

---

## ❓ Common Questions

**Q: Do I need to know Yocto already?**
A: No! That's why we have LEARNING_GUIDE.md and ARCHITECTURE.md. Start there.

**Q: Can I run this on macOS?**
A: The final build must run on Linux. You can set up files on macOS, but need Linux for the actual build (use a VM or Docker).

**Q: How long does the build take?**
A: First build: 2-6 hours. Subsequent builds: 5-30 minutes (due to caching).

**Q: What if the build fails?**
A: Check BUILD_INSTRUCTIONS.md's troubleshooting section. Most issues are layer configuration or disk space.

**Q: Can I modify the Qt application?**
A: Yes! Edit `main.cpp`, `mainwindow.cpp`, etc. Then run `bitbake hello-world -f` to rebuild.

**Q: What's the difference between BitBake and CMake?**
A: CMake = builds individual C++ projects. BitBake = orchestrates building entire Linux distributions using many recipes.

---

## 🔗 External Resources

- **Yocto Project**: https://www.yoctoproject.org/
- **Yocto Manual**: https://docs.yoctoproject.org/
- **BitBake Manual**: https://docs.yoctoproject.org/bitbake/
- **Qt Documentation**: https://doc.qt.io/qt-5/
- **Poky Repository**: https://git.yoctoproject.org/poky

---

## 📋 Checklist Before Building

- [ ] Read README.md
- [ ] Read LEARNING_GUIDE.md
- [ ] Read ARCHITECTURE.md
- [ ] Have ~60 GB free disk space
- [ ] Have Linux system (or VM) available
- [ ] Have Git installed
- [ ] Have Python 3.8+ installed
- [ ] Read BUILD_INSTRUCTIONS.md completely

---

## 🚀 Next Steps

1. **Start learning**: Read the docs in order (README → LEARNING_GUIDE → ARCHITECTURE)
2. **Prepare environment**: Ensure you have Linux and disk space
3. **Clone Poky**: Follow BUILD_INSTRUCTIONS.md Step 1
4. **Build**: Follow the remaining steps
5. **Celebrate** 🎉: You built an embedded Linux application!

---

## Questions While Reading?

- **Terminology unclear?** → Check QUICK_REFERENCE.md
- **How does X work?** → Check ARCHITECTURE.md
- **What's this variable?** → Check QUICK_REFERENCE.md
- **Build failed?** → Check BUILD_INSTRUCTIONS.md "Troubleshooting"

---

**Ready? Start with [README.md](README.md)** →
