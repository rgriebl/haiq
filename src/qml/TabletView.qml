// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick.Controls.Universal
import HAiQ
import Ui


ApplicationWindow {
    id: root

    property real menuFontPixelSize: root.font.pixelSize
    property Drawer drawer: menuDrawer

    property int screenWidth: 1280
    property int screenHeight: 800

    palette.text: Universal.foreground
    palette.window: Universal.background

    Component.onCompleted: {
        switch (Qt.platform.pluginName) {
        case "windows":
        case "xcb":
        case "cocoa":
            width = screenWidth
            height = screenHeight
        }
        console.log("Main window: " + width + " x " + height)
        console.log("Font pixelSize: " + font.pixelSize)


        // we need to get the order right, plus we have Attached properties, so we cannot use
        // properties or property aliases within Settings here

        var col  = settings.value('accent', Universal.accent)
        Universal.accent = col

        Universal.onAccentChanged.connect(function() {
            var col = Universal.accent
            settings.setValue('accent', col)
            if (settings.sync)
                settings.sync()
        })
    }
    Settings {
        id: settings
        category: 'colors'
    }

    color: 'black'
    background: Image { source: '/icons/bg.jpg'; fillMode: Image.Tile }

//    Timer {
//        interval: 2000
//        running: true
//        onTriggered: mainStack.grabToImage(function(result) { result.saveToFile("screenshot.png") });
//    }

    property IncomingCall incomingCall: IncomingCall {
        entity: "sensor.fritzbox"
    }

    MenuDrawer {
        id: menuDrawer

        iconName: 'haiq'
        font.pixelSize: root.menuFontPixelSize

        items: ListModel {
            ListElement {
                text: "Farbe"
                iconName: 'mdi/palette'
                action: function() { colorPopup.open() }
            }
            ListElement {
                text: "FPS Anzeige"
                iconName: 'mdi/counter'
                action: function() { fpsMeter.active = !fpsMeter.active }
            }
            ListElement {
                text: "Standby"
                iconName: 'mdi/television'
                action: function() { ScreenBrightness.blank = true }
            }
            ListElement {
                spacer: true
                stretch: true
            }
            ListElement {
                text: "Neustarten"
                iconName: 'mdi/power'
                action: function() { Qt.exit(42) }
            }
            ListElement {
                spacer: true
            }
            ListElement {
                text: "Beenden"
                iconName: 'mdi/exit-to-app'
                action: function() { Qt.quit() }
            }
        }
    }

    FPSMeter {
        id: fpsMeter
        anchors.right: parent.right
        anchors.top: parent.top
        visible: false
        z: 5000
    }

    Popup {
        id: colorPopup

        modal: true
        Overlay.modal: DarkOverlay { }
        background: Rectangle {
            color: Qt.rgba(28/255, 28/255, 30/255)
            radius: colorPopup.font.pixelSize
        }
        padding: font.pixelSize
        anchors.centerIn: Overlay.overlay
//        width: parent.Window.width * 0.8
//        height: parent.Window.height * 0.8
        font.pixelSize: root.menuFontPixelSize

        ColorSettings {
            id: colorSettings
            anchors.fill: parent
        }
        onOpened: colorSettings.initialize()
    }
}
