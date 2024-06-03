// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

#include <QtWebSockets/QWebSocket>
#include <QTimerEvent>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QUrlQuery>
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QCoreApplication>
#include <QQmlEngine>
#include <qqml.h>

#include <QTimer>

#include "homeassistant.h"


template<class NonMap>
struct Print
{
    static void print(const QString& tabs, const NonMap& value)
    {
        qDebug() << tabs << value;
    }
};

template <class Key, class ValueType >
struct Print<class QMap<Key, ValueType> >
{
    static void print(const QString& tabs, const QMap< Key, ValueType>& map )
    {
        const QString extraTab = tabs + "\t";
        QMapIterator<Key, ValueType> iterator(map);
        while(iterator.hasNext())
        {
            iterator.next();
            qDebug() << tabs << iterator.key();
            Print<ValueType>::print(extraTab, iterator.value());
        }
    }
};

template<class Type>
void printMe(const Type& type )
{
    Print<Type>::print("", type);
}


HomeAssistant *HomeAssistant::s_instance = nullptr;

HomeAssistant *HomeAssistant::instance()
{
    return s_instance;
}

HomeAssistant *HomeAssistant::createInstance(const QUrl &homeAssistantUrl,
                                             const QString &authenicationToken, QObject *parent)
{
    if (Q_UNLIKELY(s_instance))
        qFatal("HomeAssistant::createInstance() was called a second time.");

    s_instance = new HomeAssistant(homeAssistantUrl, authenicationToken, parent);
    QMetaObject::invokeMethod(s_instance, &HomeAssistant::connectToWebSocket);

    return s_instance;
}

void HomeAssistant::reconnect()
{
    m_ws->close();
}

QUrl HomeAssistant::baseUrl() const
{
    return m_baseUrl;
}

HomeAssistant::HomeAssistant(const QUrl &homeAssistantUrl,
                               const QString &authenticationToken, QObject *parent)
    : QObject(parent)
    , m_baseUrl(homeAssistantUrl)
    , m_webSocketUrl(homeAssistantUrl)
    , m_authenticationToken(authenticationToken)
{
    m_baseUrl.setPath(QString());
    m_baseUrl.setQuery(QUrlQuery());

    if (m_webSocketUrl.scheme() == u"http")
        m_webSocketUrl.setScheme(u"ws"_qs);
    else if (m_webSocketUrl.scheme() == u"https")
        m_webSocketUrl.setScheme(u"wss"_qs);


    m_states.emplace_back(State::Connected, u"auth_ok"_qs, [this](const QJsonObject &) {
        getInitialState();
        return State::Authenticated;
    });
    m_states.emplace_back(State::Connected, u"auth_required"_qs, [this](const QJsonObject &) {
        authenticate();
        return State::AuthenticationSent;
    });
    m_states.emplace_back(State::AuthenticationSent, u"auth_invalid"_qs, [](const QJsonObject &message) {
        qWarning() << "Authentication failed:" << message.value(u"message"_qs).toString();
        return State::AuthenticationFailed;
    });
    m_states.emplace_back(State::AuthenticationSent, u"auth_ok"_qs, [this](const QJsonObject &) {
        getInitialState();
        return State::Authenticated;
    });
    m_states.emplace_back(State::Authenticated, u"result"_qs, [this](const QJsonObject &message) {
        if (message[u"id"_qs].toInt() != m_initialStateId) {
            qWarning() << "Ignoring result id" << message[u"id"_qs].toInt()
                       << "while waiting for initial state id" << m_initialStateId;
            return State::Authenticated;
        } else if (!message[u"success"_qs].toBool()) {
            qWarning() << "Getting the initial state failed:"
                       << QJsonDocument(message).toJson().constData();
            return State::InitialStateFailed;
        } else {
            parseInitialState(message[u"result"_qs].toArray().toVariantList());
            subscribeToStateChange();
            return State::InitialStateReceived;
        }
    });
    m_states.emplace_back(State::InitialStateReceived, u"result"_qs, [this](const QJsonObject &message) {
        if (message[u"id"_qs].toInt() != m_subscriptionId) {
            qWarning() << "Ignoring result id" << message[u"id"_qs].toInt()
                       << "while waiting for subscription id" << m_subscriptionId;
            return State::InitialStateReceived;
        }
        else if (!message[u"success"_qs].toBool()) {
            qWarning() << "Subscription failed:"
                       << message[u"error"_qs].toObject()[u"message"_qs].toString();
            return State::SubscriptionFailed;
        } else {
            emit connected();
            m_pingTimer.start(m_timeoutPing, this);
            return State::Subscribed;
        }
    });
    m_states.emplace_back(State::Subscribed, u"event"_qs, [this](const QJsonObject &message) {
        if (message[u"id"_qs].toInt() != m_subscriptionId) {
            qWarning() << "Ignoring event id" << message[u"id"_qs].toInt()
                       << "while waiting for subscription id" << m_subscriptionId;
        } else {
            const QJsonObject event = message[u"event"_qs].toObject();
            const QString eventType = event[u"event_type"_qs].toString();
            const QDateTime firedAt = QDateTime::fromString(event[u"time_fired"_qs].toString(), Qt::ISODateWithMs);

            if (!handleEvent(eventType, firedAt, event[u"data"_qs].toObject().toVariantMap())) {
//                qWarning() << "Event was not handled: type =" << eventType << "\n"
//                           << QJsonDocument(message).toJson().constData();
            }
        }
        return State::Subscribed;
    });
    m_states.emplace_back(State::Subscribed, u"result"_qs, [](const QJsonObject &message) {
        if (!message[u"success"_qs].toBool())
            qWarning() << "service call" << message[u"id"_qs].toInt() << "failed:"
                       << message[u"error"_qs].toObject()[u"message"_qs].toString();
        return State::Subscribed;
    });
}

