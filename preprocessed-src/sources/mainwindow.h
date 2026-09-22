#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QLabel>
#include <QPushButton>
#include <QLineEdit>

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow(int argc, char *argv[]);
    ~MainWindow();

private slots:
    void onButtonClicked();
    void onInputSubmitted();

private:
    void processInput(const char *input);
    void logAction(const char *msg);
    void loadConfig(const char *path);
    void exportData(const char *filename);

    QLabel *label;
    QPushButton *button;
    QLineEdit *inputField;

    char *m_configBuffer;
    char *m_logBuffer;
    int m_clickCount;
    char **m_argv;
    int m_argc;
};

#endif // MAINWINDOW_H
