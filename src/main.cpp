// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QQmlPropertyMap>
#include <QCommandLineParser>
#include <QLoggingCategory>
#include <QQuickWindow>
#include <QQuickItem>
#include <QDir>
#include <QFileSelector>
#include <QQmlFileSelector>
#include <QTimer>
#include <QtPlugin>
#include <QAbstractNativeEventFilter>
#include <QSettings>
#include <QTemporaryFile>
#include <private/qabstractanimation_p.h> // For QUnifiedTimer
#include <QStringBuilder>
#include <QStandardPaths>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QEventLoop>
#include <QSaveFile>
#include <QQuickStyle>
#if defined(HAIQ_USE_WEBENGINE)
#  include <QtWebEngineQuick/qtwebenginequickglobal.h>
#endif
#if defined(HAIQ_USE_MULTIMEDIA)
#  include <QMediaDevices>
#  include <QAudioDevice>
#endif

#include "qtsingleapplication/qtsingleapplication.h"
#include "homeassistant.h"
#include "screenbrightness.h"
#include "squeezeboxserver.h"
#include "calendar.h"
#include "xbrowsersync/xbrowsersync.h"
#include "version.h"
#include "configuration.h"
#include "exception.h"


#if defined(Q_OS_ANDROID)
#  include "openurlclient.h"
#endif


// vvvv copied from QCommandLineParser ... why is this not public API?

enum MessageType { UsageMessage, ErrorMessage };

#if defined(Q_OS_ANDROID)
#  include <android/log.h>
#elif defined(Q_OS_WIN) && !defined(Q_OS_WINCE) && !defined(Q_OS_WINRT)
#  include <Windows.h>
#  pragma comment(lib, "user32.lib")

// Return whether to use a message box. Use handles if a console can be obtained
// or we are run with redirected handles (for example, by QProcess).
static inline bool displayMessageBox()
{
    if (GetConsoleWindow())
        return false;
    STARTUPINFO startupInfo;
    startupInfo.cb = sizeof(STARTUPINFO);
    GetStartupInfo(&startupInfo);
    return !(startupInfo.dwFlags & STARTF_USESTDHANDLES);
}
#endif // Q_OS_WIN && !QT_BOOTSTRAPPED && !Q_OS_WIN && !Q_OS_WINRT

static void showParserMessage(const QString &message, MessageType type)
{
#if defined(Q_OS_WIN) && !defined(Q_OS_WINCE) && !defined(Q_OS_WINRT)
    if (displayMessageBox()) {
        const UINT flags = MB_OK | MB_TOPMOST | MB_SETFOREGROUND
            | (type == UsageMessage ? MB_ICONINFORMATION : MB_ICONERROR);
        QString title;
        if (QCoreApplication::instance())
            title = QCoreApplication::instance()->property("applicationDisplayName").toString();
        if (title.isEmpty())
            title = QCoreApplication::applicationName();
        MessageBoxW(nullptr, reinterpret_cast<const wchar_t *>(message.utf16()),
                    reinterpret_cast<const wchar_t *>(title.utf16()), flags);
        return;
    }
#elif defined(Q_OS_ANDROID)
    static QByteArray appName = QCoreApplication::applicationName().toLocal8Bit();

    __android_log_print(type == UsageMessage ? ANDROID_LOG_WARN : ANDROID_LOG_ERROR,
                        appName.constData(), "%s", qPrintable(message));
    return;
#endif // Q_OS_WIN && !QT_BOOTSTRAPPED && !Q_OS_WIN && !Q_OS_WINRT
    fputs(qPrintable(message), type == UsageMessage ? stdout : stderr);
}

// ^^^^ copied from QCommandLineParser ... why is this not public API?




