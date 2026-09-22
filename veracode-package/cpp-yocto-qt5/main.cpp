#include <QApplication>
#include <cstring>
#include <cstdlib>
#include <cstdio>
#include "mainwindow.h"

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);

    // CWE-78: OS command injection - argv passed directly to system()
    if (argc > 1) {
        char cmd[256];
        sprintf(cmd, "echo Launching with config: %s", argv[1]);
        system(cmd);
    }

    // CWE-120: Buffer overflow - argv copied into undersized stack buffer
    char appName[8];
    if (argc > 0) {
        strcpy(appName, argv[0]);
    }

    MainWindow window(argc, argv);
    window.show();
    return app.exec();
}
