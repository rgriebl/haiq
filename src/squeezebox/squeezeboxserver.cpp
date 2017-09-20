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
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QNetworkAccessManager>
#include <QNetworkReply>
#include <QNetworkRequest>
#include <QQmlEngine>
#include <QTcpSocket>
#include <QTimer>
#include <QNetworkInterface>

#include "squeezeboxserver.h"

using namespace std::placeholders;

#define qSL(x) QStringLiteral(x)
#define qL1S(x) QLatin1String(x)


void SqueezeBoxServer::onPlayersReply(const QStringList &result)
{
    const auto parsed = parseExtendedResult(result, "playerindex");

    if (parsed.first.value("count").toInt() != parsed.second.count())
        return;

    //qWarning() << parsed.second;

    QStringList existingPlayerIds = m_players.keys();

    for (const auto &sbplayer : parsed.second) {
        const QString id = sbplayer.value("playerid");
        const QString ip = sbplayer.value("ip").section(':', 0, -2); // chop off port number
        const QString name = sbplayer.value("name");

        if (m_nameFilter.isEmpty() || m_nameFilter.contains(name)) {
            auto it = m_players.find(id);
            if (it != m_players.end()) {
                auto player = *it;

                if (player->name() != name) {
                    player->m_name = name;
                    emit player->nameChanged(name);
                }
                existingPlayerIds.removeOne(id);

                bool isThisPlayer = (player == m_thisPlayer);
                bool willBeThisPlayer;

                if (!m_thisPlayerName.isEmpty())
                    willBeThisPlayer = (m_thisPlayerName == name);
                else
                    willBeThisPlayer = m_ipAddresses.contains(ip);

                if (ip != player->m_address)
                    player->m_address = ip;

                if (isThisPlayer != willBeThisPlayer) {
                    m_thisPlayer = willBeThisPlayer ? player : nullptr;
                    emit thisPlayerChanged(m_thisPlayer);
                }
            } else {
                auto player = new SqueezeBoxPlayer();
                QQmlEngine::setObjectOwnership(player, QQmlEngine::CppOwnership);
                player->m_playerId = id;
                player->m_address = ip;
                player->m_name = name;
                m_players.insert(id, player);
                emit playersChanged();
                emit playerAdded(player);

                if (!m_thisPlayerName.isEmpty()) {
                    if (name == m_thisPlayerName) {
                        m_thisPlayer = player;
                        emit thisPlayerChanged(m_thisPlayer);
                    }
                } else if (m_ipAddresses.contains(ip)) {
                    m_thisPlayer = player;
                    emit thisPlayerChanged(m_thisPlayer);
                }
            }
        }
    }

    for (const auto &id : existingPlayerIds) {
        auto player = m_players.take(id);
        emit playerRemoved(player);
        emit playersChanged();
        if (player == m_thisPlayer) {
            m_thisPlayer.clear();
            emit thisPlayerChanged(m_thisPlayer);
        }
        delete player;
    }
}

QVariantList SqueezeBoxAlarm::dayOfWeekListFromString(const QString &s)
{
    QVariantList vl;
    auto sl = s.split(",");
    for (auto str : sl)
        vl << str.toInt();
    return vl;
}

QString SqueezeBoxAlarm::dayOfWeekListToString(const QVariantList &vl)
{
    if (vl.isEmpty())
        return {};

    QStringList dow;
    for (auto v : vl) {
        bool convertOk = false;
        int d = v.toInt(&convertOk);
        if (!convertOk || (d < 0) || (d > 6)) {
            qWarning() << "SqueezeBoxPlayer::newAlarm: invalid day of week:" << v;
            return {};
        }
        dow << QString::number(d);
    }
    std::sort(dow.begin(), dow.end());
    return dow.join(',');
}


