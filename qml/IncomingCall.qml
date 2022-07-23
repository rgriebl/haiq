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
import QtQuick.Window
import org.griebl.haiq 1.0


Popup {
    id: phoneCall

    property string entity
    property string externalNumber //: '0815 3423 4324'
    property string externalName   //: 'Robert'
    property string status         //: 'ringing'

    modal: true
    Overlay.modal: defaultOverlay
    background: Rectangle {
        color: Qt.rgba(28/255, 28/255, 30/255)
        radius: parent.font.pixelSize

        SvgIcon {
            id: phoneIcon
            //source: 'icon:mdi/phone'
            name: 'mdi/phone'
            color: 'green'
            opacity: 0.5

            anchors.centerIn: parent
            size: Math.min(parent.width / 1.5, parent.height / 1.5)

            SequentialAnimation {
                loops: Animation.Infinite
                running: phoneCall.visible
                PropertyAnimation {
                    duration: 1250
                    easing.type: Easing.OutSine
                    target: phoneIcon
                    property: "rotation"
                    to: 60 + 90

                }
                PropertyAnimation {
                    duration: 1500
                    easing.type: Easing.InOutSine
                    target: phoneIcon
                    property: "rotation"
                    to: -60 + 90

                }
                PropertyAnimation {
                    duration: 1250
                    easing.type: Easing.InSine
                    target: phoneIcon
                    property: "rotation"
                    to: 0 + 90

                }
            }
        }
    }
    padding: font.pixelSize
    anchors.centerIn: Overlay.overlay
    width: parent.Window.width * 0.9
    height: parent.Window.height * 0.9

    visible: status === 'ringing'

    Component.onCompleted: {
        HomeAssistant.subscribe(entity, function(state, attributes) {
            status = state
            externalName = attributes.from_name
            externalNumber = attributes.from
        })
    }

    ColumnLayout {
        anchors.fill: parent

        Label {
            Layout.fillWidth: true

            horizontalAlignment: Text.AlignHCenter
            text: "Eingehender Anruf"
        }
        Label {
            id: name
            Layout.fillWidth: true
            Layout.fillHeight: true

            horizontalAlignment: Text.AlignHCenter
            minimumPixelSize: phoneCall.font.pixelSize
            font.pixelSize: minimumPixelSize * 8
            fontSizeMode: Text.Fit

            text: phoneCall.externalName
            color: "yellow"
            visible: phoneCall.externalName !== ''
        }
        Label {
            Layout.fillWidth: true
            Layout.fillHeight: true

            horizontalAlignment: Text.AlignHCenter
            minimumPixelSize: name.minimumPixelSize
            font.pixelSize: name.font.pixelSize
            fontSizeMode: Text.Fit

            text: phoneCall.externalNumber
        }
    }
}

