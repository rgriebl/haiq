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

#include <QNetworkAccessManager>
#include <QAbstractListModel>
#include <QSortFilterProxyModel>
#include <QObject>
#include <QJSValue>
#include <QPointer>
#include <QTcpSocket>
#include <QQueue>
#include <QDateTime>
#include <QTimer>

#include <functional>
#include <optional>

QT_FORWARD_DECLARE_CLASS(QQmlEngine)


using StringMap = QMap<QString, QString>;

class SqueezeBoxPlayer;

class SqueezeBoxAlarm : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString playerId READ playerId CONSTANT)
    Q_PROPERTY(QString alarmId READ alarmId CONSTANT)
    Q_PROPERTY(bool enabled READ enabled WRITE setEnabled NOTIFY enabledChanged)
    Q_PROPERTY(bool repeat READ repeat WRITE setRepeat NOTIFY repeatChanged)
    Q_PROPERTY(int time READ time WRITE setTime NOTIFY timeChanged)
    Q_PROPERTY(QVariantList dayOfWeek READ dayOfWeek WRITE setDayOfWeek NOTIFY dayOfWeekChanged)
    Q_PROPERTY(QString dayOfWeekString READ dayOfWeekString NOTIFY dayOfWeekChanged STORED false)
    Q_PROPERTY(qreal volume READ volume WRITE setVolume NOTIFY volumeChanged)
    Q_PROPERTY(QUrl url READ url WRITE setUrl NOTIFY urlChanged)

public:
    QString playerId() const;
    QString alarmId() const;
    bool enabled() const;
    bool repeat() const;
    int time() const;
    QVariantList dayOfWeek() const;
    QString dayOfWeekString() const;
    qreal volume() const;
    QUrl url() const;

    static QString dayOfWeekListToString(const QVariantList &vl);
    static QVariantList dayOfWeekListFromString(const QString &s);

public slots:
    void setEnabled(bool enabled);
    void setRepeat(bool repeat);
    void setTime(int time);
    void setDayOfWeek(const QVariantList &dayOfWeek);
    void setVolume(qreal volume);
    void setUrl(const QUrl &url);

signals:
    void enabledChanged(bool enabled);
    void repeatChanged(bool repeat);
    void timeChanged(int time);
    void dayOfWeekChanged(const QVariantList &dayOfWeek);
    void volumeChanged(qreal volume);
    void urlChanged(const QUrl &url);

private:
    SqueezeBoxAlarm(SqueezeBoxPlayer *player);

    QPointer<SqueezeBoxPlayer> m_player;
    QString m_alarmId;
    bool m_enabled;
    bool m_repeat;
    int m_time;
    QVariantList m_dayOfWeek;
    qreal m_volume;
    QUrl m_url;

    Q_DISABLE_COPY(SqueezeBoxAlarm)
    friend class SqueezeBoxServer;
};

class SqueezeBoxPlayer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString playerId READ playerId CONSTANT)
    Q_PROPERTY(QString name READ name NOTIFY nameChanged)
    Q_PROPERTY(bool alarmsEnabled READ alarmsEnabled WRITE setAlarmsEnabled NOTIFY alarmsEnabledChanged)
    //            alarmsVolume: 0
    //            alarmsTimeoutSeconds: 0
    Q_PROPERTY(QList<QObject *> alarms READ alarms NOTIFY alarmsChanged)
    Q_PROPERTY(QDateTime nextAlarm READ nextAlarm NOTIFY nextAlarmChanged)
    Q_PROPERTY(bool alarmActive READ alarmActive NOTIFY alarmActiveChanged)
    Q_PROPERTY(bool snoozing READ snoozing NOTIFY snoozingChanged)

public:
    QString playerId() const;
    QString name() const;
    bool alarmsEnabled() const;
    QList<QObject *> alarms() const;
    QDateTime nextAlarm() const;
    bool alarmActive() const;
    bool snoozing() const;

    Q_INVOKABLE bool newAlarm(bool enabled = false, bool repeat = true, int time = 8 * 60 * 60, const QVariantList &dayOfWeek = {});
    Q_INVOKABLE void deleteAlarm(const QString &alarmId);

    Q_INVOKABLE void alarmSnooze();
    Q_INVOKABLE void alarmStop();

