# Quick Fix - QtBase-GUI Missing/Unbuildable

**Error:** `Missing or unbuildable dependency chain was: ['hello-world', 'qtbase-gui']`

**Solution:** Run diagnostic script to find the issue

---

## Quick Diagnostic (Inside Docker Container)

```bash
cd /home/yocto/project/build
bash /home/yocto/project/DIAGNOSE_QTBASE.sh
```

This will check:
- ✓ Layers are loaded (meta-qt5, meta-oe)
- ✓ QtBase recipes exist
- ✓ QtBase-GUI recipe exists
- ✓ Configuration is correct
- ✓ Layer order is right
- ✓ QtBase-GUI can be parsed

---

## Most Common Issues

### Issue 1: meta-oe or meta-qt5 Not in BBLAYERS

**Check:**
```bash
grep -E "meta-oe|meta-qt5" /home/yocto/project/build/conf/bblayers.conf
```

**Fix:**
```bash
nano /home/yocto/project/build/conf/bblayers.conf

# Add BOTH (meta-oe FIRST):
# BBLAYERS ?= " \
#   /home/yocto/project/poky/meta \
#   /home/yocto/project/poky/meta-poky \
#   /home/yocto/project/poky/meta-yocto-bsp \
#   /home/yocto/project/meta-openembedded/meta-oe \
#   /home/yocto/project/meta-qt5 \
#   /home/yocto/project/meta-hello-qt \
# "
```

### Issue 2: Wrong Layer Order

meta-oe MUST come BEFORE meta-qt5

**Check:**
```bash
grep -n "meta-oe\|meta-qt5" /home/yocto/project/build/conf/bblayers.conf
# meta-oe should be on a lower line number than meta-qt5
```

### Issue 3: Repositories Not Cloned

Both need to exist on your Mac

**Check:**
```bash
ls -la /Users/tfahey/github/cpp-yocto/meta-openembedded/meta-oe/
ls -la /Users/tfahey/github/cpp-yocto/meta-qt5/
```

**Fix:** Clone if missing
```bash
cd /Users/tfahey/github/cpp-yocto
git clone https://github.com/openembedded/meta-openembedded.git
git clone https://github.com/meta-qt5/meta-qt5.git -b scarthgap
```

---

## Full Fix Workflow

```bash
# 1. In Docker, run diagnostic
cd /home/yocto/project/build
bash /home/yocto/project/DIAGNOSE_QTBASE.sh

# 2. If it shows errors, fix bblayers.conf
# (see issues above)

# 3. Clean and rebuild
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*

# 4. Try again
bitbake hello-world
```

---

Done! For more details: [QTBASE_MISSING_FIX.md](QTBASE_MISSING_FIX.md)
