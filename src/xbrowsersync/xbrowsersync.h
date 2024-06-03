// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

#pragma once

#include <QObject>
#include <QUrl>
#include <QDateTime>
#include <QJsonArray>

QT_FORWARD_DECLARE_CLASS(QNetworkAccessManager)
QT_FORWARD_DECLARE_CLASS(QTimer)


class XBrowserSync : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QVariantList bookmarks READ bookmarks NOTIFY bookmarksChanged)

public:
    static XBrowserSync *instance();
    static XBrowserSync *createInstance(const QUrl &syncUrl, const QString &syncId,
                                        const QString &password, QObject *parent = nullptr);

    QVariantList bookmarks() const;

signals:
    void bookmarksChanged();

private:
    explicit XBrowserSync(const QUrl &syncUrl, const QString &syncId, const QString &password,
                          QObject *parent = nullptr);

    void sync();
    void syncBookmarks();
    bool parseBookmarks(const QByteArray &encoded);

    static XBrowserSync *s_instance;

    bool m_disabled = false;
    enum SyncingState {
        NotSyncing,
        SyncingTime,
        SyncingBookmarks,
    };
    SyncingState m_syncing = NotSyncing;
    QUrl m_syncUrl;
    QString m_syncId;
    QDateTime m_lastSync;
    QByteArray m_syncKey;
    QVariantList m_bookmarks;
    QNetworkAccessManager *m_nam;
    QTimer *m_refreshTimer;
};
