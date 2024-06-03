// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import HAiQ
import Ui


TabletView {
    id: root

    screenWidth: 800
    screenHeight: 1280

    font.family: "Noto Sans"
    font.bold: true
    font.pixelSize: height / 27

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
                rowSpacing: root.font.pixelSize
                columnSpacing: rowSpacing / 4

                component CheckButton : SceneButton {
                    required property int index
                }

                CheckButton {
                    id: livingRoomButton
                    Layout.margins: buttonLayout.columnSpacing
                    icon.source: "/icons/oa/light_light"
                    text: "Wohnzimmer"
                    scale: 3
                    checkable: true
                    checked: true

                    index: 0
                }
                CheckButton {
                    id: livingRoomButton2
                    Layout.margins: buttonLayout.columnSpacing
                    icon.source: "/icons/oa/scene_living"
                    text: "Wohnzimmer 2"
                    scale: 3
                    checkable: true

                    index: 1
                }
                CheckButton {
                    id: terraceButton
                    Layout.margins: buttonLayout.columnSpacing
                    icon.source: "/icons/oa/scene_terrace"
                    text: "Terrasse"
                    scale: 3
                    checkable: true

                    index: 2
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
                    swipeView.currentIndex = (checkedButton as CheckButton).index
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
