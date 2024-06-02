// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.griebl.haiq 1.0


Control {
    id: root

    property string label
    property string entity
    property date lastUpdate

    padding: font.pixelSize / 2

    WeatherTemperatureLabel {
        anchors.centerIn: parent
        temperature: 0
        highTemperature: 100
        opacity: temperature === 0 ? 0 : 1
        font: root.font

        Component.onCompleted: {
            HomeAssistant.subscribe(entity, function(state, attributes) {
                temperature = state
                root.lastUpdate = new Date()
            })
        }
    }
}