void HomeAssistant::createWebSocket()
{
    delete m_ws;
    m_ws = new QWebSocket(QString(), QWebSocketProtocol::VersionLatest, this);

    connect(m_ws, &QWebSocket::connected, this, [this]() {
        m_state = State::Connected;
    });
    connect(m_ws, &QWebSocket::disconnected, this, [this]() {
        m_state = State::Disconnected;
        emit disconnected();
        m_pingTimer.stop();
        m_pongTimer.stop();
        qWarning() << "Socket closed (" << m_ws->closeReason() << ") -> reconnecting in" << m_timeoutReconnect/1000. << "sec";

        QTimer::singleShot(m_timeoutReconnect, this, &HomeAssistant::connectToWebSocket);
    });
    connect(m_ws, &QWebSocket::pong, this, [this]() {
        m_pongTimer.stop();
        m_pingTimer.start(m_timeoutPing, this);
    });

    connect(m_ws, &QWebSocket::textMessageReceived, this, [this](const QString &msg) {
        QJsonParseError parseError;
        QJsonDocument json = QJsonDocument::fromJson(msg.toUtf8(), &parseError);

        QJsonObject root = json.object();
        QString type = root.value(u"type"_qs).toString();

        bool foundState = false;
        for (const auto &state : m_states) {
            if ((std::get<0>(state) == m_state) && (std::get<1>(state) == type)) {
                State newState = std::get<2>(state)(root);
                foundState = true;
                if (newState != m_state) {
//                    qWarning() << "State change: received type" << type << "while in state" << m_state
//                               << "and switched to state" << newState;
                    m_state = newState;
                }
                break;
            }
        }

        if (!foundState) {
            qWarning() << "Invalid state: received type" << type << "while in state"
                       << m_state << "- full message:" << msg;
            if (m_ws->isValid())
                m_ws->close(QWebSocketProtocol::CloseCodeProtocolError, u"Invalid client state"_qs);
        }
    });
}

bool HomeAssistant::subscribe(const QString &entity, const QJSValue &callback)
{
    if (entity.isEmpty() || !callback.isCallable())
        return false;

    m_subscriptions.insert(entity, callback);

    // we are already subscribed, so send out the current state
    if (m_state == State::Subscribed) {
        QVariantMap state = m_currentState.value(entity);
        if (!state.isEmpty()) {
            QMetaObject::invokeMethod(this, [this, entity, state]() {
                handleStateChanged(QDateTime::currentDateTime(), entity, state, QVariantMap());
            });
        }
    }

    return true;
}

bool HomeAssistant::callService(const QString &service, const QString &entity, const QVariantMap &data)
{
    return callService(service, QStringList(entity), data);
}

