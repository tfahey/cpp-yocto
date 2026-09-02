# Qt5 Packages Not Available - Complete Fix

**Errors:**
- `Nothing PROVIDES 'qt5-base'`
- `Nothing PROVIDES 'qt5-qmake-native'`
- `Nothing PROVIDES 'qt5-declarative'`

**Cause:** Qt5 recipes aren't in default Yocto layers

**Solution:** Add meta-openembedded layer which contains Qt5 support

---

## Quick Fix (5-10 minutes)

### On Your Mac

#### Step 1: Clone meta-openembedded

```bash
cd /Users/tfahey/github/cpp-yocto

# Clone the meta-openembedded layer
git clone git://git.openembedded.org/meta-openembedded -b scarthgap

# Verify it downloaded
ls -la meta-openembedded/
# Should show: meta-oe/, meta-qt5/, meta-python/, etc.
```

If `git://` doesn't work, use HTTPS:
```bash
git clone https://github.com/openembedded/meta-openembedded.git -b scarthgap
```

#### Step 2: Update bblayers.conf in Docker

Inside your Docker container, edit `conf/bblayers.conf`:

```bash
cd /home/yocto/project/build
nano conf/bblayers.conf
```

Add these two lines to the BBLAYERS variable:

```bash
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
  /home/yocto/project/meta-openembedded/meta-oe \
  /home/yocto/project/meta-openembedded/meta-qt5 \
  /home/yocto/project/meta-hello-qt \
"
```

**Key lines to add:**
```bash
/home/yocto/project/meta-openembedded/meta-oe \
/home/yocto/project/meta-openembedded/meta-qt5 \
```

#### Step 3: Save and Exit

- **nano:** Ctrl+O, Enter, Ctrl+X
- **vi:** Esc, `:wq`, Enter

#### Step 4: Retry Build

```bash
cd /home/yocto/project/build

# Clear old cache
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*
rm -rf tmp/downloads/qt5*

# Run verification
bash /home/yocto/project/VERIFY_SETUP.sh

# Should find Qt5 now! Build:
bitbake hello-world
```

---

## What is meta-openembedded?

`meta-openembedded` is a collection of Yocto layers maintained by the OpenEmbedded community:

```
meta-openembedded/
├── meta-oe/                 ← General packages (fonts, libraries, tools)
├── meta-qt5/                ← Qt5 recipes (what we need!)
├── meta-python/             ← Python packages
├── meta-multimedia/         ← Media libraries
├── meta-networking/         ← Network tools
└── other layers...
```

We need `meta-qt5` which contains:
- ✅ qt5-base (core Qt5 framework)
- ✅ qt5-qmake-native (Qt build tools)
- ✅ qt5-declarative (QML support)
- ✅ qt5-widgets (GUI widgets)
- ✅ And many other Qt5 packages

---

## Complete Workflow

### On Mac: Clone meta-openembedded

```bash
cd /Users/tfahey/github/cpp-yocto

# Clone with HTTPS (more reliable than git://)
git clone https://github.com/openembedded/meta-openembedded.git -b scarthgap

# Or with git protocol if you prefer
git clone git://git.openembedded.org/meta-openembedded -b scarthgap

# Verify
ls -la meta-openembedded/
# Should show directories: meta-oe/, meta-qt5/, meta-python/, etc.
```

### In Docker: Update bblayers.conf

```bash
# 1. Navigate to build directory
cd /home/yocto/project/build

# 2. Edit bblayers.conf
nano conf/bblayers.conf

# 3. Add meta-oe and meta-qt5 to BBLAYERS:
#    /home/yocto/project/meta-openembedded/meta-oe \
#    /home/yocto/project/meta-openembedded/meta-qt5 \

# 4. Save (Ctrl+O, Enter, Ctrl+X in nano)

# 5. Verify the file
grep -A 10 "BBLAYERS" conf/bblayers.conf
# Should show meta-oe and meta-qt5 paths
```

### In Docker: Clear Cache and Retry

```bash
# Clear old cache
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*
rm -rf tmp/downloads/qt5*

# Verify Qt5 is now available
bitbake-layers show-recipes | grep qt5-base
# Should show: qt5-base (or similar)

# Run verification
bash /home/yocto/project/VERIFY_SETUP.sh
# Should pass now!

# Build!
bitbake hello-world
```

---

## File Structure After Fix

```
/Users/tfahey/github/cpp-yocto/
├── poky/                          ← Yocto core
├── meta-openembedded/             ← NEW: Community layers
│   ├── meta-oe/                   ← General packages
│   └── meta-qt5/                  ← Qt5 recipes
├── meta-hello-qt/                 ← Our custom layer
├── build/                         ← Build directory
└── conf/
    └── bblayers.conf              ← Updated to include meta-oe, meta-qt5
```

