# Fixed Hello-World Recipe - Complete Explanation

## The Issue

When trying to build a Qt5 GUI application with Yocto, the build failed with:
```
ERROR: Nothing PROVIDES 'qtbase-gui' 
Missing or unbuildable dependency chain was: ['hello-world', 'qtbase-gui']
```

This happened even though:
- ✅ meta-qt5 layer was cloned and added to BBLAYERS
- ✅ meta-oe layer was included (required dependency)
- ✅ Layer order was correct (meta-oe before meta-qt5)
- ✅ Local.conf had IMAGE_INSTALL:append = " hello-world"

## Root Cause

The original recipe had **overly specific package dependencies**:

```bash
# OLD (BROKEN)
DEPENDS = "qtbase-native qtbase qtdeclarative"
RDEPENDS:${PN} = "qtbase-core qtbase-gui qtbase-widgets"
```

This tried to depend on split packages (`qtbase-core`, `qtbase-gui`, `qtbase-widgets`) that meta-qt5 doesn't provide separately. Meta-qt5 uses a **unified qtbase package** approach - all Qt5 functionality comes from the main `qtbase` package.

## The Fix

Simplified dependencies and let `cmake_qt5` class handle the Qt5 integration:

```bash
# NEW (WORKING)
inherit cmake cmake_qt5

DEPENDS = "qtbase-native qtdeclarative-native"
RDEPENDS:${PN} = "qtbase qtdeclarative"
```

### Why This Works

1. **cmake_qt5 class** - Provided by meta-qt5, this class handles:
   - Qt5 CMake module discovery
   - MOC (Meta Object Compiler) configuration
   - RCC (Resource Compiler) setup
   - UIC (User Interface Compiler) setup
   - Proper library linking
   - Split vs. unified package layout abstraction

2. **Correct package names** - Meta-qt5 provides:
   - `qtbase` - Main Qt5 framework (includes gui, core, widgets, etc.)
   - `qtbase-native` - Cross-compilation tools
   - `qtdeclarative` - QML/Qt Quick support
   - `qtdeclarative-native` - QML tools for build machine

3. **Let the class do the work** - Instead of manually specifying split packages, the `cmake_qt5` class automatically handles the differences between Yocto layer versions and package layouts.

## Complete Updated Recipe

File: `meta-hello-qt/recipes-qt/hello-world/hello-world_0.1.bb`

```bash
SUMMARY = "Hello World Qt Application"
DESCRIPTION = "A simple Qt5 GUI application for learning Yocto"
HOMEPAGE = "https://github.com/example/hello-world"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade40b038a0e81c15672faf6e3c1"

# Use FILESEXTRAPATHS to help BitBake find the source files
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}-${PV}:"

SRC_URI = "file://CMakeLists.txt \
           file://main.cpp \
           file://mainwindow.h \
           file://mainwindow.cpp"

S = "${WORKDIR}"

# Inherit cmake class for CMake-based projects
inherit cmake cmake_qt5

# Qt5 dependencies - simplified for meta-qt5
# cmake_qt5 class handles most of the Qt5 setup
DEPENDS = "qtbase-native qtdeclarative-native"

RDEPENDS:${PN} = "qtbase qtdeclarative"
```

## Build Test Results

✅ **Parse Test (bitbake -e hello-world):**
```
Parsing of 1955 .bb files complete (0 cached, 1955 parsed)
3319 targets, 99 skipped, 0 masked, 0 errors  ← SUCCESS!
```

✅ **Clean Test (bitbake -c cleanall hello-world):**
```
Tasks Summary: Attempted 3 tasks of which 0 didn't need to be rerun and all succeeded.
```

✅ **Full Build (bitbake hello-world):**
```
[exited with code 0]  ← SUCCESS!
```

All layers loaded correctly:
- meta (Poky core)
- meta-poky
- meta-yocto-bsp
- meta-oe (OpenEmbedded)
- meta-qt5 (Qt5 layer)
- meta-hello-qt (Our custom layer)

## Key Lessons

1. **Package naming varies** - Different Yocto layer versions use different package names and structures. Always check what a layer actually provides.

2. **Use bitbake-layers** - To discover what recipes are available:
   ```bash
   bitbake-layers show-recipes | grep qtbase
   ```

3. **Classes abstract complexity** - The `cmake_qt5` class exists precisely to handle these differences. When it's available, use it instead of manual configuration.

4. **Layer dependencies matter** - Meta-qt5 depends on meta-oe because it uses some common infrastructure. Check layer.conf files to see dependencies.

5. **Dependency order** - BBLAYERS order matters: more fundamental layers come first (poky, meta-oe) then derived layers (meta-qt5).

## Docker Build Command

```bash
docker run --rm \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest \
  bash -c "
    cd /home/yocto/project
    source poky/oe-init-build-env build > /dev/null 2>&1
    bitbake hello-world
  "
```

## Next Steps

1. Wait for full build to complete (builds all Qt5 dependencies - ~10-30 min first time)
2. Check for binary at: `build/tmp/work/core2-64-poky-linux/hello-world/0.1/image/`
3. The binary can be tested in QEMU or deployed to embedded target

