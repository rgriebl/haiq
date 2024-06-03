// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import Qt.labs.platform as Labs
import HAiQ
import Ui


ApplicationWindow {
    id: root
    title: "Raumsteuerung Wohnzimmer"
    visible: true
    flags: Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowSystemMenuHint | Qt.WindowCloseButtonHint

    onClosing: { close.accepted = false; hide() }
    Shortcut { sequence: StandardKey.Cancel; onActivated: root.hide() }

    font.family: "Noto Sans"
    font.bold: true
    font.pointSize: 30

    color: 'black'
    background: Image { source: '/icons/bg.jpg'; fillMode: Image.Tile }

    Labs.SystemTrayIcon {
        id: trayIcon
        icon.source: "/icons/haiq.svg"
        icon.mask: true
        tooltip: root.title
        visible: true

        onActivated: function(reason) {
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
