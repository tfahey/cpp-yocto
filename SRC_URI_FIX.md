# SRC_URI Error Fix - "file could not be found"

**Error:** `Unable to get checksum for hello-world SRC_URI entry CMakeLists.txt: file could not be found`

**Cause:** BitBake can't find the source files referenced in the recipe's `SRC_URI`

**Root issue:** File location mismatch in Docker container

---

## Quick Diagnosis

First, verify the files exist in the container:

```bash
# Inside Docker container
ls -la /home/yocto/project/meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/

# Should show:
# CMakeLists.txt
# main.cpp
# mainwindow.cpp
# mainwindow.h
```

If files don't show up, the volume mount isn't working properly.

---

## Solution 1: Fix File Location (Recommended)

The issue is likely that BitBake expects files in a specific location. Try moving files to the recipe directory itself:

### Step 1: Check Current Structure
```bash
# On your Mac:
ls -la /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/

# Should show:
# hello-world.bb
# hello-world-0.1/  (contains CMakeLists.txt, main.cpp, etc.)
```

### Step 2: Move Files (If Needed)

Some Yocto recipes expect files in a `files/` subdirectory instead. Try this structure:

```bash
# Create files directory
mkdir -p /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/files

# Move source files there
mv /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/* \
   /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/files/

# Remove empty directory
rm -rf /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/hello-world-0.1
```

### Step 3: Update Recipe

Edit `hello-world.bb` - change:

```bash
# OLD (wrong path):
SRC_URI = "file://CMakeLists.txt \
           file://main.cpp \
           file://mainwindow.h \
           file://mainwindow.cpp"

# NEW (correct path):
SRC_URI = "file://files/CMakeLists.txt \
           file://files/main.cpp \
           file://files/mainwindow.h \
           file://files/mainwindow.cpp"
```

---

## Solution 2: Use Proper Recipe Format

For CMake projects, the better approach is to use a tarball. But if you want to keep local files, use this format:

### Edit hello-world.bb:

```bash
SUMMARY = "Hello World Qt Application"
DESCRIPTION = "A simple Qt5 GUI application for learning Yocto"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade40b038a0e81c15672faf6e3c1"

# Use FILESPATH to find source files
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}-${PV}:"

# Source from version-named directory
SRC_URI = "file://CMakeLists.txt \
           file://main.cpp \
           file://mainwindow.h \
           file://mainwindow.cpp"

S = "${WORKDIR}"

inherit cmake

DEPENDS = "qt5-qmake-native qt5-base qt5-declarative"
RDEPENDS:${PN} = "qt5-core qt5-gui qt5-widgets"
```

Then keep structure as:
```
recipes-qt/hello-world/
├── hello-world.bb
└── hello-world-0.1/
    ├── CMakeLists.txt
    ├── main.cpp
    ├── mainwindow.h
    └── mainwindow.cpp
```

---

## Solution 3: Verify Volume Mount

The files might not be accessible from the container. Check:

```bash
# On Mac - verify files exist
ls -la /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/

# In container - verify they're shared
docker exec yocto-build ls -la /home/yocto/project/meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/

# Should show same files in both places
```

If files don't show in container, the volume mount is broken:

```bash
# Restart container with explicit volume mount
docker stop yocto-build
docker rm yocto-build

# Verify files exist on Mac first!
ls -la /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/

# Restart container
docker run -it \
  --name yocto-build \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest

# Inside container - verify access
ls -la /home/yocto/project/meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/
```

---

## Solution 4: Clean Build Cache

Sometimes BitBake caches stale information. Clear it:

```bash
# Inside container, in build/ directory
bitbake -c clean hello-world
rm -rf tmp/work/*/hello-world-*

# Or clean everything
bitbake -c cleanall hello-world
rm -rf tmp/

# Try again
bitbake hello-world
```

---

## How SRC_URI File Paths Work

### File Path Rules

In Yocto recipes, `file://` URIs work like this:

```bash
# File structure:
recipes-qt/hello-world/
├── hello-world.bb
└── hello-world-0.1/         ← Version directory (matches ${PV})
    ├── CMakeLists.txt
    └── main.cpp

# In hello-world.bb:
SRC_URI = "file://CMakeLists.txt"

# BitBake looks for file at:
# recipes-qt/hello-world/hello-world-0.1/CMakeLists.txt  ✓ Found!
```

### Alternative: Files Directory

```bash
# Alternative file structure:
recipes-qt/hello-world/
├── hello-world.bb
└── files/                    ← Alternative: files/ dir
    ├── CMakeLists.txt
    └── main.cpp

# In hello-world.bb:
SRC_URI = "file://files/CMakeLists.txt"

# BitBake looks for file at:
# recipes-qt/hello-world/files/CMakeLists.txt  ✓ Found!
```

---

## Complete Diagnosis Steps

Run these in order:

```bash
# 1. Verify files on Mac
echo "=== On Mac ==="
ls -la /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/

# 2. Verify files in container
echo "=== In Container ==="
ls -la /home/yocto/project/meta-hello-qt/recipes-qt/hello-world/

# 3. Check recipe syntax
echo "=== Recipe ==="
cat /home/yocto/project/meta-hello-qt/recipes-qt/hello-world/hello-world.bb | grep -A 5 "SRC_URI"

# 4. Check BitBake can find layer
echo "=== Layer ==="
bitbake-layers show-recipes | grep hello-world

# 5. Try to fetch (shows detailed error)
echo "=== Fetch ==="
bitbake -c fetch hello-world 2>&1 | grep -A 5 "error\|not found"

# 6. Check work directory
echo "=== Work Dir ==="
find /home/yocto/project/build/tmp/work -name "*hello-world*" -type d | head -3
ls -la /home/yocto/project/build/tmp/work/*/hello-world-*/
```

---

## File Structure Reference

### Current Structure (Should Work)
```
meta-hello-qt/recipes-qt/hello-world/
├── hello-world.bb                    ← Recipe
└── hello-world-0.1/                  ← Version directory
    ├── CMakeLists.txt
    ├── main.cpp
    ├── mainwindow.cpp
    └── mainwindow.h
```

**In recipe:**
```bash
SRC_URI = "file://CMakeLists.txt \
           file://main.cpp \
           ..."
```

### Alternative Structure (Also Works)
```
meta-hello-qt/recipes-qt/hello-world/
├── hello-world.bb                    ← Recipe
└── files/                            ← Files directory
    ├── CMakeLists.txt
    ├── main.cpp
    ├── mainwindow.cpp
    └── mainwindow.h
```

**In recipe:**
```bash
SRC_URI = "file://files/CMakeLists.txt \
           file://files/main.cpp \
           ..."
```

---

## Verify Before Building

Before running `bitbake core-image-minimal`, verify:

```bash
# 1. Files exist
[ -f /home/yocto/project/meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/CMakeLists.txt ] && echo "✓ Files found" || echo "✗ Files missing"

# 2. Layer is registered
bitbake-layers show-recipes | grep hello-world > /dev/null && echo "✓ Recipe found" || echo "✗ Recipe not found"

# 3. Can fetch
bitbake -c fetch hello-world 2>&1 | grep -i "error" && echo "✗ Fetch error" || echo "✓ Fetch OK"

# 4. If all pass, build
bitbake hello-world
```

---

## Common Mistakes

### ❌ Wrong paths in SRC_URI
```bash
# DON'T do this:
SRC_URI = "file:///Users/tfahey/..."  (Mac path in container!)
SRC_URI = "file://./CMakeLists.txt"   (relative path)
SRC_URI = "CMakeLists.txt"            (missing file://)
```

### ❌ Files in wrong location
```bash
# DON'T do this:
recipes-qt/hello-world/CMakeLists.txt  (should be in version dir)
recipes-qt/CMakeLists.txt              (wrong directory level)
```

### ❌ Recipe version mismatch
```bash
# DON'T do this:
hello-world.bb version 1.0
hello-world-0.1/ directory            (version mismatch!)

# DO this:
hello-world.bb (version defaults to 0.1)
hello-world-0.1/ directory            (matches)
```

---

## If Still Failing

### Enable Debug Logging

```bash
# Run BitBake with verbose output
bitbake -vvv hello-world 2>&1 | tee /tmp/bitbake-debug.log

# Search for actual error
grep -i "unable\|not found\|error" /tmp/bitbake-debug.log | head -10
```

### Check Layer Configuration

```bash
# Verify layer.conf is correct
cat /home/yocto/project/meta-hello-qt/conf/layer.conf

# Should contain:
# BBFILES += "${LAYERDIR}/recipes-*/*/*.bb"
```

### Manual File Copy

If all else fails, copy files to work directory:

```bash
# Create work directory manually
mkdir -p /home/yocto/project/build/tmp/work/qemux86-64/hello-world-0.1/

# Copy files there
cp /home/yocto/project/meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/* \
   /home/yocto/project/build/tmp/work/qemux86-64/hello-world-0.1/

# Verify
ls -la /home/yocto/project/build/tmp/work/qemux86-64/hello-world-0.1/
```

---

## Quick Summary

| Issue | Fix |
|-------|-----|
| Files not found | Ensure `hello-world-0.1/` directory exists with files |
| Path not found in container | Check volume mount: `-v /Users/tfahey/...:/home/yocto/project` |
| SRC_URI paths wrong | Use `file://CMakeLists.txt` for files in version directory |
| Layer not found | Verify BBLAYERS includes `/home/yocto/project/meta-hello-qt` |
| Stale cache | Run `bitbake -c clean hello-world` |

---

## See Also

- **CONFIGURE_BBLAYERS.md** - Layer configuration
- **TROUBLESHOOTING.md** - General Yocto errors
- **BUILD_INSTRUCTIONS.md** - Full build workflow
