# Yocto + Qt Hello World - Learning Guide

This guide walks you through building a simple C++ Qt "hello world" application using Yocto. We'll learn the fundamentals along the way.

## What is Yocto?

Yocto is a project that allows you to create customized Linux distributions for embedded systems. It uses BitBake (a build system) and recipes (instructions for building packages).

**Key concepts:**
- **BitBake**: The build engine that orchestrates the build process
- **Recipes**: Files (`.bb`) that tell BitBake how to build a package
- **Layers**: Collections of recipes organized by purpose (core, meta, custom)
- **Metadata**: Configuration files that describe what to build and how

## Project Structure

We'll create this structure:

```
cpp-yocto/
├── meta-hello-qt/          # Our custom layer
│   ├── conf/
│   │   └── layer.conf      # Layer configuration
│   ├── recipes-qt/
│   │   └── hello-world/
│   │       ├── hello-world.bb           # BitBake recipe
│   │       └── hello-world-0.1/         # Source directory
│   │           ├── CMakeLists.txt
│   │           ├── main.cpp
│   │           ├── mainwindow.h
│   │           └── mainwindow.cpp
│   └── COPYING
├── poky/                   # Yocto/Poky source (we'll clone this)
└── build/                  # Build directory (created by Yocto)
```

## Step-by-Step Process

1. Clone Poky (the reference Yocto distribution)
2. Create a custom layer (`meta-hello-qt`)
3. Create a Qt application source code
4. Write a BitBake recipe for our application
5. Configure the build
6. Build the image

Let's start! →
