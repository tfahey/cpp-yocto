# Version Mismatch Error - Complete Fix

**Error:** BitBake looking for `hello-world-1.0/` but files are in `hello-world-0.1/`

**Cause:** Recipe filename doesn't include version, so Yocto defaults to 1.0

**Solution:** Rename recipe file to include version number

---

## The Problem Explained

BitBake searches in this order:
1. Files in `hello-world-${PV}/` (where ${PV} is Package Version)
2. Files in `files/` directory
3. Files in machine-specific subdirs

When recipe is named just `hello-world.bb`:
- Yocto defaults to PV (Package Version) = 1.0
- Looks for files in `hello-world-1.0/`
- **But our files are in `hello-world-0.1/`!**

---

## Solution: Rename Recipe File

The fix is simple - rename the recipe file to match the version:

### On Your Mac

```bash
cd /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/

# Rename the recipe file to include version
mv hello-world.bb hello-world_0.1.bb

# Verify
ls -la
# Should show: hello-world_0.1.bb (not hello-world.bb)
```

**That's it!** The version will now match the directory name.

---

## How Recipe Versioning Works

### Option 1: Version in Filename (Recommended) ✅

```
recipes-qt/hello-world/
├── hello-world_0.1.bb      ← Version is in filename
└── hello-world-0.1/        ← Directory matches version
    ├── CMakeLists.txt
    └── main.cpp
```

BitBake extracts version from filename: `hello-world_0.1.bb` → PV=0.1

### Option 2: Version in Metadata

```bash
SUMMARY = "..."
VERSION = "0.1"    ← Explicitly set version
SRC_URI = "file://..."
```

### Option 3: Default Version (What's happening now)

```
hello-world.bb     ← No version in filename
```

Yocto defaults to PV=1.0 (which is wrong for us!)

---

## Step-by-Step Fix

### Step 1: Verify Current State

On your Mac:
```bash
ls -la /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/

# Shows:
# hello-world.bb          ← Wrong! No version
# hello-world-0.1/        ← Our source directory
```

### Step 2: Rename Recipe File

```bash
cd /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/

# Rename to include version
mv hello-world.bb hello-world_0.1.bb

# Verify
ls -la
# Shows:
# hello-world_0.1.bb      ← Correct! Version is 0.1
# hello-world-0.1/        ← Matches
```

### Step 3: Verify in Container

Inside Docker:
```bash
ls -la /home/yocto/project/meta-hello-qt/recipes-qt/hello-world/

# Should show:
# hello-world_0.1.bb      ← Version in filename
# hello-world-0.1/        ← Matching directory
```

### Step 4: Clear Cache and Retry

```bash
cd /home/yocto/project/build

# Clear cache
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*

# Run verification again
bash /home/yocto/project/VERIFY_SETUP.sh

# Should pass now!
```

---

## Recipe File Naming Convention

Yocto uses this naming convention:

```
${PN}_${PV}.bb
```

Where:
- `${PN}` = Package Name (hello-world)
- `${PV}` = Package Version (0.1)

**Valid names:**
- ✅ `hello-world_0.1.bb` (version in filename)
- ✅ `myapp_1.0.bb`
- ✅ `package_2.3.4.bb`

**Invalid names:**
- ❌ `hello-world.bb` (no version - confuses Yocto)
- ❌ `hello-world-0.1.bb` (hyphen, not underscore)

---

## File Structure After Fix

```
meta-hello-qt/recipes-qt/hello-world/
├── hello-world_0.1.bb           ← RENAMED (was: hello-world.bb)
└── hello-world-0.1/             ← Directory name matches version
    ├── CMakeLists.txt
    ├── main.cpp
    ├── mainwindow.h
    └── mainwindow.cpp
```

Now:
- Recipe filename: `hello-world_0.1.bb` → PV = 0.1
- Source directory: `hello-world-0.1/` → Matches!
- BitBake will find the files ✅

---

## Recipe Content (No Change Needed)

The recipe file itself stays the same - no edits needed:

```bash
SUMMARY = "Hello World Qt Application"
DESCRIPTION = "A simple Qt5 GUI application for learning Yocto"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade40b038a0e81c15672faf6e3c1"

# Use FILESEXTRAPATHS to help BitBake find the source files
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}-${PV}:"

SRC_URI = "file://CMakeLists.txt \
           file://main.cpp \
           file://mainwindow.h \
           file://mainwindow.cpp"

S = "${WORKDIR}"

inherit cmake

DEPENDS = "qt5-qmake-native qt5-base qt5-declarative"

RDEPENDS:${PN} = "qt5-core qt5-gui qt5-widgets"
```

Just the filename changed!

---

## Complete Fix Workflow

On Mac:
```bash
# 1. Navigate to recipe directory
cd /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/

# 2. Rename recipe file
mv hello-world.bb hello-world_0.1.bb

# 3. Verify
ls -la
# hello-world_0.1.bb ✓
# hello-world-0.1/ ✓
```

In Docker container:
```bash
cd /home/yocto/project/build

# 4. Initialize environment
source ../poky/oe-init-build-env .

# 5. Clear old cache
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*

# 6. Run verification
bash /home/yocto/project/VERIFY_SETUP.sh

# 7. Should pass now! If yes, build:
bitbake hello-world
```

---

## Why This Matters

BitBake needs to know the version to:
- Find source files in correct directory
- Calculate file checksums
- Track builds by version
- Handle version updates

Without version in filename, it guesses wrong (defaults to 1.0)!

---

## Alternative Fixes (Not Recommended)

### Option A: Rename Directory

Instead of renaming the file, rename the directory:

```bash
# DON'T DO THIS - Not recommended!
cd /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/
mv hello-world-0.1 hello-world-1.0
```

**Problem:** Mismatch with our source code version

### Option B: Add VERSION to Recipe

```bash
# DON'T DO THIS - Confusing!
SUMMARY = "..."
VERSION = "0.1"    # Explicit version
```

**Problem:** Version in two places, confusing for maintenance

### Option C: Rename Directory to Match Default

```bash
# DON'T DO THIS - Wrong version!
mv hello-world-0.1 hello-world-1.0
```

**Problem:** Version number is wrong, confusing

---

## Recommended Solution ✅

**Just rename the recipe file:**

```bash
# This is the correct approach
mv hello-world.bb hello-world_0.1.bb
```

Simple, follows Yocto convention, no other changes needed!

---

## Verification

After renaming, verify:

```bash
# On Mac
ls -la /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/
# Should show: hello-world_0.1.bb, hello-world-0.1/

# In Docker
ls -la /home/yocto/project/meta-hello-qt/recipes-qt/hello-world/
# Should show: hello-world_0.1.bb, hello-world-0.1/

# Run verification
cd /home/yocto/project/build
source ../poky/oe-init-build-env .
bash /home/yocto/project/VERIFY_SETUP.sh
# Should pass!
```

---

## Summary

**Problem:** Recipe filename `hello-world.bb` → Yocto infers version 1.0, but files are in `hello-world-0.1/`

**Solution:** Rename recipe to `hello-world_0.1.bb`

**Result:** Version matches → BitBake finds files ✅

**Time to fix:** 10 seconds! 🚀

---

## See Also

- **FIX_AND_BUILD.md** - Complete build guide
- **SRC_URI_FIX.md** - SRC_URI details
- **QUICK_BUILD_STEPS.md** - Build commands