void SqueezeBoxServer::onPlayerAlarmsReply(const QString &playerId, const QStringList &result)
{
    const auto parsed = SqueezeBoxServer::parseExtendedResult(result, "id");

    if (parsed.first.value("count").toInt() != parsed.second.count())
        return;

    SqueezeBoxPlayer *player = m_players.value(playerId);
    if (!player)
        return;

    QStringList existingAlarmIds = player->m_alarms.keys();

    for (const auto &sbalarm : parsed.second) {
        QString id = sbalarm.value("id");

        auto it = player->m_alarms.find(id);
        if (it != player->m_alarms.end()) {
            auto alarm = *it;

            bool newRepeat = sbalarm.value("repeat") == "1";
            bool newEnabled = sbalarm.value("enabled") == "1";
            int newTime = sbalarm.value("time").toInt();
            QVariantList newDow = SqueezeBoxAlarm::dayOfWeekListFromString(sbalarm.value("dow"));
            qreal newVolume = sbalarm.value("volume").toDouble();
            QUrl newUrl = sbalarm.value("url");

            if (alarm->m_enabled != newEnabled) {
                alarm->m_enabled = newEnabled;
                emit alarm->enabledChanged(newEnabled);
            }
            if (alarm->m_repeat != newRepeat) {
                alarm->m_repeat = newRepeat;
                emit alarm->repeatChanged(newRepeat);
            }
            if (alarm->m_time != newTime) {
                alarm->m_time = newTime;
                emit alarm->timeChanged(newTime);
            }
            if (alarm->m_dayOfWeek != newDow) {
                alarm->m_dayOfWeek = newDow;
                emit alarm->dayOfWeekChanged(newDow);
            }
            if (!qFuzzyCompare(alarm->m_volume, newVolume)) {
                alarm->m_volume = newVolume;
                emit alarm->volumeChanged(newVolume);
            }
            if (alarm->m_url != newUrl) {
                alarm->m_url = newUrl;
                emit alarm->urlChanged(newUrl);
            }
            existingAlarmIds.removeOne(id);
        } else {
            auto alarm = new SqueezeBoxAlarm(player);
            QQmlEngine::setObjectOwnership(alarm, QQmlEngine::CppOwnership);
            alarm->m_alarmId = id;
            alarm->m_enabled = sbalarm.value("enabled") == "1";
            alarm->m_repeat = sbalarm.value("repeat") == "1";
            alarm->m_time = sbalarm.value("time").toInt();
            alarm->m_dayOfWeek = SqueezeBoxAlarm::dayOfWeekListFromString(sbalarm.value("dow"));
            alarm->m_volume = sbalarm.value("volume").toDouble() / 100.;
            alarm->m_url = sbalarm.value("url");
            player->m_alarms.insert(id, alarm);
            emit player->alarmsChanged();
            emit player->alarmAdded(alarm);
        }
    }

    for (const auto &id : existingAlarmIds) {
        emit player->alarmRemoved(player->m_alarms.value(id));
        player->m_alarms.remove(id);
        emit player->alarmsChanged();
    }
    player->updateNextAlarm();
}

void SqueezeBoxServer::onPlayerPrefAlarmsEnabledReply(const QString &playerId, const QStringList &result)
{
    auto player = m_players[playerId];

    if (!player)
        return;

    player->updateAlarmsEnabled(result.isEmpty() ? QString() : result.first());
    player->updateNextAlarm();
}


SqueezeBoxServer *SqueezeBoxServer::s_instance = nullptr;

SqueezeBoxServer *SqueezeBoxServer::instance()
{
    return s_instance;
}

SqueezeBoxServer *SqueezeBoxServer::createInstance(const QString &serverHost, int serverPort, QObject *parent)
{
    if (Q_UNLIKELY(s_instance))
        qFatal("SqueezeBoxServer::createInstance() was called a second time.");

    s_instance = new SqueezeBoxServer(serverHost, serverPort, parent);
    QMetaObject::invokeMethod(s_instance, &SqueezeBoxServer::connectSockets);

    return s_instance;
}

void SqueezeBoxServer::setPlayerNameFilter(const QStringList &nameFilter)
{
    m_nameFilter = nameFilter;
}

void SqueezeBoxServer::setThisPlayerName(const QString &thisPlayerName)
{
    m_thisPlayerName = thisPlayerName;
}

