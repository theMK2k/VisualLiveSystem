#include "mainwindow.h"
#include "ui_mainwindow.h"

#include "core.h"
#include "channelwidget.h"
#include "visualmanager.h"
#include "masterwidget.h"
#include "projectorwidget.h"
#include "soundmanager.h"
#include "midiwindow.h"

#include <QAction>
#include <QMessageBox>

namespace
{
void showAndActivate(QWidget *window)
{
    window->show();
    window->raise();
    window->activateWindow();
}
}


MainWindow::MainWindow(QWidget *parent) :
    QMainWindow(parent),
    ui(new Ui::MainWindow)
{
    ui->setupUi(this);

    Core::instance()->initAudio();
    Core::instance()->initWidgets();

    //Windows
    m_chan[0] = new ChannelWidget(0,ui->widget);
    m_chan[1] = new ChannelWidget(1,ui->widget);
    m_master = new MasterWidget(ui->widget);
    m_visualManager = new VisualManager();
    m_proj = new ProjectorWidget(ui->widget);
    m_soundManager = new SoundManager(*(Core::instance()->audioPipe));
    m_midiManager = new MidiWindow();

    addDockWidget(Qt::LeftDockWidgetArea, m_chan[0]);
    addDockWidget(Qt::RightDockWidgetArea, m_chan[1]);
    addDockWidget(Qt::BottomDockWidgetArea, m_master);

    //Tool bar
    ui->toolBar->addAction(ui->actionSound_manager);
    ui->toolBar->addAction(ui->actionVisual_Manager);
    ui->toolBar->addAction(ui->actionControllers_manager);
    ui->toolBar->addSeparator();
    ui->toolBar->addAction(ui->actionProjector);
    //ui->toolBar->addSeparator();
    //ui->toolBar->addAction(ui->actionPreferences);

    //Connections
    connect(ui->actionVisual_Manager, &QAction::triggered, this,
            [this]() { showAndActivate(m_visualManager); });
    connect(ui->actionProjector, &QAction::triggered, this,
            [this]() { showAndActivate(m_proj); });
    connect(ui->actionControllers_manager, &QAction::triggered, this,
            [this]() { showAndActivate(m_midiManager); });
    connect(ui->actionSound_manager, &QAction::triggered, this,
            [this]() { showAndActivate(m_soundManager); });
    connect(ui->actionPreferences, &QAction::triggered,
            this, &MainWindow::showPreferencesInformation);
    connect(ui->actionQuit, &QAction::triggered, this, &QWidget::close);

    connect(m_visualManager, SIGNAL(newListFX(QList<QListWidgetItem*>)), ui->widget, SLOT(loadPostEffects(QList<QListWidgetItem*>)));
    connect(m_visualManager, SIGNAL(newListChanA(QList<QListWidgetItem*>)), m_chan[0], SLOT(updateList(QList<QListWidgetItem*>)));
    connect(m_visualManager, SIGNAL(newListChanB(QList<QListWidgetItem*>)), m_chan[1], SLOT(updateList(QList<QListWidgetItem*>)));

    connect(m_master, SIGNAL(finalPostFXDataChanged(float,float,float,float,float,float,float)),
            ui->widget, SLOT(updateFinalPostFXData(float,float,float,float,float,float,float)));

    connect(Core::instance()->audioPipe, SIGNAL(inLive(bool)), m_master, SLOT(inLive(bool)));
    connect(m_master, SIGNAL(transition()), ui->widget, SLOT(transition()));
    connect(Core::instance(), SIGNAL(channelSwitched()), m_chan[0], SLOT(Switch()));
    connect(Core::instance(), SIGNAL(channelSwitched()), m_chan[1], SLOT(Switch()));

    //Midi mapping
    connect(m_midiManager, SIGNAL(gammaValueChanged(int)), m_master, SLOT(gammaChanged(int)));
    connect(m_midiManager, SIGNAL(brightnessValueChanged(int)), m_master, SLOT(brightnessChanged(int)));
    connect(m_midiManager, SIGNAL(contrastValueChanged(int)), m_master, SLOT(contrastChanged(int)));
    connect(m_midiManager, SIGNAL(desaturateValueChanged(int)), m_master, SLOT(desaturateChanged(int)));
    connect(m_midiManager, SIGNAL(blackFadeValueChanged(int)), m_master, SLOT(blackFadeChanged(int)));
    connect(m_midiManager, SIGNAL(timeSpeedValueChanged(int)), m_master, SLOT(timeSpeedChanged(int)));
    connect(m_midiManager, SIGNAL(bassTimeSpeedValueChanged(int)), m_master, SLOT(bassTimeSpeedChanged(int)));

    connect(m_midiManager, SIGNAL(CC1Changed(int,float)), m_chan[0], SLOT(CCChanged(int,float)));
    connect(m_midiManager, SIGNAL(CC2Changed(int,float)), m_chan[1], SLOT(CCChanged(int,float)));

    connect(m_midiManager, SIGNAL(sceneUp()), m_chan[0], SLOT(sceneUp()));
    connect(m_midiManager, SIGNAL(sceneUp()), m_chan[1], SLOT(sceneUp()));
    connect(m_midiManager, SIGNAL(sceneDown()), m_chan[0], SLOT(sceneDown()));
    connect(m_midiManager, SIGNAL(sceneDown()), m_chan[1], SLOT(sceneDown()));

    connect(m_midiManager, SIGNAL(transitionUp()), m_master, SLOT(transitionUp()));
    connect(m_midiManager, SIGNAL(transitionDown()), m_master, SLOT(transitionDown()));

    connect(m_midiManager, SIGNAL(switchDisplay()), ui->widget, SLOT(transition()));
}

void MainWindow::showPreferencesInformation()
{
    QMessageBox::information(
        this,
        tr("Preferences"),
        tr("This version does not have a separate Preferences window.\n\n"
           "Use Sound manager for audio settings, Visual manager for scenes "
           "and rendering, and Controllers manager for MIDI mappings."));
}

MainWindow::~MainWindow()
{
    delete ui;
}

