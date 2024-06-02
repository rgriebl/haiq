// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Tile {
    id: root
    required property var model
    required property int hour
    required property string condition
    required property string temperature
    required property real precipitation
    required property real precipitation_probability


    headerText: {
        let d = new Date()
        return ('0' + ((d.getHours() + root.hour) % 24)).slice(-2)
    }

    property int _currentHour

    Timer {
        interval: 1000 * 60 // every minute
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: _currentHour = new Date().getHours()
    }
    
    property real fontSize: root.font.pixelSize
    property FontMetrics fontMetrics: FontMetrics { font: root.font }
    
    topInset: 3
    leftInset: 3
    rightInset: 3
    bottomInset: 3
    padding: 3
    
    ColumnLayout {
        anchors.fill: parent

        SvgIcon {
            Layout.fillWidth: true

            Tracer { }

            name: "darksky/" + root.condition
            size: width
        }

        Label {
            Tracer { }
            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter

            text: root.temperature + "°"
            font.pixelSize: root.font.pixelSize
        }

        Item {
            Tracer { }
            Layout.verticalStretchFactor: 3 // should really be 1/2, but that results in 1/3
            Layout.fillHeight: true
            Layout.fillWidth: true

            Rectangle {
                Tracer { }
                anchors.horizontalCenter: parent.horizontalCenter
                width: 9
                height: width
                radius: width / 2
                color: "red"
                y: parent.height / 2 - root.temperature * parent.height / 60

                Component.onCompleted: {
                    if (root.visible)
                        root.model.point_temperature = this
                }
                Component.onDestruction:  {
                    if (root.visible && root.model.point_temperature === this)
                        root.model.point_temperature = null
                }
            }
        }

        Rectangle {
            Layout.verticalStretchFactor: 2 // should really be 1/2, but that results in 1/3
            Layout.fillHeight: true
            Layout.fillWidth: true

            color: "transparent"
            border.color: Qt.rgba(0,0,1,0.7)
            border.width: 2
            radius: 5

            Rectangle {
                width: parent.width
                anchors.bottom: parent.bottom
                height: parent.height / 100 * 24 * root.precipitation
                color: "blue"
                radius: 5
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 9
                height: width
                radius: width / 2
                color: "white"
                y: (100 - root.precipitation_probability) * parent.height / 100

                Component.onCompleted: {
                    if (root.visible)
                        root.model.point_precipitation_probability = this
                }
                Component.onDestruction:  {
                    if (root.visible && root.model.point_precipitation_probability === this)
                        root.model.point_precipitation_probability = null
                }
            }
        }
        Label {
            Tracer { }
            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter

            text: root.precipitation ? (root.precipitation + "l") : "-"
            font.pixelSize: root.font.pixelSize
            opacity: root.precipitation_probability / 100
        }
    }
}
