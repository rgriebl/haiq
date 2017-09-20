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
import QtQml 2.12
import QtQuick.Window 2.12
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.griebl.haiq 1.0
import QtQuick.Controls.Universal 2.12

Control {
    id: control

    implicitWidth: spinbox.implicitWidth
    implicitHeight: font.pixelSize * 2

    property real value: 0
    property real from: 0
    property real to: 100
    property real stepSize: 1

    property string unit: ''
    property int decimals: 0
    readonly property int factor: Math.pow(10, decimals)
    property url upIconSource: '../icons/mdi/plus'
    property url downIconSource: '../icons/mdi/minus'
    
    signal valueModified(real value)

    SpinBox {
        anchors.fill: parent
        id: spinbox
        
        
        from: Math.round(control.from * control.factor)
        to: Math.round(control.to * control.factor)
        stepSize: Math.round(control.stepSize * control.factor)
        value: control.value * control.factor
        
        textFromValue: function(value, locale) {
            return Number(value / control.factor).toLocaleString(locale, 'f', decimals) + control.unit
        }
        
        contentItem: Label {
            z: 2
            text: spinbox.textFromValue(spinbox.value, spinbox.locale)
            font: spinbox.font
            horizontalAlignment: Qt.AlignHCenter
            verticalAlignment: Qt.AlignVCenter
        }
        
        background: Rectangle {
            id: bg
            
            property color bcol: Qt.hsva(0, 0, 0.2, 1)
            
            radius: control.font.pixelSize / 4
            border.width: 1
            border.color: bcol
            gradient: Gradient {
                GradientStop { position: 0.0; color: bg.bcol }
                GradientStop { position: 0.3; color: "black" }
                GradientStop { position: 0.7; color: "black" }
                GradientStop { position: 1.0; color: bg.bcol }
            }
        }
        
        up.indicator: Control {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: upIcon.implicitWidth + 8
            implicitHeight: upIcon.implicitHeight + 8
            SvgIcon {
                id: upIcon
                anchors.centerIn: parent
                opacity: spinbox.contentItem.opacity
                source: control.upIconSource
            }
        }
        down.indicator:  Control {
            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            implicitWidth: downIcon.implicitWidth + 8
            implicitHeight: downIcon.implicitHeight + 8
            SvgIcon {
                id: downIcon
                anchors.centerIn: parent
                opacity: spinbox.contentItem.opacity
                source: control.downIconSource
            }
        }
        
        Timer {
            id: delayedSetValue
            interval: 1000
            onTriggered: {
                control.value = spinbox.value / control.factor
                control.valueModified(control.value)
            }
        }
        onValueModified: delayedSetValue.restart()
    }
}
