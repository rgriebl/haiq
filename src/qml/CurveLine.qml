// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Shapes as Shapes
import Qt5Compat.GraphicalEffects


Item {
    id: root
    required property int count
    required property var model
    required property int offset
    required property string propertyName
    property alias strokeWidth: path.strokeWidth
    property Gradient gradientStops: Gradient {
        GradientStop { position: 0;    color: Qt.rgba(1, 0, 0, 0.5) }
        GradientStop { position: 0.33; color: Qt.rgba(1, 1, 1, 0.5) }
        GradientStop { position: 0.66; color: Qt.rgba(1, 1, 1, 0.5) }
        GradientStop { position: 1;    color: Qt.rgba(0, 0, 1, 0.5) }
    }

    function redrawLine() {
        for (let i = 0; i < root.count; i++) {
            let rect = root.model.get(i + root.offset)["point_" + root.propertyName]
            let pt = shape.mapFromItem(rect, rect.width / 2, rect.height / 2)

            path.pathElements[i].x = pt.x
            path.pathElements[i].y = pt.y
        }
    }


    Rectangle {
        id: gradient
        anchors.fill: parent
        visible: false
        gradient: root.gradientStops
    }
    Shapes.Shape {
        id: shape
        anchors.fill: parent
        visible: false
        preferredRendererType: Shapes.Shape.CurveRenderer
        Shapes.ShapePath {
            id: path
            strokeColor: "white"
            strokeWidth: 5
            fillColor: "transparent"

            PathMove { }
            Component.onCompleted: {
                for (let i = 1; i < root.count; i++)
                    pathElements.push(pcurve.createObject(this))
            }
        }
    }
    OpacityMask {
        anchors.fill: gradient
        source: gradient
        maskSource: shape
    }
}
