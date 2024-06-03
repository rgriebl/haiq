# Copyright (C) 2004-2024 Robert Griebl
# SPDX-License-Identifier: GPL-3.0-only

configure_file(version.h.in generated/version.h @ONLY)
include_directories(${CMAKE_CURRENT_BINARY_DIR}/generated)
target_include_directories(${PROJECT_NAME} PRIVATE ${CMAKE_CURRENT_BINARY_DIR}/generated)

target_include_directories(${PROJECT_NAME} PRIVATE .)

target_sources(${PROJECT_NAME} PUBLIC
    version.h.in

    main.cpp
    configuration.h
    configuration.cpp
    exception.h
    exception.cpp

    qtsingleapplication/qtsingleapplication.cpp
    qtsingleapplication/qtlocalpeer.cpp
    qtsingleapplication/qtsingleapplication.h
    qtsingleapplication/qtlocalpeer.h
)

qt_add_library(haiq_module STATIC
    screenbrightness/screenbrightness.h
    screenbrightness/screenbrightness.cpp

    squeezebox/squeezeboxserver.h
    squeezebox/squeezeboxserver.cpp

    xbrowsersync/xbrowsersync.h
    xbrowsersync/xbrowsersync.cpp
    xbrowsersync/lzutf8.h
    xbrowsersync/lzutf8.cpp
    xbrowsersync/aes.h
    xbrowsersync/aes.c
    xbrowsersync/gcm.h
    xbrowsersync/gcm.c

    calendar/calendar.h
    calendar/calendar.cpp
    calendar/icalendarparser.h
    calendar/icalendarparser.cpp

    homeassistant/homeassistant.h
    homeassistant/homeassistant.cpp
)

qt_add_qml_module(haiq_module
    URI HAiQ
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/imports/HAiQ
    IMPORT_PATH ${CMAKE_BINARY_DIR}/imports
    NO_PLUGIN
    RESOURCE_PREFIX /
    #ENABLE_TYPE_COMPILER
    DEPENDENCIES
        QtQuick
    IMPORTS
        QtQml
        QtQuick
        QtQuick.Layouts
        QtQuick.Shapes
        ${QUICK_CONTROLS}
    SOURCES
        qml_registration.cpp
        qml_registration.h
)

add_subdirectory(qml)

target_link_libraries(haiq_module PUBLIC
    Qt6::Core
    Qt6::Gui
    Qt6::GuiPrivate
    Qt6::Qml
    Qt6::Quick
    Qt6::QuickControls2
    Qt6::Widgets
    Qt6::WebSockets
)

if (MODELTEST)
    target_link_libraries(${PROJECT_NAME} PRIVATE Qt6::Test)
endif()

target_link_libraries(${PROJECT_NAME} PRIVATE haiq_module ui_module)
