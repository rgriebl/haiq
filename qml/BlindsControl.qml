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
import QtQuick.Window 2.12
import org.griebl.haiq 1.0

GroupBox {
    id: root

    property string entity

    RowLayout {
        anchors.fill: parent

        Slider {
            id: slider

            Layout.fillHeight: true
            Layout.preferredHeight: implicitHeight / 2
            Layout.minimumHeight: Layout.preferredHeight

            rotation: 180
            focusPolicy: Qt.StrongFocus
            wheelEnabled: false // buggy
            live: false
            orientation: Qt.Vertical
            value: 0
            from: 1
            to: 0

            onPressedChanged: {
                if (!pressed) {
                    HomeAssistant.callService("cover.set_cover_position",
                                               root.entity,
                                               { position: position * 100 } )
                }
            }

            Component.onCompleted: {
                HomeAssistant.subscribe(root.entity, function(state, attributes) {
                    value = attributes.current_position / 100;
                })
            }
            Tracer { }
        }

        ColumnLayout {
            Layout.fillHeight: true

            RoundIconButton {
                icon.name: 'fa/angle-double-up-solid'
                scale: 1.7
                onClicked: HomeAssistant.callService("cover.open_cover", root.entity)
                Tracer { }
            }
            RoundIconButton {
                icon.name: 'fa/stop-solid'
                scale: 1.7
                onClicked: HomeAssistant.callService("cover.stop_cover", root.entity)
                Tracer { }
            }
            RoundIconButton {
                icon.name: 'fa/angle-double-down-solid'
                scale: 1.7
                onClicked: HomeAssistant.callService("cover.close_cover", root.entity)
                Tracer { }
            }
        }
    }
}
