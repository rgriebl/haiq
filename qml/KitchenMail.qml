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
