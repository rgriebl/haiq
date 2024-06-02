// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

#pragma once

#include <QObject>
#include <QUrl>
#include <QBasicTimer>
#include <QDateTime>
#include <QMultiMap>
#include <QString>
#include <QJSValue>
#include <QVariantMap>
#include <QPointer>

#include <functional>
#include <tuple>


QT_FORWARD_DECLARE_CLASS(QWebSocket)
QT_FORWARD_DECLARE_CLASS(QQmlEngine)


class HomeAssistant : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QUrl baseUrl READ baseUrl CONSTANT)

public:    
    // only public to auto-generate QDebug pretty-printing
    enum class State {
        Disconnected,
        Connected,
        AuthenticationSent,
        AuthenticationFailed,
        Authenticated,
        InitialStateReceived,
        InitialStateFailed,
        SubscriptionFailed,
        Subscribed
    };
    Q_ENUM(State)

    static void registerQmlTypes();

    static HomeAssistant *instance();
    static HomeAssistant *createInstance(const QUrl &homeAssistantUrl,
                                         const QString &authenicationToken, QObject *parent = nullptr);

    void reconnect();
    QUrl baseUrl() const;

    Q_INVOKABLE bool subscribe(const QString &entity, const QJSValue &callback);
    Q_INVOKABLE bool callService(const QString &service, const QString &entity,
                                 const QVariantMap &data = QVariantMap {});
    Q_INVOKABLE bool callService(const QString &service, const QStringList &entities,
                                 const QVariantMap &data = QVariantMap {});

signals:
    void connected();
    void disconnected();

protected:
    void timerEvent(QTimerEvent *te) override;

    void authenticate();
    void subscribeToStateChange();
    void getInitialState();
    void parseInitialState(const QVariantList &states);
    bool handleEvent(const QString &eventType, const QDateTime &timeStamp, const QVariantMap &data);
    bool handleStateChanged(const QDateTime &timeStamp, const QString &entityId, const QVariantMap &newState, const QVariantMap &oldState);

private:
    explicit HomeAssistant(const QUrl &homeAssistantUrl,
                           const QString &authenticationToken, QObject *parent = nullptr);

    static HomeAssistant *s_instance;


    void createWebSocket();
    void connectToWebSocket();

    State m_state = State::Disconnected;
    std::vector<std::tuple<State, QString, const std::function<State(const QJsonObject &)>>> m_states;

    QUrl m_baseUrl;
    QUrl m_webSocketUrl;
    QString m_authenticationToken;
    QWebSocket *m_ws = nullptr;
    QBasicTimer m_pingTimer;
    QBasicTimer m_pongTimer;

    int m_timeoutPing = 10 * 1000;
    int m_timeoutPong = 10 * 1000;
    int m_timeoutReconnect = 10 * 1000;

    int m_nextId = 1;
    int m_subscriptionId = 0;
    int m_initialStateId = 0;
    QMultiMap<QString, QJSValue> m_subscriptions;
    QPointer<QQmlEngine> m_engine;

    QMap<QString, QVariantMap> m_currentState;

    Q_DISABLE_COPY(HomeAssistant)
};
