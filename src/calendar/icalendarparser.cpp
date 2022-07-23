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
#include <QBuffer>
#include <QUrl>
#include <QDateTime>
#include <QDate>
#include <QTime>
#include <QTimeZone>
#include <QRegularExpression>
#include <QDebug>

#include "exception.h"
#include "icalendarparser.h"

//Q_DECLARE_METATYPE(QList<QTime>)
//Q_DECLARE_METATYPE(QList<QDate>)
//Q_DECLARE_METATYPE(QList<QDateTime>)


ICalendarParser::ICalendarParser(const QByteArray &data)
    : m_ownsDevice(true)
{
    QBuffer *b = new QBuffer();
    b->setData(data);
    b->open(QIODevice::ReadOnly);
    m_device = b;
}

ICalendarParser::ICalendarParser(QIODevice *device)
    : m_device(device)
    , m_ownsDevice(false)
{ }

ICalendarParser::~ICalendarParser()
{
    if (m_ownsDevice)
        delete m_device;
}

void ICalendarParser::parse()
{
    if (!m_device || !m_device->isOpen())
        throw createException("cannot read data from device or bytearray");

    m_result.clear();
    char lineBuffer[65536];

    while (!m_device->atEnd()) {
        qint64 lineLength = m_device->readLine(lineBuffer, sizeof(lineBuffer));

        if (lineLength < 0)
            throw createException("cannot read line");
        else if (lineLength == 0)
            continue;
        else if (lineBuffer[lineLength - 1] != '\n') // too long, give up
            throw createException("line too long");

        --lineLength; // remove '\n'
        if (lineLength > 0 && lineBuffer[lineLength - 1] == '\r')
            --lineLength; // remove '\r'

        // check for folding
        if (lineLength && (lineBuffer[0] == ' ' || lineBuffer[0] == '\t')) {
            if (!m_lineUTF8.isEmpty())
                m_lineUTF8.append(lineBuffer + 1, lineLength - 1); // minus leading space
        } else {
            // no more lines to unfold, parse the last line
            parseLine(m_lineUTF8);

            m_lineUTF8 = QByteArray(lineBuffer, lineLength);
        }
    }
    // parse the remainder line
    parseLine(m_lineUTF8);
}

QList<ICalendarParser::ContentLine> ICalendarParser::result() const
{
    return m_result;
}

void ICalendarParser::parseLine(const QByteArray &line)
{
    if (line.isEmpty())
        return;

    m_line = QString::fromUtf8(line);
    m_pos = 0;
    m_valueAsBase64 = false;

    try {
        parseName();
        parseParameters();
        parseValue();

        m_result << ContentLine { m_propertyName.toUpper(), m_parameters, m_propertyValue };
    } catch (const std::exception &e) {
        QByteArray cause = e.what();
        if (!cause.contains("0329T02")) // ignore warning for un-parseable DST start dates
            qDebug().noquote() << "Ignoring line:" << e.what();
    }

    m_propertyName.clear();
    m_parameters.clear();
    m_propertyValue.clear();
}

void ICalendarParser::parseName()
{
    for (; m_pos < m_line.length(); ++m_pos) {
        QChar c = m_line[m_pos];

        if (c.isLetterOrNumber() || c == '-')
            m_propertyName += c;
        else
            break;
    }
    if (m_propertyName.isEmpty())
        throw createException("invalid property name");

    //qWarning() << "PROPERTY NAME" << m_propertyName;
}


void ICalendarParser::parseParameters()
{
    // start of param
    while ((m_pos < m_line.length()) && m_line[m_pos] == ';') {
        ++m_pos;
        parseParameter();
    }
}

void ICalendarParser::parseParameter()
{
    parseParameterName();

    if ((m_pos >= m_line.length()) || m_line[m_pos] != '=')
        throw createException("parameter name doesn't end with '='");

    do {
        ++m_pos;
        parseParameterValue();
    } while ((m_pos < m_line.length()) && m_line[m_pos] == ',');


    auto param = qMakePair(m_parameterName.toUpper(), m_parameterValues);

    if (param.first == "ENCODING") {
        // handle this internally
        if (param.second.size() == 1 && param.second.first().toUpper() == "BASE64")
            m_valueAsBase64 = true;
    } else {
        m_parameters << param;
    }

    m_parameterName.clear();
    m_parameterValues.clear();
}

void ICalendarParser::parseParameterName()
{
    for (; m_pos < m_line.length(); ++m_pos) {
        QChar c = m_line[m_pos];

        if (c.isLetterOrNumber() || c == '-')
            m_parameterName += c;
        else
            break;
    }
    if (m_parameterName.isEmpty())
        throw createException("invalid parameter name");
    //qWarning() << " - PARAMETER NAME" << m_parameterName;
}

