# Code Walkthrough - Understanding Each File

Let's go through each file in our project and understand what it does.

---

## BitBake Recipe: `hello-world.bb`

**Location:** `meta-hello-qt/recipes-qt/hello-world/hello-world.bb`

This is the **most important file**. It tells Yocto how to build our application.

```bash
SUMMARY = "Hello World Qt Application"
```
Short one-line description. Shown by `bitbake-layers show-recipes`.

```bash
DESCRIPTION = "A simple Qt5 GUI application for learning Yocto"
```
Longer description. For documentation.

```bash
HOMEPAGE = "https://github.com/example/hello-world"
LICENSE = "MIT"
```
Metadata about the project.

```bash
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835..."
```
License verification. Ensures the license file hasn't been altered. 
- `${COMMON_LICENSE_DIR}` = `/path/to/poky/meta/files/common-licenses/`

```bash
SRC_URI = "file://CMakeLists.txt \
           file://main.cpp \
           file://mainwindow.h \
           file://mainwindow.cpp"
```
**Source URIs** - Where BitBake gets our source files:
- `file://` prefix = relative to the recipe directory
- Yocto looks in `hello-world-0.1/` (version directory)
- BitBake copies these to `tmp/work/` during build

```bash
S = "${WORKDIR}"
```
**Source directory** - Where BitBake extracts/finds source code.
- `${WORKDIR}` = the working directory in `tmp/work/`

```bash
inherit cmake
```
**Class inheritance** - Use CMake build system.
This automatically:
- Calls `cmake ..` during configure
- Calls `make` during compile
- Calls `make install` during install

(Could also be: `inherit autotools`, `inherit qmake5`, `inherit meson`, etc.)

```bash
DEPENDS = "qt5-qmake-native qt5-base qt5-declarative"
```
**Build-time dependencies** - Packages needed to BUILD this recipe:
- `qt5-qmake-native` = Qt build tools (for the build machine)
- `qt5-base` = Qt base libraries (for target/linking)
- `qt5-declarative` = Qt Quick (we don't need this, but it's included)

BitBake will build these first, then build our app.

```bash
RDEPENDS:${PN} = "qt5-core qt5-gui qt5-widgets"
```
**Runtime dependencies** - Packages needed to RUN this application on the target:
- `qt5-core` = Core Qt library
- `qt5-gui` = GUI framework
- `qt5-widgets` = Widget framework

These must be on the target device when the app runs.

---

## CMake Build Config: `CMakeLists.txt`

**Location:** `meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/CMakeLists.txt`

This tells the C++ build system (CMake) how to compile our application.

```cmake
cmake_minimum_required(VERSION 3.16)
```
Require CMake 3.16 or higher. Fails if older version.

```cmake
project(hello-world)
```
Project name. Sets `${PROJECT_NAME}` variable.

```cmake
set(CMAKE_CXX_STANDARD 11)
```
Use C++11 standard. Could be 14, 17, 20, etc.

```cmake
set(CMAKE_AUTOMOC ON)
set(CMAKE_AUTORCC ON)
set(CMAKE_AUTOUIC ON)
```
Qt5-specific settings:
- **AUTOMOC**: Auto-run Qt's Meta-Object Compiler (moc tool)
  - Processes `Q_OBJECT` macro in headers
- **AUTORCC**: Auto-compile resource files (.qrc)
- **AUTOUIC**: Auto-compile UI files (.ui)

```cmake
find_package(Qt5 COMPONENTS Core Gui Widgets REQUIRED)
```
Find Qt5 libraries on the system:
- Core = Core library
- Gui = GUI framework
- Widgets = Widget framework

**REQUIRED** means fail if not found.

```cmake
add_executable(hello-world
    main.cpp
    mainwindow.cpp
    mainwindow.h
)
```
Create an executable named `hello-world` from these source files:
- `main.cpp` = implementation
- `mainwindow.cpp` = implementation
- `mainwindow.h` = header file

