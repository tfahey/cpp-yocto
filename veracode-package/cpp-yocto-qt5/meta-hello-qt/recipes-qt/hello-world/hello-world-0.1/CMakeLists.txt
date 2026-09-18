cmake_minimum_required(VERSION 3.16)

project(hello-world)

set(CMAKE_CXX_STANDARD 11)
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)

find_package(Qt5 COMPONENTS Core Gui Widgets REQUIRED)

add_executable(hello-world
    main.cpp
    mainwindow.cpp
    mainwindow.h
)

target_link_libraries(hello-world Qt5::Core Qt5::Gui Qt5::Widgets)

install(TARGETS hello-world DESTINATION bin)
