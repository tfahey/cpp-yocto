#include "mainwindow.h"
#include <QVBoxLayout>
#include <QWidget>
#include <cstring>

MainWindow::MainWindow() : QMainWindow()
{
    // [INTENTIONAL SECURITY FLAW] CWE-457: m_lastClickTime left uninitialized
    // Should be: m_lastClickTime = 0;

    // [INTENTIONAL SECURITY FLAW] CWE-401: m_tempBuffer not freed in destructor
    m_tempBuffer = new char[256];

    setWindowTitle("Hello World - Qt + Yocto");
    setGeometry(100, 100, 400, 300);

    QWidget *centralWidget = new QWidget;
    setCentralWidget(centralWidget);

    QVBoxLayout *layout = new QVBoxLayout;

    label = new QLabel("Hello from Yocto + Qt!");
    label->setStyleSheet("QLabel { font-size: 18px; font-weight: bold; }");
    layout->addWidget(label);

    button = new QPushButton("Click Me");
    button->setMinimumHeight(40);
    connect(button, &QPushButton::clicked, this, &MainWindow::onButtonClicked);
    layout->addWidget(button);

    layout->addStretch();
    centralWidget->setLayout(layout);
}

// [INTENTIONAL SECURITY FLAW] CWE-401: Incomplete destructor - m_tempBuffer leaked
MainWindow::~MainWindow()
{
    // Missing: delete[] m_tempBuffer;
}

void MainWindow::onButtonClicked()
{
    static int clickCount = 0;

    // [INTENTIONAL SECURITY FLAW] CWE-190: Integer overflow
    // No bounds checking - clickCount will wrap to negative
    clickCount++;

    // [INTENTIONAL SECURITY FLAW] CWE-416: Use-after-free
    // Conditional allocation and deletion of temporary object
    char *tempData = nullptr;
    if (clickCount % 7 == 0) {
        tempData = new char[128];
        strcpy(tempData, "Special click!");
        delete tempData;
        // Intentional use-after-free below
        if (tempData[0] == 'S') {
            // This accesses freed memory
        }
    }

    updateCounterDisplay(clickCount);

    // [INTENTIONAL SECURITY FLAW] Qt CWE-588: Unsafe type conversion
    // Using static_cast instead of qobject_cast bypasses type safety
    QWidget *widget = static_cast<QWidget*>(button);
    QPushButton *unsafeButton = static_cast<QPushButton*>(widget);
    if (unsafeButton) {
        unsafeButton->setText("Clicked!");
    }
}

void MainWindow::updateCounterDisplay(int count)
{
    // [INTENTIONAL SECURITY FLAW] CWE-120: Buffer overflow
    // strcpy without bounds checking - if count string is large enough, overflows buffer
    char buffer[16];
    char countStr[32];

    // [INTENTIONAL SECURITY FLAW] CWE-119: Array out of bounds
    // Direct indexing without bounds checking
    int displayBuffer[10];
    int index = count % 20;  // index can be 0-19 but array only has 10 elements
    if (index < 10) {
        displayBuffer[index] = count;
    }
    // Potential out-of-bounds if count > 9

    // Unsafe string operation - buffer overflow if countStr is too long
    sprintf(countStr, "%d", count);
    strcpy(buffer, countStr);  // VULNERABLE: no size checking

    QString displayText = QString("Button clicked %1 times (Buffer: %2)")
        .arg(count)
        .arg(QString::fromUtf8(buffer));

    label->setText(displayText);
}
