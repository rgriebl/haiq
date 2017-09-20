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
import QtQuick.Controls.Universal 2.12
import Qt.labs.settings 1.0

TabletView {
    id: root

    screenWidth: 800
    screenHeight: 1280

    font.family: "Noto Sans"
    font.bold: true
    font.pixelSize: height / 27

    property real defaultRowSpacing: font.pixelSize / 2
    property real defaultColumnSpacing: font.pixelSize / 4

    property Component defaultOverlay: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.8)
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    visible: true

    property int backToHomeScreen: 5 // min

    GridLayout {
        anchors.fill: parent

        rowSpacing: 0
        columnSpacing: 0
        rows: 2
        columns: 1

        ToolBar {
            id: mainMenu
            Layout.fillWidth: true
            Layout.preferredHeight: buttonLayout.implicitHeight * 1.2

            background: Rectangle {
                gradient: Gradient {
                    orientation: Qt.Vertical
                    GradientStop { position: 0; color: Qt.hsla(0, 0, 0.5, 0.3) }
                    GradientStop { position: 0.95; color: Qt.hsla(0, 0, 0.5, 0.3) }
                    GradientStop { position: 1; color: Qt.hsla(0, 0, 0, 1) }
                }
            }

            GridLayout {
                id: buttonLayout
                anchors.centerIn: parent
                rows: 1
                columns: children.length
                rowSpacing: defaultRowSpacing
                columnSpacing: defaultColumnSpacing

                SceneButton {
                    id: livingRoomButton
                    Layout.margins: defaultColumnSpacing
                    icon.source: "../icons/oa/light_light"
                    text: "Wohnzimmer"
                    scale: 3
                    checkable: true
                    checked: true

                    property int index: 0
                }
                SceneButton {
                    id: livingRoomButton2
                    Layout.margins: defaultColumnSpacing
                    icon.source: "../icons/oa/scene_living"
                    text: "Wohnzimmer 2"
                    scale: 3
                    checkable: true

                    property int index: 1
                }
                SceneButton {
                    id: terraceButton
                    Layout.margins: defaultColumnSpacing
                    icon.source: "../icons/oa/scene_terrace"
                    text: "Terrasse"
                    scale: 3
                    checkable: true

                    property int index: 2
                }
            }
            Timer {
                id: backToLivingRoomTimer
                interval: root.backToHomeScreen * 60 * 1000
                onTriggered: mainButtons.checkedButton = livingRoomButton
            }

            ButtonGroup {
                id: mainButtons
                buttons: [ livingRoomButton, livingRoomButton2, terraceButton ]
                exclusive: true
                onCheckedButtonChanged: {
                    swipeView.currentIndex = checkedButton.index
                    //mainStack.replace(null, checkedButton.page)

                    if (checkedButton !== livingRoomButton)
                        backToLivingRoomTimer.restart()
                }
            }
        }

        SwipeView {
            id: swipeView
            interactive: false
            Layout.fillHeight: true
            Layout.fillWidth: true

            LivingRoomPage { }
            LivingRoomPage2 { }
            TerracePage { }
        }
    }
}
