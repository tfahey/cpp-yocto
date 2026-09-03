#include "mainwindow.h"
#include <QVBoxLayout>
#include <QWidget>

MainWindow::MainWindow() : QMainWindow()
{
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

void MainWindow::onButtonClicked()
{
    static int clickCount = 0;
    clickCount++;
    label->setText(QString("Button clicked %1 times").arg(clickCount));
}
