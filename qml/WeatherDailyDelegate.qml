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


Tile {
    id: delegate
    
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

    property real fontSize: delegate.font.pixelSize
    property FontMetrics fontMetrics: FontMetrics { font: delegate.font }
    
    topInset: 3
    leftInset: 3
    rightInset: 3
    bottomInset: 3
    padding: 3
    width: ListView.view.width / ListView.view.count
    height: ListView.view.height
    
    Item {
        id: column
        anchors.fill: parent
        
        SvgIcon {
            id: wicon
            anchors.top: column.top
            anchors.margins: column.width / 10
            
            name: "darksky/" + model.condition
            size: column.width
        }
        
        WeatherTemperatureLabel {
            id: tempHigh
            anchors.top: wicon.bottom
            anchors.horizontalCenter: tempBar.horizontalCenter
            
            font.pixelSize: delegate.fontSize * 2
            padding: 0
            
            temperature: Number(model.temperature)
        }
        SvgIcon {
            id: tempIcon
            icon: 'mdi/thermometer'
            anchors.verticalCenter: tempHigh.bottom
            size: delegate.fontSize * 2
        }
        Rectangle {
            id: tempBar
            anchors.verticalCenter: tempHigh.bottom
            anchors.right: column.right
            anchors.left: tempIcon.right
            height: 1
        }
        WeatherTemperatureLabel {
            id: tempLow
            anchors.top: tempHigh.bottom
            anchors.horizontalCenter: tempBar.horizontalCenter
            
            font.pixelSize: delegate.fontSize * 2
            padding: 0
            
            temperature: Number(model.templow)
        }
        
        Label {
            id: rainProbability
            anchors.top: tempLow.bottom
            anchors.topMargin: delegate.fontSize
            anchors.horizontalCenter: rainBar.horizontalCenter
            font.pixelSize: delegate.fontSize * 2
            padding: 0
            
            property int percent: Math.round(model.precipitation_probability)
            
            text: percent ? root.addUnit(this, percent, '%') : ''
            textFormat: Qt.RichText
        }
        SvgIcon {
            id: rainIcon
            icon: 'darksky/rainy'
            anchors.verticalCenter: rainProbability.bottom
            size: delegate.fontSize * 2
        }
        Rectangle {
            id: rainBar
            anchors.verticalCenter: rainProbability.bottom
            anchors.right: column.right
            anchors.left: rainIcon.right
            height: 1
            color: rainProbability.color
        }
        Label {
            id: rainIntensity
            anchors.top: rainProbability.bottom
            anchors.horizontalCenter: rainBar.horizontalCenter
            font.pixelSize: delegate.fontSize * 2
            padding: 0
            
            property int mm: Math.round(model.precipitation * 24)
            
            text: (rainProbability.percent <= 0 || mm <= 0) ? '-' : root.addUnit(this, mm, 'mm')
            textFormat: Qt.RichText
        }
        Label {
            id: wind
            anchors.top: rainIntensity.bottom
            anchors.topMargin: delegate.fontSize
            anchors.left: windIcon.right
            anchors.right: column.right
            
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: delegate.fontSize * 2
            
            property int speed: Math.round(model.wind_speed)
            
            text: speed ? root.addUnit(this, speed, 'km/h') : ''
            textFormat: Qt.RichText
        }
        SvgIcon {
            id: windIcon
            icon: 'darksky/windy'
            anchors.verticalCenter: wind.verticalCenter
            size: delegate.fontSize * 2
        }
    }
    
}
