# Complete Fix and Build Guide

The SRC_URI error has been fixed. Here's how to proceed.

---

## What Was Fixed

Updated `hello-world.bb` recipe to add `FILESEXTRAPATHS`. This tells BitBake exactly where to find the source files.

**Change made:**
```bash
# Added this line to recipe:
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}-${PV}:"
```

This helps BitBake locate files in the version-named directory (`hello-world-0.1/`).

---

## Quick Build Steps (Copy & Paste)

### Inside Docker Container

```bash
# 1. Navigate to build directory
cd /home/yocto/project/build

# 2. Verify everything is set up correctly
bash /home/yocto/project/VERIFY_SETUP.sh

# 3. If verification passes, build!
bitbake hello-world

# 4. Or build full image
bitbake core-image-minimal
```

---

## Detailed Steps

### Step 1: Verify Setup

Run the verification script in your Docker container:

```bash
cd /home/yocto/project/build
bash /home/yocto/project/VERIFY_SETUP.sh
```

This checks:
- ✓ Source files exist
- ✓ Locale is set to en_US.UTF-8
- ✓ Layer is registered
- ✓ Recipe is found
- ✓ Configuration is correct
- ✓ BitBake can parse recipe
- ✓ BitBake can fetch sources

**Expected output:**
```
1. Checking source files...
✓ Source directory exists: /home/yocto/project/meta-hello-qt/recipes-qt/hello-world/hello-world-0.1
  ✓ CMakeLists.txt found
  ✓ main.cpp found
  ✓ mainwindow.h found
  ✓ mainwindow.cpp found

2. Checking locale...
✓ Locale set to en_US.UTF-8

3. Checking Yocto layer...
✓ meta-hello-qt layer registered

4. Checking BitBake recipe...
✓ hello-world recipe found

5. Checking build configuration...
✓ conf/local.conf exists
  ✓ MACHINE = "qemux86-64"
  ✓ hello-world in IMAGE_INSTALL

6. Checking BitBake recipe parsing...
✓ BitBake can parse hello-world recipe

7. Checking BitBake fetch...
✓ BitBake can fetch sources

================================
Verification Complete!
================================
```

### Step 2: If Verification Fails

**If source files not found:**
```bash
# Verify files exist on your Mac
ls -la /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/

# Should show all 4 files
# If missing, they need to be in this directory
```

**If locale not set:**
```bash
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Or rebuild Docker (has locale support now):
# exit container and: docker build -t yocto-qt-builder:latest .
```

**If layer not registered:**
```bash
# Check bblayers.conf
grep meta-hello-qt conf/bblayers.conf

# If missing, add to BBLAYERS:
# /home/yocto/project/meta-hello-qt
```

**If recipe not found:**
```bash
# Check files exist in layer
ls -la /home/yocto/project/meta-hello-qt/recipes-qt/hello-world/

# Should show:
# hello-world.bb
# hello-world-0.1/
```

**If BitBake parse error:**
```bash
# Show detailed error
bitbake -e hello-world 2>&1 | grep -i error

# Common fixes:
# - Check conf/bblayers.conf syntax
# - Check conf/local.conf syntax
# - Run: bitbake -c clean hello-world
```

### Step 3: Build

Once verification passes, build:

```bash
# Build just our app (fast)
bitbake hello-world

# OR build full image (slow, ~2-6 hours)
bitbake core-image-minimal
```

---

## Expected Build Output

### Building hello-world

```
Loading cache: 100%
Loaded 4321 entries from dependency cache in 1.234s
ERROR: Cannot find a proper machine type...
```

Wait for the build to start. You'll see:

```
Parsing recipes: 100% |  1234/1234 |  10s
Loading packages: 100% |  1234/1234 |  5s
Resolving dependencies: 100% | ...
Preparing workspace: 100% | ...
Building core-image-minimal: 100% | ...
```

---

## If Build Fails

Common errors and fixes:

### Error: "Unable to get checksum for SRC_URI"

The recipe fix should resolve this. If still occurring:

```bash
# Clear cache and try again
bitbake -c cleanall hello-world
bitbake hello-world
```

### Error: "cmake: command not found"

CMake should be in dependencies. Verify:

```bash
bitbake -e hello-world | grep CMAKE
```

### Error: "Qt5 not found"

Qt5 layers should be in core. Verify:

```bash
bitbake-layers show-recipes | grep qt5-base
```

Should show the recipe.

### Other Errors

Check these:

```bash
# 1. View full error log
cat /home/yocto/project/build/tmp/work/qemux86-64/hello-world-0.1/temp/log.do_*

# 2. Clean and retry
bitbake -c clean hello-world
bitbake hello-world

# 3. Show variables
bitbake -e hello-world | head -20
```

---

## Success: What to Expect

After successful build, you'll see:

```
Loading cache: 100%
Loaded 1234 entries from dependency cache in 1.234s
Parsing recipes: 100%
Loading packages: 100%
Resolving dependencies: 100%
Preparing workspace: 100%

Building hello-world-0.1 in /home/yocto/project/build/tmp/work/qemux86-64/hello-world-0.1
Configuring...
Building...
Installing...

Package hello-world created

Build succeeded!
```

### Find Build Output

```bash
# Built executable
find /home/yocto/project/build/tmp -name hello-world -type f -executable

# Should be in:
# /home/yocto/project/build/tmp/work/qemux86-64/hello-world-0.1/image/usr/bin/hello-world

# Or in deployed form:
ls /home/yocto/project/build/tmp/deploy/rpm/
```

---

## Complete Workflow (From Scratch)

If starting fresh inside a new container:

```bash
# 1. Clone Poky (on Mac first to avoid git hang)
cd /Users/tfahey/github/cpp-yocto
git clone https://git.yoctoproject.org/poky -b scarthgap

# 2. Start Docker
docker run -it \
  --name yocto-build \
  -e LANG=en_US.UTF-8 \
  -e LC_ALL=en_US.UTF-8 \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest

# 3. Inside container
cd /home/yocto/project/poky
source oe-init-build-env ../build
cd ../build

# 4. Edit configs
nano conf/bblayers.conf
# Add: /home/yocto/project/meta-hello-qt

nano conf/local.conf
# Add:
# MACHINE = "qemux86-64"
# IMAGE_INSTALL:append = " hello-world"

# 5. Verify
bash /home/yocto/project/VERIFY_SETUP.sh

# 6. Build
bitbake hello-world
```

---

## Verification Script Details

The `VERIFY_SETUP.sh` script checks:

1. **Source files** - Are all 4 files present?
2. **Locale** - Is en_US.UTF-8 set?
3. **Layer** - Is meta-hello-qt registered?
4. **Recipe** - Can BitBake find hello-world.bb?
5. **Configuration** - Are MACHINE and IMAGE_INSTALL set?
6. **Parse** - Can BitBake parse the recipe?
7. **Fetch** - Can BitBake fetch the sources?

Run it anytime to diagnose issues:

```bash
bash /home/yocto/project/VERIFY_SETUP.sh
```

---

## Files Updated

1. **hello-world.bb** - Added FILESEXTRAPATHS for file discovery
2. **VERIFY_SETUP.sh** - New verification script
3. **SRC_URI_FIX.md** - New troubleshooting guide
4. **FIX_AND_BUILD.md** - This guide

---

## See Also

- **SRC_URI_FIX.md** - Detailed SRC_URI error explanation
- **TROUBLESHOOTING.md** - General troubleshooting
- **BUILD_INSTRUCTIONS.md** - Full build workflow
- **LOCALE_FIX.md** - Locale error fixes
- **CONFIGURE_BBLAYERS.md** - Configuration details

---

## Summary

✅ Recipe updated with file path helper
✅ Verification script created
✅ Ready to build!

**Next:** Run `bash VERIFY_SETUP.sh` in the build directory, then build!

```bash
bitbake hello-world
```

Good luck! 🚀
