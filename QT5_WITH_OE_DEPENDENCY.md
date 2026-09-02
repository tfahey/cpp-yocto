# Qt5 with OpenEmbedded Dependency - Correct Setup

**Error:** `Layer 'qt5-layer' depends on layer 'openembedded-layer', but this layer is not enabled`

**Reason:** meta-qt5 layer depends on meta-oe (from meta-openembedded)

**Solution:** Add BOTH meta-oe and meta-qt5 to BBLAYERS, in the correct order

---

## Quick Fix

### On Your Mac

You should still have both repositories:

```bash
# You should have both:
ls -la /Users/tfahey/github/cpp-yocto/meta-openembedded/meta-oe/
# Should exist

ls -la /Users/tfahey/github/cpp-yocto/meta-qt5/
# Should exist
```

If either is missing, clone it:

```bash
cd /Users/tfahey/github/cpp-yocto

# If meta-openembedded is missing
git clone https://github.com/openembedded/meta-openembedded.git

# If meta-qt5 is missing
git clone https://github.com/meta-qt5/meta-qt5.git -b scarthgap
```

### In Docker: Fix bblayers.conf

This is the KEY issue - the order and inclusion:

```bash
cd /home/yocto/project/build
nano conf/bblayers.conf
```

**Correct BBLAYERS (order matters!):**

```bash
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
  /home/yocto/project/meta-openembedded/meta-oe \
  /home/yocto/project/meta-qt5 \
  /home/yocto/project/meta-hello-qt \
"
```

**Critical points:**
- ✅ meta-oe BEFORE meta-qt5 (dependency order)
- ✅ Include meta-oe from meta-openembedded
- ✅ Include meta-qt5 standalone
- ✅ Include meta-hello-qt last

**Save:** Ctrl+O, Enter, Ctrl+X

### In Docker: Clear and Rebuild

```bash
# Clear old cache
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*
rm -rf tmp/cache/

# Verify layers are loaded correctly
bitbake-layers show-layers
# Should show:
# - openembedded-layer (meta-oe)
# - qt5-layer (meta-qt5)
# - meta-hello-qt

# Verify Qt5 recipes are found
bitbake-layers show-recipes | grep qt5-base
# Should show: qt5-base

# Build!
bitbake hello-world
```

---

## Understanding the Dependency

```
meta-qt5
  ↓ (depends on)
meta-oe (openembedded-layer)
  ↓ (depends on)
Poky core (meta, meta-poky, meta-yocto-bsp)
```

So BBLAYERS must include all three levels, in order:

1. **Poky core** (base Yocto)
2. **meta-oe** (OpenEmbedded general packages)
3. **meta-qt5** (Qt5 recipes that depend on meta-oe)
4. **meta-hello-qt** (our app layer)

---

## Correct File Structure

```
/Users/tfahey/github/cpp-yocto/
├── poky/
├── meta-openembedded/         ← Still needed for meta-oe!
│   ├── meta-oe/               ← REQUIRED by meta-qt5
│   ├── meta-multimedia/
│   └── ... other layers
├── meta-qt5/                  ← Standalone Qt5 layer
│   ├── conf/
│   └── recipes-qt5/
├── meta-hello-qt/
└── build/
```

---

## Correct bblayers.conf

```bash
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
  /home/yocto/project/meta-openembedded/meta-oe \
  /home/yocto/project/meta-qt5 \
  /home/yocto/project/meta-hello-qt \
"
```

**This is NOT optional:**
- ✅ `meta-openembedded/meta-oe` - Required by Qt5
- ✅ `meta-qt5` - The Qt5 layer itself

---

## Verification Commands

```bash
# In Docker container
cd /home/yocto/project/build

# 1. Check layers are registered
bitbake-layers show-layers
# Should include:
# - openembedded-layer
# - qt5-layer
# - meta-hello-qt

# 2. Check dependencies are satisfied
bitbake-layers show-recipes | grep -E "qt5-base|oe-meta"
# Should show recipes from both layers

# 3. Check specific Qt5 recipe
bitbake -e qt5-base | head -20
# Should show Qt5 variables without errors
```

---

## Complete Workflow

### On Mac: Ensure Both Repos Exist

```bash
cd /Users/tfahey/github/cpp-yocto

# Verify meta-openembedded exists
ls -la meta-openembedded/meta-oe/
# If not, clone it:
# git clone https://github.com/openembedded/meta-openembedded.git

# Verify meta-qt5 exists
ls -la meta-qt5/
# If not, clone it:
# git clone https://github.com/meta-qt5/meta-qt5.git -b scarthgap
```

### In Docker: Fix Configuration

```bash
# 1. Stop and restart
docker stop yocto-build
docker rm yocto-build

docker run -it \
  -e LANG=en_US.UTF-8 \
  -e LC_ALL=en_US.UTF-8 \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest

# 2. Initialize
cd /home/yocto/project/poky
source oe-init-build-env ../build
cd ../build

# 3. Fix bblayers.conf
nano conf/bblayers.conf
# Add meta-oe and meta-qt5 in correct order
# Save: Ctrl+O, Enter, Ctrl+X

# 4. Clean and rebuild
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*

# 5. Verify
bitbake-layers show-layers | grep -E "openembedded|qt5"
# Both should show

# 6. Build!
bitbake hello-world
```

---

## Why This Works

The dependency chain is:

```
meta-qt5 requires openembedded-layer
  ↓
openembedded-layer = meta-oe from meta-openembedded
  ↓
So we MUST include meta-oe in BBLAYERS
```

BitBake checks dependencies before building, and it was complaining that `qt5-layer` needs `openembedded-layer` but it's not in the configuration.

By adding both layers to BBLAYERS (with meta-oe first), all dependencies are satisfied.

---

## Key Takeaway

**You need BOTH:**

1. **meta-openembedded** (for meta-oe layer)
   - Contains general OpenEmbedded recipes
   - Required dependency for meta-qt5
   - Clone from: https://github.com/openembedded/meta-openembedded.git

2. **meta-qt5** (for Qt5 recipes)
   - Contains all Qt5 recipes
   - Depends on meta-oe
   - Clone from: https://github.com/meta-qt5/meta-qt5.git

**Add both to BBLAYERS, meta-oe first:**

```bash
/home/yocto/project/meta-openembedded/meta-oe \
/home/yocto/project/meta-qt5 \
```

---

## Summary

| Item | Before | After |
|------|--------|-------|
| meta-openembedded | Removed (thought not needed) | Keep (meta-oe required) |
| meta-qt5 | Added | Keep |
| bblayers.conf | Only meta-qt5 | Both meta-oe and meta-qt5 |
| Error | openembedded-layer missing | ✅ Fixed |

---

## See Also

- **QT5_STANDALONE_FIX.md** - Original Qt5 setup
- **QUICK_QT5_STANDALONE.md** - Quick fix (now needs update)
- **TROUBLESHOOTING.md** - General troubleshooting
