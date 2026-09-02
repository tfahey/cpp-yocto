# Qt5 Package Names Mismatch - Fix

**Error:** `Nothing PROVIDES 'qt5-declarative'` but suggests `qtdeclarative`

**Cause:** Package names in our recipe don't match the actual names in meta-qt5

**Solution:** Update recipe to use correct package names from meta-qt5

---

## The Problem

Our recipe (`hello-world.bb`) specifies:
```bash
DEPENDS = "qt5-qmake-native qt5-base qt5-declarative"
RDEPENDS:${PN} = "qt5-core qt5-gui qt5-widgets"
```

But meta-qt5 uses different names:
- `qt5-declarative` → `qtdeclarative` ❌ (wrong)
- `qt5-base` → `qtbase` ❌ (wrong)
- `qt5-core` → `qtbase-core` ❌ (wrong)
- `qt5-gui` → `qtbase-gui` ❌ (wrong)
- `qt5-widgets` → `qtbase-widgets` ❌ (wrong)

---

## Quick Fix

### Edit hello-world.bb on Your Mac

```bash
# Open the recipe
nano /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/hello-world_0.1.bb
```

**Find these lines:**
```bash
DEPENDS = "qt5-qmake-native qt5-base qt5-declarative"
RDEPENDS:${PN} = "qt5-core qt5-gui qt5-widgets"
```

**Replace with:**
```bash
DEPENDS = "qtbase-native qtbase qtdeclarative"
RDEPENDS:${PN} = "qtbase-core qtbase-gui qtbase-widgets"
```

**Save:** Ctrl+O, Enter, Ctrl+X

### Complete Updated Recipe

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

inherit cmake

# Qt5 dependencies (corrected names for meta-qt5)
DEPENDS = "qtbase-native qtbase qtdeclarative"

RDEPENDS:${PN} = "qtbase-core qtbase-gui qtbase-widgets"
```

---

## In Docker: Rebuild

```bash
cd /home/yocto/project/build

# Clear cache
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*

# Rebuild
bitbake hello-world
```

---

## Qt5 Package Name Mappings

| Old Name (Wrong) | New Name (meta-qt5) | Purpose |
|---|---|---|
| qt5-qmake-native | qtbase-native | Build tools |
| qt5-base | qtbase | Core framework |
| qt5-declarative | qtdeclarative | QML support |
| qt5-core | qtbase-core | Core library |
| qt5-gui | qtbase-gui | GUI library |
| qt5-widgets | qtbase-widgets | Widgets library |
| qt5-sql | qtbase-sql | SQL support |
| qt5-network | qtbase-network | Network support |

---

## Why This Happens

Different Yocto layers use different naming conventions:

- **Old meta-qt5 (from meta-openembedded):** Used `qt5-*` names
- **New meta-qt5 (standalone):** Uses `qtbase-*` and `qt*` names

The standalone meta-qt5 repository follows a different naming scheme.

---

## Verification

After updating the recipe:

```bash
# In Docker
bitbake-layers show-recipes | grep -E "qtbase|qtdeclarative"
# Should find the packages

# Build
bitbake hello-world
# Should work now!
```

---

## Common Qt5 Packages in meta-qt5

```bash
qtbase              # Core framework (replaces qt5-base)
qtbase-native       # Native build tools
qtbase-core         # Core library
qtbase-gui          # GUI library
qtbase-widgets      # Widgets library
qtbase-network      # Network support
qtbase-sql          # SQL support
qtbase-svg          # SVG support
qtbase-opengl       # OpenGL support
qtdeclarative       # QML/QQuick support
qttools             # Qt tools
qttools-native      # Native tools
```

---

## Complete Fix Workflow

### On Mac (1 minute)

```bash
# Edit recipe
nano /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/hello-world_0.1.bb

# Change:
# OLD: DEPENDS = "qt5-qmake-native qt5-base qt5-declarative"
# NEW: DEPENDS = "qtbase-native qtbase qtdeclarative"

# And:
# OLD: RDEPENDS:${PN} = "qt5-core qt5-gui qt5-widgets"
# NEW: RDEPENDS:${PN} = "qtbase-core qtbase-gui qtbase-widgets"

# Save and close
```

### In Docker (2 minutes)

```bash
cd /home/yocto/project/build

# Clear cache
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*

# Verify packages exist
bitbake-layers show-recipes | grep qtbase | head -5

# Build!
bitbake hello-world
```

---

## Summary

**Problem:** Package names don't match meta-qt5

**Solution:** Update recipe to use correct names:
- `qt5-*` → `qtbase-*` (for base packages)
- `qt5-declarative` → `qtdeclarative` (for QML)

**Result:** BitBake finds all required packages ✅

---

## See Also

- **QT5_WITH_OE_DEPENDENCY.md** - Qt5 setup overview
- **QUICK_QT5_CORRECT.md** - Quick setup guide
- **hello-world.bb** - Our recipe (needs updating)