bool HomeAssistant::callService(const QString &service, const QStringList &entities, const QVariantMap &data)
{
    auto pos = service.indexOf(u'.');

    if (pos <= 0)
        return false;

    QString serviceDomain = service.left(pos);
    QString serviceName = service.mid(pos + 1);
    QVariantMap serviceData = data;

    if (!entities.isEmpty())
        serviceData.insert(u"entity_id"_qs, entities);

    QJsonDocument doc {{
            { u"id"_qs, m_nextId++ },
            { u"type"_qs, u"call_service"_qs },
            { u"domain"_qs, serviceDomain },
            { u"service"_qs, serviceName },
            { u"service_data"_qs, QJsonValue::fromVariant(serviceData) }
                       }};
//    qWarning() << "Calling service\n" << doc.toJson().constData();
    if (m_ws)
        m_ws->sendTextMessage(QString::fromUtf8(doc.toJson()));
    return true;
}

void HomeAssistant::timerEvent(QTimerEvent *te)
{
    if (te->timerId() == m_pingTimer.timerId()) {
        m_pingTimer.stop();

        if (m_ws && (m_ws->state() == QAbstractSocket::ConnectedState)) {
            m_ws->ping();
            m_pongTimer.start(m_timeoutPong, this);
        }
    } else if (m_ws && (te->timerId() == m_pongTimer.timerId())) {
        m_ws->close(QWebSocketProtocol::CloseCodeMissingStatusCode, u"No pong received"_qs);
    }
}

void HomeAssistant::authenticate()
{
    QJsonDocument doc {{
            { u"type"_qs, u"auth"_qs },
            { u"access_token"_qs, m_authenticationToken }
                       }};
    if (m_ws)
        m_ws->sendTextMessage(QString::fromUtf8(doc.toJson()));
}

void HomeAssistant::subscribeToStateChange()
{
    m_subscriptionId = m_nextId++;
    QJsonDocument doc {{
            { u"id"_qs, m_subscriptionId },
            { u"type"_qs, u"subscribe_events"_qs }/*,
            { u"event_type"_qs, u"state_changed"_qs }*/
                       }};
    if (m_ws)
        m_ws->sendTextMessage(QString::fromUtf8(doc.toJson()));
}

void HomeAssistant::getInitialState()
{
    m_initialStateId = m_nextId++;
    QJsonDocument doc {{
            { u"id"_qs, m_initialStateId },
            { u"type"_qs, u"get_states"_qs },
                       }};
    if (m_ws)
        m_ws->sendTextMessage(QString::fromUtf8(doc.toJson()));
}

void HomeAssistant::parseInitialState(const QVariantList &states)
{
    QDateTime now = QDateTime::currentDateTime();

    for (const auto &s : states) {
        QVariantMap state = s.toMap();
        //qWarning() << "IS" << state[u"entity_id"_qs].toString() << state[u"state"_qs].toString();

        handleStateChanged(now, state[u"entity_id"_qs].toString(), state, QVariantMap());
    }
}

bool HomeAssistant::handleEvent(const QString &eventType, const QDateTime &timeStamp,
                                 const QVariantMap &data)
{
    //qWarning() << "RECEIVED EVENT:" << eventType << timeStamp << data;

    if (eventType == u"state_changed") {
        return handleStateChanged(timeStamp,  data[u"entity_id"_qs].toString(),
                data[u"new_state"_qs].toMap(),
                data[u"old_state"_qs].toMap());
    }
    return false;
}


bool HomeAssistant::handleStateChanged(const QDateTime &timeStamp, const QString &entityId,
                                        const QVariantMap &newState, const QVariantMap &oldState)
{
    Q_UNUSED(timeStamp)
    Q_UNUSED(oldState)

    m_currentState[entityId] = newState;

    QString state = newState.value(u"state"_qs).toString();
    QJSValue attributes;
    if (auto engine = qmlEngine(this))
        attributes = engine->toScriptValue(newState.value(u"attributes"_qs).toMap());

    for (auto it = m_subscriptions.constFind(entityId);
         (it != m_subscriptions.cend()) && (it.key() == entityId);
         ++it) {
        const QJSValue &v = it.value();
        //qWarning() << "ISC" << entityId << state;
        v.call({ state, attributes });
    }
    return true;
}

void HomeAssistant::connectToWebSocket()
{
    if (!m_ws || (m_ws->state() == QAbstractSocket::UnconnectedState)) {
        createWebSocket();
        qWarning() << "Connecting HomeAssistant WS to" << m_webSocketUrl;
        m_ws->open(m_webSocketUrl);
    }
}

