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
#pragma once

#include <QObject>
#include <QVariantMap>

QT_FORWARD_DECLARE_CLASS(QProcess)


class AppStarter : public QObject
{
    Q_OBJECT

public:
    ~AppStarter() override;

    static void registerQmlTypes();

    static AppStarter *instance();
    static AppStarter *createInstance(QObject *parent = nullptr);

    Q_INVOKABLE void addApp(const QStringList &commandLine, const QVariantMap &env = { });

private:
    static AppStarter *s_instance;

    explicit AppStarter(QObject *parent = nullptr);

    QVector<QProcess *> m_apps;
};
