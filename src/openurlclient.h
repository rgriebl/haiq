// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

#pragma once

#include <QObject>

class OpenUrlClient : public QObject
{
    Q_OBJECT

public:
    static OpenUrlClient *instance();

signals:
    void commandReceived(const QString &command, const QStringList &paramters);

private:
    explicit OpenUrlClient(QObject *parent = nullptr);
    static OpenUrlClient *s_instance;
};
