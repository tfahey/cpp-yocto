# Building the Hello World Qt Application with Yocto

## Two Build Paths

Choose one approach:

1. **[Docker (Recommended for macOS/Windows)](#build-with-docker-recommended)** - Containerized, portable, works on any OS
2. **[Native Linux Build](#native-linux-build)** - Direct, fastest, requires Linux OS

---

## Build with Docker (Recommended)

**Benefits:** Works on macOS, Windows, or Linux without installing dependencies.

### Prerequisites (Docker Path)

- Docker Desktop installed
- ~60 GB disk space
- ~2 hours first build (container overhead is minimal)

### Quick Start (Docker)

```bash
# 1. Build the Docker image
cd /Users/tfahey/github/cpp-yocto
docker build -t yocto-qt-builder:latest .

# 2. Start interactive container
docker run -it \
  --name yocto-build \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest

# 3. Inside container, follow Native Steps 1-6 below
#    All commands are identical!
```

Then follow **Steps 1-6** from the Native Build section below. Everything works the same inside the container.

**For detailed Docker instructions, see [DOCKER_BUILD.md](DOCKER_BUILD.md)**

---

## Native Linux Build

**Prerequisites:** You must use a Linux system (Ubuntu 20.04+ recommended)

### Prerequisites (Native Path)

You'll need:
- Linux OS (Ubuntu, Fedora, etc.)
- Git
- Python 3.8+
- About 50-100GB of disk space (Yocto downloads and builds a lot)
- Several hours for the first build

Install build dependencies:

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y git chrpath diffstat wget python3 python3-dev python3-pip \
    texinfo gcc g++ build-essential ipython3 git cmake curl libncurses-dev \
    zlib1g-dev gawk libbz2-dev libssl-dev socat cpio time bison flex xz-utils \
    liblz4-tool zstd
```

**Other Distributions:**
Install equivalent packages for your distro (Git, Python 3.8+, GCC, build-essential)

### Step 1: Clone Poky (Yocto Reference Implementation)

**Docker users:** Run these commands inside the container (after `docker run`)

```bash
cd /home/yocto/project  # (Docker) or /Users/tfahey/github/cpp-yocto (Native)
git clone git://git.yoctoproject.org/poky -b scarthgap
cd poky
```

The `scarthgap` branch is a recent stable release. You can check available branches at:
https://git.yoctoproject.org/poky

### Step 2: Initialize the Yocto Build Environment

```bash
cd /home/yocto/project/poky  # (Docker) or /Users/tfahey/github/cpp-yocto/poky (Native)
source oe-init-build-env ../build
```

This script:
- Sets up environment variables
- Creates the `build/` directory with configuration
- Prepares BitBake for use

You'll be in the `build` directory after this.

### Step 3: Add Our Custom Layer

The build system needs to know about our `meta-hello-qt` layer. Edit `conf/bblayers.conf`:

```bash
nano conf/bblayers.conf
# or use: vi conf/bblayers.conf
```

Find the `BBLAYERS` variable and add the path to our layer:

**For Docker:**
```
BBLAYERS ?= " \
  /home/yocto/project/poky/meta \
  /home/yocto/project/poky/meta-poky \
  /home/yocto/project/poky/meta-yocto-bsp \
  /home/yocto/project/meta-hello-qt \
"
```

**For Native Linux:**
```
BBLAYERS ?= " \
  /Users/tfahey/github/cpp-yocto/poky/meta \
  /Users/tfahey/github/cpp-yocto/poky/meta-poky \
  /Users/tfahey/github/cpp-yocto/poky/meta-yocto-bsp \
  /Users/tfahey/github/cpp-yocto/meta-hello-qt \
"
```

(Make sure the `meta-hello-qt` path is in there!)

### Step 4: Configure the Build (local.conf)

Edit `conf/local.conf` and add/modify:

```bash
nano conf/local.conf
```

Add these lines:

```bash
# Target machine (can be "qemux86-64" for x86_64 emulation)
MACHINE = "qemux86-64"

# Image type - use core-image-minimal for learning (much smaller/faster)
# We'll add Qt packages to it
IMAGE_INSTALL:append = " hello-world"
```

### Step 5: Build!

This is where the magic happens. From the `build` directory:

```bash
bitbake core-image-minimal
```

**What happens:**
1. BitBake parses all recipes from all layers
2. Downloads source code for Qt, our app, and all dependencies
3. Cross-compiles everything for the target architecture
4. Creates a bootable image

**First build time:** 2-6 hours (depends on your system)
**Subsequent builds:** 5-30 minutes (uses cache)

**Docker tip:** The build runs in the container, but artifacts are saved to your host via the volume mount (`-v`), so you can access them from your host machine after the build completes!

#### Alternative: Build Just Our Package

If you want to test just our application before doing a full image build:

```bash
bitbake hello-world
```

This builds only our recipe and its dependencies.

### Step 6: Inspect the Build

After the build completes:

```bash
# The built image is at:
ls -la tmp/deploy/images/qemux86-64/

# The built package (our app):
find tmp -name "hello-world*" -type f

# BitBake build logs:
ls -la tmp/work/
```

**Docker users:** All these paths are accessible from your host machine too (via the volume mount).

### Step 7: Run the Application

### Option A: Build a Runnable Image

Create a minimal image with our Qt app:

```bash
# In build/ directory, edit local.conf to include:
# IMAGE_INSTALL:append = " hello-world"

bitbake core-image-minimal
```

Then you can:
- Boot the image in QEMU (emulator)
- Flash it to actual hardware
- Extract and run the binary

### Option B: Extract and Run Directly

```bash
# Find the built executable
find tmp/work -name "hello-world" -type f -executable

# Copy it out and run
cp <path-from-above> /tmp/hello-world
# (requires Qt5 libraries installed on your system)
/tmp/hello-world
```

## Understanding Key Concepts

### What is the BitBake Recipe (hello-world.bb)?

The recipe is a description of:
- **What** to build (our application)
- **Where** to get the source (SRC_URI)
- **How** to build it (inherit cmake)
- **What dependencies** are needed (DEPENDS)
- **What gets installed** (RDEPENDS)

### The Build Process

```
Parse recipes → Resolve dependencies → Download sources → 
Configure (CMake) → Compile → Install → Package → Create image
```

### Key Yocto Concepts

- **BitBake**: The build engine (similar to GNU Make, but more powerful)
- **Recipe (.bb file)**: Instructions for building one package
- **Layer**: A collection of recipes (like plugins)
- **Metadata**: Configuration files (bblayers.conf, local.conf)
- **Task**: Individual steps in building (fetch, configure, compile, install, etc.)

### Common BitBake Commands

```bash
# Build a recipe
bitbake <recipe-name>

# Rebuild from scratch
bitbake -c clean <recipe-name>
bitbake <recipe-name>

# Show recipe information
bitbake -e <recipe-name> | grep VAR_NAME

# Search for recipes
bitbake-layers show-recipes | grep qt

# Clean all
bitbake -c cleanall <recipe-name>
```

## Troubleshooting

### "bb_task_name is not a function"
→ Check layer.conf syntax

### "Could not find dependency"
→ Check DEPENDS/RDEPENDS in the recipe

### "Cannot find qt5-base"
→ Make sure core layers are included in bblayers.conf

### Out of disk space
→ Clean with `bitbake -c cleanall` or remove `build/tmp/`

## Next Steps

Once this builds:
1. **Modify the Qt app**: Add more GUI elements
2. **Cross-compile for real hardware**: Change MACHINE in local.conf
3. **Create a custom image recipe**: Bundle multiple packages
4. **Learn about BitBake classes**: recipes inherit functionality
5. **Explore other layers**: meta-openembedded, meta-qt5, etc.

Enjoy learning Yocto!
