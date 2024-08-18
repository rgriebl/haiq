// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

#include <QGuiApplication>
#include <QEvent>
#include <QStringBuilder>
#include <QVariantAnimation>
#include <QFile>
#include <QThread>
#include <QDebug>
#include <QQuickWindow>
#include <QQuickItem>
#include <QDir>
#include <QScreen>
#include <qpa/qplatformscreen.h>

#include "screenbrightness.h"


ScreenBrightness *ScreenBrightness::s_instance = nullptr;

ScreenBrightness *ScreenBrightness::instance()
{
    return s_instance;
}

ScreenBrightness *ScreenBrightness::createInstance(const QString &options, QObject *parent)
{
    if (Q_UNLIKELY(s_instance))
        qFatal("ScreenBrightness::createInstance() was called a second time.");

    s_instance = new ScreenBrightness(options, parent);

    return s_instance;
}

ScreenBrightness::ScreenBrightness(const QString &options, QObject *parent)
    : QObject(parent)
{
    if (options == u"off" || options == u"0" || options == u"disable")
        return;
#if !defined(Q_OS_LINUX)
    return;
#endif

    QString backlightDevice;
    bool forceBlank = false;
    QString ddcDevice;
    uint ddcVcp = 0x10; // luminance

    QStringList optionList = options.split(u':', Qt::SkipEmptyParts);

    if (optionList.isEmpty() || optionList.constFirst() == u"backlight") {
        QString backlightPath(u"/sys/class/backlight/"_qs);

        for (int i = 1; i < optionList.size(); ++i) {
            if (optionList.at(i).startsWith(backlightPath)) {
                backlightDevice = optionList.at(1);
            } else if (optionList.at(i) == u"force-blank") {
                forceBlank = true;
            }
        }
        if (backlightDevice.isEmpty()) {
            auto backlights = QDir(backlightPath).entryList(QDir::Dirs | QDir::NoDotAndDotDot);
            if (!backlights.isEmpty())
                backlightDevice = backlightPath + backlights.at(0);
        }
        if (backlightDevice.isEmpty()) {
            qWarning() << "Brightness control via" << backlightPath << "was requested, but no suitable device is available";
        }
    } else if (optionList.constFirst() == u"ddc") {
        for (int i = 1; i < optionList.size(); ++i) {
            if (optionList.at(i).startsWith(u"/dev/")) {
                ddcDevice = optionList.at(1);
            } else if (optionList.at(i) == u"force-blank") {
                forceBlank = true;
            } else if (optionList.at(i).startsWith(u"vcp=")) {
                bool ok = false;
                uint vcp = optionList.at(i).section(u'=', 1, 1).toUInt(&ok, 0);
                if (ok)
                    ddcVcp = vcp;
            }
        }
        if (ddcDevice.isEmpty()) {
            qWarning() << "Brightness control via DDC was requested, but no suitable device is available";
        }
    }

    qApp->installEventFilter(this);

    if (!ddcDevice.isEmpty()) {
        int maxBrightness = -1;

        {
            QFile ddc(ddcDevice);
            if (ddc.open(QIODevice::ReadWrite | QIODevice::Unbuffered)) {
                QByteArray msg(2, 0);
                msg[0] = 0x01; // get vcp
                msg[1] = char(ddcVcp & 0xff);
                ddc.write(msg);
                QThread::msleep(100);
                QByteArray response = ddc.read(8);
                if (response.size() != 8) {
                    qWarning() << "DDC response size is not 8 bytes";
                    maxBrightness = 100;
                } else {
                    maxBrightness = int(uint(response.at(4)) << 8 | uint(response.at(5)));
                }
            }
        }

        qWarning() << "Brightness control via DDC:" << ddcDevice
                   << "- max brightness:" << maxBrightness
                   << "- force blank:" << forceBlank
                   << "- VCP:" << Qt::hex << ddcVcp;

        QObject::connect(this, &ScreenBrightness::effectiveBrightnessChanged,
                         this, [maxBrightness, ddcVcp, ddcDevice, forceBlank](qreal brightness) {
            qDebug() << "Setting effective brightness to" << brightness
                     << "(in hw units:" << qBound(0, int(maxBrightness * brightness), maxBrightness) << ")";

            QFile ddc(ddcDevice);
            if (ddc.open(QIODevice::ReadWrite | QIODevice::Unbuffered)) {
                int b = qBound(0, int(maxBrightness * brightness), maxBrightness);
                QByteArray msg(4, 0);
                msg[0] = 0x03; // set vcp
                msg[1] = char(ddcVcp & 0xff);
                msg[2] = char((b >> 8) & 0xff);
                msg[3] = char(b & 0xff);
                ddc.write(msg);
                ddc.close();

                if (forceBlank) {
                    QScreen *s = qApp->primaryScreen();
                    auto currentState = s->handle()->powerState();
                    auto newState = b ? QPlatformScreen::PowerStateOn
                                      : QPlatformScreen::PowerStateStandby;

                    if (currentState != newState) {
                        // we need to stop the rendering during standby, because KMS/DRM will not
                        // accept page flips int this state, leading to qWarnings for each frame
                        // QML is trying to render
                        qWarning() << "Monitor power state:" << (b ? "on" : "standby");

                        const auto windows = qApp->allWindows();
                        for (auto &window : windows) {
                            if (auto quickWindow = qobject_cast<QQuickWindow *>(window)) {
                                quickWindow->contentItem()->setOpacity(b ? 1 : 0);
                            }
                        }

                        s->handle()->setPowerState(newState);
                    }
                }
            }
        });
    } else if (!backlightDevice.isEmpty()) {
        int maxBrightness = -1;

        {
            QFile maxBrightnessFile(backlightDevice + u"/max_brightness"_qs);
            if (maxBrightnessFile.open(QIODevice::ReadOnly))
                maxBrightness = maxBrightnessFile.readAll().toInt();
        }

        qWarning() << "Brightness control via:" << backlightDevice
                   << "- max brightness:" << maxBrightness
                   << "- force blank:" << forceBlank;

        QObject::connect(this, &ScreenBrightness::effectiveBrightnessChanged,
                         this, [maxBrightness, forceBlank, backlightDevice](qreal brightness) {

//            qDebug() << "Setting effective brightness to" << brightness
//                     << "(in hw units:" << qBound(0, int(maxBrightness * brightness), maxBrightness) << ")";

            QFile brightnessFile(backlightDevice + u"/brightness"_qs);
            if (brightnessFile.open(QIODevice::ReadWrite | QIODevice::Unbuffered)) {
                QByteArray data = QByteArray::number(qBound(0, int(maxBrightness * brightness), maxBrightness)) + '\n';
                brightnessFile.write(data);
                brightnessFile.close();

                if (forceBlank) {
                    QFile blankFile(backlightDevice + u"/device/graphics/fb0/blank"_qs);
                    if (blankFile.open(QIODevice::ReadWrite | QIODevice::Unbuffered)) {
                        QByteArray blankData = qFuzzyIsNull(brightness) ? "1\n" : "0\n";
                        blankFile.write(blankData);
                        blankFile.close();
                    }
                }
            }
        });
    }
}


