// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import HAiQ
import Ui


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
