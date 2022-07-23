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

    property string entity

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

    readonly property int days: 5
    readonly property int hours: 48

    Component.onCompleted: {

        var daily_conditions = [
                    'icon',
                    'daytime_high_apparent_temperature',
                    'overnight_low_apparent_temperature',
                    'daytime_high_temperature',
                    'overnight_low_temperature',
                    'precip',
                    'precip_intensity',
                    'precip_probability',
                    'pressure',
                    'wind_speed',
                    'cloud_coverage',
                ]

        var hourly_conditions = [
                    'icon',
                    'apparent_temperature',
                    'temperature',
                    'precip',
                    'precip_intensity',
                    'precip_probability',
                    'pressure',
                    'wind_speed',
                    'cloud_coverage',
                ]



        // daily
        for (let d = 0; d <= days; ++d) {
            let properties = { 'day': d }
            for (let condition of daily_conditions) {
                properties[condition] = '' // init model with dummy value
                let sensor = root.entity + "_" + condition + '_' + d + 'd'
                HomeAssistant.subscribe(sensor, function(state, attributes) {
                    dailyWeatherModel.setProperty(d, condition, state)
                })
            }
            dailyWeatherModel.insert(d, properties)
        }
        // hourly
        for (let h = 0; h <= hours; ++h) {
            let properties = { 'hour': h }
            for (let condition of hourly_conditions) {
                properties[condition] = '' // init model with dummy value
                let sensor = root.entity + "_" + condition + '_' + h + 'h'
                HomeAssistant.subscribe(sensor, function(state, attributes) {
                    hourlyWeatherModel.setProperty(h, condition, state)
                })
            }
            hourlyWeatherModel.insert(h, properties)
        }
    }
}
