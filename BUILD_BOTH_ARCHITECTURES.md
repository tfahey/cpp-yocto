# Building for Both ARM64 and x86-64

Build your Qt5 application for multiple architectures to run on different platforms.

## Architecture Overview

| Architecture | Target Machines | Use Cases |
|--------------|-----------------|-----------|
| **ARM64** | qemuarm64, Raspberry Pi, ARM servers | Mac Docker, ARM embedded devices |
| **x86-64** | qemux86-64, cloud servers, x86 embedded | Linux servers, Docker on Linux, x86 devices |

## Build Strategy

You'll use the same source code and recipe, just change the `MACHINE` variable to build for different targets.

### Step 1: Build ARM64 Version

```bash
cd /Users/tfahey/github/cpp-yocto

# Create separate build directory for ARM64
mkdir -p build-arm64

# Initialize Yocto for ARM64
source poky/oe-init-build-env build-arm64

# Configure for ARM64
cat > conf/local.conf << 'EOF'
MACHINE = "qemuarm64"
TMPDIR = "/tmp/yocto-build-arm64/tmp"
IMAGE_INSTALL:append = " hello-world"
EXTRA_IMAGE_FEATURES ?= "debug-tweaks"
USER_CLASSES ?= "buildstats"
PATCHRESOLVE = "noop"
BB_DISKMON_DIRS ??= "\
    STOPTASKS,${TMPDIR},1G,100K \
    STOPTASKS,${DL_DIR},1G,100K \
    STOPTASKS,${SSTATE_DIR},1G,100K \
    STOPTASKS,/tmp,100M,100K \
    HALT,${TMPDIR},100M,1K \
    HALT,${DL_DIR},100M,1K \
    HALT,${SSTATE_DIR},100M,1K \
    HALT,/tmp,10M,1K"
PACKAGECONFIG:append:pn-qemu-system-native = " sdl"
CONF_VERSION = "2"
EOF

# Copy bblayers.conf from main build
cp /Users/tfahey/github/cpp-yocto/build/conf/bblayers.conf conf/

# Build
docker run --rm \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest \
  bash -c "
    cd /tmp
    mkdir -p yocto-build-arm64
    cd yocto-build-arm64
    cp -r /home/yocto/project/build-arm64/conf .
    source /home/yocto/project/poky/oe-init-build-env . > /dev/null 2>&1
    bitbake hello-world
    
    # Copy binary
    mkdir -p /home/yocto/project/hello-world-output/arm64
    find tmp/work -name 'hello-world' -type f ! -name '*.so' 2>/dev/null | \
      xargs cp -t /home/yocto/project/hello-world-output/arm64 2>/dev/null || true
  "
```

### Step 2: Build x86-64 Version (Keep Current)

```bash
cd /Users/tfahey/github/cpp-yocto

# Use existing build directory
cd build

# Verify config
cat conf/local.conf | grep "^MACHINE"
# Should show: MACHINE = "qemux86-64"

# Build
docker run --rm \
  -v /Users/tfahey/github/cpp-yocto:/home/yocto/project \
  yocto-qt-builder:latest \
  bash -c "
    cd /tmp
    mkdir -p yocto-build
    cd yocto-build
    cp -r /home/yocto/project/build/conf .
    source /home/yocto/project/poky/oe-init-build-env . > /dev/null 2>&1
    bitbake hello-world
    
    # Binary already copied to hello-world-output/hello-world
  "
```

## File Organization After Building Both

```
hello-world-output/
├── hello-world              ← x86-64 binary (current)
└── arm64/
    └── hello-world          ← ARM64 binary
```

## Testing Each Binary

### ARM64 Binary

**On Mac Docker:**
```bash
docker run --rm \
  -e QT_QPA_PLATFORM=offscreen \
  -v /Users/tfahey/github/cpp-yocto/hello-world-output/arm64:/app \
  --platform linux/arm64 \
  ubuntu:20.04 \
  bash -c "
    apt-get update && apt-get install -y libqt5core5a libqt5gui5 libqt5widgets5
    /app/hello-world
  "
```

**On Raspberry Pi or ARM Linux:**
```bash
scp hello-world-output/arm64/hello-world pi@raspberrypi:
ssh pi@raspberrypi "
  sudo apt-get install -y libqt5core5a libqt5gui5 libqt5widgets5
  ./hello-world
"
```

