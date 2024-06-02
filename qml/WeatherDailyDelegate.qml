// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal

Tile {
    id: root
    required property var model
    required property int day
    required property date datetime
    required property string condition
    required property real temperature
    required property real templow
    required property real precipitation
    required property real precipitation_probability

    headerText: {
        return Qt.locale("de").dayName(root.datetime.getDay())
    }

    function addUnit(value, unit) {
        return value + '<font size="1">' + unit + '</font>'
    }

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

        WeatherTemperatureLabel {
            Tracer { }
            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter

            temperature: root.temperature
            font.pixelSize: root.font.pixelSize * 1.75
        }

        Rectangle {
            Layout.verticalStretchFactor: 3 // should really be 1/2, but that results in 1/3
            Layout.fillHeight: true
            Layout.fillWidth: true

            radius: 5
            color: "transparent"
            border.color: Qt.rgba(1, 1, 1, 0.1)

            Repeater {
                model: 5
                Rectangle {
                    required property int index
                    x: 1
                    width: parent.width - 2
                    height: 1
                    color: parent.color
                    border.color: parent.border.color
                    y: (index + 1) * 0.166 * parent.height
                }
            }

            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 11
                height: width
                radius: width / 2
                color: "red"
                y: -width / 2 + parent.height * (root.temperature - 40) / -60 // [-20 .. +40]

                Component.onCompleted: {
                    if (root.visible)
                        root.model.point_temperature = this
                }
                Component.onDestruction:  {
                    if (root.visible && root.model.point_temperature === this)
                        root.model.point_temperature = null
                }
            }
            Rectangle {
                Tracer { }
                anchors.horizontalCenter: parent.horizontalCenter
                width: 11
                height: width
                radius: width / 2
                color: "blue"
                y: -width / 2 + parent.height * (root.templow - 40) / -60 // [-20 .. +40]

                Component.onCompleted: {
                    if (root.visible)
                        root.model.point_templow = this
                }
                Component.onDestruction:  {
                    if (root.visible && root.model.point_templow === this)
                        root.model.point_templow = null
                }
            }
        }

        WeatherTemperatureLabel {
            Tracer { }
            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter

            temperature: root.templow
            font.pixelSize: root.font.pixelSize * 1.75
        }
        Rectangle {
            Layout.verticalStretchFactor: 2 // should really be 1/2, but that results in 1/3
            Layout.fillHeight: true
            Layout.fillWidth: true

            color: "transparent"
            border.color: { let c = Universal.accent; return Qt.rgba(c.r, c.g, c.b, 0.2) }
            border.width: 2
            radius: 5

            Rectangle {
                width: parent.width
                anchors.bottom: parent.bottom
                height: parent.height / 100 * root.precipitation
                color: Universal.accent
                radius: parent.radius
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter
                width: 9
                height: width
                radius: width / 2
                color: "white"
                y: -width / 2 + (100 - root.precipitation_probability) * parent.height / 100

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

            text: root.precipitation ? addUnit(root.precipitation, "l") : "-"
            font.pixelSize: root.font.pixelSize
            opacity: root.precipitation_probability / 100
        }
    }
}
