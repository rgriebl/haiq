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
import QtQuick 2.12
import QtQuick.Controls 2.12


Label {
    id: root

    property string prefix: ''
    property int temperature: 0
    property int temperatureFeelsLike: 0
    property bool showFeelsLike: false
    property int highTemperature: 20
    
    function temperatureHtml(t) {
        var c = Qt.rgba(1, 1, 1, 1)
        if (t < 0)
            c = Qt.tint(c, Qt.rgba(0, 0, 1, 0.2 + t / -40))
        else if (t > highTemperature)
            c = Qt.tint(c, Qt.rgba(1, 0, 0, 0.2 + (t - highTemperature) / highTemperature))
        
        return '<span style="color: ' + c + ';">' + t + '</span>'
    }
    
    textFormat: Text.RichText
    text: {
        var s = prefix
        if (!showFeelsLike || (Math.abs(temperature - temperatureFeelsLike) < 3)) {
            s = s + root.temperatureHtml(temperature)
        } else {
            s = s + temperatureHtml(temperature) + '/' + temperatureHtml(temperatureFeelsLike)
        }
        return s + '<span style="font-size: ' + font.pixelSize / 2 + 'px;"> °</span>'
    }
}
