INCLUDEPATH += $$PWD
DEPENDPATH += $$PWD

QT = core gui gui-private qml quick websockets qml-private multimedia svg quickcontrols2

include(homeassistant/homeassistant.pri)
include(squeezebox/squeezebox.pri)
include(calendar/calendar.pri)
include(screenbrightness/screenbrightness.pri)
include(xbrowsersync/xbrowsersync.pri)
include(qtsingleapplication/qtsingleapplication.pri)

HEADERS += \
    $$PWD/configuration.h \
    $$PWD/exception.h \

SOURCES += \
    $$PWD/configuration.cpp \
    $$PWD/main.cpp \
    $$PWD/exception.cpp \

OTHER_FILES += \
    $$PWD/version.h.in
