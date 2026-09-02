# Quick Qt5 Fix - 5 Minutes

**Error:** `Nothing PROVIDES 'qt5-base'`

**Cause:** Qt5 recipes not in default layers

**Solution:** Add meta-openembedded layer

---

## On Your Mac (1 minute)

```bash
cd /Users/tfahey/github/cpp-yocto

# Clone meta-openembedded
git clone https://github.com/openembedded/meta-openembedded.git -b scarthgap

# Verify
ls -la meta-openembedded/meta-qt5/
# Should show files
```

If git fails, try:
```bash
git clone git://git.openembedded.org/meta-openembedded -b scarthgap
```

---

## In Docker (4 minutes)

```bash
cd /home/yocto/project/build

# Edit bblayers.conf
nano conf/bblayers.conf

# Add these two lines to BBLAYERS (after poky layers, before meta-hello-qt):
#   /home/yocto/project/meta-openembedded/meta-oe \
#   /home/yocto/project/meta-openembedded/meta-qt5 \

# Save: Ctrl+O, Enter, Ctrl+X

# Clear cache
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*
rm -rf tmp/downloads/qt5*

# Verify Qt5 is found
bitbake-layers show-recipes | grep qt5-base
# Should show: qt5-base

# Build!
bitbake hello-world
```

---

## Expected bblayers.conf

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

---

## Verify

```bash
# Should find Qt5 now
bitbake-layers show-recipes | grep qt5-base

# Run verification
bash /home/yocto/project/VERIFY_SETUP.sh

# Should pass!
bitbake hello-world
```

---

That's it! For details, see: [QT5_MISSING_FIX.md](QT5_MISSING_FIX.md)
