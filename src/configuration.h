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

#include <QString>
#include <QStringList>
#include <QVariantMap>

class Configuration
{
public:
    Configuration(const QString &configFile, const QString &variant);

    void parse();
    const QStringList &possibleVariants() const;
    const QVariantMap &asMap() const;

    QVariant operator[](const char *key) const;

private:
    QString m_configFile;
    QString m_variant;
    QStringList m_possibleVariants;
    QVariantMap m_map;
    bool m_parsed = false;

    static void recursiveMergeVariantMap(QVariantMap &into, const QVariantMap &from);
};

