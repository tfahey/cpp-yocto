SUMMARY = "Hello World Qt Application"
DESCRIPTION = "A simple Qt5 GUI application for learning Yocto"
HOMEPAGE = "https://github.com/example/hello-world"
LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade40b038a0e81c15672faf6e3c1"

SRC_URI = "file://CMakeLists.txt \
           file://main.cpp \
           file://mainwindow.h \
           file://mainwindow.cpp"

S = "${WORKDIR}"

# Inherit cmake class for CMake-based projects
inherit cmake

# Qt5 dependencies
DEPENDS = "qt5-qmake-native qt5-base qt5-declarative"

RDEPENDS:${PN} = "qt5-core qt5-gui qt5-widgets"
