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
import QtQuick.Window
import org.griebl.haiq 1.0
import QtQuick.Shapes as Shapes
import Qt5Compat.GraphicalEffects


Pane {
    id: root

    property alias currentPage: swipe.currentIndex
    background: null

    property string location

    property ListModel dailyWeatherModel: ListModel {
        dynamicRoles: true
    }
    property ListModel hourlyWeatherModel: ListModel {
        dynamicRoles: true
    }

    readonly property int days: 9
    readonly property int hours: 48

    readonly property real hourSlice: width / 23.5
    readonly property real daySlice: width / days

    function addUnit(item, str, unit) {
        var html = '<span>' + str + '</span>'
                + '<span style="font-size: ' + item.font.pixelSize / 2 + 'px;"> ' + unit + '</span>'
        return html
    }

    Component  {
        id: pcurve
        PathCurve { }
    }

    SwipeView {
        id: swipe
        anchors.fill: parent
        orientation: Qt.Vertical
        clip: true

        Item {
            Repeater {
                model: dailyWeatherModel
                delegate: WeatherDailyDelegate {
                    required property int index

                    height: parent.height
                    x: index * parent.width / root.days + 1
                    width: parent.width / root.days - 2
                }
            }
            CurveLine {
                id: tempHighCurve
                anchors.fill: parent
                z: 2
                model: dailyWeatherModel
                count: root.days
                offset: 0
                propertyName: "temperature"
            }
            CurveLine {
                id: tempLowCurve
                anchors.fill: parent
                z: 2
                model: dailyWeatherModel
                count: root.days
                offset: 0
                propertyName: "templow"
            }
            CurveLine {
                id: precipDayCurve
                anchors.fill: parent
                z: 2
                strokeWidth: 3
                model: dailyWeatherModel
                count: root.days
                offset: 0
                propertyName: "precipitation_probability"
                color0: "white"
                color1: Qt.rgba(1,1,1,0.5)
                color2: Qt.rgba(1,1,1,0)
            }
        }

        Item {
            Item {
                width: parent.width
                height: parent.height / 2 - 3

                Repeater {
                    model: hourlyWeatherModel
                    delegate: WeatherHourlyDelegate {
                        required property int index

                        height: parent.height
                        x: index * parent.width / (root.hours / 2) + 1
                        width: visible ? parent.width / (root.hours / 2) - 2 : 0
                        visible: index < (root.hours / 2)
                    }
                }

                CurveLine {
                    id: tempCurve
                    anchors.fill: parent
                    z: 2
                    model: hourlyWeatherModel
                    count: root.hours / 2
                    offset: 0
                    propertyName: "temperature"
                }
                CurveLine {
                    id: precipCurve
                    anchors.fill: parent
                    z: 2
                    strokeWidth: 3
                    model: hourlyWeatherModel
                    count: root.hours / 2
                    offset: 0
                    propertyName: "precipitation_probability"
                    color0: "white"
                    color1: Qt.rgba(1,1,1,0.5)
                    color2: Qt.rgba(1,1,1,0)
                }
            }
            Item {
                width: parent.width
                height: parent.height / 2 - 3
                y: height + 6

                Repeater {
                    model: hourlyWeatherModel
                    delegate: WeatherHourlyDelegate {
                        required property int index

                        height: parent.height
                        x: (index - (root.hours / 2)) * parent.width / (root.hours / 2) + 1
                        width: visible ? parent.width / (root.hours / 2) - 2 : 0
                        visible: index >= (root.hours / 2)
                    }
                }
                CurveLine {
                    id: tempCurve2
                    anchors.fill: parent
                    z: 2
                    model: hourlyWeatherModel
                    count: root.hours / 2
                    offset: (root.hours / 2)
                    propertyName: "temperature"
                }
                CurveLine {
                    id: precipCurve2
                    anchors.fill: parent
                    z: 2
                    strokeWidth: 3
                    model: hourlyWeatherModel
                    count: root.hours / 2
                    offset: (root.hours / 2)
                    propertyName: "precipitation_probability"
                    color0: "white"
                    color1: Qt.rgba(1,1,1,0.5)
                    color2: Qt.rgba(1,1,1,0)
                }
            }
        }
    }

    // Label {
    //     id: indicator
    //     opacity: 0.8

    //     text: swipe.currentIndex === 0 ? "v Stündliche Vorhersage v"
    //                                    : "^ Tägliche Vorhersage ^"

    //     anchors.bottom: swipe.bottom
    //     anchors.horizontalCenter: parent.horizontalCenter
    // }

    function updateLines() {
        tempCurve.redrawLine()
        tempCurve2.redrawLine()
        precipCurve.redrawLine()
        precipCurve2.redrawLine()
        tempHighCurve.redrawLine()
        tempLowCurve.redrawLine()
        precipDayCurve.redrawLine()
    }

    Component.onCompleted: {

        var daily_conditions = [
                    'condition',
                    'temperature',
                    'templow',
                    'precipitation',
                    'precipitation_probability',
                    'wind_speed',
                ]

        var hourly_conditions = [
                    'condition',
                    'temperature',
                    'precipitation',
                    'precipitation_probability',
                    'wind_speed',
                ]



        // daily
        for (let d = 0; d < days; ++d) {
            let properties = {
                'day': d,
                'point_temperature': null,
                'point_templow': null,
                'point_precipitation_probability': null
            }
            for (let condition of daily_conditions)
                properties[condition] = '' // init model with dummy value
            dailyWeatherModel.insert(d, properties)
        }
        HomeAssistant.subscribe("sensor.weather_forecast_daily", function(state, attributes) {
            for (let d = 0; d < days; ++d) {
                for (let condition of daily_conditions)
                    dailyWeatherModel.setProperty(d, condition, attributes.forecast[d][condition])
            }
        })

        // hourly
        for (let h = 0; h < root.hours; ++h) {
            let properties = {
                'hour': h,
                'point_temperature': null,
                'point_precipitation_probability': null
            }
            for (let condition of hourly_conditions)
                properties[condition] = '' // init model with dummy value
            hourlyWeatherModel.insert(h, properties)
        }

        HomeAssistant.subscribe("sensor.weather_forecast_hourly", function(state, attributes) {
            for (let h = 0; h < root.hours; ++h) {
                for (let condition of hourly_conditions)
                    hourlyWeatherModel.setProperty(h, condition, attributes.forecast[h][condition])
            }
            Qt.callLater(updateLines)
        })
    }
}
