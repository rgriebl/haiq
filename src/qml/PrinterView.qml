// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import Qt.labs.platform as Labs
import HAiQ

ApplicationWindow {
    id: window
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
                                 SystemTrayIcon.Information, 10 * 1000)
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
        icon.source: "/icons/printer" + (offline ? "-off" : (idle ? "" : "-alert")) + ".svg"
        tooltip: window.title + ":\n" + (offline ? "Ausgeschalten" : line)
        visible: true

        onActivated: {
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
                property var callback
                onTriggered: callback()
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
                if (status === 'ringing' && trayIcon.supportsMessages) {
                    if (!delay.running) {
                        delay.callback = function() {
                            trayIcon.showMessage("Anruf",
                                                 "Eingehender Anruf von\n\n" + caller,
                                                 SystemTrayIcon.Information, 20 * 1000)
                        }
                        delay.running = true
                    }
                }
            }            
        }
    }
}