public slots:
    void setAlarmsEnabled(bool alarmsEnabled);

signals:
    void nameChanged(const QString &name);
    void alarmsEnabledChanged(bool alarmsEnabled);
    void alarmsChanged();
    void nextAlarmChanged(const QDateTime &nextAlarm);
    void alarmActiveChanged(bool alarmActive);
    bool snoozingChanged(bool snoozing);

    void alarmAdded(SqueezeBoxAlarm *alarm);
    void alarmRemoved(SqueezeBoxAlarm *alarm);
    void alarmSounding(bool sounding);

private:
    SqueezeBoxPlayer();

    void updateName(const QString &s);
    void updateAlarmsEnabled(const QString &s);
    void updateAlarmActive(bool on);
    void updateSnoozing(bool on);

    void updateNextAlarm();

    QString m_playerId;
    QString m_name;
    bool m_alarmsEnabled = false;
    QMap<QString, SqueezeBoxAlarm *> m_alarms;
    QDateTime m_nextAlarm;
    bool m_alarmActive = false;
    bool m_snoozing = false;
    QString m_address;

    Q_DISABLE_COPY(SqueezeBoxPlayer)
    friend class SqueezeBoxServer;
};

class SqueezeBoxServer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QList<QObject *> players READ players NOTIFY playersChanged)
    Q_PROPERTY(QObject * thisPlayer READ thisPlayer NOTIFY thisPlayerChanged)
    Q_PROPERTY(bool connected READ connected NOTIFY connectedChanged)

public:
    static void registerQmlTypes();

    static SqueezeBoxServer *instance();
    static SqueezeBoxServer *createInstance(const QString &serverHost, int serverPort = 9090, QObject *parent = nullptr);

    void setPlayerNameFilter(const QStringList &nameFilter);

    void setThisPlayerName(const QString &thisPlayerName);

    void setThisPlayerAlarmState(const QString &newState); // Android only

    void command(const QVariantList &args, std::function<void(const QStringList &)> callback);

    static QPair<StringMap, QVector<StringMap>> parseExtendedResult(const QStringList &result, const QString &separatorTag);

    QList<QObject *> players();
    QObject *thisPlayer();

    bool connected() const;

signals:
    void connectedChanged(bool connected);
    void receivedNotification(const QStringList &args);

    void playersChanged();
    void thisPlayerChanged(SqueezeBoxPlayer *player);
    void playerAdded(SqueezeBoxPlayer *player);
    void playerRemoved(SqueezeBoxPlayer *player);

protected:
    void connectSockets();

    void parseListenData();
    void parseCommandData();

private:
    void onPlayersReply(const QStringList &result);
    void onPlayerPrefAlarmsEnabledReply(const QString &playerId, const QStringList &result);
    void onPlayerAlarmsReply(const QString &playerId, const QStringList &result);

    explicit SqueezeBoxServer(const QString &serverHost, int serverPort = 9090, QObject *parent = nullptr);

    void send(const QStringList &args, const std::function<void(const QStringList &)> &callback);
    static SqueezeBoxServer *s_instance;

    struct Command {
        quint64    id { 0 };
        QByteArray raw;
        std::function<void(const QStringList &)> callback;
    };

    QString m_serverHost;
    quint16 m_serverPort;
    QPointer<QQmlEngine> m_engine;
    QTcpSocket m_listen;
    QTcpSocket m_command;
    QTimer m_reconnectTimer;
    int m_timeoutReconnect = 4 * 1000;
    bool m_disabled = false;
    bool m_connected = false;

    QByteArray m_listenData;
    QByteArray m_commandData;

    std::optional<Command> m_sent;
    QQueue<Command> m_outgoing;

    QMap<QString, SqueezeBoxPlayer *> m_players;
    QPointer<SqueezeBoxPlayer> m_thisPlayer;

    QStringList m_ipAddresses;
    QStringList m_nameFilter;
    QString m_thisPlayerName;

    Q_DISABLE_COPY(SqueezeBoxServer)
    friend class SqueezeBoxPlayerModel;
    friend class SqueezeBoxAlarmModel;
};
