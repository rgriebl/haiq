# Copyright (C) 2017-2024 Robert Griebl
# SPDX-License-Identifier: GPL-3.0-only

qt_add_qml_module(ui_module
    STATIC
    URI Ui
    VERSION 1.0
    OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/imports/Ui
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

    QML_FILES
        AlarmPage.qml
        BedsideAlarm.qml
        BedsideDayPicker.qml
        BedsidePage.qml
        BedsideSelectPlayer.qml
        BedsideTimePicker.qml
        BedsideView.qml
        BlindsControl.qml
        BrowserPage.qml
        CalendarEvents.qml
        ColorSettings.qml
        CurveLine.qml
        DialButton.qml
        DigitalClock.qml
        DimmerControl.qml
        FPSMeter.qml
        GoogleMapsDistance.qml
        HereMapsDistance.qml
        HomeAssistantPage.qml
        IncomingCall.qml
        KitchenMail.qml
        KitchenPage.qml
        KitchenTimer.qml
        KitchenTrashIcon.qml
        KitchenView.qml
        LivingRoomLaptopView.qml
        LivingRoomPage.qml
        LivingRoomPage2.qml
        LivingRoomView.qml
        MenuDrawer.qml
        OfficeView.qml
        PrinterView.qml
        PullToRefreshListHeader.qml
        RoundIconButton.qml
        SceneButton.qml
        SceneLabel.qml
        SceneSlider.qml
        SceneSpinBox.qml
        Setup.qml
        SqueezeBoxRadio.qml
        SqueezeBoxSettings.qml
        SqueezeBoxVolume.qml
        StackPage.qml
        SvgIcon.qml
        TabletView.qml
        TemperatureProbe.qml
        TerracePage.qml
        Tile.qml
        Tracer.qml
        TrainDepartures.qml
        WeatherDailyDelegate.qml
        WeatherHourlyDelegate.qml
        WeatherPage.qml
        WeatherTemperatureLabel.qml
        WebTab.qml
        WebTabBar.qml
        WebTabButton.qml
        WebTabStack.qml
        WebToolButton.qml
)
