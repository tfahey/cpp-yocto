# 1 "meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/main.cpp"
# 1 "<built-in>" 1
# 1 "<built-in>" 3
# 531 "<built-in>" 3
# 1 "<command line>" 1
# 1 "<built-in>" 2
# 1 "meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/main.cpp" 2

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
# 3 "meta-hello-qt/recipes-qt/hello-world/hello-world-0.1/main.cpp" 2

int main(int argc, char *argv[])
{
    QApplication app(argc, argv);
    MainWindow window;
    window.show();
    return app.exec();
}