void SqueezeBoxServer::setThisPlayerAlarmState(const QString &newState)
{
    // Android only -- we get an Intent when the alarm has already gone active

    auto setState = [](SqueezeBoxPlayer *player, const QString &newState) {
        if (player) {
            if (newState == "sound")
                player->updateAlarmActive(true);
            else if (newState == "end")
                player->updateAlarmActive(false);
            else if (newState == "snooze")
                player->updateSnoozing(true);
            else if (newState == "snooze_end")
                player->updateSnoozing(false);
        }
    };

    if (m_thisPlayer) {
        setState(m_thisPlayer, newState);
    } else {
        auto *singleShot = new QObject(this);

        static bool recursionGuard = false;

        if (!recursionGuard) {
            recursionGuard = true;

            connect(this, &SqueezeBoxServer::thisPlayerChanged,
                    singleShot, [this, singleShot, setState, newState]() {
                setState(m_thisPlayer, newState);
                recursionGuard = false;
                delete singleShot;
            });
        }
    }
}

void SqueezeBoxServer::registerQmlTypes()
{
    qmlRegisterSingletonType<SqueezeBoxServer>("org.griebl.haiq", 1, 0, "SqueezeBoxServer",
                                           [](QQmlEngine *engine, QJSEngine *) -> QObject * {
        s_instance->m_engine = engine;
        QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
        return instance();
    });
}

SqueezeBoxServer::SqueezeBoxServer(const QString &serverHost, int serverPort, QObject *parent)
    : QObject(parent)
    , m_serverHost(serverHost)
    , m_serverPort(quint16(serverPort))
{
    m_disabled = m_serverHost.isEmpty();
    if (m_disabled)
        qWarning() << "SqueezeBoxServer is disabled due to missing configuration";

    auto allAdrs = QNetworkInterface::allAddresses();
    std::for_each(allAdrs.cbegin(), allAdrs.cend(), [this](const auto &adr) {
        m_ipAddresses << adr.toString();
    });

    connect(&m_listen, &QTcpSocket::readyRead, this, [this]() {
        m_listenData.append(m_listen.readAll());
        parseListenData();
    });
    connect(&m_command, &QTcpSocket::readyRead, this, [this]() {
        m_commandData.append(m_command.readAll());
        parseCommandData();
    });

    m_reconnectTimer.setInterval(m_timeoutReconnect);
    m_reconnectTimer.setSingleShot(true);
    m_reconnectTimer.callOnTimeout(this, &SqueezeBoxServer::connectSockets);

    auto checkDisconnected = [this]() {
        bool commandNotConnected = (m_command.state() == QAbstractSocket::UnconnectedState);
        bool listenNotConnected = (m_listen.state() == QAbstractSocket::UnconnectedState);

        if (m_connected && commandNotConnected && !listenNotConnected) {
            m_listen.disconnectFromHost();
        } else if (m_connected && listenNotConnected && !commandNotConnected) {
            m_command.disconnectFromHost();
        } else if (listenNotConnected && commandNotConnected) {
            if (m_connected) {
                qWarning() << "Disconnected from the SqueezeBox server on both sockets";
                m_connected = false;
                emit connectedChanged(m_connected);
            }

            if (!m_reconnectTimer.isActive())
                m_reconnectTimer.start();
        }
    };

    connect(&m_command, &QAbstractSocket::stateChanged, this, checkDisconnected);
    connect(&m_listen, &QAbstractSocket::stateChanged, this, checkDisconnected);

    auto checkConnected = [this]() {
        if (m_command.state() == QAbstractSocket::ConnectedState
                && m_listen.state() == QAbstractSocket::ConnectedState
                && !m_connected) {
            qWarning() << "Connected to the SqueezeBox server";
            m_connected = true;
            emit connectedChanged(m_connected);

            m_reconnectTimer.stop();
        }
    };

    connect(&m_command, &QTcpSocket::connected, this, checkConnected);
    connect(&m_listen, &QTcpSocket::connected, this, checkConnected);

    connect(this, &SqueezeBoxServer::connectedChanged, [this]() {
        if (m_connected) {
            // no login support atm
            m_listen.write("listen\r\n");
            command({ "players", 0, 1000 }, std::bind(&SqueezeBoxServer::onPlayersReply, this, _1));
        } else {
            while (!m_players.isEmpty()) {
                auto player = m_players.take(m_players.firstKey());
                emit playerRemoved(player);
                if (player == m_thisPlayer) {
                    m_thisPlayer.clear();
                    emit thisPlayerChanged(m_thisPlayer);
                }
                delete player;
            }
            emit playersChanged();

            m_sent.reset();
            m_outgoing.clear();
            m_listenData.clear();
            m_commandData.clear();
        }
    });

    connect(this, &SqueezeBoxServer::playerAdded, this, [this](SqueezeBoxPlayer *player) {
        Q_ASSERT(player);
        QString id = player->playerId();
        qWarning() << "Added Player" << id;
        command({ id, "alarms", 0, 1000, "filter:all" }, std::bind(&SqueezeBoxServer::onPlayerAlarmsReply, this, id, _1));
        command({ id, "playerpref", "alarmsEnabled", "?" }, std::bind(&SqueezeBoxServer::onPlayerPrefAlarmsEnabledReply, this, id, _1));
    });

    connect(this, &SqueezeBoxServer::receivedNotification, this, [this](const QStringList &args) {
        auto player = m_players.value(args.first());

        if (player) {
            QString id = player->playerId();

            if (args.size() >= 4) {
                if (args.at(1) == "client") {
                    command({ "players", 0, 1000 }, std::bind(&SqueezeBoxServer::onPlayersReply, this, _1));
                } else if (args.at(1) == "playerpref" && args.at(2) == "alarmsEnabled") {
                    player->updateAlarmsEnabled(args.at(3));
                } else if (args.at(1) == "alarm") {
                    if (args.at(2) == "update" || args.at(2) == "add" || args.at(2) == "delete") {
                        command({ id, "alarms", 0, 1000, "filter:all" }, std::bind(&SqueezeBoxServer::onPlayerAlarmsReply, this, id, _1));
                    } else if (args.at(2) == "sound") {
                        player->updateAlarmActive(true);
                    } else if (args.at(2) == "end") {
                        player->updateAlarmActive(false);
                    } else if (args.at(2) == "snooze") {
                        player->updateSnoozing(true);
                    } else if (args.at(2) == "snooze_end") {
                        player->updateSnoozing(false);
                    }
                }
            }
        }

        qWarning() << "SqueezeBox server sent notification" << args;
    });
}

