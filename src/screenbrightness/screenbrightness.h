// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

#pragma once

#include <QObject>

QT_FORWARD_DECLARE_CLASS(QVariantAnimation)

class ScreenBrightness : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool screenSaverActive READ isScreenSaverActive WRITE setSetScreenSaverActive NOTIFY screenSaverActiveChanged)
    Q_PROPERTY(int dimTimeout READ dimTimeout WRITE setDimTimeout NOTIFY dimTimeoutChanged)
    Q_PROPERTY(int blankTimeout READ blankTimeout WRITE setBlankTimeout NOTIFY blankTimeoutChanged)
    Q_PROPERTY(bool blank READ isBlanked WRITE blank NOTIFY blankChanged)
    Q_PROPERTY(qreal brightness READ brightness WRITE setBrightness NOTIFY brightnessChanged)
    Q_PROPERTY(qreal normalBrightness READ normalBrightness WRITE setNormalBrightness NOTIFY normalBrightnessChanged)
    Q_PROPERTY(qreal dimBrightness READ dimBrightness WRITE setDimBrightness NOTIFY dimBrightnessChanged)
    Q_PROPERTY(qreal minimumBrightness READ minimumBrightness WRITE setMinimumBrightness NOTIFY minimumBrightnessChanged)
    Q_PROPERTY(qreal maximumBrightness READ maximumBrightness WRITE setMaximumBrightness NOTIFY maximumBrightnessChanged)

public:
    ~ScreenBrightness();

    static ScreenBrightness *instance();
    static ScreenBrightness *createInstance(const QString &options, QObject *parent = nullptr);

    void initializeWindows();
    void initializeLinux();

    bool isScreenSaverActive() const;
    int dimTimeout() const;
    int blankTimeout() const;
    qreal normalBrightness() const;
    qreal brightness() const;
    qreal dimBrightness() const;
    qreal minimumBrightness() const;
    qreal maximumBrightness() const;
    bool isBlanked() const;

public slots:
    void setSetScreenSaverActive(bool screenSaverActive);
    void setDimTimeout(int dimTimeout);
    void setBlankTimeout(int blankTimeout);
    void setBrightness(qreal brightness);
    void setNormalBrightness(qreal normalBrightness);
    void setDimBrightness(qreal dimBrightness);
    void setMinimumBrightness(qreal minimumBrightness);
    void setMaximumBrightness(qreal maximumBrightness);

    void blank(bool on = true);
    void unblank();

signals:
    void screenSaverActiveChanged(bool screenSaverActive);
    void dimTimeoutChanged(int dimTimeout);
    void blankTimeoutChanged(int blankTimeout);
    void brightnessChanged(qreal brightness);
    void normalBrightnessChanged(qreal normalBrightness);
    void dimBrightnessChanged(qreal dimBrightness);
    void minimumBrightnessChanged(qreal minimumBrightness);
    void maximumBrightnessChanged(qreal maximumBrightness);
    void effectiveBrightnessChanged(qreal effectiveBrightness);
    bool blankChanged();

protected:
    bool eventFilter(QObject *watched, QEvent *event) override;
    void timerEvent(QTimerEvent *event) override;

private:
    static ScreenBrightness *s_instance;

    explicit ScreenBrightness(const QString &options, QObject *parent = nullptr);

    enum ScreenSaverState {
        IsActive,
        IsDimmed,
        IsBlanked
    };
    void setScreenSaverState(ScreenSaverState newState);

    bool m_screenSaverActive = false;

    qreal m_brightness = 1;
    qreal m_minimumBrightness = 0;
    qreal m_maximumBrightness = 1;

    qreal m_normalBrightness = 1;
    qreal m_dimBrightness = 0.5;
    int m_dimTimeout = 0;
    int m_dimTimer = 0;

    int m_blankTimeout = 0;
    int m_blankTimer = 0;

    ScreenSaverState m_screenSaverState = IsActive;

    QVariantAnimation *m_brightnessAnimation = nullptr;
};
