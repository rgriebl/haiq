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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.griebl.haiq 1.0


Control {
    id: root

    property string label
    property string entity
    property date lastUpdate

    padding: font.pixelSize / 2

    WeatherTemperatureLabel {
        anchors.centerIn: parent
        temperature: 0
        highTemperature: 100
        opacity: temperature === 0 ? 0 : 1
        font: root.font

        Component.onCompleted: {
            HomeAssistant.subscribe(entity, function(state, attributes) {
                temperature = state
                root.lastUpdate = new Date()
            })
        }
    }
}
