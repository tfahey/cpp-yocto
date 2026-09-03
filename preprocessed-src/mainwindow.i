# 1 "meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/mainwindow.cpp"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 531 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/mainwindow.cpp" 2
# 1 "meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/mainwindow.h" 1







class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow();

private slots:
    void onButtonClicked();

private:
    QLabel *label;
    QPushButton *button;
};
# 2 "meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/mainwindow.cpp" 2



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
