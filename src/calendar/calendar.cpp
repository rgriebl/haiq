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
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QDebug>
#include <qqml.h>
#include <QtConcurrent/QtConcurrent>

#include "calendar.h"
#include "exception.h"
#include "icalendarparser.h"


enum Role {
    StartDateTime = Qt::UserRole + 1,
    EndDateTime,
    Summary,
    Duration,
    AllDay,
    SameDay
};


Calendar::Calendar(const QUrl &url, QObject *parent)
    : QAbstractListModel(parent)
    , m_url(url)
    , m_nam(new QNetworkAccessManager(this))
{
    m_disabled = m_url.isEmpty() || !m_url.isValid();
    if (m_disabled)
        qWarning() << "Calendar is disabled due to missing configuration";

    connect(m_nam, &QNetworkAccessManager::finished, this, &Calendar::handleNetworkReply);

    connect(&m_parserWatcher, &QFutureWatcher<QVector<Entry>>::finished, this, [this]() {
        m_entries = m_parserWatcher.result();
        endResetModel();
        m_isLoading = false;
        emit isLoadingChanged(m_isLoading);
    });

    connect(this, &QAbstractItemModel::modelReset, this, &Calendar::countChanged);
    connect(this, &QAbstractItemModel::rowsInserted, this, &Calendar::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &Calendar::countChanged);
}

int Calendar::rowCount(const QModelIndex &parent) const
{
    return parent.isValid() ? 0 : m_entries.size();
}

QVariant Calendar::data(const QModelIndex &index, int role) const
{
    if (index.parent().isValid() || !index.isValid() || index.row() < 0 || index.row() >= m_entries.size())
        return QVariant();

    const Entry &entry = m_entries.at(index.row());

    switch (role) {
    case StartDateTime:
        return entry.m_start;
    case EndDateTime:
        return entry.m_end;
    case Summary:
        return entry.m_summary;
    case Duration:
        return entry.m_duration;
    case AllDay:
        return entry.m_allDay;
    case SameDay:
        return entry.m_sameDay;
    }
    return QVariant();
}

QHash<int, QByteArray> Calendar::roleNames() const
{
    static QHash<int, QByteArray> roleNames = {
        { StartDateTime, "startDateTime" },
        { EndDateTime, "endDateTime" },
        { Summary, "summary" },
        { Duration, "duration" },
        { AllDay, "allDay" },
        { SameDay, "sameDay" }
    };
    return roleNames;
}

bool Calendar::isLoading() const
{
    return m_isLoading;
}

int Calendar::count() const
{
    return rowCount();
}

void Calendar::reload()
{
    load();
}

QVariantMap Calendar::get(int row) const
{
    QVariantMap map;
    if (row >= 0 && row < rowCount()) {
        const auto roles = roleNames();
        for (auto it = roles.begin(); it != roles.end(); ++it)
            map.insert(QLatin1String(it.value()), data(index(row), it.key()));
    }
    return map;
}


void Calendar::load()
{
    if (m_isLoading || m_disabled)
        return;

    QNetworkRequest request(m_url);

    if (!m_lastETag.isEmpty())
        request.setHeader(QNetworkRequest::IfNoneMatchHeader, m_lastETag);
    qDebug() << "Fetching calendar from" << m_url;
    auto *reply = m_nam->get(request);

    m_isLoading = (reply);
    if (m_isLoading)
        emit isLoadingChanged(m_isLoading);
}

