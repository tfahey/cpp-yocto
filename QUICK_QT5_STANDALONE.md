# Quick Qt5 Standalone Fix - 5 Minutes

**Update:** Qt5 has moved to its own repository at `github.com/meta-qt5`

---

## On Your Mac (2 minutes)

```bash
# 1. Remove old meta-openembedded if you cloned it
rm -rf /Users/tfahey/github/cpp-yocto/meta-openembedded

# 2. Clone official meta-qt5 repository
cd /Users/tfahey/github/cpp-yocto
git clone https://github.com/meta-qt5/meta-qt5.git -b scarthgap

# 3. Verify
ls -la /Users/tfahey/github/cpp-yocto/meta-qt5/
# Should show: conf/, recipes-qt5/, etc.
```

---

## In Docker (3 minutes)

```bash
# 1. Stop and remove old container
docker stop yocto-build
docker rm yocto-build

# 2. Start fresh container
docker run -it \
  -e LANG=en_US.UTF-8 \
  -e LC_ALL=en_US.UTF-8 \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest

# 3. Initialize build
cd /home/yocto/project/poky
source oe-init-build-env ../build
cd ../build

# 4. Edit bblayers.conf
nano conf/bblayers.conf

# Update BBLAYERS to:
# BBLAYERS ?= " \
#   /home/yocto/project/poky/meta \
#   /home/yocto/project/poky/meta-poky \
#   /home/yocto/project/poky/meta-yocto-bsp \
#   /home/yocto/project/meta-qt5 \
#   /home/yocto/project/meta-hello-qt \
# "

# Save: Ctrl+O, Enter, Ctrl+X

# 5. Clear cache and build
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*
bitbake hello-world
```

---

## Key Difference

**Old (Doesn't work):**
```
/home/yocto/project/meta-openembedded/meta-qt5  ❌
```

**New (Correct):**
```
/home/yocto/project/meta-qt5  ✅
```

---

## Verify

```bash
# In Docker
bitbake-layers show-recipes | grep qt5-base
# Should show: qt5-base
```

**Done!** 🚀

For details, see: [QT5_STANDALONE_FIX.md](QT5_STANDALONE_FIX.md)
