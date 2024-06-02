// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQml
import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import org.griebl.haiq 1.0
import Qt.labs.platform as Labs


ApplicationWindow {
    id: root
    title: "Raumsteuerung Wohnzimmer"
    visible: true
    flags: Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowSystemMenuHint | Qt.WindowCloseButtonHint

    onClosing: { close.accepted = false; hide() }
    Shortcut { sequence: StandardKey.Cancel; onActivated: hide() }

    font.family: "Noto Sans"
    font.bold: true
    font.pointSize: 30

    color: 'black'
    background: Image { source: '../icons/bg.jpg'; fillMode: Image.Tile }

    property real defaultRowSpacing: font.pixelSize
    property real defaultColumnSpacing: font.pixelSize / 2

    Labs.SystemTrayIcon {
        id: trayIcon
        icon.source: "../icons/haiq.svg"
        icon.mask: true
        tooltip: root.title
        visible: true

        onActivated: {
            switch (reason) {
            case Labs.SystemTrayIcon.Trigger:
            case Labs.SystemTrayIcon.DoubleClick:
                if (root.visible) {
                    root.hide()
                } else {
                    root.show()
                    root.raise()
                    root.requestActivate()
                }
                break;
            }
        }
    }

    property Component defaultOverlay: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.8)
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    width: gridLayout.implicitWidth + 2 * gridLayout.anchors.leftMargin
    height: gridLayout.implicitHeight + 2 * gridLayout.anchors.topMargin

    Component.onCompleted: {
        minimumWidth = width
        maximumWidth = width
        minimumHeight = height
        maximumHeight = height
    }

    RowLayout {
        id: gridLayout
        anchors.fill: parent
        anchors.leftMargin: 11
        anchors.rightMargin: anchors.leftMargin

        LivingRoomPage {
            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
        }
        LivingRoomPage2 {
            Layout.alignment: Qt.AlignTop | Qt.AlignLeft
        }
    }
}
