// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

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
        QChar c = m_line.at(m_pos);

        if (c.isLetterOrNumber() || c == u'-')
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
    while ((m_pos < m_line.length()) && m_line[m_pos] == u';') {
        ++m_pos;
        parseParameter();
    }
}

void ICalendarParser::parseParameter()
{
    parseParameterName();

    if ((m_pos >= m_line.length()) || m_line[m_pos] != u'=')
        throw createException("parameter name doesn't end with '='");

    do {
        ++m_pos;
        parseParameterValue();
    } while ((m_pos < m_line.length()) && m_line[m_pos] == u',');


    auto param = qMakePair(m_parameterName.toUpper(), m_parameterValues);

    if (param.first == u"ENCODING") {
        // handle this internally
        if (param.second.size() == 1 && param.second.first().toUpper() == u"BASE64")
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
        QChar c = m_line.at(m_pos);

        if (c.isLetterOrNumber() || c == u'-')
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
    m_parameterValueQuoted = (m_line[m_pos] == u'"');
    if (m_parameterValueQuoted)
        ++m_pos;

    for (; m_pos < m_line.length(); ++m_pos) {
        QChar c = m_line.at(m_pos);

        bool quote = (c == u'"');
        bool ok = (c >= u' ') || (c == u'\t');
        if (!m_parameterValueQuoted) {
            ok = ok && !quote && (c != u',') && (c != u':') && (c != u';');
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
    if ((m_pos >= m_line.length()) || m_line[m_pos] != u':')
        throw createException("invalid property value");

    ++m_pos;
    const QString value = m_line.mid(m_pos, m_line.length() - m_pos);
    QString valueType = firstParameterValue(u"VALUE"_qs);
    QString tzId = firstParameterValue(u"TZID"_qs);

    if (valueType.isEmpty()) {
        static QHash<QString, QString> defaultTypes = {
            { u"DTSTART"_qs, u"DATE-TIME"_qs },
            { u"DTEND"_qs,   u"DATE-TIME"_qs },
            { u"DTSTAMP"_qs, u"DATE-TIME"_qs },
            { u"RRULE"_qs,   u"RECUR"_qs },
            { u"RDATE"_qs,   u"DATE-TIME-LIST"_qs },
            { u"EXDATE"_qs,  u"DATE-TIME-LIST"_qs }
        };
        valueType = defaultTypes.value(m_propertyName);
    }

    if (valueType == u"BINARY") {
        if (!m_valueAsBase64)
            throw createException("binary value types require base64 encoding");
        m_propertyValue = QByteArray::fromBase64(value.toLatin1());
    } else if (valueType == u"BOOLEAN") {
        if (value.toUpper() == u"TRUE")
            m_propertyValue = true;
        else if (value.toUpper() == u"FALSE")
            m_propertyValue = false;
        else
            throw createException("invalid value for boolean type");
    } else if (valueType == u"DATE") {
        m_propertyValue = parseDate(value);
    } else if (valueType == u"DATE-LIST") {
        m_propertyValue = QVariant::fromValue(parseDateList(value));
    } else if (valueType == u"TIME") {
        QStringList timeStrings = value.split(u',');
        QList<QDateTime> times;
        times.reserve(timeStrings.size());
        for (const QString &timeString : timeStrings) {
            auto dt = parseDateTime(u"00000000T" + timeString, tzId);
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

    } else if (valueType == u"DATE-TIME") {
        m_propertyValue = parseDateTime(value, tzId);
    } else if (valueType == u"DATE-TIME-LIST") {
        m_propertyValue = QVariant::fromValue(parseDateTimeList(value, tzId));
    } else if (valueType == u"FLOAT") {
        m_propertyValue = value.toFloat();
    } else if (valueType == u"INTEGER") {
        m_propertyValue = value.toInt();
    } else if (valueType == u"URI") {
        QUrl url = QUrl::fromUserInput(value);
        //if (!url.isValid())
        //    throw createException("invalid URI");
        m_propertyValue = url;
    } else if (valueType == u"UTC-OFFSET") {
        static const QRegularExpression re(u"^[+-](\\d\\d)(\\d\\d)(\\d\\d)?$"_qs);
        auto match = re.match(value);
        if (match.hasMatch()) {
            int hh = match.captured(1).toInt();
            int mm = match.captured(2).toInt();
            int ss = match.capturedLength() < 3 ? 0
                                                : match.captured(3).toInt();

            int offsetSec = ss + 60 * mm + 60 * 60 * hh;
            if (value[0] == u'-')
                offsetSec = -offsetSec;

            if (hh > 12 || mm >= 60 || ss >= 60 || offsetSec == 0)
                throw createException("invalid UTC-OFFSET values");

            m_propertyValue = offsetSec;
        } else {
            throw createException("invalid UTC-OFFSET");
        }
    } else if (valueType == u"RECUR") {
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
    auto d = QDate::fromString(dateString, u"yyyyMMdd"_qs);
    if (!d.isValid())
        throw createException("invalid date specification");
    return d;
}

QList<QDate> ICalendarParser::parseDateList(const QString &dateString)
{
    QStringList dateStrings = dateString.split(u',');
    QList<QDate> dates;
    dates.reserve(dateStrings.size());
    for (const QString &ds : dateStrings)
        dates << parseDate(ds);
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
        if (!tz.isValid() && tzId.startsWith(u"(UTC")) {
            static const QRegularExpression re(u"^\\(UTC([+-])(\\d\\d):(\\d\\d)\\)$"_qs);
            auto match = re.match(tzId.left(11));
            if (match.hasMatch()) {
                int sign = (match.captured(1) == u"+") ? 1 : -1;
                int hh = match.captured(2).toInt();
                int mm = match.captured(3).toInt();
                tz = QTimeZone(sign * 60 * (hh * 60 + mm));
            }
        }
        if (!tz.isValid())
            throw createException("unknown timezone");
    }

    QDateTime dt;
    if (dtString.endsWith(u"Z")) {
        if (tz.isValid())
            throw createException("cannot have TZID and 'Z' UTC designator at the same time");

        dt = QDateTime::fromString(dtString, u"yyyyMMdd'T'HHmmss'Z'"_qs);
        dt.setTimeSpec(Qt::UTC);
    } else {
        dt = QDateTime::fromString(dtString, u"yyyyMMdd'T'HHmmss"_qs);
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
    QStringList dateTimeStrings = dateTimeString.split(u',');
    QList<QDateTime> dateTimes;
    dateTimes.reserve(dateTimeStrings.size());
    for (const QString &dts : dateTimeStrings)
        dateTimes << parseDateTime(dts, tzId);
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
    QStringList parts = value.split(u';');
    for (const auto &part : parts) {
        auto pos = part.indexOf(u'=');
        if (pos > 0) {
            const QString name = part.left(pos);
            const QString val = part.mid(pos + 1);

            if (name == u"FREQ") {
                static QHash<QString, int> intervals = {
                    { u"SECONDLY"_qs, 1 },
                    { u"MINUTELY"_qs, 60 },
                    { u"HOURLY"_qs,   60*60 },
                    { u"DAILY"_qs,    60*60*24 },
                    { u"WEEKLY"_qs,   60*60*24*7 },
                    { u"MONTHLY"_qs,  -1 },
                    { u"YEARLY"_qs,   -12 },
                };
                rrule.m_frequency = intervals.value(val);
            } else if (name == u"INTERVAL") {
                rrule.m_interval = val.toInt();
                hasInterval = true;
            } else if (name == u"COUNT") {
                rrule.m_count = val.toInt();
                hasCount = true;
            } else if (name == u"UNTIL") {
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
    QString msg = u"Error while parsing:\n"_qs + m_line + u"\n"_qs;
    msg.append(QString(m_pos, u' '));
    msg.append(u"^\n"_qs);
    msg.append(QString::fromLatin1(message));

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