void ICalendarParser::parseParameterValue()
{
    if (m_pos >= m_line.length())
        return;
    m_parameterValueQuoted = (m_line[m_pos] == '"');
    if (m_parameterValueQuoted)
        ++m_pos;

    for (; m_pos < m_line.length(); ++m_pos) {
        QChar c = m_line[m_pos];

        bool quote = (c == '"');
        bool ok = (c >= ' ') || (c == '\t');
        if (!m_parameterValueQuoted) {
            ok = ok && !quote && (c != ',') && (c != ':') && (c != ';');
        } else if (quote) { // end of quote
            ok = false;
            ++m_pos;
        }

        if (ok)
            m_parameterValue += c;
        else
            break;
    }
    //qWarning() << " - PARAMETER VALUE" << m_parameterValue;
    m_parameterValues << m_parameterValue;
    m_parameterValue.clear();

}

QString ICalendarParser::firstParameterValue(const QString &parameterName)
{
    for (int i = 0; i < m_parameters.size(); ++i) {
        const auto &param = m_parameters.at(i);

        if (param.first == parameterName && !param.second.isEmpty())
            return param.second.first();
    }
    return QString();
}

void ICalendarParser::parseValue()
{
    if ((m_pos >= m_line.length()) || m_line[m_pos] != ':')
        throw createException("invalid property value");

    ++m_pos;
    const QString value = m_line.mid(m_pos, m_line.length() - m_pos);
    QString valueType = firstParameterValue("VALUE");
    QString tzId = firstParameterValue("TZID");

    if (valueType.isEmpty()) {
        static QHash<QString, QString> defaultTypes = {
            { "DTSTART", "DATE-TIME" },
            { "DTEND", "DATE-TIME" },
            { "DTSTAMP", "DATE-TIME" },
            { "RRULE", "RECUR" },
            { "RDATE", "DATE-TIME-LIST" },
            { "EXDATE", "DATE-TIME-LIST" }
        };
        valueType = defaultTypes.value(m_propertyName);
    }

    if (valueType == "BINARY") {
        if (!m_valueAsBase64)
            throw createException("binary value types require base64 encoding");
        m_propertyValue = QByteArray::fromBase64(value.toLatin1());
    } else if (valueType == "BOOLEAN") {
        if (value.toUpper() == "TRUE")
            m_propertyValue = true;
        else if (value.toUpper() == "FALSE")
            m_propertyValue = false;
        else
            throw createException("invalid value for boolean type");
    } else if (valueType == "DATE") {
        m_propertyValue = parseDate(value);
    } else if (valueType == "DATE-LIST") {
        m_propertyValue = QVariant::fromValue(parseDateList(value));
    } else if (valueType == "TIME") {
        QStringList timeStrings = value.split(',');
        QList<QDateTime> times;
        for (const QString &timeString : timeStrings) {
            auto dt = parseDateTime("00000000T" + timeString, tzId);
            if (!dt.isValid())
                throw createException("invalid time specification");
            times << dt;
        }
        if (times.size() == 1)
            m_propertyValue = times.first();
        else if (times.size() > 1)
            m_propertyValue = QVariant::fromValue(times);
        else
            throw createException("empty time specification");

    } else if (valueType == "DATE-TIME") {
        m_propertyValue = parseDateTime(value, tzId);
    } else if (valueType == "DATE-TIME-LIST") {
        m_propertyValue = QVariant::fromValue(parseDateTimeList(value, tzId));
    } else if (valueType == "FLOAT") {
        m_propertyValue = value.toFloat();
    } else if (valueType == "INTEGER") {
        m_propertyValue = value.toInt();
    } else if (valueType == "URI") {
        QUrl url = QUrl::fromUserInput(value);
        //if (!url.isValid())
        //    throw createException("invalid URI");
        m_propertyValue = url;
    } else if (valueType == "UTC-OFFSET") {
        QRegularExpression re("^[+-](\\d\\d)(\\d\\d)(\\d\\d)?$");
        auto match = re.match(value);
        if (match.hasMatch()) {
            int hh = match.captured(1).toInt();
            int mm = match.captured(2).toInt();
            int ss = match.capturedLength() < 3 ? 0
                                                : match.captured(3).toInt();

            int offsetSec = ss + 60 * mm + 60 * 60 * hh;
            if (value[0] == '-')
                offsetSec = -offsetSec;

            if (hh > 12 || mm >= 60 || ss >= 60 || offsetSec == 0)
                throw createException("invalid UTC-OFFSET values");

            m_propertyValue = offsetSec;
        } else {
            throw createException("invalid UTC-OFFSET");
        }
    } else if (valueType == "RECUR") {
        m_propertyValue.setValue(parseRecurrence(value, tzId));
    } else {
        m_propertyValue = value;
    }

    //qWarning() << "PARAMETER VALUE" << m_propertyValue.toString();

    // UNHANDLED:
                     // "DURATION" -- comma speparated -> QList<int>
//    WEEK: xW
//    DAY:  xD || xD TIME
//    TIME: HOUR || MIN || SEC
//    HOUR: xH || xH MIN
//    MIN:  xM || xM SEC
//    SEC:  xS

                     // "PERIOD"
    // "RECUR"
}

QDate ICalendarParser::parseDate(const QString &dateString)
{
    auto d = QDate::fromString(dateString, "yyyyMMdd");
    if (!d.isValid())
        throw createException("invalid date specification");
    return d;
}

