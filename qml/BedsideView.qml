/* Copyright (C) 2017-2022 Robert Griebl. All rights reserved.
**
** This file is part of HAiQ.
**
** This file may be distributed and/or modified under the terms of the GNU
** General Public License version 2 as published by the Free Software Foundation
** and appearing in the file LICENSE.GPL included in the packaging of this file.
**
** This file is provided AS IS with NO WARRANTY OF ANY KIND, INCLUDING THE
** WARRANTY OF DESIGN, MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
**
** See http://fsf.org/licensing/licenses/gpl.html for GPL licensing information.
*/
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import org.griebl.haiq 1.0


TabletView {
    id: root

    screenWidth: 800
    screenHeight: 480

    font.family: "Noto Sans"
    font.weight: Font.Black
    font.pixelSize: height / 10

    property Component defaultOverlay: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.8)
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    color: 'black'
    background: null

    menuFontPixelSize: root.font.pixelSize / 2

    StackView {
        id: mainStack
        anchors.fill: parent

        initialItem: BedsidePage { }
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onDoubleClicked: ScreenBrightness.blank()
    }

    Connections {
        target: incomingCall
        function onVisibleChanged() {
            if (incomingCall.visible)
                ScreenBrightness.unblank()
        }
    }

    Connections {
        target: SqueezeBoxServer.thisPlayer
        function onAlarmSounding(sounding) {
            if (sounding)
                ScreenBrightness.unblank()
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