void SqueezeBoxServer::connectSockets()
{
    if (m_disabled || m_connected)
        return;

    qWarning() << "Connecting to the SqueezeBox server at" << m_serverHost << "port" << m_serverPort;

    m_command.connectToHost(m_serverHost, m_serverPort);
    m_listen.connectToHost(m_serverHost, m_serverPort);
}

void SqueezeBoxServer::command(const QVariantList &args, std::function<void(const QStringList &)> callback = {})
{
    QStringList sl;
    for (auto arg : args)
        sl << arg.toString();
    send(sl, callback);
}

QPair<StringMap, QVector<StringMap>> SqueezeBoxServer::parseExtendedResult(const QStringList &result, const QString &separatorTag)
{
    StringMap global;
    QVector<StringMap> objects;
    StringMap currentObject;
    bool inObject = false;

    for (auto tagValue : result) {
        int pos = tagValue.indexOf(':');
        const QString tag(pos <= 0 ? QString() : tagValue.left(pos));
        const QString value(tagValue.mid(pos + 1));

        if (tag == separatorTag) {
            if (inObject && !currentObject.isEmpty())
                objects << currentObject;
            currentObject.clear();
            inObject = true;
        }

        if (inObject)
            currentObject.insert(tag, value);
        else
            global.insert(tag, value);
    }
    if (!currentObject.isEmpty())
        objects << currentObject;

    return qMakePair(global, objects);
}

QList<QObject *> SqueezeBoxServer::players()
{
    QObjectList players;
    for (auto &player : m_players)
        players << player;
    return players;
}

QObject *SqueezeBoxServer::thisPlayer()
{
    return m_thisPlayer;
}

bool SqueezeBoxServer::connected() const
{
    return m_connected;
}

