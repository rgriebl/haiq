// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import Qt5Compat.GraphicalEffects
import HAiQ
import Ui


Control {
    id: root
    property string entity
    property bool isBag: false
    property int dueInDays: -1
    property bool isActive: (dueInDays === 0 && new Date().getHours() <= 11) || (dueInDays === 1 && new Date().getHours() >= 17)
    property int wiggleInterval: 3*60  // every 3 minutes
    property alias color: icon.color

    Item {
        anchors.fill: parent

        SvgIcon {
            id: icon
            name: root.isBag ? "fhemsvg/bag" : "fhemsvg/dustbin"
            anchors.centerIn: parent
            size: root.font.pixelSize * 3
            opacity: root.isActive ? 1 : Math.max(1 - root.dueInDays / 28, 0.5)
        }
        Label {
            anchors.right: icon.right
            anchors.bottom: icon.bottom

            function labelText(days) {
                switch (days) {
                case 0: return "Heute"
                case 1: return "Morgen"
                default: return days < 0 ? "" : days
                }
            }

            id: togo
            font.family: root.font.family
            font.pixelSize: root.font.pixelSize * 2 / 3
            text: labelText(root.dueInDays)
            color: "black"
            opacity: 1

            Rectangle {
                z: -1
                anchors.centerIn: parent
                height: parent.height + parent.font.pixelSize / 8
                width: Math.max(height, parent.width + parent.font.pixelSize)
                color: root.color
                opacity: 1
                radius: height / 2
            }
        }

        Component.onCompleted: {
            HomeAssistant.subscribe(root.entity, function(state, attributes) {
                root.dueInDays = state
            })
        }

        ParallelAnimation {
            running: root.isActive
            loops: Animation.Infinite
            SequentialAnimation {
                NumberAnimation {
                    target: icon; property: "rotation"
                    from: 0; to: 20; duration: 100; easing.type: Easing.OutSine
                }
                NumberAnimation {
                    target: icon; property: "rotation"
                    from: 20; to: -20; duration: 200; easing.type: Easing.InOutSine
                }
                NumberAnimation {
                    target: icon; property: "rotation"
                    from: -20; to: 0; duration: 100; easing.type: Easing.InSine
                }
                PauseAnimation {
                    duration: root.wiggleInterval * 1000
                }
            }
            SequentialAnimation {
                NumberAnimation {
                    target: icon; property: "scale"
                    from: 1; to: 1.3; duration: 200; easing.type: Easing.InQuad
                }
                NumberAnimation {
                    target: icon; property: "scale"
                    from: 1.3; to: 1; duration: 200; easing.type: Easing.OutQuad
                }
                PauseAnimation {
                    duration: root.wiggleInterval * 1000
                }
            }
        }
    }
}