### x86-64 Binary

**On Linux x86-64 VM or cloud:**
```bash
scp hello-world-output/hello-world user@linux-server:
ssh user@linux-server "
  sudo apt-get install -y libqt5core5a libqt5gui5 libqt5widgets5
  ./hello-world
"
```

**On x86-64 Docker:**
```bash
docker run --rm \
  -e QT_QPA_PLATFORM=offscreen \
  -v /Users/tfahey/github/cpp-yocto/hello-world-output:/app \
  --platform linux/amd64 \
  ubuntu:20.04 \
  bash -c "
    apt-get update && apt-get install -y libqt5core5a libqt5gui5 libqt5widgets5
    /app/hello-world
  "
```

## Automated Build Script (Both Architectures)

Create `BUILD_ALL_ARCHITECTURES.sh`:

```bash
#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
OUTPUT_DIR="$SCRIPT_DIR/hello-world-output"

echo "Building for ARM64 and x86-64..."
echo ""

# Build ARM64
echo "1️⃣  Building ARM64 version..."
mkdir -p "$SCRIPT_DIR/build-arm64/conf"
cp "$SCRIPT_DIR/build/conf/bblayers.conf" "$SCRIPT_DIR/build-arm64/conf/"

cat > "$SCRIPT_DIR/build-arm64/conf/local.conf" << 'EOF'
MACHINE = "qemuarm64"
TMPDIR = "/tmp/yocto-build-arm64/tmp"
IMAGE_INSTALL:append = " hello-world"
EXTRA_IMAGE_FEATURES ?= "debug-tweaks"
USER_CLASSES ?= "buildstats"
PATCHRESOLVE = "noop"
CONF_VERSION = "2"
EOF

docker run --rm \
  -v "$SCRIPT_DIR:/home/yocto/project" \
  yocto-qt-builder:latest \
  bash -c "
    cd /tmp && mkdir -p yocto-build-arm64 && cd yocto-build-arm64
    cp -r /home/yocto/project/build-arm64/conf .
    source /home/yocto/project/poky/oe-init-build-env . > /dev/null 2>&1
    bitbake hello-world
    mkdir -p /home/yocto/project/hello-world-output/arm64
    find tmp/work -name 'hello-world' -type f ! -name '*.so' -exec cp {} /home/yocto/project/hello-world-output/arm64/ \; 2>/dev/null
  "

echo "✅ ARM64 binary ready"
echo ""

# Build x86-64 (already done, but you can rebuild if needed)
echo "2️⃣  x86-64 version already built"
echo "   Location: $OUTPUT_DIR/hello-world"
echo ""

echo "═════════════════════════════════════════"
echo "✅ Both architectures built successfully!"
echo ""
echo "ARM64:  $OUTPUT_DIR/arm64/hello-world"
echo "x86-64: $OUTPUT_DIR/hello-world"
echo ""
```

## Deployment Scenarios

### Scenario 1: Company Uses ARM Servers
Deploy ARM64 binary to ARM infrastructure.

### Scenario 2: Company Uses x86-64 Cloud
Deploy x86-64 binary to AWS/Azure/GCP.

### Scenario 3: Mixed Environment
Distribute both binaries to different target platforms.

### Scenario 4: Consumer Products
- Raspberry Pi deployment: ARM64 binary
- x86 Mini-PC deployment: x86-64 binary

## Build Time

**First build of each architecture:** 60-90 minutes (Qt5 compilation)

**With shared sstate cache:** 15-30 minutes per architecture (most cached)

## Storage Requirements

- **ARM64 build:** ~20GB
- **x86-64 build:** ~20GB
- **Total for both:** ~40GB

Use separate TMPDIR paths to avoid conflicts (see script above).

## Advantages of Multi-Architecture Build

✅ Single source code, multiple deployments
✅ No recompilation for code changes (just bitbake)
✅ Test on actual target hardware
✅ Production-ready for diverse platforms

## Which Should You Choose?

**For Mac testing:** ARM64 (runs on Mac Docker)
**For Linux servers:** x86-64 (industry standard)
**For maximum compatibility:** Build both

