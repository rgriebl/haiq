// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

pragma ComponentBehavior: Bound
import HAiQ
import Ui


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

     SwipeView {
        id: swipe
        anchors.fill: parent
        orientation: Qt.Horizontal
        clip: true

        Item {
            Repeater {
                model: root.dailyWeatherModel
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
                model: root.dailyWeatherModel
                count: root.days
                offset: 0
                propertyName: "temperature"
                strokeWidth: 3
            }
            CurveLine {
                id: tempLowCurve
                anchors.fill: parent
                z: 2
                model: root.dailyWeatherModel
                count: root.days
                offset: 0
                propertyName: "templow"
                strokeWidth: 3
            }
            CurveLine {
                id: precipDayCurve
                anchors.fill: parent
                z: 2
                strokeWidth: 3
                model: root.dailyWeatherModel
                count: root.days
                offset: 0
                propertyName: "precipitation_probability"
                gradientStops: Gradient {
                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.5) }
                    GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0)   }
                }
            }
        }

        Item {
            Item {
                width: parent.width
                height: parent.height / 2 - 3

                Repeater {
                    model: root.hourlyWeatherModel
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
                    model: root.hourlyWeatherModel
                    count: root.hours / 2
                    offset: 0
                    propertyName: "temperature"
                }
                CurveLine {
                    id: precipCurve
                    anchors.fill: parent
                    z: 2
                    strokeWidth: 3
                    model: root.hourlyWeatherModel
                    count: root.hours / 2
                    offset: 0
                    propertyName: "precipitation_probability"
                    gradientStops: Gradient {
                        GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.5) }
                        GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0)   }
                    }
                }
            }
            Item {
                width: parent.width
                height: parent.height / 2 - 3
                y: height + 6

                Repeater {
                    model: root.hourlyWeatherModel
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
                    model: root.hourlyWeatherModel
                    count: root.hours / 2
                    offset: (root.hours / 2)
                    propertyName: "temperature"
                }
                CurveLine {
                    id: precipCurve2
                    anchors.fill: parent
                    z: 2
                    strokeWidth: 3
                    model: root.hourlyWeatherModel
                    count: root.hours / 2
                    offset: (root.hours / 2)
                    propertyName: "precipitation_probability"
                    gradientStops: Gradient {
                        GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.5) }
                        GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0)   }
                    }
                }
            }
        }
    }

    Label {
        id: indicator
        opacity: 0.8

        text: swipe.currentIndex === 0 ? "<< Stündliche Vorhersage <<"
                                       : ">> Tägliche Vorhersage >>"

        anchors.bottom: swipe.bottom
        anchors.horizontalCenter: swipe.horizontalCenter

        Connections {
            target: swipe
            function onCurrentIndexChanged() { indicator.flash() }
        }
        Component.onCompleted: flash()

        function flash() {
            visible = true
            hideTimer.start()
        }
        Timer {
            id: hideTimer
            interval: 2000
            onTriggered: indicator.visible = false
        }
    }
    SwipeView.onIsCurrentItemChanged: if (SwipeView.isCurrentItem) indicator.flash()

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
        const daily_conditions = [
                                   'datetime',
                                   'condition',
                                   'temperature',
                                   'templow',
                                   'precipitation',
                                   'precipitation_probability',
                                   'wind_speed',
                               ]

        const hourly_conditions = [
                                    'datetime',
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
            for (let d = 0; d < root.days; ++d) {
                for (let condition of daily_conditions)
                    root.dailyWeatherModel.setProperty(d, condition, attributes.forecast[d][condition])
            }
            Qt.callLater(updateLines)
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
                    root.hourlyWeatherModel.setProperty(h, condition, attributes.forecast[h][condition])
            }
            Qt.callLater(updateLines)
        })
    }
}