ScreenBrightness::~ScreenBrightness()
{
    qApp->removeEventFilter(this);
}

bool ScreenBrightness::isScreenSaverActive() const
{
    return m_screenSaverActive;
}

int ScreenBrightness::dimTimeout() const
{
    return m_dimTimeout;
}

int ScreenBrightness::blankTimeout() const
{
    return m_blankTimeout;
}

qreal ScreenBrightness::normalBrightness() const
{
    return m_normalBrightness;
}

qreal ScreenBrightness::brightness() const
{
    return m_brightness;
}

qreal ScreenBrightness::dimBrightness() const
{
    return m_dimBrightness;
}

qreal ScreenBrightness::minimumBrightness() const
{
    return m_minimumBrightness;
}

qreal ScreenBrightness::maximumBrightness() const
{
    return m_maximumBrightness;
}

bool ScreenBrightness::isBlanked() const
{
    return m_screenSaverActive && (m_screenSaverState == IsBlanked);
}

void ScreenBrightness::setSetScreenSaverActive(bool active)
{
    if (m_screenSaverActive != active) {
        m_screenSaverActive = active;
        emit screenSaverActiveChanged(m_screenSaverActive);

        if (active)
            setBrightness(m_normalBrightness);
        setScreenSaverState(IsActive);
    }
}

void ScreenBrightness::setDimTimeout(int dimTimeout)
{
    if (dimTimeout < 0)
        dimTimeout = 0;

    if (m_dimTimeout != dimTimeout) {
        m_dimTimeout = dimTimeout;
        emit dimTimeoutChanged(m_dimTimeout);

        // restart the timers
        setScreenSaverState(dimTimeout ? m_screenSaverState : IsActive);
    }
}

void ScreenBrightness::setBlankTimeout(int blankTimeout)
{
    if (blankTimeout < 0)
        blankTimeout = 0;
    if (blankTimeout && (blankTimeout <= m_dimTimeout)) {
        qWarning() << "Blank timeout cannot be smaller than dim timeout";
        return;
    }

    if (m_blankTimeout != blankTimeout) {
        m_blankTimeout = blankTimeout;
        emit blankTimeoutChanged(m_blankTimeout);

        // restart the timers
        setScreenSaverState(blankTimeout ? m_screenSaverState : IsActive);
    }
}

