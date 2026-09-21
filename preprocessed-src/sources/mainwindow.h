#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QLabel>
#include <QPushButton>

class MainWindow : public QMainWindow
{
    Q_OBJECT

public:
    MainWindow();
    ~MainWindow();

private slots:
    void onButtonClicked();

private:
    void updateCounterDisplay(int count);

    QLabel *label;
    QPushButton *button;

    // [INTENTIONAL SECURITY FLAW] CWE-457: Uninitialized variable
    int m_lastClickTime;

    // [INTENTIONAL SECURITY FLAW] CWE-401: Potential resource leak
    char *m_tempBuffer;
};

#endif // MAINWINDOW_H
