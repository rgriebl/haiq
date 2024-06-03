// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import HAiQ
import Ui


TabletView {
    id: root

    screenWidth: 800
    screenHeight: 480

    font.family: "Noto Sans"
    font.weight: Font.Black
    font.pixelSize: height / 10

    color: 'black'
    background: null

    menuFontPixelSize: root.font.pixelSize / 2

    StackView {
        id: mainStack
        anchors.fill: parent

        initialItem: BedsidePage {
            mainStack: mainStack
            blindsEntity: Config.coverEntity || "cover.schlafzimmer_rollladen"
            ceilingLightEntity: Config.lights[0].entity || "switch.schlafzimmer_licht"
            ceilingLightIcon: Config.lights[0].icon || 'fa/lightbulb-solid'
            wardrobeLightEntity: Config.lights[1].entity || "switch.schlafzimmer_schranklicht"
            wardrobeLightIcon: Config.lights[1].icon || 'fa/tshirt-solid'
        }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onDoubleClicked: ScreenBrightness.blank = true
    }

    Connections {
        target: root.incomingCall
        function onVisibleChanged() {
            if (root.incomingCall.visible)
                ScreenBrightness.blank = false
        }
    }

    Connections {
        target: SqueezeBoxServer.thisPlayer
        function onAlarmSounding(sounding) {
            if (sounding)
                ScreenBrightness.blank = false
        }
    }

    Component.onCompleted: {
        ScreenBrightness.brightness = 0.8
        ScreenBrightness.normalBrightness = 0.4
        ScreenBrightness.dimBrightness = 0.4
        ScreenBrightness.dimTimeout = 20
        ScreenBrightness.blankTimeout = 40

        ScreenBrightness.minimumBrightness = 11/255 // values below 11 blank the RPI 7" touchscreen
        ScreenBrightness.maximumBrightness = 0.8

        ScreenBrightness.screenSaverActive = true

        HomeAssistant.subscribe("sun.sun", function(state, attributes) {
            var light = Math.min(Math.max(attributes.elevation / 45, 0), 1)

            var factor = light * 0.9 + 0.1

            console.warn("setting new factor " + factor)

            ScreenBrightness.normalBrightness = 0.8 * factor
            ScreenBrightness.dimBrightness = 0.4 * factor

        })
    }
}