---

## Expected bblayers.conf

After editing, your `conf/bblayers.conf` should look like:

```bash
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
  /home/yocto/project/meta-openembedded/meta-oe \
  /home/yocto/project/meta-openembedded/meta-qt5 \
  /home/yocto/project/meta-hello-qt \
"
```

**Important:**
- ✅ Each path on its own line
- ✅ Backslash (`\`) at end of each line except last
- ✅ Absolute paths (full paths from root)
- ✅ `meta-oe` before `meta-qt5` (order matters for dependencies)

---

## Verification Commands

After setting up meta-openembedded:

```bash
# 1. Check if meta-openembedded is cloned on Mac
ls -la /Users/tfahey/github/cpp-yocto/meta-openembedded/

# 2. Check if layers are registered in Docker
bitbake-layers show-layers | grep meta
# Should show:
# - meta-oe
# - meta-qt5
# - meta-hello-qt

# 3. Check if Qt5 recipes are available
bitbake-layers show-recipes | grep qt5-base
# Should show: qt5-base (or similar)

# 4. Check recipe details
bitbake -e qt5-base | head -10
# Should show variables from qt5-base recipe
```

---

## If Clone Fails

### git:// Protocol Issue

```bash
# Try HTTPS instead
cd /Users/tfahey/github/cpp-yocto
git clone https://github.com/openembedded/meta-openembedded.git -b scarthgap
```

### Network Issues

If cloning fails, manually download:

```bash
# Visit: https://github.com/openembedded/meta-openembedded
# Click "Code" → "Download ZIP"
# Extract to: /Users/tfahey/github/cpp-yocto/meta-openembedded/
```

### Verify Downloaded Content

```bash
# Check if meta-qt5 exists
ls -la /Users/tfahey/github/cpp-yocto/meta-openembedded/meta-qt5/

# Should show: conf/, recipes-qt/, etc.
```

---

## If Layers Still Not Found

### Check Docker Volume Mount

```bash
# In Docker, verify meta-openembedded is accessible
ls -la /home/yocto/project/meta-openembedded/
# Should show: meta-oe/, meta-qt5/, etc.

# If not showing, volume mount might be incomplete
# Restart container and try again
```

### Manually Verify Paths

```bash
# In Docker
bitbake-layers show-layers

# Look for output like:
# meta-oe            /home/yocto/project/meta-openembedded/meta-oe
# meta-qt5           /home/yocto/project/meta-openembedded/meta-qt5

# If these show, Qt5 should be available
```

---

## Alternative: Use Different Qt Version

If meta-openembedded doesn't work, you can modify the recipe to not require Qt:

```bash
# Edit hello-world.bb and remove Qt dependencies:
DEPENDS = "cmake"
RDEPENDS:${PN} = ""
```

But this would require rewriting the CMakeLists.txt and app without Qt.

---

## Why This Fix Works

1. **meta-openembedded** contains recipes for many packages
2. **meta-qt5** layer specifically has Qt5 recipes
3. When we add these layers to BBLAYERS, BitBake can find:
   - `qt5-base` - Core framework
   - `qt5-qmake-native` - Build tools
   - `qt5-declarative` - QML support
   - `qt5-widgets` - GUI components
   - And all their dependencies

4. BitBake resolves all dependencies automatically

---

## Common Issues

### Layer Not Found

**Error:** `Layer 'meta-qt5' not found in search path`

**Fix:**
```bash
# Verify path is correct in bblayers.conf
grep meta-qt5 conf/bblayers.conf

# Verify path exists in Docker
ls -la /home/yocto/project/meta-openembedded/meta-qt5/
```

### Recipe Still Not Found

**Error:** `Nothing PROVIDES 'qt5-base'`

**Fix:**
```bash
# 1. Clear cache
bitbake -c cleanall hello-world
rm -rf tmp/cache/

# 2. Reload layers
source ../poky/oe-init-build-env .

# 3. Verify Qt5 is found
bitbake-layers show-recipes | grep qt5-base
```

### Dependency Conflict

**Error:** `Conflicting values set for variable X`

**Fix:** Check layer order in bblayers.conf. `meta-oe` should come before `meta-qt5`.

---

## Summary

| Step | Action | Time |
|------|--------|------|
| 1 | Clone meta-openembedded on Mac | 2 min |
| 2 | Update bblayers.conf in Docker | 1 min |
| 3 | Clear cache and retry | 1 min |
| 4 | Build | ~30 min |

**Total: ~30 minutes**

---

## See Also

- **CONFIGURE_BBLAYERS.md** - Detailed bblayers.conf guide
- **TROUBLESHOOTING.md** - General troubleshooting
- **QUICK_BUILD_STEPS.md** - Build commands
- **FIX_VERSION_MISMATCH.md** - Recipe versioning
