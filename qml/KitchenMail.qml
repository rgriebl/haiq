// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import org.griebl.haiq 1.0


Control {
    id: root

    RowLayout {
        spacing: 0
        anchors.fill: parent

        SvgIcon {
            id: post

            property string state: "no"

            property var stateMap: {
                'no':  { 'color': "#222222", 'icon': "email" },
                'yes': { 'color': "#ffff00", 'icon': "email" },
                'big': { 'color': "#ffff00", 'icon': "email-open" },
            }

            icon: '../icons/mdi/' + stateMap[state].icon
            color: stateMap[state].color
            Layout.fillWidth: true
            size: 3 * root.font.pixelSize

            Component.onCompleted: {
                HomeAssistant.subscribe("sensor.mailbox", function(state, attributes) {
                    post.state = (state === 'yes') ? ((attributes.big === 'yes') ? 'big' : 'yes')
                                                   : 'no'
                })
            }
        }

        SvgIcon {
            id: battery
            property string batteriesState
            property bool batteriesOk: true

            onBatteriesStateChanged: {
                batteriesOk = (batteriesState === '' || batteriesState === 'alle OK')
            }

            icon: '../icons/mdi/battery-low'
            color: batteriesOk ? "#222222" : "#ff0000"
            Layout.fillWidth: true
            size: 3 * root.font.pixelSize
        }
    }
}