int main(int argc, char *argv[])
{
    for (int i = 1; i < argc; ++i) {
        if (strcmp(argv[i], "--software-gl") == 0) {
            QCoreApplication::setAttribute(Qt::AA_UseSoftwareOpenGL, true);
            QQuickWindow::setSceneGraphBackend(u"software"_qs);
            qDebug("USING SOFTWARE RENDERING");
        }
        if (strcmp(argv[i], "--verbose") == 0) {
            QLoggingCategory::setFilterRules(u"*=true"_qs);
            qDebug("VERBOSE");
        }
    }

#if !defined(Q_OS_ANDROID) && !defined(Q_OS_IOS)
    qputenv("QT_IM_MODULE", "qtvirtualkeyboard");
    qputenv("QT_VIRTUALKEYBOARD_DESKTOP_DISABLE", "1");
#endif

    QCoreApplication::setApplicationName(QLatin1String(HAIQ_NAME));
    QCoreApplication::setApplicationVersion(QLatin1String(HAIQ_VERSION));
    QCoreApplication::setOrganizationName(QLatin1String(HAIQ_NAME));
    QCoreApplication::setOrganizationDomain(u"haiq.griebl.org"_qs);
    QCoreApplication::setAttribute(Qt::AA_SynthesizeTouchForUnhandledMouseEvents);
    QCoreApplication::setAttribute(Qt::AA_ShareOpenGLContexts); // for webengine
#if defined(HAIQ_USE_WEBENGINE)
    QtWebEngineQuick::initialize();
#endif
#if defined(Q_OS_WINDOWS)
//    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
    QGuiApplication::setHighDpiScaleFactorRoundingPolicy(Qt::HighDpiScaleFactorRoundingPolicy::PassThrough);
#endif
    QtSingleApplication app(QCoreApplication::applicationName(), argc, argv);

//    if (QQuickWindow::sceneGraphBackend() == QSGRendererInterface::Software)
//        QUnifiedTimer::instance()->setTimingInterval(32 * 60); // 16 ~ 60fps, 32 ~ 30fps

    QQuickWindow *window = nullptr;
    bool anotherInstanceAvailable = app.isRunning();

    QObject::connect(&app, &QtSingleApplication::messageReceived,
                     &app, [&window](const QString &msg) {

        qDebug() << "Received an event from another instance: window="
                 << static_cast<void*>(window) << "; msg=" << msg;
        if ((msg == u"show") && window) {
            if (window->isVisible()) {
                window->close();
            } else {
                window->show();
                window->raise();
                window->requestActivate();
            }
        }
    });

    QString basePath = QLatin1String(HAIQ_BASE_PATH);
    if (!basePath.endsWith(u'/'))
        basePath.append(u'/');
    if (basePath.startsWith(u"qrc:/"))
        basePath.remove(0, 3);
    QString qmlPath = basePath + u"qml/"_qs;

    QSettings settings;


    QCommandLineParser clp;
    clp.addHelpOption();
    clp.addOption({ u"config-file"_qs, u"Local config file."_qs, u"file"_qs });
    clp.addOption({ u"config-host"_qs, u"Config download hostname or IP."_qs, u"hostname"_qs });
    clp.addOption({ u"config-token"_qs, u"Config download unique token."_qs, u"token"_qs });
    clp.addOption({ u"variant"_qs, u"Variant identifier in config file."_qs, u"variant"_qs });
    clp.addOption({ u"software-gl"_qs, u"Use the QML software renderer."_qs });
    clp.addOption({ u"verbose"_qs, u"Full debug output."_qs });
    clp.addOption({ u"fullscreen"_qs, u"Show the main window in full-screen mode."_qs });
    clp.addOption({ u"show-tracer"_qs, u"Show QML tracers."_qs });
    clp.addOption({ u"rotation"_qs, u"Rotate the window."_qs, u"degrees"_qs });
    clp.addOption({ u"new-instance"_qs, u"Don't just show the window of an already running instance, but always start a new one."_qs });
    clp.addOption({ u"brightness-control"_qs, u"Enable screen brightness control."_qs, u"options"_qs });

    if (!clp.parse(QCoreApplication::arguments())) {
        showParserMessage(clp.errorText() + "\n", ErrorMessage);
        return 1;
    }
    if (clp.isSet(u"help"_qs))
        clp.showHelp();

    // trigger existing instance and quit if there is one
    if (anotherInstanceAvailable && !clp.isSet(u"new-instance"_qs)) {
        qDebug() << "Activating other instance";
        return app.sendMessage(u"show"_qs) ? 0 : 3;
    }

    QString configHost = clp.value(u"config-host"_qs);
    if (configHost.isEmpty())
        configHost = qEnvironmentVariable("HAIQ_CONFIG_HOST");
    if (configHost.isEmpty())
        configHost = settings.value("Settings/ConfigHost").toString();
    if (configHost.isEmpty())
        configHost = u"haiq-config"_qs;

    QString configToken = clp.value(u"config-token"_qs);
    if (configToken.isEmpty())
        configToken = qEnvironmentVariable("HAIQ_CONFIG_TOKEN");
    if (configToken.isEmpty())
        configToken = settings.value("Settings/ConfigToken").toString();

    QString configFile = clp.value(u"config-file"_qs);

    if (configFile.isEmpty()) {
        QDir cacheDir = QStandardPaths::writableLocation(QStandardPaths::CacheLocation);
        cacheDir.mkpath(u"."_qs);
        configFile = cacheDir.absoluteFilePath(u"config.json"_qs);

        if (!configHost.isEmpty() && !configToken.isEmpty()) {
            QSaveFile scf(configFile);
            if (!scf.open(QIODevice::WriteOnly)) {
                showParserMessage("Could not open config file " + configFile + "\n", ErrorMessage);
                return 4;
            }
            QUrl url(u"http://" % configHost % u"/config/" % configToken % u"/config.json");
            QNetworkAccessManager nam;
            auto reply = nam.get(QNetworkRequest(url));
            QEventLoop loop;
            QObject::connect(reply, &QNetworkReply::finished, &loop, &QEventLoop::quit);
            loop.exec();
            if (reply->error() == QNetworkReply::NoError) {
                auto data = reply->readAll();
                if (!data.isEmpty() && (scf.write(data) == data.size()))
                    scf.commit();
            }
            delete reply;
        }
    }

    QString variant = clp.value(u"variant"_qs);
    if (variant.isEmpty())
        variant = qEnvironmentVariable("HAIQ_VARIANT");
    if (variant.isEmpty())
        variant = settings.value("Settings/Variant").toString();

    bool needSetup = variant.isEmpty()
            || (!clp.isSet(u"config-file"_qs) && (configHost.isEmpty() || configToken.isEmpty()));

    Configuration config(configFile, variant);
    try {
        config.parse();
    } catch (const Exception &e) {
        showParserMessage(e.errorString() % u".\n", ErrorMessage);
    }

#if defined(HAIQ_USE_MULTIMEDIA)
    const auto aos = QMediaDevices::audioOutputs();
    qWarning() << "Found" << aos.size() << "audio device(s)";
    for (const auto &ao : aos) {
        qWarning() << (ao.isDefault() ? " *" : " -") << ao.description() << ao.id();
    }
#endif

    QQmlApplicationEngine engine;
    engine.addImportPath(qmlPath);

    QQmlFileSelector *selector = new QQmlFileSelector(&engine);
    selector->setExtraSelectors({ variant });

    int rotation = clp.value(u"rotation"_qs).toInt();
    QString qmlFile;

    if (needSetup) {
        qmlFile= u"Setup.qml"_qs;

        auto pfn = qApp->platformName();
        QQuickStyle::setStyle((pfn == u"windows" || pfn == u"cocoa" || pfn == u"xcb" || pfn == u"wayland")
                              ? u"fusion"_qs : u"material"_qs);

        auto setup = new QQmlPropertyMap(&engine);
        setup->insert(u"possibleVariants"_qs, config.possibleVariants());
        setup->insert(u"selectedVariant"_qs, variant);
        setup->insert(u"configHostname"_qs, configHost);
        setup->insert(u"configToken"_qs, configToken);
        engine.rootContext()->setContextProperty(u"SetupProperties"_qs, setup);

        QObject::connect(setup, &QQmlPropertyMap::valueChanged,
                         &engine, [&settings](const QString &key, const QVariant &value) {
            if (key == u"selectedVariant")
                settings.setValue(u"/Settings/Variant"_qs, value.toString());
            else if (key == u"configHostname")
                settings.setValue(u"/Settings/ConfigHostname"_qs, value.toString());
            else if (key == u"configToken")
                settings.setValue(u"/Settings/ConfigToken"_qs, value.toString());
            settings.sync();
        });
    } else {
        if (!clp.isSet(u"rotation"_qs))
            rotation = config["rotation"].toInt();

        qmlFile = config["view"].toString();
        if (!qmlFile.isEmpty() && !QFile::exists(qmlPath + qmlFile)) {
            showParserMessage("Invalid view: " + qmlFile + "\n", ErrorMessage);
            return 2;
        }

        const QVariantMap qc = config["quickControls"].toMap();
        auto qqc2conf = new QTemporaryFile(qApp);
        if (!qc.isEmpty()) {
            // generate a temporary qtquickcontrols2.conf
            if (qqc2conf->open()) {
                QTextStream ts(qqc2conf);
                const auto groups = qc.keys();
                for (const auto &group : groups) {
                    ts << "[" << group << "]\n";
                    const auto map = qc.value(group).toMap();
                    for (auto it = map.begin(); it != map.end(); ++ it)
                        ts << it.key() << "=\"" << it.value().toString() << "\"\n";
                }
                qqc2conf->close();
                qputenv("QT_QUICK_CONTROLS_CONF", qqc2conf->fileName().toLocal8Bit().constData());
            }
        }

        /////////////////////////////////

        ScreenBrightness::registerQmlTypes();
        ScreenBrightness::createInstance(clp.value(u"brightness-control"_qs));

        /////////////////////////////////

        const auto homeAssistant = config["homeAssistant"].toMap();
        const QUrl haUrl = QUrl::fromUserInput(homeAssistant[u"url"_qs].toString());
        if (!haUrl.isEmpty() && !haUrl.scheme().startsWith(u"http")) {
            showParserMessage("Invalid Home-Assistant server URL: " + haUrl.toString() + "\n", ErrorMessage);
            return 2;
        }
        const QString haAuthToken = homeAssistant[u"accessToken"_qs].toString();

        HomeAssistant::registerQmlTypes();
        HomeAssistant::createInstance(haUrl, haAuthToken);

        /////////////////////////////////

        const auto squeezeboxServer = config["squeezeboxServer"].toMap();
        QUrl squeezeBoxServerUrl = QUrl::fromUserInput(squeezeboxServer[u"url"_qs].toString());
        QStringList sbPlayerNames = squeezeboxServer[u"players"_qs].toStringList();
        auto sbThisPlayerName = squeezeboxServer[u"thisPlayer"_qs].toString();

        SqueezeBoxServer::registerQmlTypes();
        SqueezeBoxServer::createInstance(squeezeBoxServerUrl.host(), squeezeBoxServerUrl.port());
        if (!sbPlayerNames.isEmpty())
            SqueezeBoxServer::instance()->setPlayerNameFilter(sbPlayerNames);
        if (!sbThisPlayerName.isEmpty())
            SqueezeBoxServer::instance()->setThisPlayerName(sbThisPlayerName);

        /////////////////////////////////

        const auto xbSync= config["xBrowserSync"].toMap();
        QUrl xbSyncUrl = QUrl::fromUserInput(xbSync[u"url"_qs].toString());
        auto xbSyncId = xbSync[u"syncId"_qs].toString();
        auto xbSyncPassword = xbSync[u"password"_qs].toString();

        XBrowserSync::registerQmlTypes();
        XBrowserSync::createInstance(xbSyncUrl, xbSyncId, xbSyncPassword);

        /////////////////////////////////

#if defined(Q_OS_ANDROID)
        QObject::connect(OpenUrlClient::instance(), &OpenUrlClient::commandReceived,
                         &app, [](const QString &command, const QStringList &parameters) {
            if (command == "alarm" && !parameters.isEmpty()) {
                SqueezeBoxServer::instance()->setThisPlayerAlarmState(parameters.at(0));
            }
        });
#endif

        /////////////////////////////////

        const auto calendar = config["calendar"].toMap();
        QUrl calUrl = QUrl::fromUserInput(calendar[u"url"_qs].toString());
        calUrl.setUserName(calendar[u"username"_qs].toString());
        calUrl.setPassword(calendar[u"password"_qs].toString());

        UpcomingCalendarEntries::registerQmlTypes();
        Calendar *cal = new Calendar(calUrl, qApp);
        engine.rootContext()->setContextProperty(u"MainCalendar"_qs, cal); //TODO: get rid of context property

        /////////////////////////////////

        engine.rootContext()->setContextProperty(u"Config"_qs, config["qml"].toMap());
    }

    QUrl baseUrl = basePath.startsWith(u":/") ? u"qrc"_qs + basePath
                                              : u"file:///"_qs + basePath;

    QIcon::setThemeName(u"dummy"_qs);
    QIcon::setFallbackSearchPaths({ basePath + u"icons/"_qs });

    engine.rootContext()->setContextProperty(u"showTracer"_qs, clp.isSet(u"show-tracer"_qs));

    engine.setBaseUrl(baseUrl);
    engine.load(QUrl(u"qml/"_qs + qmlFile));

    bool isFullscreen = clp.isSet(u"fullscreen"_qs);
#if defined(Q_OS_ANDROID)
    isFullscreen = true;
#endif

    const auto ros = engine.rootObjects();
    for (auto ro : ros) {
        if ((window = qobject_cast<QQuickWindow *>(ro))) {
            if (rotation)
                window->contentItem()->setRotation(rotation);
            if (isFullscreen)
                window->showFullScreen();

            qDebug() << "Device pixel ratio:" << window->devicePixelRatio();

#if defined(Q_OS_LINUX)
            // get rid of the annoying messages while the monitor is in standby
            if (qApp->platformName() == u"eglfs") {
                static QtMessageHandler oldHandler = nullptr;
                oldHandler = qInstallMessageHandler([](QtMsgType type, const QMessageLogContext &context, const QString &msg) {
                    if (!msg.startsWith(u"Could not queue DRM page flip on screen"))
                        oldHandler(type, context, msg);
                });
            }

#elif defined(Q_OS_WIN) && !defined(Q_OS_WINCE) && !defined(Q_OS_WINRT)

            class Win32Filter : public QAbstractNativeEventFilter
            {
            public:
                Win32Filter(QQuickWindow *window)
                    : m_window(window)
                {
                    HWND h = reinterpret_cast<HWND>(window->winId());

                    // disable all system gestures, most importantly, the hold-for-right-click gesture
                    GESTURECONFIG config;
                    config.dwID = 0;
                    config.dwWant = 0;
                    config.dwBlock = GC_ALLGESTURES;
                    SetGestureConfig(h, 0, 1, &config, sizeof(config));


                    // disable hold-for-right-click the ancient (tablet-pc way)
                    LPCTSTR tabletAtom = L"MicrosoftTabletPenServiceProperty";
                    ATOM atomID = GlobalAddAtomW(tabletAtom);
                    if (atomID)
                        SetPropW(h,  tabletAtom, reinterpret_cast<HANDLE>(1));

                    // register global hotkey
                    RegisterHotKey(h, 1, MOD_ALT | MOD_CONTROL | MOD_WIN, 'H');

                }
            protected:
                bool nativeEventFilter(const QByteArray &eventType, void *message, qintptr *result) override
                {
                    Q_UNUSED(eventType)
                    MSG *msg = static_cast<MSG *>(message);
                    if (msg) {
                        if (msg->message == WM_QUERYENDSESSION && msg->lParam == ENDSESSION_CLOSEAPP) {
                            // enable the installer to re-start the app after installation
                            QString cmdline = qApp->arguments().mid(1).join(' ');
                            auto restartOk = RegisterApplicationRestart(reinterpret_cast<const WCHAR *>(cmdline.utf16()), 0);
                            qWarning() << "RegisterApplicationRestart=" << restartOk << " -- cmdline:" << cmdline;
                            *result = 1;
                            return true;
                        } else if (msg->message == WM_HOTKEY && msg->wParam == 1) {
                            // handle global hot key
                            if (m_window->isVisible() && m_window->isActive()) {
                                m_window->close();
                            } else {
                                m_window->show();
                                m_window->raise();
                                m_window->requestActivate();
                            }
                            return true;
                        } else if (msg->message == WM_POWERBROADCAST && msg->wParam == PBT_APMRESUMEAUTOMATIC) {
                            QMetaObject::invokeMethod(HomeAssistant::instance(), &HomeAssistant::reconnect);
                            return true;
                        }
                    }
                    return false;
                }
            private:
                QQuickWindow *m_window;
            };
            app.installNativeEventFilter(new Win32Filter { window });
#endif
        }
    }
    return app.exec();
}
