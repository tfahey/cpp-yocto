SUMMARY = "Hello World Qt Application"
DESCRIPTION = "A simple Qt5 GUI application for learning Yocto"
HOMEPAGE = "https://github.com/example/hello-world"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

# Use FILESEXTRAPATHS to help BitBake find the source files
FILESEXTRAPATHS:prepend := "${THISDIR}/${PN}-${PV}:"

SRC_URI = "file://CMakeLists.txt \
           file://main.cpp \
           file://mainwindow.h \
           file://mainwindow.cpp"

S = "${WORKDIR}"

# Inherit cmake class for CMake-based projects
inherit cmake cmake_qt5

# Qt5 dependencies - simplified for meta-qt5
# cmake_qt5 class handles most of the Qt5 setup
DEPENDS = "qtbase-native qtdeclarative-native"

RDEPENDS:${PN} = "qtbase qtdeclarative"
