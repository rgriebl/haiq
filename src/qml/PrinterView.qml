// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import Qt.labs.platform as Labs
import HAiQ
import Ui


ApplicationWindow {
    id: root
    title: "Druckerstatus"
    visible: false

    property string entity: "sensor.laserjet_status"
    property string line
    property bool idle
    property bool offline

    onLineChanged: {
        if (!offline && !idle && line != '' && trayIcon.supportsMessages) {
            trayIcon.showMessage("Druckerstatus",
                                 line,
                                 Labs.SystemTrayIcon.Information, 10 * 1000)
        }
    }

    Component.onCompleted: {
        HomeAssistant.subscribe(entity, function(state, attributes) {
            idle = state.startsWith("idle")
            offline = state.startsWith("<offline>")
            line = state
        })
    }

    Labs.SystemTrayIcon {
        id: trayIcon
        icon.source: "/icons/printer" + (root.offline ? "-off" : (root.idle ? "" : "-alert")) + ".svg"
        tooltip: root.title + ":\n" + (root.offline ? "Ausgeschalten" : root.line)
        visible: true

        onActivated: function(reason) {
            switch (reason) {
            case Labs.SystemTrayIcon.Trigger:
            case Labs.SystemTrayIcon.DoubleClick:
                break;

            case Labs.SystemTrayIcon.MiddleClick:
                Qt.quit();
                break;
            }
        }

        menu: Labs.Menu {
            Labs.MenuItem {
                text: qsTr("Open Home-Assistant...")
                onTriggered: Qt.openUrlExternally(HomeAssistant.baseUrl)
            }
            Labs.MenuItem { separator: true }

            Labs.MenuItem {
                text: qsTr("Quit")
                onTriggered: Qt.quit()
            }
        }

        property var incomingCall: Item {
            id: incoming

            property string entity: "sensor.fritzbox"
            property string status
            property string caller

            Timer {
                id: delay
                interval: 500
                running: false
                repeat: false
                onTriggered: {
                    trayIcon.showMessage("Anruf",
                                         "Eingehender Anruf von\n\n" + incoming.caller,
                                         Labs.SystemTrayIcon.Information, 20 * 1000)

                }
            }
            Component.onCompleted: {
                HomeAssistant.subscribe(entity, function(state, attributes) {
                    status = state
                    if (attributes.from_name === '')
                        caller = attributes.from + " (Unbekannt)"
                    else
                        caller = attributes.from_name + " (" + attributes.from + ")"
                })
            }

            onStatusChanged: {
                if (status === 'ringing' && trayIcon.supportsMessages)
                    delay.running = true
            }            
        }
    }
}