// run via QtConcurrent in separate thread
QVector<Calendar::Entry> Calendar::parseNetworkReply(const QByteArray &data)
{
    ICalendarParser p(data);

    QVector<Entry> entries;

    try {
        p.parse();
        auto result = p.result();

        bool parsingEntry = false;
        Entry current;
        ICalendarRecurrence recurrenceRules;
        QList<QDateTime> recurrenceDates;
        QList<QDateTime> recurrenceExceptionDates;


        for (const ICalendarParser::ContentLine &line : result) {
            if (line.name == "BEGIN" && line.value == "VEVENT" && !parsingEntry) {
                parsingEntry = true;
            } else if (line.name == "END" && line.value == "VEVENT" && parsingEntry) {
                parsingEntry = false;
                if (current.m_start.isValid()) {
                    QVector<QDateTime> startTimes = { current.m_start };
                    auto diffTime = current.m_start.secsTo(current.m_end);

                    for (const auto &recDate : recurrenceDates)
                        startTimes.append(recDate);

                    if (recurrenceRules.isValid()) {
                        int interval = qMax(1, recurrenceRules.m_interval);
                        int addSecs = 0;
                        int addMonths = 0;
                        if (recurrenceRules.m_frequency > 0) // seconds diff
                            addSecs = recurrenceRules.m_frequency * interval;
                        else // -months diff
                            addMonths = -recurrenceRules.m_frequency * interval;

                        constexpr int maxCount = 200; // safety!

                        bool untilValid = recurrenceRules.m_until.isValid();
                        QDateTime startTime = current.m_start;
                        int count = 0;

                        while (true) {
                            if (addSecs)
                                startTime = startTime.addSecs(addSecs);
                            else
                                startTime = startTime.addMonths(addMonths);

                            if (untilValid && (startTime >= recurrenceRules.m_until))
                                break;

                            ++count;
                            if (recurrenceRules.m_count && (count >= recurrenceRules.m_count))
                                break;
                            if (count >= maxCount)
                                break;

                            //                                qWarning() << "RECUR" << current.m_summary << current.m_start.toString(Qt::SystemLocaleShortDate)
                            //                                           << "ADD" << addSecs << addMonths << " --> " << startTime.toString(Qt::SystemLocaleShortDate);
                            startTimes.append(startTime);
                        }
                    }
                    for (const auto &excDate : recurrenceExceptionDates)
                        startTimes.removeAll(excDate);

                    for (const QDateTime &dt : startTimes) {
                        // Fix the DST offset. A meeting scheduled at 10:00 will be at that time,
                        // regardless of the current DST offset.

                        QTimeZone tz = current.m_start.timeZone();
                        int wasDSTOffset = tz.daylightTimeOffset(current.m_start);
                        int isDSTOffset = tz.daylightTimeOffset(dt);

                        QDateTime startTime = (isDSTOffset != wasDSTOffset)
                                ? dt.addSecs(wasDSTOffset - isDSTOffset) : dt;

                        //qWarning() << current.m_summary << dt << "timeZone" << tz << "isDST" << isDSTOffset << "wasDST" << wasDSTOffset << " -> " << startTime;

                        QDateTime endTime = startTime.addSecs(diffTime);
                        bool allDay = (startTime.time().hour() == 0 && startTime.time().minute() == 0)
                                && ((endTime.time().hour() == 0 && endTime.time().minute() == 0)
                                    || (endTime.time().hour() == 23 && endTime.time().minute() == 59));

                        bool sameDay = (startTime.date() == endTime.date());
                        entries << Entry { current.m_summary, startTime, endTime, diffTime, allDay, sameDay };
                    }
                    //                        if (recurrenceRules.isValid()) {
                    //                            qWarning() << current.m_summary << "from" << current.m_start.toString(Qt::SystemLocaleShortDate) << "to"
                    //                                       << current.m_end.toString(Qt::SystemLocaleShortDate) << "recur?" << recurrenceRules
                    //                                       << "except?" << recurrenceExceptionDates;
                    //                        }
                }
                current = Entry();
                recurrenceRules = ICalendarRecurrence();
                recurrenceDates.clear();
                recurrenceExceptionDates.clear();
            } else if (parsingEntry) {
                if (line.name == "DTSTART") {
                    current.m_start = line.value.toDateTime();
                } else if (line.name == "DTEND") {
                    current.m_end = line.value.toDateTime();
                } else if (line.name == "SUMMARY") {
                    current.m_summary = line.value.toString();
                } else if (line.name == "RRULE") {
                    recurrenceRules = line.value.value<ICalendarRecurrence>();
                } else if (line.name == "RDATA") {
                    recurrenceDates.append(line.value.value<QList<QDateTime>>());
                } else if (line.name == "EXDATA") {
                    recurrenceExceptionDates.append(line.value.value<QList<QDateTime>>());
                }
            }
        }
    } catch (const std::exception &e) {
        qWarning().noquote() << "iCalendar parse error:" << e.what();
        entries.clear();
    }
    return entries;
}

