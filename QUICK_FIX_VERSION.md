# Quick Fix - Version Mismatch (10 Seconds!)

## The Problem

BitBake looking for files in `hello-world-1.0/` but they're in `hello-world-0.1/`

## The Fix

### On Your Mac

```bash
cd /Users/tfahey/github/cpp-yocto/meta-hello-qt/recipes-qt/hello-world/
mv hello-world.bb hello-world_0.1.bb
```

**That's it!** One command. Done.

## Verify

```bash
ls -la
# Should show:
# hello-world_0.1.bb    ✓ (was: hello-world.bb)
# hello-world-0.1/      ✓ (unchanged)
```

## In Docker Container

After the fix above, in Docker:

```bash
cd /home/yocto/project/build
source ../poky/oe-init-build-env .
bitbake -c cleanall hello-world
rm -rf tmp/work/*/hello-world-*
bash /home/yocto/project/VERIFY_SETUP.sh
# Should pass now!
bitbake hello-world
```

## Why This Works

- Old: `hello-world.bb` → Yocto infers version 1.0 (wrong!)
- New: `hello-world_0.1.bb` → Yocto extracts version from filename (correct!)
- Now version matches directory name: `hello-world-0.1/`
- BitBake finds files ✅

## That's All!

For details, see: [FIX_VERSION_MISMATCH.md](FIX_VERSION_MISMATCH.md)

**Ready?** One command on Mac, then build in Docker! 🚀
