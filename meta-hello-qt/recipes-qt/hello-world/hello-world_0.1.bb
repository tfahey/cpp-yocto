SUMMARY = "Hello World Qt Application"
DESCRIPTION = "A simple Qt5 GUI application for learning Yocto"
HOMEPAGE = "https://github.com/example/hello-world"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade40b038a0e81c15672faf6e3c1"

# Use FILESEXTRAPATHS to help BitBake find the source files
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}-${PV}:"

SRC_URI = "file://CMakeLists.txt \
           file://main.cpp \
           file://mainwindow.h \
           file://mainwindow.cpp"

S = "${WORKDIR}"

# Inherit cmake class for CMake-based projects
inherit cmake

# Qt5 dependencies (using meta-qt5 package names)
DEPENDS = "qtbase-native qtbase qtdeclarative"

RDEPENDS:${PN} = "qtbase-core qtbase-gui qtbase-widgets"
