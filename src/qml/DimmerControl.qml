// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import HAiQ
import Ui


GroupBox {
    id: dimmer

    property string entity
    property int currentBrightness

    function setBrightness(brightness) {
        HomeAssistant.callService((brightness ? "light.turn_on" : "light.turn_off"), entity,
                                   (brightness ? { brightness_pct: brightness } : { }))
    }

    Component.onCompleted: {
        HomeAssistant.subscribe(entity, function(state, attributes) {
            currentBrightness = state === "off" ? 0 : attributes.brightness * 100 / 255
        })
    }

     DialButton {
        anchors.centerIn: parent
        value: dimmer.currentBrightness
        dialColor: "yellow"
        icon.name: 'fa/lightbulb-solid'
        scale: 3

        onClicked: dimmer.setBrightness(dimmer.currentBrightness ? 0 : 100)
        onMoved: brightnessTimer.restart()

        // we need to throttle updates, otherwise we will overflow the MQTT stack in the ESP
        // 200ms between updates seems to work well.
        Timer {
            id: brightnessTimer
            interval: 200
            onTriggered: dimmer.setBrightness(parent.position)
        }
    }
}