QList<QDate> ICalendarParser::parseDateList(const QString &dateString)
{
    QStringList dateStrings = dateString.split(',');
    QList<QDate> dates;
    for (const QString &dateString : dateStrings)
        dates << parseDate(dateString);
    if (dates.isEmpty())
        throw createException("empty date specification");
    return dates;
}

QDateTime ICalendarParser::parseDateTime(const QString &dtString, const QString &tzId)
{
    // please note: the returned QDateTime could be invalid when interpreted in the wrong (read:
    // by default, the local) timezone. Only the upper layers have all the information to convert
    // the value to the correct timezone.

    QTimeZone tz;
    if (!tzId.isEmpty()) {
        tz = QTimeZone(tzId.toLatin1());
        if (!tz.isValid()) {
            QByteArray winTzId = QTimeZone::windowsIdToDefaultIanaId(tzId.toLatin1());
            if (!winTzId.isEmpty())
                tz = QTimeZone(winTzId);
        }
        if (!tz.isValid())
            throw createException("unknown timezone");
    }

    QDateTime dt;
    if (dtString.endsWith("Z")) {
        if (tz.isValid())
            throw createException("cannot have TZID and 'Z' UTC designator at the same time");

        dt = QDateTime::fromString(dtString, "yyyyMMdd'T'HHmmss'Z'");
        dt.setTimeSpec(Qt::UTC);
    } else {
        dt = QDateTime::fromString(dtString, "yyyyMMdd'T'HHmmss");
        if (tz.isValid()) {
            //dt.setTimeSpec(Qt::TimeZone);
            dt.setTimeZone(tz);
        }
    }
    if (!dt.isValid()) {
        // let's see if it was a parse error, or if we are just in the wrong time zone
        dt.setTimeSpec(Qt::UTC);
        if (!dt.isValid()) {
            // try to parse it as a date instead:
            try {
                dt = QDateTime(parseDate(dtString), QTime(0, 0));
            } catch (...) {
                throw createException("invalid date-time specification");
            }
        }
    }
    //qDebug() << "Parse DateTime:" << dtString << "in TZ:" << tzId << "yields:" << dt;
    return dt;
}

QList<QDateTime> ICalendarParser::parseDateTimeList(const QString &dateTimeString, const QString &tzId)
{
    QStringList dateTimeStrings = dateTimeString.split(',');
    QList<QDateTime> dateTimes;
    for (const QString &dateTimeString : dateTimeStrings)
        dateTimes << parseDateTime(dateTimeString, tzId);
    if (dateTimes.isEmpty())
        throw createException("empty date-time specification");
    return dateTimes;
}

ICalendarRecurrence ICalendarParser::parseRecurrence(const QString &value, const QString &tzId)
{
    ICalendarRecurrence rrule;

    bool hasCount = false;
    bool hasUntil = false;
    bool hasInterval = false;
    QStringList parts = value.split(';');
    for (const auto &part : parts) {
        int pos = part.indexOf('=');
        if (pos > 0) {
            const QString name = part.left(pos);
            const QString val = part.mid(pos + 1);

            if (name == "FREQ") {
                static QHash<QString, int> intervals = {
                    { "SECONDLY", 1 },
                    { "MINUTELY", 60 },
                    { "HOURLY", 60*60 },
                    { "DAILY", 60*60*24 },
                    { "WEEKLY", 60*60*24*7 },
                    { "MONTHLY", -1 },
                    { "YEARLY", -12 },
                };
                rrule.m_frequency = intervals.value(val);
            } else if (name == "INTERVAL") {
                rrule.m_interval = val.toInt();
                hasInterval = true;
            } else if (name == "COUNT") {
                rrule.m_count = val.toInt();
                hasCount = true;
            } else if (name == "UNTIL") {
                rrule.m_until = parseDateTime(val, tzId);
                hasUntil = true;
            }
        }
    }
    if (!rrule.m_frequency || (hasCount && hasUntil)
            || (hasCount && (rrule.m_count <= 0))
            || (hasInterval && (rrule.m_interval <= 0))
            || (hasUntil && !rrule.m_until.isValid())) {
        throw createException("invalid recurrence definition");
    }
    return rrule;
}

Exception ICalendarParser::createException(const char *message) const
{
    QString msg = "Error while parsing:\n" + m_line + "\n";
    msg.append(QString(m_pos, ' '));
    msg.append("^\n");
    msg.append(message);

    return Exception(msg);
}

QDebug &operator<<(QDebug &dbg, const ICalendarRecurrence &recurrence)
{
    QDebugStateSaver save(dbg);
    dbg.nospace();

    int f = recurrence.m_frequency;
    dbg << (f ? "[Recurrence" : "[No recurrence]");
    if (f) {
        dbg << ", frequency: " << (f < 0 ? -f : f) << (f < 0 ? " [months]" : " [sec]");
        if (recurrence.m_count)
            dbg << ", count: " << recurrence.m_count;
        if (recurrence.m_interval)
            dbg << ", interval: " << recurrence.m_interval;
        if (recurrence.m_until.isValid())
            dbg << ", until: " << recurrence.m_until;
        dbg << "]";
    }
    return dbg;
}