void SqueezeBoxServer::send(const QStringList &args, const std::function<void (const QStringList &)> &callback)
{
    if (!m_connected)
        return;

    QByteArray out;
    qWarning() << "SqueezeBox server sending command:" << args;

    for (auto arg : args) {
        auto rawArg = QUrl::toPercentEncoding(arg);
        if (!out.isEmpty())
            out.append(' ');
        out.append(rawArg);
    }

    static quint64 counter = 0;
    Command c { ++counter, out, callback };


    if (!m_sent) {
        m_sent = c;
        m_command.write(c.raw + '\n');
    } else {
        m_outgoing.enqueue(c);
    }
}

void SqueezeBoxServer::parseCommandData()
{
    do {
        int eol = m_commandData.indexOf('\n');
        if (eol < 0)
            break;

        QByteArray msg = m_commandData.left(eol).trimmed();
        m_commandData.remove(0, eol + 1);

        if (!m_sent) {
            qWarning() << "SqueezeBox server sent a reply, but we weren't expecting one:\n" << msg;
            continue;
        }

        QByteArray sentRaw = m_sent->raw;
        if (sentRaw.endsWith("%3F")) // ? query
            sentRaw.chop(4);

        if (!msg.startsWith(sentRaw)) {
            qWarning() << "SqueezeBox server sent a reply, but we were expecting a different one:\n"
                          "    wanted:" << m_sent->raw << "\n"
                          "  received:" << msg;
            continue;
        }

        msg.remove(0, sentRaw.size() + 1); // also remove the following space

        //qWarning() << "RECEIVED REPLY:" << msg;

        QStringList args;
        const auto rawArgs = msg.split(' ');
        for (auto rawArg : rawArgs)
            args << QUrl::fromPercentEncoding(rawArg);
        if (m_sent->callback)
            m_sent->callback(args);

        m_sent.reset();

        if (!m_outgoing.isEmpty()) {
            m_sent = m_outgoing.dequeue();

            if (m_connected)
                m_command.write(m_sent->raw + '\n');
        }
    } while (true);
}

void SqueezeBoxServer::parseListenData()
{
    do {
        int eol = m_listenData.indexOf('\n');
        if (eol < 0)
            break;

        const QByteArray msg = m_listenData.left(eol).trimmed();
        m_listenData.remove(0, eol + 1);

        if (msg == "listen")
            continue;

        QStringList args;
        const auto rawArgs = msg.split(' ');
        for (auto rawArg : rawArgs)
            args << QUrl::fromPercentEncoding(rawArg);

        if (!args.isEmpty())
            emit receivedNotification(args);
    } while (true);
}

#if 0

bool SqueezeBoxServer::callMethod(const QString &playerId, const QString &method,
                                  const QVariantList &parameters, const QJSValue &callback,
                                  const QJSValue &errorCallback)
{
    if (method.isEmpty() || !callback.isCallable() || !callback.engine())
        return false;

    QUrl url = m_serverUrl;
    url.setPath(qSL("/jsonrpc.js"));
    QNetworkRequest nr(url);

    //QNetworkRequest nr(m_serverUrlqSL("http://") + server() + qSL(":") + QString::number(port()) + qSL("/jsonrpc.js"));
    nr.setHeader(QNetworkRequest::ContentTypeHeader, qSL("application/json"));
    QJsonArray methodArray = QJsonArray::fromVariantList(parameters);
    methodArray.prepend(method);
    QJsonDocument rpcout { QJsonObject {
            { "method", "slim.request" },
            { "params", QJsonArray { playerId, methodArray } }
        } };
    auto reply = m_nam->post(nr, rpcout.toJson());
    if (!reply)
        return false;

    connect(reply, &QNetworkReply::finished, this, [this, reply, callback, errorCallback]() {
//        qWarning() << "RPC finished:" << reply->error() << reply->errorString()
//                   << reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();
        QByteArray data = reply->readAll();
        reply->deleteLater();

        int code = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

        auto doError = [errorCallback](const QString &error) {
            if (errorCallback.isCallable()) {
                QJSValue cb = errorCallback;
                cb.call({ error });
            }
        };

        if (reply->error() != QNetworkReply::NoError) {
            doError(reply->errorString());
        } else if (code < 200 || code >= 400) {
            doError(qSL("HTTP error code: %1").arg(code));
        } else {
            QJsonParseError err;
            QJsonDocument rpcin = QJsonDocument::fromJson(data, &err);

            //        qWarning() << "received JSONRPC response:";
            //        qWarning().noquote() << data;
            if (rpcin.isNull()) {
                //                doError(qSL("JSON parse error at offset ") + QString::number(err.offset) +
                //                        qSL(": ") + err.errorString());
            } else {

                QJsonObject root = rpcin.object();

                if (root.value(qSL("method")) != qSL("slim.request"))
                    doError(qSL("Unexpected response method: ") + root.value(qSL("method")).toString());

                QJsonValue result = root.value(qSL("result"));
                auto jsResult = callback.engine()->toScriptValue(result); // ??? toVariant?
                QJSValue cb = callback;
                cb.call({ jsResult });
            }
        }
    });

    return true;
}
#endif
#ifdef CPP_VARIANT

