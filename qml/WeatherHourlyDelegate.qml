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

    headerText: {
        if (model.hour === 0) {
            return 'Jetzt'
        } else {
            let d = new Date()
            d.setHours(d.getHours() + model.hour)
            let prefix = (_currentHour + model.hour) < 24
                ? 'Heute'
                : (_currentHour + model.hour) < 48
                  ? 'Morgen'
                  : 'Übermorgen'
            return prefix + Qt.formatTime(d, ", h 'Uhr'")
        }
    }

    property int _currentHour

    Timer {
        interval: 1000 * 60 // every minute
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: _currentHour = new Date().getHours()
    }
    
    property real fontSize: delegate.font.pixelSize
    property FontMetrics fontMetrics: FontMetrics { font: delegate.font }
    
    topInset: 3
    leftInset: 3
    rightInset: 3
    bottomInset: 3
    padding: 3
    width: ListView.view.width / 7.5
    height: ListView.view.height
    
    Item {
        id: hcolumn
        anchors.fill: parent
        
        SvgIcon {
            id: wicon
            anchors.top: hcolumn.top
            anchors.margins: hcolumn.width / 20
            
            name: "darksky/" + model.icon
            size: hcolumn.width
        }
        
        WeatherTemperatureLabel {
            id: temp
            anchors.top: wicon.bottom
            anchors.left: tempIcon.right
            anchors.right: hcolumn.right
            
            font.pixelSize: delegate.fontSize * 2
            padding: 0
            
            temperature: Number(model.apparent_temperature)
        }
        SvgIcon {
            id: tempIcon
            icon: 'mdi/thermometer'
            anchors.verticalCenter: temp.verticalCenter
            size: delegate.fontSize * 2
        }
        
        Label {
            id: rainProbability
            anchors.top: temp.bottom
            anchors.topMargin: delegate.fontSize
            anchors.horizontalCenter: rainBar.horizontalCenter
            font.pixelSize: delegate.fontSize * 2
            padding: 0
            
            property int percent: Math.round(precip_probability)
            
            text: percent ? root.addUnit(this, percent, '%') : '-'
            textFormat: Qt.RichText
        }
        SvgIcon {
            id: rainIcon
            icon: 'darksky/rain'
            anchors.verticalCenter: rainProbability.bottom
            size: delegate.fontSize * 2
        }
        Rectangle {
            id: rainBar
            anchors.verticalCenter: rainProbability.bottom
            anchors.right: hcolumn.right
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
            
            property int mm: Math.round(precip_intensity)
            
            text: (precip_probability <= 0 || mm <= 0) ? '-' : root.addUnit(this, mm, 'mm')
            textFormat: Qt.RichText
        }
        
        Label {
            id: wind
            anchors.top: rainIntensity.bottom
            anchors.topMargin: delegate.fontSize
            anchors.left: windIcon.right
            anchors.right: hcolumn.right
            
            horizontalAlignment: Text.AlignHCenter
            font.pixelSize: delegate.fontSize * 2
            
            property int speed: Math.round(wind_speed)
            
            text: speed ? root.addUnit(this, speed, 'm/s') : ''
            textFormat: Qt.RichText
        }
        SvgIcon {
            id: windIcon
            icon: 'darksky/wind'
            anchors.verticalCenter: wind.verticalCenter
            size: delegate.fontSize * 2
        }
    }
    
}
