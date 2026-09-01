# Configuration Files - Quick Visual Guide

When you run `oe-init-build-env`, two configuration files are created. You need to edit both.

---

## File 1: conf/bblayers.conf

**What it does:** Tells BitBake which layers to search for recipes

**Location in container:** `/home/yocto/project/build/conf/bblayers.conf`

**Edit with:** `nano conf/bblayers.conf`

### What to Add

Find the `BBLAYERS ?= "` section and **add our layer path:**

```bash
# ORIGINAL (doesn't work - missing meta-hello-qt):
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
"

# AFTER EDIT (works!):
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
  /home/yocto/project/meta-hello-qt \
"
                     ↑ Add this line!
```

**Key points:**
- ✅ Add new path on new line
- ✅ Keep backslash (`\`) at end of PREVIOUS line
- ✅ Remove backslash from last line
- ✅ Use absolute path (full path from root)

---

## File 2: conf/local.conf

**What it does:** Configures the build (machine, packages to include)

**Location in container:** `/home/yocto/project/build/conf/local.conf`

**Edit with:** `nano conf/local.conf`

### What to Add

Scroll to **end of file** (after all the commented examples) and **add these two lines:**

```bash
# ORIGINAL (empty/mostly comments):
# Lines 1-200: Lots of commented examples
# (No MACHINE set)
# (No IMAGE_INSTALL set)

# AFTER EDIT (at end of file):
MACHINE = "qemux86-64"
IMAGE_INSTALL:append = " hello-world"
                        ↑ Note the space!
```

**Key points:**
- ✅ Add at END of file (after examples)
- ✅ Don't comment out with `#`
- ✅ `MACHINE = ` specifies target architecture
- ✅ `IMAGE_INSTALL:append = ` adds packages
- ✅ Space before package name is important!

---

## Visual Comparison

### Before Editing
```
conf/bblayers.conf                    conf/local.conf
─────────────────                     ───────────────
BBLAYERS = " \                        # Lots of comments
  meta \                              # with examples
  meta-poky \                         # (all starting with #)
  meta-yocto-bsp \
"                                     # At end of file:
                                      # (nothing custom)
❌ BitBake can't find                 ❌ Uses wrong MACHINE
   hello-world recipe                    and IMAGE_INSTALL
```

### After Editing
```
conf/bblayers.conf                    conf/local.conf
─────────────────                     ───────────────
BBLAYERS = " \                        # Lots of comments
  meta \                              # with examples
  meta-poky \                         # (all starting with #)
  meta-yocto-bsp \
  meta-hello-qt \    ← NEW!           # At end of file:
"                                     MACHINE = "qemux86-64"
                                      IMAGE_INSTALL:append = " hello-world"
✅ BitBake finds                       ✅ Uses correct MACHINE
   hello-world recipe                    and includes hello-world
```

---

## Step-by-Step Editing Process

```
1. Navigate to build directory
   cd /home/yocto/project/build

2. Edit bblayers.conf
   nano conf/bblayers.conf
   → Find BBLAYERS
   → Add meta-hello-qt path
   → Save (Ctrl+O, Ctrl+X)

3. Edit local.conf
   nano conf/local.conf
   → Go to end of file
   → Add MACHINE line
   → Add IMAGE_INSTALL line
   → Save (Ctrl+O, Ctrl+X)

4. Verify
   bitbake -e | grep "^MACHINE="
   bitbake -e | grep "^IMAGE_INSTALL="
```

---

## Common Mistakes

### ❌ Mistake 1: Wrong Path for Docker

```bash
# DON'T use in Docker:
/Users/tfahey/github/cpp-yocto/meta-hello-qt

# DO use in Docker:
/home/yocto/project/meta-hello-qt
```

### ❌ Mistake 2: Missing Space in IMAGE_INSTALL

```bash
# DON'T (no space):
IMAGE_INSTALL:append = "hello-world"

# DO (space before package):
IMAGE_INSTALL:append = " hello-world"
                       ↑ This space matters!
```

### ❌ Mistake 3: Commented Out MACHINE

```bash
# DON'T (commented):
# MACHINE = "qemux86-64"

# DO (not commented):
MACHINE = "qemux86-64"
```

### ❌ Mistake 4: Added to Wrong Place in bblayers.conf

```bash
# DON'T (inside the quotes):
BBLAYERS ?= " \
  /path/to/meta \
  meta-hello-qt \    ← Missing leading /home/yocto/project
  /path/to/meta-yocto-bsp \
"

# DO (full absolute path):
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
  /home/yocto/project/meta-hello-qt \
"
```

---

## Verification Commands

After editing both files:

```bash
# 1. Check bblayers.conf has meta-hello-qt
grep meta-hello-qt conf/bblayers.conf
# Should show: /home/yocto/project/meta-hello-qt

# 2. Check local.conf has MACHINE
grep "^MACHINE" conf/local.conf
# Should show: MACHINE = "qemux86-64"

# 3. Check local.conf has IMAGE_INSTALL
grep "^IMAGE_INSTALL" conf/local.conf
# Should show: IMAGE_INSTALL:append = " hello-world"

# 4. Verify BitBake can parse both
bitbake -e 2>&1 | head -20
# Should NOT show "Parse error"

# 5. Verify BitBake finds our recipe
bitbake-layers show-recipes | grep hello-world
# Should show recipe details
```

---

## If Something Goes Wrong

### Reset bblayers.conf
```bash
# Delete and regenerate
rm conf/bblayers.conf
cd ../poky
source oe-init-build-env ../build
# Then edit conf/bblayers.conf again
```

### Reset local.conf
```bash
# Delete and regenerate
rm conf/local.conf
cd ../poky
source oe-init-build-env ../build
# Then edit conf/local.conf again
```

### Debug BitBake parsing
```bash
# Show any parse errors
bitbake -e 2>&1 | grep -i "error\|parse\|line"

# Show what BitBake sees
bitbake -e | grep "^MACHINE="
bitbake -e | grep "^BBLAYERS="
```

---

## File Locations Reference

| Item | Docker Path | Native Linux Path |
|------|-------------|-------------------|
| bblayers.conf | `/home/yocto/project/build/conf/bblayers.conf` | `/Users/tfahey/.../build/conf/bblayers.conf` |
| local.conf | `/home/yocto/project/build/conf/local.conf` | `/Users/tfahey/.../build/conf/local.conf` |
| meta-hello-qt | `/home/yocto/project/meta-hello-qt` | `/Users/tfahey/.../meta-hello-qt` |
| poky | `/home/yocto/project/poky` | `/Users/tfahey/.../poky` |

---

## Next Steps

1. **Follow this guide** to edit both files
2. **Run verification commands** above
3. **If all pass**, you're ready to build:
   ```bash
   bitbake core-image-minimal
   ```

---

## See Also

- **CONFIGURE_BBLAYERS.md** - Detailed bblayers.conf guide
- **CONFIGURE_LOCAL_CONF.md** - Detailed local.conf guide
- **BUILD_INSTRUCTIONS.md** - Full build workflow
