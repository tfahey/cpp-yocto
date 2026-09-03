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

private slots:
    void onButtonClicked();

private:
    QLabel *label;
    QPushButton *button;
};

#endif // MAINWINDOW_H