```cmake
target_link_libraries(hello-world Qt5::Core Qt5::Gui Qt5::Widgets)
```
Link against Qt5 libraries. Without this, compilation fails (unresolved symbols).

```cmake
install(TARGETS hello-world DESTINATION bin)
```
Install the binary to `/usr/bin` on the target system.

---

## C++ Application: `main.cpp`

**Location:** `meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/main.cpp`

This is the application entry point.

```cpp
#include <QApplication>
#include "mainwindow.h"
```
Include headers for:
- `QApplication` = Qt application object (event loop)
- `MainWindow` = Our custom window class

```cpp
int main(int argc, char *argv[])
{
```
Entry point. `argc`/`argv` = command-line arguments.

```cpp
    QApplication app(argc, argv);
```
Create the Qt application object:
- Processes command-line arguments
- Sets up the event loop
- Manages application-wide settings

Every Qt GUI app needs exactly one `QApplication`.

```cpp
    MainWindow window;
    window.show();
```
Create and display our main window.

```cpp
    return app.exec();
}
```
Start the event loop. Qt processes events (clicks, messages, timers, etc.).
Returns when user closes the window.

---

## Qt Header: `mainwindow.h`

**Location:** `meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/mainwindow.h`

Declares our custom `MainWindow` class.

```cpp
#ifndef MAINWINDOW_H
#define MAINWINDOW_H
```
Header guard. Prevents including the file twice.

```cpp
#include <QMainWindow>
#include <QLabel>
#include <QPushButton>
```
Include Qt classes:
- `QMainWindow` = Main application window
- `QLabel` = Text/image display widget
- `QPushButton` = Clickable button

```cpp
class MainWindow : public QMainWindow
{
    Q_OBJECT
```
Define `MainWindow` class inheriting from `QMainWindow`.

`Q_OBJECT` macro enables:
- Signal/slot mechanism
- Meta-object system (introspection)
- Dynamic property system

**This macro must be in the class definition!**

```cpp
public:
    MainWindow();
```
Public constructor. Called when creating a window.

```cpp
private slots:
    void onButtonClicked();
```
Private slot (signal handler). Called when button is clicked.

In Qt:
- **Signal** = event that can happen (button click, timer, etc.)
- **Slot** = function that receives the signal
- `Q_OBJECT` + `connect()` wires them together

```cpp
private:
    QLabel *label;
    QPushButton *button;
```
Member variables:
- `label` = pointer to label widget
- `button` = pointer to button widget

---

## Qt Implementation: `mainwindow.cpp`

**Location:** `meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/mainwindow.cpp`

Implements the `MainWindow` class.

```cpp
#include "mainwindow.h"
#include <QVBoxLayout>
#include <QWidget>
```
Include headers:
- `mainwindow.h` = Our header
- `QVBoxLayout` = Vertical box layout (arranges widgets)
- `QWidget` = Base widget class

```cpp
MainWindow::MainWindow() : QMainWindow()
{
```
Constructor. `:` calls parent class constructor first.

```cpp
    setWindowTitle("Hello World - Qt + Yocto");
    setGeometry(100, 100, 400, 300);
```
Set window properties:
- Title (shown in title bar)
- Position (100, 100) and size (400x300)

```cpp
    QWidget *centralWidget = new QWidget;
    setCentralWidget(centralWidget);
```
Create central widget and set it as the main content area.

In `QMainWindow`, you need a central widget to hold other widgets.

```cpp
    QVBoxLayout *layout = new QVBoxLayout;
```
Create a vertical box layout. Arranges widgets top-to-bottom.

```cpp
    label = new QLabel("Hello from Yocto + Qt!");
    label->setStyleSheet("QLabel { font-size: 18px; font-weight: bold; }");
    layout->addWidget(label);
```
Create and configure label:
- Text = "Hello from Yocto + Qt!"
- Stylesheet = CSS-like styling (18px, bold)
- Add to layout

