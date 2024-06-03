// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

#pragma once
#include <QQmlEngine>

#include "homeassistant/homeassistant.h"
#include "screenbrightness/screenbrightness.h"
#include "squeezebox/squeezeboxserver.h"
#include "calendar/calendar.h"
#include "xbrowsersync/xbrowsersync.h"

class ForeignXBrowserSync
{
    Q_GADGET
    QML_FOREIGN(XBrowserSync)
    QML_NAMED_ELEMENT(XBrowserSync)
    QML_SINGLETON
public:
    static XBrowserSync *create(QQmlEngine *, QJSEngine *)
    {
        QQmlEngine::setObjectOwnership(XBrowserSync::instance(), QQmlEngine::CppOwnership);
        return XBrowserSync::instance();
    }
};

class ForeignHomeAssistant
{
    Q_GADGET
    QML_FOREIGN(HomeAssistant)
    QML_NAMED_ELEMENT(HomeAssistant)
    QML_SINGLETON
public:
    static HomeAssistant *create(QQmlEngine *, QJSEngine *)
    {
        QQmlEngine::setObjectOwnership(HomeAssistant::instance(), QQmlEngine::CppOwnership);
        return HomeAssistant::instance();
    }
};

class ForeignScreenBrightness
{
    Q_GADGET
    QML_FOREIGN(ScreenBrightness)
    QML_NAMED_ELEMENT(ScreenBrightness)
    QML_SINGLETON
public:
    static ScreenBrightness *create(QQmlEngine *, QJSEngine *)
    {
        QQmlEngine::setObjectOwnership(ScreenBrightness::instance(), QQmlEngine::CppOwnership);
        return ScreenBrightness::instance();
    }
};

class ForeignCalendar
{
    Q_GADGET
    QML_FOREIGN(Calendar)
    QML_NAMED_ELEMENT(Calendar)
    QML_SINGLETON
public:
    static Calendar *create(QQmlEngine *, QJSEngine *)
    {
        QQmlEngine::setObjectOwnership(Calendar::instance(), QQmlEngine::CppOwnership);
        return Calendar::instance();
    }
};

class ForeignUpcomingCalendarEntries
{
    Q_GADGET
    QML_FOREIGN(UpcomingCalendarEntries)
    QML_NAMED_ELEMENT(UpcomingCalendarEntries)
};

class ForeignSqueezeBoxServer
{
    Q_GADGET
    QML_FOREIGN(SqueezeBoxServer)
    QML_NAMED_ELEMENT(SqueezeBoxServer)
    QML_SINGLETON
public:
    static SqueezeBoxServer *create(QQmlEngine *, QJSEngine *)
    {
        QQmlEngine::setObjectOwnership(SqueezeBoxServer::instance(), QQmlEngine::CppOwnership);
        return SqueezeBoxServer::instance();
    }
};

