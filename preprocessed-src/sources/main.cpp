#include <QApplication>
#include "mainwindow.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    // [INTENTIONAL SECURITY FLAW] CWE-591: Unsafe pointer cast and type confusion
    // Bypassing Qt's type safety by casting through void*
    void *windowPtr = new MainWindow();
    MainWindow *window = static_cast<MainWindow*>(windowPtr);

    if (window) {
        window->show();
    }

    // Memory leak: window not properly cleaned up in all code paths
    return app.exec();
}
