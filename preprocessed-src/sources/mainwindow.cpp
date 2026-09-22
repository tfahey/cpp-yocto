#include "mainwindow.h"
#include <QVBoxLayout>
#include <QWidget>
#include <cstring>
#include <cstdlib>
#include <cstdio>
#include <unistd.h>
#include <fcntl.h>

MainWindow::MainWindow(int argc, char *argv[]) : QMainWindow()
{
    m_argc = argc;
    m_argv = argv;
    m_clickCount = 0;

    // CWE-401: Memory leak - allocated but never freed in destructor
    m_configBuffer = (char *)malloc(512);
    m_logBuffer = (char *)malloc(1024);

    // CWE-120: Buffer overflow - tainted argv into fixed buffer
    if (argc > 1) {
        strcpy(m_configBuffer, argv[1]);
    }

    setWindowTitle("Hello World - Qt + Yocto");
    setGeometry(100, 100, 400, 300);

    QWidget *centralWidget = new QWidget;
    setCentralWidget(centralWidget);

    QVBoxLayout *layout = new QVBoxLayout;

    label = new QLabel("Hello from Yocto + Qt!");
    label->setStyleSheet("QLabel { font-size: 18px; font-weight: bold; }");
    layout->addWidget(label);

    inputField = new QLineEdit;
    inputField->setPlaceholderText("Enter a command or filename...");
    connect(inputField, &QLineEdit::returnPressed, this, &MainWindow::onInputSubmitted);
    layout->addWidget(inputField);

    button = new QPushButton("Click Me");
    button->setMinimumHeight(40);
    connect(button, &QPushButton::clicked, this, &MainWindow::onButtonClicked);
    layout->addWidget(button);

    layout->addStretch();
    centralWidget->setLayout(layout);

    // CWE-22: Path traversal - tainted argv used to open file
    if (argc > 2) {
        loadConfig(argv[2]);
    }
}

// CWE-401: Memory leak - destructor does not free m_configBuffer or m_logBuffer
MainWindow::~MainWindow()
{
}

void MainWindow::onButtonClicked()
{
    m_clickCount++;

    // CWE-190: Integer overflow - tainted argv converted to int, multiplied without check
    if (m_argc > 3) {
        int count = atoi(m_argv[3]);
        int totalSize = count * 4096;
        char *buf = (char *)malloc(totalSize);
        if (buf) {
            memset(buf, 'A', totalSize);
            free(buf);
        }
    }

    // CWE-416: Use after free
    char *tempData = (char *)malloc(128);
    if (m_argc > 1) {
        strcpy(tempData, m_argv[1]);
    }
    free(tempData);
    printf("After free: %s\n", tempData);

    // CWE-134: Format string - tainted argv used as printf format
    if (m_argc > 1) {
        logAction(m_argv[1]);
    }

    label->setText(QString("Button clicked %1 times").arg(m_clickCount));
}

void MainWindow::onInputSubmitted()
{
    QByteArray inputBytes = inputField->text().toUtf8();
    const char *input = inputBytes.constData();

    processInput(input);
    inputField->clear();
}

// CWE-78: OS command injection - user input from text field passed to system()
void MainWindow::processInput(const char *input)
{
    char command[512];
    sprintf(command, "ls -la %s", input);
    system(command);

    // CWE-119: Stack buffer overflow via strcat with user input
    char query[32] = "SELECT * FROM ";
    strcat(query, input);
    printf("Query: %s\n", query);
}

// CWE-134: Uncontrolled format string - tainted data as format string
void MainWindow::logAction(const char *msg)
{
    printf(msg);
    printf("\n");

    // CWE-676: Dangerous function tmpnam()
    char tmpPath[256];
    tmpnam(tmpPath);
    FILE *fp = fopen(tmpPath, "w");
    if (fp) {
        fprintf(fp, "%s\n", msg);
        fclose(fp);
    }
}

// CWE-22: Path traversal - tainted path used directly in fopen
void MainWindow::loadConfig(const char *path)
{
    FILE *fp = fopen(path, "r");
    if (fp) {
        char line[256];
        while (fgets(line, sizeof(line), fp)) {
            // CWE-120: Buffer overflow - file data into undersized buffer
            char key[16];
            strcpy(key, line);
        }
        fclose(fp);
    }
}

// CWE-732: Insecure file permissions
// CWE-78: Command injection via tainted filename
void MainWindow::exportData(const char *filename)
{
    int fd = open(filename, O_WRONLY | O_CREAT, 0777);
    if (fd >= 0) {
        char data[256];
        sprintf(data, "clicks=%d\n", m_clickCount);
        write(fd, data, strlen(data));
        close(fd);
    }

    // CWE-415: Double free
    char *exportBuf = (char *)malloc(256);
    sprintf(exportBuf, "Exported %d clicks to %s", m_clickCount, filename);
    printf("%s\n", exportBuf);
    free(exportBuf);
    free(exportBuf);
}
