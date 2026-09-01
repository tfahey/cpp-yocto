# Dockerfile for Yocto Qt5 Build Environment
#
# Usage:
#   docker build -t yocto-qt-builder:latest .
#   docker run -it -v $(pwd):/home/yocto/project yocto-qt-builder:latest
#
# Based on: Ubuntu 20.04 LTS

FROM ubuntu:20.04

# Metadata
LABEL maintainer="Yocto Learning Project"
LABEL description="Complete Yocto build environment with Qt5 support"

# Prevent interactive prompts during installation
ENV DEBIAN_FRONTEND=noninteractive

# Install all Yocto build dependencies in one layer (reduces image size)
RUN apt-get update && apt-get install -y \
    # Version control
    git \
    \
    # Yocto core tools
    chrpath \
    diffstat \
    wget \
    \
    # Python (required for BitBake)
    python3 \
    python3-dev \
    python3-pip \
    \
    # Build tools
    texinfo \
    gcc \
    g++ \
    build-essential \
    cmake \
    \
    # System tools
    curl \
    sudo \
    \
    # Development libraries
    libncurses-dev \
    zlib1g-dev \
    gawk \
    libbz2-dev \
    libssl-dev \
    socat \
    cpio \
    time \
    bison \
    flex \
    xz-utils \
    liblz4-tool \
    zstd \
    \
    # Optional but useful
    vim \
    nano \
    less \
    ipython3 \
    \
    # Cleanup
    && rm -rf /var/lib/apt/lists/*

# Create non-root user for builds (Yocto best practice)
# This prevents permission issues and is more secure
RUN useradd -m -s /bin/bash yocto && \
    echo "yocto ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    mkdir -p /home/yocto/project && \
    chown -R yocto:yocto /home/yocto

# Switch to non-root user
USER yocto

# Set working directory
WORKDIR /home/yocto/project

# Set helpful shell prompt
ENV PS1="\[$(tput bold)\]\[$(tput setaf 2)\]yocto-container:\w\$\[$(tput sgr0)\] "

# Print build info
RUN echo "Yocto Qt5 Build Environment Ready" && \
    echo "Yocto User: $(whoami)" && \
    echo "Python: $(python3 --version)" && \
    echo "Git: $(git --version)" && \
    echo "GCC: $(gcc --version | head -1)"

# Default command (interactive bash shell)
CMD ["/bin/bash"]
