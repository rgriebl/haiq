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

    function addUnit(item, str, unit) {
        var html = '<span>' + str + '</span>'
                + '<span style="font-size: ' + item.font.pixelSize / 2 + 'px;"> ' + unit + '</span>'
        return html
    }

    SwipeView {
        id: swipe
        anchors.fill: parent
        orientation: Qt.Vertical
        clip: true

        ListView {
            id: dailyList
            orientation: ListView.Horizontal
            interactive: false
            spacing: 3

            model: dailyWeatherModel
            delegate: WeatherDailyDelegate { }
        }


        ListView {
            id: hourly
            orientation: ListView.Horizontal
            spacing: 3
            interactive: true

            model: hourlyWeatherModel
            delegate: WeatherHourlyDelegate { }
        }
    }

    Label {
        id: indicator
        opacity: 0.8

        text: swipe.currentIndex == 0 ? "v Stündliche Vorhersage v"
                                      : "^ Tägliche Vorhersage ^"

        anchors.bottom: swipe.bottom
        anchors.horizontalCenter: parent.horizontalCenter
    }

    readonly property int days: 8
    readonly property int hours: 48

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
                    'weather',
                    'temperature',
                    'precipitation',
                    'precipitation_probability',
                    'wind_speed',
                ]



        // daily
        for (let d = 0; d <= days; ++d) {
            let properties = { 'day': d }
            for (let condition of daily_conditions) {
                properties[condition] = '' // init model with dummy value
            }
            dailyWeatherModel.insert(d, properties)
        }
        HomeAssistant.subscribe("weather.dwd_weather_" + root.location, function(state, attributes) {
            for (let d = 0; d < days; ++d) {
                for (let condition of daily_conditions) {
                    dailyWeatherModel.setProperty(d, condition, attributes.forecast[d][condition])
                }
            }
        })

        // hourly
        let properties = { }
        for (let condition of hourly_conditions) {
            properties[condition] = '' // init model with dummy value

            HomeAssistant.subscribe("sensor." + condition + "_" + root.location, function(state, attributes) {
                for (let h = 0; h <= hours; ++h) {
                    hourlyWeatherModel.setProperty(h, condition, attributes.data[h].value)
                }
            })
        }
        for (let h = 0; h <= hours; ++h) {
            properties['hour'] = h
            hourlyWeatherModel.insert(h, properties)
        }
    }
}
