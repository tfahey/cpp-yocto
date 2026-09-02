# Running Qt5 Application in Docker on Mac

## Overview

Your hello-world binary is a **Linux x86-64 executable**. Docker on Mac can run it with proper setup.

## Prerequisites

### Check Your Setup

```bash
# Verify binary exists and is x86-64
file /Users/tfahey/github/cpp-yocto/hello-world-output/hello-world
# Output should show: ELF 64-bit LSB pie executable, x86-64
```

## Option 1: Quick Test (No GUI)

Test that the binary works in Docker:

```bash
bash RUN_QT_APP.sh --no-display
```

This runs the application with `QT_QPA_PLATFORM=offscreen`, which tests the application without attempting to display a window.

## Option 2: View GUI with XQuartz

To actually see the Qt GUI window on Mac:

### Step 1: Install XQuartz
```bash
brew install xquartz
```

### Step 2: Start XQuartz
```bash
open -a XQuartz
```

### Step 3: Allow Docker connections
```bash
# In XQuartz preferences, enable "Allow connections from network clients"
# Or run this command:
xhost + 127.0.0.1
```

### Step 4: Run the application
```bash
bash RUN_QT_APP.sh
```

## Option 3: Manual Docker Commands

If you want to run without the script:

### Test mode (no display):
```bash
docker build -f Dockerfile.qt-runtime -t qt5-runtime:latest .

docker run --rm \
  -e QT_QPA_PLATFORM=offscreen \
  -v /Users/tfahey/github/cpp-yocto/hello-world-output:/app \
  qt5-runtime:latest
```

### With display (requires XQuartz):
```bash
MAC_IP=$(ifconfig en0 | grep "inet " | awk '{print $2}')

docker run --rm \
  -e DISPLAY=$MAC_IP:0 \
  -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
  -v /Users/tfahey/github/cpp-yocto/hello-world-output:/app \
  qt5-runtime:latest
```

## What You'll See

### Without Display (Test Mode)
```
✅ Application ran successfully (without display)
```

This confirms the binary:
- ✅ Loads correctly
- ✅ Links to Qt5 libraries
- ✅ Initializes without errors
- ✅ Is compatible with the container

### With Display (GUI Mode)
A window appears showing:
- Title: "Hello World Qt Application"
- A label: "Hello, Qt5!"
- A button: "Click me"
- A counter displaying the number of clicks

## Troubleshooting

### "rosetta error: failed to open elf at /lib/ld-linux-x86-64.so.2"
This is expected on Mac outside of Docker. It means your Mac CPU (ARM) can't run x86-64 binaries directly. Inside Docker, Linux emulation handles this.

### "Cannot connect to display :0"
XQuartz isn't running or accessible:
```bash
# Start XQuartz
open -a XQuartz

# Allow connections
xhost + 127.0.0.1

# Try again
bash RUN_QT_APP.sh
```

### "docker: command not found"
Docker isn't installed or not in PATH:
```bash
# Check Docker is running
docker ps

# Or install: brew install docker
```

### Binary doesn't appear to do anything
This is normal for offscreen/test mode. Add verbose output:

```bash
docker run --rm \
  -e QT_QPA_PLATFORM=offscreen \
  -e QT_DEBUG_PLUGINS=1 \
  -v /Users/tfahey/github/cpp-yocto/hello-world-output:/app \
  qt5-runtime:latest 2>&1 | head -100
```

## Docker Container Details

**Base image:** ubuntu:20.04

**Qt5 libraries installed:**
- libqt5core5a
- libqt5gui5
- libqt5widgets5
- libqt5qml5
- libqt5quick5
- libqt5network5
- libqt5dbus5
- libqt5printsupport5
- And supporting libraries (OpenGL, fonts, X11)

**Why Ubuntu 20.04:**
- Matches Yocto Poky version (built for x86_64-poky-linux)
- Has compatible Qt5 libraries
- Lightweight compared to full desktop environments

## Binary Details

Your application was built with:
- **Framework:** Qt5 (qtbase 5.15.13)
- **Build system:** CMake
- **Compiler:** GCC cross-compiler (x86_64-poky-linux-gcc)
- **Optimization:** -O2 (production)
- **Size:** 889 KB (including debug info)

## Next Steps

### Option A: Use in Real Deployment
Copy the binary to any x86_64 Linux target with Qt5 libraries:
```bash
scp /Users/tfahey/github/cpp-yocto/hello-world-output/hello-world user@target:/usr/bin/
```

### Option B: Create a Full Image
Build a complete Yocto image with your app included:
```bash
# Edit build/conf/local.conf:
echo 'IMAGE_INSTALL:append = " hello-world"' >> build/conf/local.conf

# Build:
bitbake core-image-minimal
```

### Option C: Test on Linux VM
If you have Linux available (VirtualBox, parallels, etc.):
1. Copy the binary to the VM
2. Install Qt5 libraries: `apt-get install libqt5core5a libqt5gui5 libqt5widgets5`
3. Run: `/path/to/hello-world`

## Performance Note

Running x86-64 Linux in Docker on Mac has some overhead:
- Docker Desktop creates a Linux VM
- Emulation of x86-64 architecture
- Performance is good for testing but not for production

For production deployment, run on native Linux hardware or cloud infrastructure.

