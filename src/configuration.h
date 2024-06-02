// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

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

