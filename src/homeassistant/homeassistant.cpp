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

#define qSL(x) QStringLiteral(x)
#define qL1S(x) QLatin1String(x)


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

void HomeAssistant::registerQmlTypes()
{
    qmlRegisterSingletonType<HomeAssistant>("org.griebl.haiq", 1, 0, "HomeAssistant",
                                           [](QQmlEngine *engine, QJSEngine *) -> QObject * {
        s_instance->m_engine = engine;
        QQmlEngine::setObjectOwnership(instance(), QQmlEngine::CppOwnership);
        return instance();
    });
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
        m_webSocketUrl.setScheme(qSL("ws"));
    else if (m_webSocketUrl.scheme() == u"https")
        m_webSocketUrl.setScheme(qSL("wss"));


    m_states.emplace_back(State::Connected, qSL("auth_ok"), [this](const QJsonObject &) {
        getInitialState();
        return State::Authenticated;
    });
    m_states.emplace_back(State::Connected, qSL("auth_required"), [this](const QJsonObject &) {
        authenticate();
        return State::AuthenticationSent;
    });
    m_states.emplace_back(State::AuthenticationSent, qSL("auth_invalid"), [](const QJsonObject &message) {
        qWarning() << "Authentication failed:" << message.value(qSL("message")).toString();
        return State::AuthenticationFailed;
    });
    m_states.emplace_back(State::AuthenticationSent, qSL("auth_ok"), [this](const QJsonObject &) {
        getInitialState();
        return State::Authenticated;
    });
    m_states.emplace_back(State::Authenticated, qSL("result"), [this](const QJsonObject &message) {
        if (message[qSL("id")].toInt() != m_initialStateId) {
            qWarning() << "Ignoring result id" << message[qSL("id")].toInt()
                       << "while waiting for initial state id" << m_initialStateId;
            return State::Authenticated;
        } else if (!message[qSL("success")].toBool()) {
            qWarning() << "Getting the initial state failed:"
                       << QJsonDocument(message).toJson().constData();
            return State::InitialStateFailed;
        } else {
            parseInitialState(message[qSL("result")].toArray().toVariantList());
            subscribeToStateChange();
            return State::InitialStateReceived;
        }
    });
    m_states.emplace_back(State::InitialStateReceived, qSL("result"), [this](const QJsonObject &message) {
        if (message[qSL("id")].toInt() != m_subscriptionId) {
            qWarning() << "Ignoring result id" << message[qSL("id")].toInt()
                       << "while waiting for subscription id" << m_subscriptionId;
            return State::InitialStateReceived;
        }
        else if (!message[qSL("success")].toBool()) {
            qWarning() << "Subscription failed:"
                       << message[qSL("error")].toObject()[qSL("message")].toString();
            return State::SubscriptionFailed;
        } else {
            emit connected();
            m_pingTimer.start(m_timeoutPing, this);
            return State::Subscribed;
        }
    });
    m_states.emplace_back(State::Subscribed, qSL("event"), [this](const QJsonObject &message) {
        if (message[qSL("id")].toInt() != m_subscriptionId) {
            qWarning() << "Ignoring event id" << message[qSL("id")].toInt()
                       << "while waiting for subscription id" << m_subscriptionId;
        } else {
            const QJsonObject event = message[qSL("event")].toObject();
            const QString eventType = event[qSL("event_type")].toString();
            const QDateTime firedAt = QDateTime::fromString(event[qSL("time_fired")].toString(), Qt::ISODateWithMs);

            if (!handleEvent(eventType, firedAt, event[qSL("data")].toObject().toVariantMap())) {
//                qWarning() << "Event was not handled: type =" << eventType << "\n"
//                           << QJsonDocument(message).toJson().constData();
            }
        }
        return State::Subscribed;
    });
    m_states.emplace_back(State::Subscribed, qSL("result"), [](const QJsonObject &message) {
        if (!message[qSL("success")].toBool())
            qWarning() << "service call" << message[qSL("id")].toInt() << "failed:"
                       << message[qSL("error")].toObject()[qSL("message")].toString();
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
        QString type = root.value(qSL("type")).toString();

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
                m_ws->close(QWebSocketProtocol::CloseCodeProtocolError, qSL("Invalid client state"));
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
        serviceData.insert(qSL("entity_id"), entities);

    QJsonDocument doc {{
            { qSL("id"), m_nextId++ },
            { qSL("type"), qSL("call_service") },
            { qSL("domain"), serviceDomain },
            { qSL("service"), serviceName },
            { qSL("service_data"), QJsonValue::fromVariant(serviceData) }
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
        m_ws->close(QWebSocketProtocol::CloseCodeMissingStatusCode, qSL("No pong received"));
    }
}

void HomeAssistant::authenticate()
{
    QJsonDocument doc {{
            { qSL("type"), qSL("auth") },
            { qSL("access_token"), m_authenticationToken }
                       }};
    if (m_ws)
        m_ws->sendTextMessage(QString::fromUtf8(doc.toJson()));
}

void HomeAssistant::subscribeToStateChange()
{
    m_subscriptionId = m_nextId++;
    QJsonDocument doc {{
            { qSL("id"), m_subscriptionId },
            { qSL("type"), qSL("subscribe_events") }/*,
            { qSL("event_type"), qSL("state_changed") }*/
                       }};
    if (m_ws)
        m_ws->sendTextMessage(QString::fromUtf8(doc.toJson()));
}

void HomeAssistant::getInitialState()
{
    m_initialStateId = m_nextId++;
    QJsonDocument doc {{
            { qSL("id"), m_initialStateId },
            { qSL("type"), qSL("get_states") },
                       }};
    if (m_ws)
        m_ws->sendTextMessage(QString::fromUtf8(doc.toJson()));
}

void HomeAssistant::parseInitialState(const QVariantList &states)
{
    QDateTime now = QDateTime::currentDateTime();

    for (const auto &s : states) {
        QVariantMap state = s.toMap();
        //qWarning() << "IS" << state[qSL("entity_id")].toString() << state[qSL("state")].toString();

        handleStateChanged(now, state[qSL("entity_id")].toString(), state, QVariantMap());
    }
}

bool HomeAssistant::handleEvent(const QString &eventType, const QDateTime &timeStamp,
                                 const QVariantMap &data)
{
    //qWarning() << "RECEIVED EVENT:" << eventType << timeStamp << data;

    if (eventType == u"state_changed") {
        return handleStateChanged(timeStamp,  data[qSL("entity_id")].toString(),
                data[qSL("new_state")].toMap(),
                data[qSL("old_state")].toMap());
    }
    return false;
}


bool HomeAssistant::handleStateChanged(const QDateTime &timeStamp, const QString &entityId,
                                        const QVariantMap &newState, const QVariantMap &oldState)
{
    Q_UNUSED(timeStamp)
    Q_UNUSED(oldState)

    m_currentState[entityId] = newState;

    QString state = newState.value(qSL("state")).toString();
    QJSValue attributes;
    if (m_engine)
        attributes = m_engine->toScriptValue(newState.value(qSL("attributes")).toMap());

    for (auto it = m_subscriptions.constFind(entityId);
         (it != m_subscriptions.cend()) && (it.key() == entityId);
         ++it) {
        QJSValue v = it.value();
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

