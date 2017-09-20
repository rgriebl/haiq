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

#include <QCoreApplication>
#include <QStringBuilder>
#include <QPasswordDigestor>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QTimer>
#include <QQmlEngine>
#include <QDebug>

#include "xbrowsersync.h"
#include "lzutf8.h"
#include "gcm.h"


XBrowserSync *XBrowserSync::s_instance = nullptr;

void XBrowserSync::registerQmlTypes()
{
    qmlRegisterSingletonType<XBrowserSync>("org.griebl.xbrowsersync", 1, 0, "XBrowserSync",
                                           [](QQmlEngine *, QJSEngine *) -> QObject * {
        QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
        return instance();
    });
}

XBrowserSync *XBrowserSync::instance()
{
    return s_instance;
}

XBrowserSync *XBrowserSync::createInstance(const QUrl &syncUrl, const QString &syncId,
                                           const QString &password, QObject *parent)
{
    if (Q_UNLIKELY(s_instance))
        qFatal("XBrowserSync::createInstance() was called a second time.");

    s_instance = new XBrowserSync(syncUrl, syncId, password, parent);
    QMetaObject::invokeMethod(s_instance, &XBrowserSync::sync);

    return s_instance;
}

QVariantList XBrowserSync::bookmarks() const
{
    return m_bookmarks;
}

XBrowserSync::XBrowserSync(const QUrl &syncUrl, const QString &syncId,
                           const QString &password, QObject *parent)
    : QObject(parent)
    , m_disabled(syncUrl.isEmpty())
    , m_syncUrl(syncUrl)
    , m_syncId(syncId)
    , m_nam(new QNetworkAccessManager(this))
    , m_refreshTimer(new QTimer(this))
{
    if (m_disabled)
        qWarning() << "XBrowserSync is disabled due to missing configuration";

    m_syncKey = QPasswordDigestor::deriveKeyPbkdf2(QCryptographicHash::Sha256,
                                                   password.toLatin1(), syncId.toLatin1(), 250000, 32);

    connect(m_refreshTimer, &QTimer::timeout, this, &XBrowserSync::sync);
    m_refreshTimer->start(1 * 60 * 1000); // 30min
}

void XBrowserSync::sync()
{
    if (m_disabled || (m_syncing != NotSyncing))
        return;
    m_syncing = SyncingTime;

    if (m_lastSync.isValid()) {
        QUrl url = m_syncUrl;
        url.setPath(url.path() % QLatin1String("/bookmarks/") % m_syncId % QLatin1String("/lastUpdated"));
        auto reply = m_nam->get(QNetworkRequest(url));

        QObject::connect(reply, &QNetworkReply::finished, this, [this, reply]() {
            if (reply->error() == QNetworkReply::NoError) {
                auto jsonReply = QJsonDocument::fromJson(reply->readAll());
                if (!jsonReply.isNull()) {
                    auto syncTime = QDateTime::fromString(jsonReply.object().value("lastUpdated").toString(),
                                                          Qt::ISODateWithMs);

                    if (syncTime > m_lastSync) {
                        m_syncing = SyncingBookmarks;
                        syncBookmarks();
                    }
                } else {
                    qWarning() << "XBrowserSync: failed to parse JSON reply to lastUpdated request";
                    m_syncing = NotSyncing;
                }
            } else {
                qWarning() << "XBrowserSync: failed to retrieve lastUpdated request:" << reply->errorString();
                m_syncing = NotSyncing;
            }
            reply->deleteLater();
        });
    } else {
        m_syncing = SyncingBookmarks;
        syncBookmarks();
    }
}

void XBrowserSync::syncBookmarks()
{
    if (m_disabled || (m_syncing != SyncingBookmarks))
        return;

    QUrl url = m_syncUrl;
    url.setPath(url.path() % QLatin1String("/bookmarks/") % m_syncId);

    auto reply = m_nam->get(QNetworkRequest(url));

    QObject::connect(reply, &QNetworkReply::finished, this, [this, reply]() {
        if (reply->error() == QNetworkReply::NoError) {
            auto jsonReply = QJsonDocument::fromJson(reply->readAll());
            if (!jsonReply.isNull()) {
                auto syncTime = QDateTime::fromString(jsonReply.object().value("lastUpdated").toString(),
                                                      Qt::ISODateWithMs);
                auto bookmarks = QByteArray::fromBase64(jsonReply.object().value("bookmarks").toString().toLatin1());

                if (parseBookmarks(bookmarks))
                    m_lastSync = syncTime;
            } else {
                qWarning() << "XBrowserSync: failed to parse JSON reply to bookmarks request";
            }
        } else {
            qWarning() << "XBrowserSync: failed to retrieve bookmarks request:" << reply->errorString();
        }
        m_syncing = NotSyncing;
        reply->deleteLater();
    });
}

bool XBrowserSync::parseBookmarks(const QByteArray &encoded)
{
    // Step 1: extract AES info from "bookmarks"

    // inner layer: [16 bytes IV] [AES-GCM-256 encrypted data] [16 bytes GCM tag]
    QByteArray iv = encoded.left(16);
    QByteArray tag = encoded.right(16);
    QByteArray in = encoded.mid(16, encoded.length() - 32);
    QByteArray out;
    out.resize(in.size());

    // Step 2: decrypt AES

    aes_init_keygen_tables();
    gcm_context ctx;            // includes the AES context structure
    int result = gcm_setkey(&ctx, (const uchar *) m_syncKey.constData(), m_syncKey.size());
    if (result != 0) {
        qWarning() << "Failed to setup AES GCM";
        return false;
    }

    result = gcm_auth_decrypt(&ctx,
                              (const uchar *) iv.constData(), iv.size(),
                              nullptr, 0,
                              (const uchar *) in.constData(), (uchar *) out.data(), in.size(),
                              (const uchar *) tag.constData(), tag.size());
    if (result != 0) {
        qWarning() << "Failed to decrypt";
        return false;
    }

    // Step 3: uncompress LZUTF8

    QByteArray utf8 = LZUTF8::decompress(out);
    if (utf8.isEmpty()) {
        qWarning() << "Failed to uncompress LZUTF8";
        return false;
    }

    // Step 4: parse inner JSON

    auto bookmarks = QJsonDocument::fromJson(utf8);
    if (bookmarks.isNull()) {
        qWarning() << "Could not parse bookmarks";
        return false;
    }
    //qWarning().noquote() << bookmarks.toJson(QJsonDocument::Indented);

    // Step 5: parse the actual bookmarks JSON data

    QVariantList newBookmarks = bookmarks.array().toVariantList(); // parseBookmarksFromJSON(bookmarks.array());

    // Step 6: check if anything changed (shouldn't be needed, but better safe than sorry)

    if (newBookmarks != m_bookmarks) {
        m_bookmarks = newBookmarks;
        qWarning() << "TL bookmarks:" << m_bookmarks.size();
        emit bookmarksChanged();
    }
    return true;
}