bool SqueezeBoxServer::callMethod(const QString &playerId, const QString &method,
                                  const QVariantList &parameters,
                                  const std::function<void(const QVariant &)> &callback,
                                  const std::function<void(const QString &)> &errorCallback)
{
    if (method.isEmpty() || !callback)
        return false;

    //    Request r;
    //    r.method = method;
    //    r.parameters = parameters;
    //    r.callback = callback;

    QNetworkRequest nr(qSL("http://") + server() + qSL(":") + QString::number(port()) + qSL("/jsonrpc.js"));
    nr.setHeader(QNetworkRequest::ContentTypeHeader, qSL("application/json"));
    QJsonArray methodArray = QJsonArray::fromVariantList(parameters);
    methodArray.prepend(method);
    QJsonDocument rpcout { QJsonObject {
            { "method", "slim.request" },
            { "params", QJsonArray { playerId, methodArray } }
        } };
    auto reply = m_nam->post(nr, rpcout.toJson());
    if (!reply)
        return false;

    connect(reply, &QNetworkReply::finished, this, [this, reply, callback, errorCallback]() {
        QByteArray data = reply->readAll();
        reply->deleteLater();

        int code = reply->attribute(QNetworkRequest::HttpStatusCodeAttribute).toInt();

        if (reply->error() != QNetworkReply::NoError) {
            if (errorCallback)
                errorCallback(reply->errorString());
        } else if (code < 200 || code >= 400) {
            if (errorCallback)
                errorCallback(qSL("HTTP error code: %1").arg(code));
        } else {
            QJsonParseError err;
            QJsonDocument rpcin = QJsonDocument::fromJson(data, &err);

            //        qWarning() << "received JSONRPC response:";
            //        qWarning().noquote() << data;
            if (rpcin.isNull()) {
                if (errorCallback) {
                    errorCallback(qSL("JSON parse error at offset ") + QString::number(err.offset) +
                                  qSL(": ") + err.errorString());
                }
            } else {
                QJsonObject root = rpcin.object();

                if (root.value(qSL("method")) != qSL("slim.request")) {
                    if (errorCallback)
                        errorCallback(qSL("Unexpected response method: ") + root.value(qSL("method")).toString());
                }

                QJsonValue result = root.value(qSL("result"));
                callback(result.toVariant());
            }
        }
    });

    return true;
}

#endif

SqueezeBoxPlayer::SqueezeBoxPlayer()
{ }

QString SqueezeBoxPlayer::playerId() const
{
    return m_playerId;
}

QString SqueezeBoxPlayer::name() const
{
    return m_name;
}

void SqueezeBoxPlayer::updateName(const QString &s)
{
    if (s != m_name) {
        m_name = s;
        emit nameChanged(s);
    }
}

bool SqueezeBoxPlayer::alarmsEnabled() const
{
    return m_alarmsEnabled;
}

void SqueezeBoxPlayer::updateAlarmsEnabled(const QString &s)
{
    bool newAlarmsEnabled = (s == "1");
    if (newAlarmsEnabled != m_alarmsEnabled) {
        m_alarmsEnabled = newAlarmsEnabled;
        emit alarmsEnabledChanged(newAlarmsEnabled);
    }
}

