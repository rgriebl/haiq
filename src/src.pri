INCLUDEPATH += $$PWD
DEPENDPATH += $$PWD

QT = core gui gui-private qml quick websockets qml-private svg quickcontrols2

haiq_use_webengine {
  QT *= webenginequick
  DEFINES *= HAIQ_USE_WEBENGINE
}

haiq_use_multimedia {
  QT *= multimedia
  DEFINES *= HAIQ_USE_MULTIMEDIA
}


include(homeassistant/homeassistant.pri)
include(squeezebox/squeezebox.pri)
include(calendar/calendar.pri)
include(screenbrightness/screenbrightness.pri)
include(xbrowsersync/xbrowsersync.pri)
include(qtsingleapplication/qtsingleapplication.pri)

HEADERS += \
    $$PWD/configuration.h \
    $$PWD/exception.h \
    $$PWD/appstarter.h \

SOURCES += \
    $$PWD/configuration.cpp \
    $$PWD/main.cpp \
    $$PWD/exception.cpp \
    $$PWD/appstarter.cpp \

OTHER_FILES += \
    $$PWD/version.h.in
