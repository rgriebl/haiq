// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

#pragma once

#include <QAbstractListModel>
#include <QSortFilterProxyModel>
#include <QUrl>
#include <QDateTime>
#include <QFutureWatcher>

#include "icalendarparser.h"

QT_FORWARD_DECLARE_CLASS(QNetworkAccessManager)
QT_FORWARD_DECLARE_CLASS(QNetworkReply)
QT_FORWARD_DECLARE_CLASS(QTimer)
QT_FORWARD_DECLARE_CLASS(QTextStream)

class Calendar : public QAbstractListModel
{
    Q_OBJECT
    Q_PROPERTY(bool loading READ isLoading NOTIFY isLoadingChanged)
    Q_PROPERTY(int count READ count NOTIFY countChanged)

public:
    explicit Calendar(const QUrl &url, QObject *parent = nullptr);

    int rowCount(const QModelIndex &parent = QModelIndex()) const override;
    QVariant data(const QModelIndex &index, int role) const override;
    QHash<int, QByteArray> roleNames() const override;

    bool isLoading() const;
    int count() const;

    Q_INVOKABLE void reload();

    Q_INVOKABLE QVariantMap get(int row) const;

protected:
    void load();

signals:
    void isLoadingChanged(bool isLoading);
    void countChanged();

private:
    void handleNetworkReply(QNetworkReply *reply);

private:
    struct Entry
    {
        QString m_summary;
        QDateTime m_start;
        QDateTime m_end;

        qint64 m_duration = 0; // sec
        bool m_allDay = false;
        bool m_sameDay = false;
    };
    QVector<Entry> m_entries;
    QUrl m_url;
    QNetworkAccessManager *m_nam;
    bool m_isLoading = false;
    bool m_disabled = false;
    QString m_lastETag;

    QFutureWatcher<QVector<Entry>> m_parserWatcher;

    QVector<Entry> parseNetworkReply(const QByteArray &data);

    friend class UpcomingCalendarEntries;
};

class UpcomingCalendarEntries : public QSortFilterProxyModel
{
    Q_OBJECT
    Q_PROPERTY(Calendar *calendar READ calendar WRITE setCalendar NOTIFY calendarChanged)
    Q_PROPERTY(QDateTime from READ from WRITE setFrom NOTIFY fromChanged)
    Q_PROPERTY(QDateTime to READ to WRITE setTo NOTIFY toChanged)
    Q_PROPERTY(int count READ rowCount NOTIFY countChanged)

public:
    static void registerQmlTypes();

    UpcomingCalendarEntries(QObject *parent = nullptr);

    Calendar *calendar() const;
    QDateTime from() const;
    QDateTime to() const;

    Q_INVOKABLE QVariantMap get(int row) const;

public slots:
    void setCalendar(Calendar *calendar);
    void setFrom(const QDateTime &from);
    void setTo(const QDateTime &to);

signals:
    void calendarChanged(Calendar *calendar);
    void fromChanged(const QDateTime &from);
    void toChanged(const QDateTime &to);
    void countChanged();

protected:

    bool filterAcceptsRow(int row, const QModelIndex &parent) const override;
    bool lessThan(const QModelIndex &index1, const QModelIndex &index2) const override;

private:
    bool m_complete = false;
    Calendar *m_calendar = nullptr;
    QDateTime m_from;
    QDateTime m_to;
};