void Calendar::handleNetworkReply(QNetworkReply *reply)
{
    bool stillLoading = false;
    QString etag = reply->header(QNetworkRequest::ETagHeader).toString();
    bool etagValid = !etag.isEmpty();

    if (reply->error() != QNetworkReply::NoError) {
        qWarning() << "Failed to retrieve calendar from" << reply->url() << ":" << reply->errorString();
    } else if ((etagValid && (etag == m_lastETag)) || (reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt() == 304)) {
        qDebug() << "ETAG matches on" << (reply->operation() == QNetworkAccessManager::HeadOperation ? "HEAD" : "GET") << "operation -> no changes";
        ; // no changes
    } else if ((reply->operation() == QNetworkAccessManager::HeadOperation) && (etagValid && (etag != m_lastETag))) {
        qDebug() << "HEAD says we have new entries -> issue GET";
        m_nam->get(reply->request());
        stillLoading = true;
    } else {
        m_lastETag = etag;

#if QT_VERSION < QT_VERSION_CHECK(6, 0, 0)
        auto future = QtConcurrent::run(this, &Calendar::parseNetworkReply, reply->readAll());
#else
        auto future = QtConcurrent::run(&Calendar::parseNetworkReply, this, reply->readAll());
#endif
        m_parserWatcher.setFuture(future);
        reply->deleteLater();

        beginResetModel();
        m_entries.clear();
        stillLoading = true;
    }

    m_isLoading = stillLoading;
    if (!m_isLoading)
        emit isLoadingChanged(m_isLoading);
}

void UpcomingCalendarEntries::registerQmlTypes()
{
    qmlRegisterType<UpcomingCalendarEntries>("org.griebl.calendar", 1, 0, "UpcomingCalendarEntries");
}

UpcomingCalendarEntries::UpcomingCalendarEntries(QObject *parent)
    : QSortFilterProxyModel(parent)
    , m_from(QDate::currentDate(), QTime(0, 0))
    , m_to(m_from.addDays(60))
{
    sort(0);

    connect(this, &QAbstractItemModel::modelReset, this, &UpcomingCalendarEntries::countChanged);
    connect(this, &QAbstractItemModel::rowsInserted, this, &UpcomingCalendarEntries::countChanged);
    connect(this, &QAbstractItemModel::rowsRemoved, this, &UpcomingCalendarEntries::countChanged);
}

Calendar *UpcomingCalendarEntries::calendar() const
{
    return m_calendar;
}

QDateTime UpcomingCalendarEntries::from() const
{
    return m_from;
}

QDateTime UpcomingCalendarEntries::to() const
{
    return m_to;
}

QVariantMap UpcomingCalendarEntries::get(int row) const
{
    if (row < 0 || row >= rowCount())
        return {};
    return m_calendar->get(mapToSource(index(row, 0)).row());
}

void UpcomingCalendarEntries::setCalendar(Calendar *calendar)
{
    if (m_calendar != calendar) {
        m_calendar = calendar;
        setSourceModel(calendar);
        emit calendarChanged(m_calendar);
    }
}

void UpcomingCalendarEntries::setFrom(const QDateTime &from)
{
    if (m_from != from) {
        m_from = from;
        invalidateFilter();
        emit fromChanged(m_from);
    }
}

void UpcomingCalendarEntries::setTo(const QDateTime &to)
{
    if (m_to != to) {
        m_to = to;
        invalidateFilter();
        emit toChanged(m_to);
    }
}

bool UpcomingCalendarEntries::filterAcceptsRow(int row, const QModelIndex &parent) const
{
    if (parent.isValid())
        return false;

    const QDateTime &start = m_calendar->m_entries.at(row).m_start;
    const QDateTime &end = m_calendar->m_entries.at(row).m_end;

    return (end >= m_from) && (start <= m_to);
}

bool UpcomingCalendarEntries::lessThan(const QModelIndex &index1, const QModelIndex &index2) const
{
    const QDateTime &start1 = m_calendar->m_entries.at(index1.row()).m_start;
    const QDateTime &end1 = m_calendar->m_entries.at(index1.row()).m_end;
    const QDateTime &start2 = m_calendar->m_entries.at(index2.row()).m_start;
    const QDateTime &end2 = m_calendar->m_entries.at(index2.row()).m_end;

    return (start1 != start2) ? (start1 < start2) : (end1 > end2);
}

