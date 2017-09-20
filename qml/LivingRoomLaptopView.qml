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
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.griebl.haiq 1.0
import Qt.labs.platform 1.1


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

    SystemTrayIcon {
        id: trayIcon
        icon.source: "../icons/haiq.svg"
        icon.mask: true
        tooltip: root.title
        visible: true

        onActivated: {
            switch (reason) {
            case SystemTrayIcon.Trigger:
            case SystemTrayIcon.DoubleClick:
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
