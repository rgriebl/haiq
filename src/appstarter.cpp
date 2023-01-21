/* Copyright (C) 2017-2022 Robert Griebl. All rights reserved.
**
** This file is part of HAiQ.
**
** This file may be distributed and/or modified under the terms of the GNU
** General Public License version 2 as published by the Free Software Foundation
** and appearing in the file LICENSE.GPL included in the packaging of this file.
**
** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
**
** See http://fsf.org/licensing/licenses/gpl.html for GPL licensing information.
*/
#include <QProcess>
#include <QCoreApplication>
#include <QStringBuilder>
#include <QDebug>
#include <QQmlEngine>
#include <QTimer>

#include "appstarter.h"

#define qSL(x) QStringLiteral(x)
#define qL1S(x) QLatin1String(x)


AppStarter *AppStarter::s_instance = nullptr;

AppStarter *AppStarter::instance()
{
    return s_instance;
}

AppStarter *AppStarter::createInstance(QObject *parent)
{
    if (Q_UNLIKELY(s_instance))
        qFatal("AppStarter::createInstance() was called a second time.");

    s_instance = new AppStarter(parent);

    return s_instance;
}

void AppStarter::registerQmlTypes()
{
    qmlRegisterSingletonType<AppStarter>("org.griebl.haiq", 1, 0, "AppStarter",
                                           [](QQmlEngine *, QJSEngine *) -> QObject * {
        QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
        return instance();
    });
}

AppStarter::AppStarter(QObject *parent)
    : QObject(parent)
{ }


AppStarter::~AppStarter()
{
    for (QProcess *p : m_apps) {
        p->terminate();
        delete p;
    }
    m_apps.clear();
}

void AppStarter::addApp(const QStringList &commandLine, const QVariantMap &env)
{
    auto *p = new QProcess(this);
    p->setProgram(commandLine.value(0));
    p->setArguments(commandLine.mid(1));
    p->setProcessChannelMode(QProcess::ForwardedChannels);

    QProcessEnvironment penv = QProcessEnvironment::systemEnvironment();
    for (auto it = env.cbegin(); it != env.cend(); ++it)
        penv.insert(it.key(), it.value().toString());
    p->setProcessEnvironment(penv);

    connect(p, &QProcess::finished,
            this, [this, p](int code, QProcess::ExitStatus status) {
        qWarning() << "App" << p->program() << "exited with code" << code << "and status" << status;
        QTimer::singleShot(2000, this, [p]() {
            qWarning() << "Restarting app" << p->program() << "after 2sec timeout";
            p->start();
        });
    });

    connect(p, &QProcess::errorOccurred,
            this, [p](QProcess::ProcessError error) {
        qWarning() << "App" << p->program() << "failed with error" << error;
    });

    p->start();
    m_apps.append(p);
}