void ScreenBrightness::setBrightness(qreal brightness)
{
    if (!qIsNull(brightness))
        brightness = qBound(minimumBrightness(), brightness, maximumBrightness());

    if (!qFuzzyCompare(brightness, m_brightness)) {
        if (!m_brightnessAnimation) { // lazy allocation
            m_brightnessAnimation = new QVariantAnimation(this);
            m_brightnessAnimation->setEasingCurve(QEasingCurve(QEasingCurve::OutCubic));
            connect(m_brightnessAnimation, &QVariantAnimation::valueChanged,
                    this, [this](const QVariant &value) {
                emit effectiveBrightnessChanged(value.toReal());
            });
        }

        if (m_brightnessAnimation->state() == QAbstractAnimation::Running)
            m_brightnessAnimation->stop();

        // dim up in 500 msec / dim down in 2000 msec
        m_brightnessAnimation->setDuration(m_brightness < brightness ? 500 : 2000);
        m_brightnessAnimation->setStartValue(m_brightness);
        m_brightnessAnimation->setEndValue(brightness);

        m_brightnessAnimation->start();
        m_brightness = brightness;
        emit brightnessChanged(m_brightness);
    }
}

void ScreenBrightness::setNormalBrightness(qreal normalBrightness)
{
    if (!qFuzzyCompare(m_normalBrightness, normalBrightness)) {
        m_normalBrightness = normalBrightness;
        emit normalBrightnessChanged(m_normalBrightness);
    }
}

void ScreenBrightness::setDimBrightness(qreal dimBrightness)
{
    if (!qFuzzyCompare(m_dimBrightness, dimBrightness)) {
        m_dimBrightness = dimBrightness;
        emit dimBrightnessChanged(m_dimBrightness);
    }
}

void ScreenBrightness::setMinimumBrightness(qreal minimumBrightness)
{
    if (!qFuzzyCompare(m_minimumBrightness, minimumBrightness)) {
        m_minimumBrightness = minimumBrightness;
        emit minimumBrightnessChanged(m_minimumBrightness);
    }
}

void ScreenBrightness::setMaximumBrightness(qreal maximumBrightness)
{
    if (!qFuzzyCompare(m_maximumBrightness, maximumBrightness)) {
        m_maximumBrightness = maximumBrightness;
        emit maximumBrightnessChanged(m_maximumBrightness);
    }
}

void ScreenBrightness::blank(bool on)
{
    if (m_screenSaverActive) {
        if (on && (m_screenSaverState != IsBlanked))
            setScreenSaverState(IsBlanked);
        else if (!on && (m_screenSaverState == IsBlanked))
            setScreenSaverState(IsActive);
    }
}

bool ScreenBrightness::eventFilter(QObject *watched, QEvent *event)
{
    if (watched && event && isScreenSaverActive()) {
        switch (event->type()) {
        case QEvent::KeyPress:
        case QEvent::MouseButtonPress:
        case QEvent::MouseMove:
        case QEvent::TouchBegin: {
            bool wasBlanked = (m_screenSaverState == IsBlanked);
            setScreenSaverState(IsActive);
            if (wasBlanked)
                return true; // eat the wake-up event
            break;
        }
        default:
            break;
        }
    }
    return QObject::eventFilter(watched, event);
}

void ScreenBrightness::timerEvent(QTimerEvent *event)
{
    if (!event || !event->timerId())
        return;
    else if (event->timerId() == m_dimTimer)
        setScreenSaverState(IsDimmed);
    else if (event->timerId() == m_blankTimer)
        setScreenSaverState(IsBlanked);
    else
        QObject::timerEvent(event);
}

void ScreenBrightness::setScreenSaverState(ScreenBrightness::ScreenSaverState newState)
{
    // kill all timers
    if (m_dimTimer) {
        killTimer(m_dimTimer);
        m_dimTimer = 0;
    }
    if (m_blankTimer) {
        killTimer(m_blankTimer);
        m_blankTimer = 0;
    }

    qreal newBrightness = 1;

    if (m_screenSaverActive) {
        // restart relevant timers
        switch (newState) {
        case IsActive:
            if (m_dimTimeout)
                m_dimTimer = startTimer(m_dimTimeout * 1000);
            else if (m_blankTimeout)
                m_blankTimer = startTimer(m_blankTimeout * 1000);
            newBrightness = m_normalBrightness;
            break;

        case IsDimmed:
            if (m_blankTimeout)
                m_blankTimer = startTimer((m_blankTimeout - m_dimTimeout) * 1000);
            newBrightness = m_dimBrightness;
            break;

        case IsBlanked:
            newBrightness = 0;
            break;
        }
    } else {
        newBrightness = m_normalBrightness;
    }

    if (m_screenSaverState != newState) {
        //qDebug() << "Screensaver state change from" << m_screenSaverState << "to" << newState
        //           << "(brightness:" << newBrightness << ")";

        if (m_screenSaverState == IsBlanked || newState == IsBlanked)
            QMetaObject::invokeMethod(this, &ScreenBrightness::blankChanged);

        m_screenSaverState = newState;
    }
    setBrightness(newBrightness);
}
