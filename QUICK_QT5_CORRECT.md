# Quick Fix - Qt5 Correct Setup

**Error:** `Layer 'qt5-layer' depends on layer 'openembedded-layer'`

**Fix:** Need BOTH meta-oe and meta-qt5

---

## On Your Mac (2 minutes)

```bash
cd /Users/tfahey/github/cpp-yocto

# Verify/clone meta-openembedded (for meta-oe layer)
if [ ! -d meta-openembedded ]; then
  git clone https://github.com/openembedded/meta-openembedded.git
fi

# Verify/clone meta-qt5 (Qt5 recipes)
if [ ! -d meta-qt5 ]; then
  git clone https://github.com/meta-qt5/meta-qt5.git -b scarthgap
fi

# Verify both exist
ls -la meta-openembedded/meta-oe/ | head -3
ls -la meta-qt5/ | head -3
```

---

## In Docker (3 minutes)

```bash
cd /home/yocto/project/build

# Edit bblayers.conf
nano conf/bblayers.conf

# Set BBLAYERS to include BOTH (meta-oe FIRST):
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
  /home/yocto/project/meta-openembedded/meta-oe \
  /home/yocto/project/meta-qt5 \
  /home/yocto/project/meta-hello-qt \
"

# Save: Ctrl+O, Enter, Ctrl+X

# Clear and rebuild
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*

# Verify both layers are found
bitbake-layers show-layers | grep -E "openembedded|qt5"

# Build!
bitbake hello-world
```

---

## Key Points

| Layer | Location | Purpose |
|-------|----------|---------|
| meta-oe | `meta-openembedded/meta-oe/` | OpenEmbedded base packages (REQUIRED by Qt5) |
| meta-qt5 | `meta-qt5/` | Qt5 recipes |

**Order matters:** meta-oe must come BEFORE meta-qt5

---

That's it! Need both layers. 🚀

For details, see: [QT5_WITH_OE_DEPENDENCY.md](QT5_WITH_OE_DEPENDENCY.md)
