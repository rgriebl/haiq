// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Shapes
import QtQuick.Controls

Control {
    id: root
    property real value: 0
    property real stepSize: 5
    property real position: 0
    property alias dialColor: ring.strokeColor
    property alias icon: button.icon
    property alias scale: button.scale

    width: button.width + button.radius
    height: button.height + button.radius + font.pixelSize - button.radius / 8
    implicitWidth: button.implicitWidth + button.radius
    implicitHeight: button.implicitHeight + button.radius + font.pixelSize - button.radius / 8
    wheelEnabled: true

    signal clicked()
    signal moved()

    onValueChanged: position = value

    function changePosition(delta) {
        position = Math.max(0, Math.min(100, (position + delta)))
        root.moved()
    }

    MouseArea {
        anchors.fill: parent
        onWheel: {
            changePosition(wheel.angleDelta.y / 120 * root.stepSize)
        }
    }

    Keys.onUpPressed: changePosition(+5)
    Keys.onDownPressed: changePosition(-5)
    Keys.onLeftPressed: changePosition(-5)
    Keys.onRightPressed: changePosition(+5)

    RoundIconButton {
        id: button
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -(root.font.pixelSize - button.radius / 8 ) / 2
        onClicked: root.clicked()
        Tracer { }
    }

    Label {
        id: label
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        y: button.y + button.height + button.radius / 8
        text: root.position ? (Math.round(root.position) + '%') : 'Aus'

    }

    Shape {
        anchors.fill: parent
        layer.enabled: true
        layer.samples: 4

        ShapePath {
            strokeWidth: button.radius / 4
            fillColor: "transparent"
            strokeColor: "darkgray"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: arc
                centerX: root.width / 2
                centerY: root.width / 2
                radiusX: button.radius * 1.25 // ( 1 + 3 / 8)
                radiusY: button.radius * 1.25 // ( 1 + 3 / 8)
                startAngle: 135
                sweepAngle: 270
            }
        }
        ShapePath {
            id: ring
            strokeWidth: button.radius / 4 - 2
            fillColor: "transparent"
            strokeColor: "yellow"
            capStyle: ShapePath.RoundCap

            PathAngleArc {
                id: arc2
                centerX: arc.centerX
                centerY: root.width / 2  // https://codereview.qt-project.org/#/c/247812/
                radiusX: arc.radiusX
                radiusY: arc.radiusY
                startAngle: arc.startAngle
                sweepAngle: 270 * root.position / 100
            }
        }
    }
    Tracer { }
}
