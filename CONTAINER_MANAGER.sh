#!/bin/bash
# Manage the yocto-builder container for manual exploration and debugging
#
# Usage:
#   bash CONTAINER_MANAGER.sh [command]
#
# Commands:
#   start         - Start the container in background
#   shell         - Open an interactive shell in the container
#   stop          - Stop the container
#   rm            - Remove the container
#   status        - Show container status
#   logs          - Show container logs
#   bash [cmd]    - Run a bash command in the container

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
YOCTO_CACHE_DIR="$SCRIPT_DIR/.yocto-cache"
YOCTO_DL_DIR="$YOCTO_CACHE_DIR/downloads"
YOCTO_SSTATE_ARM64="$YOCTO_CACHE_DIR/sstate-cache-arm64"
YOCTO_SSTATE_X86_64="$YOCTO_CACHE_DIR/sstate-cache-x86_64"

mkdir -p "$YOCTO_DL_DIR" "$YOCTO_SSTATE_ARM64" "$YOCTO_SSTATE_X86_64"

# Architecture (arm64 or x86-64, defaults to arm64)
ARCH="${1:-arm64}"
COMMAND="${2:-status}"

case "$ARCH" in
    arm64)
        CONTAINER_NAME="yocto-builder-arm64"
        PLATFORM="linux/arm64"
        ;;
    x86-64)
        CONTAINER_NAME="yocto-builder-x86-64"
        PLATFORM="linux/amd64"
        ;;
    *)
        echo "❌ Invalid architecture: $ARCH"
        echo "Usage: bash CONTAINER_MANAGER.sh [arm64|x86-64] [command]"
        echo ""
        echo "Architectures:"
        echo "  arm64     - ARM64 native container"
        echo "  x86-64    - x86_64 container"
        echo ""
        echo "Commands:"
        echo "  start, shell, stop, rm, status, logs, bash [cmd]"
        exit 1
        ;;
esac

case "$COMMAND" in
    start)
        echo "🚀 Starting container '$CONTAINER_NAME'..."
        if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
                echo "   Container already running"
            else
                echo "   Starting existing container..."
                docker start "$CONTAINER_NAME"
                echo "   ✅ Container started"
            fi
        else
            echo "   Creating new container for $ARCH..."
            docker create \
                --platform "$PLATFORM" \
                -m 14g \
                --memory-swap 16g \
                -e SRCCLR_API_TOKEN \
                -v "$SCRIPT_DIR:/home/yocto/project" \
                -v "$YOCTO_DL_DIR:/home/yocto/cache/downloads" \
                -v "$YOCTO_SSTATE_ARM64:/home/yocto/cache/sstate-cache-arm64" \
                -v "$YOCTO_SSTATE_X86_64:/home/yocto/cache/sstate-cache-x86_64" \
                --name "$CONTAINER_NAME" \
                yocto-qt-builder:latest \
                sleep infinity
            docker start "$CONTAINER_NAME"
            echo "   ✅ Container created and started ($ARCH)"
        fi
        ;;

    shell)
        echo "🐚 Opening shell in '$CONTAINER_NAME'..."
        docker exec -it "$CONTAINER_NAME" /bin/bash
        ;;

    stop)
        echo "⏹️  Stopping container '$CONTAINER_NAME'..."
        docker stop "$CONTAINER_NAME"
        echo "   ✅ Container stopped"
        ;;

    rm)
        echo "🗑️  Removing container '$CONTAINER_NAME'..."
        docker rm "$CONTAINER_NAME" -f
        echo "   ✅ Container removed"
        ;;

    status)
        echo "📊 Container status:"
        if docker ps -a --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
            if docker ps --format '{{.Names}}' | grep -q "^${CONTAINER_NAME}$"; then
                echo "   Status: RUNNING"
                docker ps --filter "name=$CONTAINER_NAME" --format "table {{.ID}}\t{{.Image}}\t{{.Status}}"
            else
                echo "   Status: STOPPED"
                docker ps -a --filter "name=$CONTAINER_NAME" --format "table {{.ID}}\t{{.Image}}\t{{.Status}}"
            fi
        else
            echo "   Status: NOT FOUND"
        fi
        ;;

    logs)
        echo "📜 Container logs:"
        docker logs "$CONTAINER_NAME"
        ;;

    bash)
        shift
        echo "🔨 Running: $@"
        docker exec "$CONTAINER_NAME" bash -c "$@"
        ;;

    *)
        echo "Usage: bash CONTAINER_MANAGER.sh [arch] [command]"
        echo ""
        echo "Architecture (default: arm64):"
        echo "  arm64         - ARM64 native container"
        echo "  x86-64        - x86_64 container"
        echo ""
        echo "Commands:"
        echo "  start         - Start the container in background"
        echo "  shell         - Open an interactive shell in the container"
        echo "  stop          - Stop the container"
        echo "  rm            - Remove the container"
        echo "  status        - Show container status"
        echo "  logs          - Show container logs"
        echo "  bash [cmd]    - Run a bash command in the container"
        echo ""
        echo "Examples:"
        echo "  bash CONTAINER_MANAGER.sh arm64 shell"
        echo "  bash CONTAINER_MANAGER.sh x86-64 shell"
        echo "  bash CONTAINER_MANAGER.sh x86-64 bash 'srcclr --version'"
        echo "  bash CONTAINER_MANAGER.sh x86-64 bash 'srcclr scan /home/yocto/build-x86-64/tmp-glibc/work'"
        ;;
esac
