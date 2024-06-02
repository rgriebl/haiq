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
import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Tile {
    id: root
    required property var model
    required property int day
    required property string condition
    required property string temperature
    required property string templow
    required property real precipitation
    required property real precipitation_probability

    headerText: (model.day === 0)
                ? 'Heute'
                : (model.day === 1)
                  ? 'Morgen'
                  : Qt.locale().dayName((_weekday + model.day) % 7)

    property int _weekday

    Timer {
        interval: 1000 * 60 // every minute
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: _weekday = new Date().getDay()
    }

    property real fontSize: root.font.pixelSize * 1.75
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

        WeatherTemperatureLabel {
            Tracer { }
            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter

            temperature: Number(root.temperature)
            font.pixelSize: root.fontSize
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
            Rectangle {
                Tracer { }
                anchors.horizontalCenter: parent.horizontalCenter
                width: 9
                height: width
                radius: width / 2
                color: "blue"
                y: parent.height / 2 - root.templow * parent.height / 60

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

            temperature: Number(root.templow)
            font.pixelSize: root.fontSize
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
                height: parent.height / 100 * root.precipitation
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