void SqueezeBoxPlayer::updateAlarmActive(bool on)
{
    if (on != m_alarmActive) {
        m_alarmActive = on;
        emit alarmActiveChanged(on);

        emit alarmSounding(m_alarmActive && !m_snoozing);
    }
}

void SqueezeBoxPlayer::updateSnoozing(bool on)
{
    if (on != m_snoozing) {
        m_snoozing = on;
        emit snoozingChanged(on);

        emit alarmSounding(m_alarmActive && !m_snoozing);
    }
}

void SqueezeBoxPlayer::updateNextAlarm()
{
    QDateTime next;

    for (const SqueezeBoxAlarm *alarm : qAsConst(m_alarms)) {
        if (alarm->enabled()) {
            QDate whenDate = QDate::currentDate();
            auto whenTime = QTime(0, 0).addSecs(alarm->time());

            if (whenTime < QTime::currentTime())
                whenDate = whenDate.addDays(1);

            //qWarning() << m_name << alarm->alarmId() << whenDate << whenTime << QTime::currentTime() << alarm->dayOfWeek() << (whenDate.dayOfWeek() % 7) << next;

            if (alarm->dayOfWeek().contains(whenDate.dayOfWeek() % 7)) {
                QDateTime when(whenDate, whenTime);
                if (!next.isValid() || (when < next))
                    next = when;
            }
        }
    }

    if (next != m_nextAlarm) {
        m_nextAlarm = next;
        emit nextAlarmChanged(next);
    }
}

void SqueezeBoxPlayer::setAlarmsEnabled(bool alarmsEnabled)
{
    if (m_alarmsEnabled == alarmsEnabled)
        return;

    SqueezeBoxServer::instance()->command({ playerId(), "playerpref", "alarmsEnabled",
                                            QString::number(alarmsEnabled ? 1 : 0) });
    m_alarmsEnabled = alarmsEnabled;
    emit alarmsEnabledChanged(m_alarmsEnabled);
}

QList<QObject *> SqueezeBoxPlayer::alarms() const
{
    QObjectList alarms;
    for (auto &alarm : m_alarms)
        alarms << alarm;
    return alarms;
}

bool SqueezeBoxPlayer::newAlarm(bool enabled, bool repeat, int time, const QVariantList &dayOfWeek)
{
    QVariantList args = { playerId(), "alarm", "add",
                          qSL("enabled:") + (enabled ? "1" : "0"),
                          qSL("repeat:") + (repeat ? "1" : "0"),
                          qSL("time:") + QString::number(time),
                        };
    if (!dayOfWeek.isEmpty())
        args.append(qSL("dow:") + SqueezeBoxAlarm::dayOfWeekListToString(dayOfWeek));

    SqueezeBoxServer::instance()->command(args);
    return true;
}

void SqueezeBoxPlayer::deleteAlarm(const QString &alarmId)
{
    if (m_alarms.contains(alarmId))
        SqueezeBoxServer::instance()->command({ playerId(), "alarm", "delete", qSL("id:") + alarmId });
}

void SqueezeBoxPlayer::alarmSnooze()
{
    if (m_alarmActive)
        SqueezeBoxServer::instance()->command({ playerId(), "button", "snooze" });
}

void SqueezeBoxPlayer::alarmStop()
{
    if (m_alarmActive)
        SqueezeBoxServer::instance()->command({ playerId(), "button", "stop" });
}

QDateTime SqueezeBoxPlayer::nextAlarm() const
{
    return m_nextAlarm;
}

bool SqueezeBoxPlayer::alarmActive() const
{
    return m_alarmActive;
}

bool SqueezeBoxPlayer::snoozing() const
{
    return m_snoozing;
}


QString SqueezeBoxAlarm::playerId() const
{
    return m_player ? m_player->playerId() : QString();
}

QString SqueezeBoxAlarm::alarmId() const
{
    return m_alarmId;
}

bool SqueezeBoxAlarm::enabled() const
{
    return m_enabled;
}

bool SqueezeBoxAlarm::repeat() const
{
    return m_repeat;
}

int SqueezeBoxAlarm::time() const
{
    return m_time;
}

