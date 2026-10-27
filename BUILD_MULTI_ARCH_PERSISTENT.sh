#!/bin/bash
# Build Qt5 hello-world for multiple architectures using PERSISTENT containers
#
# This version uses CONTAINER_MANAGER.sh to create persistent containers,
# then calls BUILD_MULTI_ARCH.sh with USE_PERSISTENT_CONTAINER=1
#
# Usage:
#   bash BUILD_MULTI_ARCH_PERSISTENT.sh [arm64|x86-64|both]
#
# Default: build both

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

TARGET="${1:-both}"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║   Building Qt5 Hello World for Multiple Architectures      ║"
echo "║   Using Persistent Containers                              ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Ensure CONTAINER_MANAGER.sh exists
if [ ! -f "$SCRIPT_DIR/CONTAINER_MANAGER.sh" ]; then
    echo "❌ ERROR: CONTAINER_MANAGER.sh not found"
    exit 1
fi

# Start persistent containers based on target
case "$TARGET" in
    arm64)
        echo "🚀 Setting up arm64 persistent container..."
        bash "$SCRIPT_DIR/CONTAINER_MANAGER.sh" arm64 start
        ;;
    x86-64)
        echo "🚀 Setting up x86-64 persistent container..."
        bash "$SCRIPT_DIR/CONTAINER_MANAGER.sh" x86-64 start
        ;;
    both)
        echo "🚀 Setting up persistent containers..."
        bash "$SCRIPT_DIR/CONTAINER_MANAGER.sh" arm64 start
        bash "$SCRIPT_DIR/CONTAINER_MANAGER.sh" x86-64 start
        ;;
    *)
        echo "❌ Invalid target: $TARGET"
        echo "Usage: $0 [arm64|x86-64|both]"
        exit 1
        ;;
esac

echo ""
echo "✅ Persistent containers ready"
echo ""
echo "Running builds using persistent containers..."
echo ""

# Run BUILD_MULTI_ARCH.sh with persistent container mode
USE_PERSISTENT_CONTAINER=1 bash "$SCRIPT_DIR/BUILD_MULTI_ARCH.sh" "$TARGET"

BUILD_RESULT=$?

if [ $BUILD_RESULT -eq 0 ]; then
    echo ""
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║   ✅ Builds Complete! Persistent Containers Still Running  ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo ""
    echo "To stop persistent containers:"
    case "$TARGET" in
        arm64)
            echo "  bash CONTAINER_MANAGER.sh arm64 stop"
            ;;
        x86-64)
            echo "  bash CONTAINER_MANAGER.sh x86-64 stop"
            ;;
        both)
            echo "  bash CONTAINER_MANAGER.sh arm64 stop"
            echo "  bash CONTAINER_MANAGER.sh x86-64 stop"
            ;;
    esac
    echo ""
    echo "To remove containers completely:"
    case "$TARGET" in
        arm64)
            echo "  bash CONTAINER_MANAGER.sh arm64 rm"
            ;;
        x86-64)
            echo "  bash CONTAINER_MANAGER.sh x86-64 rm"
            ;;
        both)
            echo "  bash CONTAINER_MANAGER.sh arm64 rm"
            echo "  bash CONTAINER_MANAGER.sh x86-64 rm"
            ;;
    esac
    echo ""
else
    echo "❌ Build failed"
    exit 1
fi
