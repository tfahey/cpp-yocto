# How to Run VERIFY_SETUP.sh

The verification script requires the Yocto build environment to be initialized. Here's how to run it correctly.

---

## Quick Start

Inside your Docker container:

```bash
# 1. Navigate to build directory
cd /home/yocto/project/build

# 2. Initialize Yocto environment (if not already done)
source ../poky/oe-init-build-env .

# 3. Run verification script
bash /home/yocto/project/VERIFY_SETUP.sh
```

---

## Step by Step

### Step 1: Enter Build Directory

```bash
cd /home/yocto/project/build
```

**Verify you're in the right place:**
```bash
pwd
# Should show: /home/yocto/project/build

ls conf/
# Should show: bblayers.conf, local.conf, sanity_info
```

### Step 2: Initialize Yocto Environment

This sets up all the BitBake tools:

```bash
source ../poky/oe-init-build-env .
```

**What this does:**
- Sets environment variables
- Makes `bitbake` command available
- Makes `bitbake-layers` command available
- Configures build tools

**Verify it worked:**
```bash
bitbake --version
# Should show: BitBake Build Tool version X.X.X
```

### Step 3: Run the Verification Script

```bash
bash /home/yocto/project/VERIFY_SETUP.sh
```

---

## Full Session Example

```bash
# You're in the container, let's say in /home/yocto/project/

# Navigate to build
cd /home/yocto/project/build

# Check where we are
pwd
# Output: /home/yocto/project/build

# Initialize environment
source ../poky/oe-init-build-env .

# Verify bitbake is available
which bitbake
# Output: /home/yocto/project/poky/bin/bitbake

# Run verification
bash /home/yocto/project/VERIFY_SETUP.sh

# If all checks pass, build!
bitbake hello-world
```

---

## Common Errors and Fixes

### Error: "Not in build directory"

```
❌ Error: Not in build directory!
Expected: /home/yocto/project/build
```

**Fix:** Navigate to the build directory first

```bash
cd /home/yocto/project/build
pwd  # Verify
bash /home/yocto/project/VERIFY_SETUP.sh
```

### Error: "BitBake environment not initialized"

```
⚠️  BitBake environment not initialized
```

**Fix:** Source the environment

```bash
source ../poky/oe-init-build-env .
bash /home/yocto/project/VERIFY_SETUP.sh
```

### Error: "Could not find oe-init-build-env"

```
❌ Could not find oe-init-build-env
```

**Fix:** Verify Poky is cloned

```bash
ls -la /home/yocto/project/poky/oe-init-build-env
# Should exist

# If not, clone it
cd /home/yocto/project
git clone https://git.yoctoproject.org/poky -b scarthgap
```

---

## What Each Command Does

### `cd /home/yocto/project/build`
Changes to the build directory where BitBake will work.

### `source ../poky/oe-init-build-env .`
Initializes the Yocto build environment:
- Sets up PATH to include BitBake tools
- Sets up build configuration
- Makes all bitbake commands available
- The `.` at the end means "use current directory as build dir"

### `bash /home/yocto/project/VERIFY_SETUP.sh`
Runs the verification script which checks:
- Files exist
- Locale is set
- Layer is registered
- Recipe is found
- Configuration is correct
- BitBake can parse recipe
- BitBake can fetch sources

---

## Script Improvements

The updated script now:

✅ Checks if you're in the build directory
✅ Checks if BitBake environment is initialized
✅ Automatically tries to source the environment
✅ Gives helpful error messages if something is wrong
✅ Provides exact fix instructions

---

## Tips

### Shortcut: Do Everything at Once

```bash
cd /home/yocto/project/build && \
source ../poky/oe-init-build-env . && \
bash /home/yocto/project/VERIFY_SETUP.sh
```

### Check Environment Variables

After sourcing, verify environment is set:

```bash
echo $BITBAKEPATH
# Should show path to BitBake

echo $PATH | grep poky
# Should show /home/yocto/project/poky in PATH
```

### Create an Alias (Optional)

If you run this often:

```bash
alias verify='cd /home/yocto/project/build && source ../poky/oe-init-build-env . && bash /home/yocto/project/VERIFY_SETUP.sh'

# Then just run:
verify
```

---

## After Verification

Once all checks pass:

```bash
# Build just our app
bitbake hello-world

# Or build full image
bitbake core-image-minimal
```

---

## Troubleshooting: Still Getting bitbake-layers Not Found?

If you still get `bitbake-layers: command not found` after sourcing:

```bash
# Verify the environment actually sourced
which bitbake-layers
# Should show: /home/yocto/project/poky/bin/bitbake-layers

# If nothing shows, try:
source ../poky/oe-init-build-env .

# Verify again
which bitbake-layers

# If still not found, check poky is properly installed
ls -la ../poky/bin/bitbake-layers
# Should exist
```

---

## See Also

- **FIX_AND_BUILD.md** - Complete build guide
- **VERIFY_SETUP.sh** - The verification script itself
- **BUILD_INSTRUCTIONS.md** - Full build workflow
