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
    static void registerQmlTypes();

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
