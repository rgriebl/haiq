// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import HAiQ
import Ui


Popup {
    id: phoneCall

    property string entity
    property string externalNumber //: '0815 3423 4324'
    property string externalName   //: 'Robert'
    property string status         //: 'ringing'

    modal: true
    Overlay.modal: DarkOverlay { }
    background: Rectangle {
        color: Qt.rgba(28/255, 28/255, 30/255)
        radius: phoneCall.font.pixelSize

        SvgIcon {
            id: phoneIcon
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

