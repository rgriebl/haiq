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
import QtQuick.Shapes 1.12
import QtQuick.Controls 2.12

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
