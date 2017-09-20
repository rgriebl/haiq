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
#include <QByteArray>
#include <QList>
#include <QPair>
#include <QString>
#include <QStringList>
#include <QVariant>
#include <QDateTime>

#include "exception.h"

#pragma once

QT_FORWARD_DECLARE_CLASS(QIODevice)

class ICalendarRecurrence
{
public:
    bool isValid() const { return (m_frequency); }

    int m_frequency = 0;
    int m_count = 0;
    int m_interval = 1;
    QDateTime m_until;
};

Q_DECLARE_METATYPE(ICalendarRecurrence)
QDebug &operator<<(QDebug &dbg, const ICalendarRecurrence &recurrence);

class ICalendarParser
{
public:
    ICalendarParser(const QByteArray &data);
    ICalendarParser(QIODevice *device);
    ~ICalendarParser();

    void parse();

    struct ContentLine
    {
        QString name;
        QList<QPair<QString, QStringList>> parameters;
        QVariant value;
    };

    QList<ContentLine> result() const;

private:
    void parseLine(const QByteArray &line);
    void parseName();
    void parseParameters();
    void parseParameter();
    void parseParameterName();
    void parseParameterValue();
    void parseValue();

    QDate parseDate(const QString &dString);
    QList<QDate> parseDateList(const QString &dateString);
    QDateTime parseDateTime(const QString &dtString, const QString &tzId);
    QList<QDateTime> parseDateTimeList(const QString &dateTimeString, const QString &tzId);
    QString firstParameterValue(const QString &parameterName);
    ICalendarRecurrence parseRecurrence(const QString &value, const QString &tzId);

    Exception createException(const char *message) const;

    QIODevice *m_device;
    bool m_ownsDevice;
    QByteArray m_lineUTF8;

    QString m_line;
    int m_pos;
    QString m_propertyName;
    QVariant m_propertyValue;
    QList<QPair<QString, QStringList>> m_parameters;
    QString m_parameterName;
    QString m_parameterValue;
    QStringList m_parameterValues;
    bool m_parameterValueQuoted;
    bool m_valueAsBase64;

    QList<ContentLine> m_result;
};
