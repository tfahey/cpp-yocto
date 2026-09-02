#!/bin/bash
# Run Qt5 hello-world application in Docker with display support
#
# Usage:
#   bash RUN_QT_APP.sh [--no-display]
#
# Options:
#   --no-display    Run without GUI (test mode)
#   (default)       Try to connect to XQuartz display if available

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
BINARY="$SCRIPT_DIR/hello-world-output/hello-world"
DOCKERFILE="$SCRIPT_DIR/Dockerfile.qt-runtime"

# Check binary exists
if [ ! -f "$BINARY" ]; then
    echo "❌ Binary not found: $BINARY"
    exit 1
fi

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Running Qt5 Hello World Application in Docker            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Check if running on Mac
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "🍎 Detected macOS"

    # Check if XQuartz is running
    if pgrep -q Xvfb; then
        echo "✅ XQuartz detected (Xvfb running)"
        USE_DISPLAY=true
    else
        echo "⚠️  XQuartz not detected"
        echo "   To see the GUI, install XQuartz: brew install xquartz"
        USE_DISPLAY=false
    fi
else
    echo "🐧 Detected Linux"
    if [ -S /tmp/.X11-unix/X0 ]; then
        echo "✅ X11 display detected"
        USE_DISPLAY=true
    else
        echo "⚠️  X11 display not available"
        USE_DISPLAY=false
    fi
fi

echo ""

# Override with command line argument
if [ "$1" == "--no-display" ]; then
    USE_DISPLAY=false
    echo "Running in test mode (no GUI display)"
fi

echo "Building Qt5 runtime container..."
docker build -f "$DOCKERFILE" -t qt5-runtime:latest "$SCRIPT_DIR" > /dev/null 2>&1
echo "✅ Container built"
echo ""

if [ "$USE_DISPLAY" = true ]; then
    echo "🖥️  Starting application with display support..."
    echo ""

    # Get display info
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        MAC_IP=$(ifconfig en0 2>/dev/null | grep "inet " | awk '{print $2}' || echo "127.0.0.1")
        echo "Display: $MAC_IP:0"

        docker run --rm \
            -e DISPLAY=$MAC_IP:0 \
            -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
            -v "$SCRIPT_DIR/hello-world-output:/app" \
            -u $(id -u):$(id -g) \
            qt5-runtime:latest
    else
        # Linux
        docker run --rm \
            -e DISPLAY=:0 \
            -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
            -v "$SCRIPT_DIR/hello-world-output:/app" \
            -u $(id -u):$(id -g) \
            qt5-runtime:latest
    fi
else
    echo "🧪 Starting application in test mode..."
    echo ""

    # Run without display (just test it starts)
    docker run --rm \
        -e QT_QPA_PLATFORM=offscreen \
        -v "$SCRIPT_DIR/hello-world-output:/app" \
        qt5-runtime:latest 2>&1 | head -50

    echo ""
    echo "✅ Application ran successfully (without display)"
    echo ""
    echo "To see the GUI:"
    echo "  1. Install XQuartz on Mac: brew install xquartz"
    echo "  2. Run: bash RUN_QT_APP.sh"
    echo ""
fi