QVariantList SqueezeBoxAlarm::dayOfWeek() const
{
    return m_dayOfWeek;
}

QString SqueezeBoxAlarm::dayOfWeekString() const
{
    const int minimumDayRange = 3; // only x consecutive days will be displayed as A-C

    //qWarning() << "DLTR 1" << m_dayOfWeek;

    QVector<int> days;
    for (const auto &v : m_dayOfWeek) {
        int d = v.toInt();
        // European format: Sunday is 7
        days << (d == 0 ? 7 : d);
    }

    if (days.isEmpty())
        return {};

    std::sort(days.begin(), days.end());

    //qWarning() << "DLTR 1" << days;

    auto dayName = [](int d) {
        return QLocale("de").standaloneDayName(d, QLocale::ShortFormat);
    };

    QString result;
    for (int i = 0; i < days.size(); ++i) {
        for (int j = i + 1; j <= days.size(); ++j) {
            if ((j == days.size()) || (days[j] != (days[i] + (j-i)))) {
                // non-consecutive or end of array
                if (!result.isEmpty())
                    result.append(',');
                if (j - i >= minimumDayRange) {
                    result = result + dayName(days[i]) + qSL("-") + dayName(days[j - 1]);
                } else {
                    for (int k = i; k < j; ++k) {
                        if (k > i)
                            result.append(',');
                        result.append(dayName(days[k]));
                    }
                }
                i = j - 1;
                break;
            }
        }
    }

    //qWarning() << "DLTR 3" << result;
    return result;
}

qreal SqueezeBoxAlarm::volume() const
{
    return m_volume;
}

QUrl SqueezeBoxAlarm::url() const
{
    return m_url;
}


void SqueezeBoxAlarm::setEnabled(bool enabled)
{
    if (m_enabled == enabled)
        return;

    SqueezeBoxServer::instance()->command({ playerId(), "alarm", "update",
                                            qSL("id:") + m_alarmId,
                                            qSL("enabled:") + (enabled ? "1" : "0") });
    m_enabled = enabled;
    emit enabledChanged(m_enabled);
}

void SqueezeBoxAlarm::setRepeat(bool repeat)
{
    if (m_repeat == repeat)
        return;

    SqueezeBoxServer::instance()->command({ playerId(), "alarm", "update",
                                            qSL("id:") + m_alarmId,
                                            qSL("repeat:") + (repeat ? "1" : "0") });
        m_repeat = repeat;
    emit repeatChanged(m_repeat);
}

void SqueezeBoxAlarm::setTime(int time)
{
    if (m_time == time)
        return;

    SqueezeBoxServer::instance()->command({ playerId(), "alarm", "update",
                                            qSL("id:") + m_alarmId,
                                            qSL("time:") + QString::number(time) });
    m_time = time;
    emit timeChanged(m_time);
}

void SqueezeBoxAlarm::setDayOfWeek(const QVariantList &dayOfWeek)
{
    if (m_dayOfWeek == dayOfWeek)
        return;

    SqueezeBoxServer::instance()->command({ playerId(), "alarm", "update",
                                            qSL("id:") + m_alarmId,
                                            qSL("dow:") + SqueezeBoxAlarm::dayOfWeekListToString(dayOfWeek) });
    m_dayOfWeek = dayOfWeek;
    emit dayOfWeekChanged(m_dayOfWeek);
}

void SqueezeBoxAlarm::setVolume(qreal volume)
{
    if (qFuzzyCompare(m_volume, volume))
        return;

    SqueezeBoxServer::instance()->command({ playerId(), "alarm", "update",
                                            qSL("id:") + m_alarmId,
                                            qSL("volume:") + QString::number(int(volume * 100)) });
    m_volume = volume;
    emit volumeChanged(m_volume);
}

void SqueezeBoxAlarm::setUrl(const QUrl &url)
{
    if (m_url == url)
        return;

    qWarning() << "Alarm URL setting is not implemented yet";
    //TODO

    m_url = url;
    emit urlChanged(m_url);
}

SqueezeBoxAlarm::SqueezeBoxAlarm(SqueezeBoxPlayer *player)
    : QObject(player)
    , m_player(player)
{ }