```cpp
    button = new QPushButton("Click Me");
    button->setMinimumHeight(40);
    connect(button, &QPushButton::clicked, this, &MainWindow::onButtonClicked);
    layout->addWidget(button);
```
Create and configure button:
- Text = "Click Me"
- Minimum height = 40 pixels
- **Connect signal to slot**: When button is clicked, call `onButtonClicked()`
- Add to layout

The `connect()` call is the key Qt feature:
```
connect(sender,     signal,                  receiver,   slot)
        button      clicked                  this        onButtonClicked
```

```cpp
    layout->addStretch();
    centralWidget->setLayout(layout);
}
```
Add empty space (stretch) to push widgets to top.
Set the layout on the central widget.

```cpp
void MainWindow::onButtonClicked()
{
    static int clickCount = 0;
    clickCount++;
    label->setText(QString("Button clicked %1 times").arg(clickCount));
}
```
Slot function called when button is clicked:
- `static int clickCount` = persists between function calls
- Increment counter
- Update label with count

`QString::arg()` = string formatting (like printf).

---

## Layer Configuration: `layer.conf`

**Location:** `meta-hello-qt/conf/layer.conf`

Tells Yocto about our custom layer.

```bash
BBPATH .= ":${LAYERDIR}"
```
Add layer directory to BitBake search path.
- `.=` = append to existing path
- `${LAYERDIR}` = this layer's directory

```bash
BBFILES += "${LAYERDIR}/recipes-*/*/*.bb"
BBFILES += "${LAYERDIR}/recipes-*/*/*.bbappend"
```
Tell BitBake where to find recipe files:
- `recipes-*/*/*.bb` = all `.bb` files in recipe directories
- `recipes-*/*/*.bbappend` = recipe append files (for modifications)

```bash
BBFILE_COLLECTIONS += "meta-hello-qt"
```
Register this layer as a collection named "meta-hello-qt".

```bash
BBFILE_PATTERN_meta-hello-qt = "^${LAYERDIR}/"
BBFILE_PRIORITY_meta-hello-qt = "10"
```
Set the pattern and priority:
- **Pattern** = recipes in this directory belong to this collection
- **Priority** = 10 (higher = takes precedence over other layers)
  - Allows overriding recipes from other layers

```bash
LAYERSERIES_COMPAT_meta-hello-qt = "scarthgap"
```
Declare compatibility with Yocto series "scarthgap".
- Prevents using old recipes with new Yocto versions
- Must match the Poky branch you cloned

---

## Summary: Data Flow

```
User edits → main.cpp, mainwindow.cpp, CMakeLists.txt
    ↓
hello-world.bb describes how to build
    ↓
BitBake reads recipe + layer.conf
    ↓
BitBake downloads sources (using SRC_URI)
    ↓
CMake configures (reads CMakeLists.txt)
    ↓
C++ compiler builds (g++ for target)
    ↓
Binary linked against Qt libraries
    ↓
hello-world executable created
    ↓
Installed to /usr/bin on target system
```

Each file has a specific purpose in this pipeline!

---

## Modifying the Application

Want to change the app? Edit these:

| Want to... | Edit... |
|-----------|---------|
| Change UI layout | `mainwindow.cpp` |
| Add a new button | `mainwindow.h` + `mainwindow.cpp` |
| Add new feature | `mainwindow.cpp` |
| Change build system | `CMakeLists.txt` |
| Change dependencies | `hello-world.bb` (DEPENDS/RDEPENDS) |
| Change name/version | `hello-world.bb` (filename, SRC_URI) |

After editing, rebuild:
```bash
bitbake hello-world -f    # Force rebuild
```

The `-f` flag tells BitBake to ignore cache and rebuild.

---

## Next Steps

- Ready to build? → Follow [BUILD_INSTRUCTIONS.md](BUILD_INSTRUCTIONS.md)
- Want to modify? → Edit the source files, then rebuild
- Questions? → Check [QUICK_REFERENCE.md](QUICK_REFERENCE.md)
