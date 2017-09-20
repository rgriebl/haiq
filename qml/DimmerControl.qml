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
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.griebl.haiq 1.0


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

        onClicked: setBrightness(dimmer.currentBrightness ? 0 : 100)
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
