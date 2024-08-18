// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick.VirtualKeyboard
import QtQuick.VirtualKeyboard.Settings
import HAiQ
import Ui


TabletView {
    id: root

    screenWidth: 1920
    screenHeight: 1080

    font.family: "Noto Sans"
    font.bold: true
    font.pixelSize: height / 36

    property int backToHomeScreen: 15 // min

    property int nightTimeStart: 24
    property int nightTimeEnd: 6
    property bool nightTime: false

    Timer {
        running: true
        repeat: true
        interval: 1000 * 60 * 1 // every min
        onTriggered: {
            let now = new Date()
            nightTime = (now.getHours() >= nightTimeStart || now.getHours() < nightTimeEnd)
        }
    }

    onNightTimeChanged: {
        if (nightTime)
            ScreenBrightness.blankTimeout = 120
        else if (ScreenBrightness.blank)
            ScreenBrightness.blankTimeout = 0
    }

    Component.onCompleted: {
        drawer.dragMargin = 50

        // drawer.items.insert(0, {
        //     text: "Nachts ausschalten",
        //     iconName: "",
        //     action: function() { }
        // })

        ScreenBrightness.brightness = 1
        ScreenBrightness.normalBrightness = 1
        ScreenBrightness.dimBrightness = 1

        ScreenBrightness.screenSaverActive = true

        HomeAssistant.subscribe("sun.sun", function(state, attributes) {
            var light = Math.min(Math.max(attributes.elevation / 45, 0), 1)
            var factor = light * 0.8 + 0.2

            console.warn("Light: " + light + " -- setting new factor: " + factor)

            if (!nightTime)
                ScreenBrightness.normalBrightness = factor
        })
        HomeAssistant.subscribe("group.irgendwer", function(state, attributes) {
            if (!nightTime)
                ScreenBrightness.blankTimeout = (state === "not_home") ? 120 : 0;
        })
    }

    InputPanel {
        id: inputPanel
        y: root.height
        x: 0
        z: 9000
        width: root.width
        externalLanguageSwitchEnabled: true
        onExternalLanguageSwitch: {
            VirtualKeyboardSettings.locale = VirtualKeyboardSettings.locale === "de_DE" ? "en_US" : "de_DE"
        }

        Component.onCompleted: {
            VirtualKeyboardSettings.locale = "de_DE"
        }

        states: State {
            name: "active"
            when: InputMethod.visible
            PropertyChanges { inputPanel.y: root.height - inputPanel.height }
        }
        transitions: Transition {
            to: "active"
            reversible: true
            NumberAnimation {
                properties: "y"
                duration: 300
                easing.type: Easing.InOutCubic
            }
        }
    }

    GridLayout {
        id: grid
        anchors.fill: parent

        rowSpacing: 0
        columnSpacing: 0
        rows: 1
        columns: 2

        SwipeView {
            id: swipeView
            interactive: false
            orientation: Qt.Vertical
            clip: true
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: 25
            Layout.topMargin: 0
            Layout.bottomMargin: 10

            KitchenPage {
                onRequestShowWeather: weatherButton.checked = true
            }
            WeatherPage { location: "osterseeon" }
            AlarmPage { }
            HomeAssistantPage { }
            BrowserPage { }
        }

        Pane {
            id: mainMenu
            Layout.fillHeight: true
            Layout.preferredWidth: buttonLayout.implicitWidth * 1.03
            Layout.rightMargin: 25
            Layout.topMargin: 0
            Layout.bottomMargin: 10

            background: Rectangle {
                gradient: Gradient {
                    orientation: Qt.Horizontal
                    GradientStop { position: 0; color: Qt.hsla(0, 0, 0, 1) }
                    GradientStop { position: 0.05; color: Qt.hsla(0, 0, 0.5, 0.3) }
                    GradientStop { position: 1; color: Qt.hsla(0, 0, 0.5, 0.3) }
                }
            }
            font.pixelSize: root.font.pixelSize * 2


            GridLayout {
                id: buttonLayout
                anchors.centerIn: parent
                columns: 1
                rows: children.length
                rowSpacing: root.font.pixelSize / 2
                columnSpacing: rowSpacing / 2

                SceneButton {
                    id: homeButton
                    Layout.margins: buttonLayout.rowSpacing
                    icon.name: 'mdi/view-grid'
                    scale: 2
                    checkable: true
                    checked: true
                    ButtonGroup.group: mainButtons
                }
                SceneButton {
                    id: weatherButton
                    Layout.margins: buttonLayout.rowSpacing
                    icon.name: 'mdi/weather-partly-rainy'
                    scale: 2
                    checkable: true
                    ButtonGroup.group: mainButtons
                }
                SceneButton {
                    id: alarmButton
                    Layout.margins: buttonLayout.rowSpacing
                    icon.name: 'mdi-rounded/alarm'
                    scale: 2
                    checkable: true
                    ButtonGroup.group: mainButtons
                }
                SceneButton {
                    id: haButton
                    Layout.margins: buttonLayout.rowSpacing
                    icon.name: 'mdi/home-assistant'
                    scale: 2
                    checkable: true
                    ButtonGroup.group: mainButtons
                }
                SceneButton {
                    id: browserButton
                    Layout.margins: buttonLayout.rowSpacing
                    icon.name: 'mdi/firefox'
                    scale: 2
                    checkable: true
                    ButtonGroup.group: mainButtons
                }
                SceneButton {
                    property string entity: 'light.kueche_arbeitslicht'
                    property string entityState: ''

                    id: lightButton
                    Layout.margins: buttonLayout.rowSpacing
                    icon.name: 'mdi/lightbulb-on'
                    scale: 2
                    checkable: true
                    checked: (entityState === "on")

                    Component.onCompleted: {
                        HomeAssistant.subscribe(entity, function(state, attributes) {
                            entityState = state
                            if (!lightPopupSlider.pressed)
                                lightPopupSlider.value = 100 * (attributes.brightness || 0) / 255
                        })
                    }

                    onPressAndHold: {
                        lightPopup.open()
                        lightPopupHideTimer.start()
                    }

                    onToggled: {
                        HomeAssistant.callService(checked ? 'light.turn_on' : 'light.turn_off',
                                                  lightButton.entity)
                        if (checked) {
                            lightPopupShowTimer.start()
                            lightPopupHideTimer.start()
                        }
                    }

                    Timer {
                        id: lightPopupShowTimer
                        interval: 100
                        onTriggered: lightPopup.open()
                    }

                    Timer {
                        id: lightPopupHideTimer
                        interval: 3000
                        onTriggered: lightPopup.close()
                    }

                    Popup {
                        id: lightPopup
                        width: root.contentItem.width - 2 * (root.contentItem.width - d) - 40
                        x: -20 - width
                        height: lightPopupSlider.implicitHeight

                        modal: true
                        dim: false

                        // force re-evaluation on show/hide
                        property real d: { if (visible || !visible) return lightButton.parent.mapToItem(root.contentItem, lightButton.x, 0).x }

                        padding: 0
                        background: null

                        SceneSlider {
                            font: lightButton.font
                            anchors.fill: parent
                            scale: 2

                            id: lightPopupSlider
                            from: 0; to: 100; stepSize: 5
                            sliderType: SceneSlider.BrightnessType

                            onMoved: {
                                lightPopupHideTimer.restart()

                                HomeAssistant.callService('light.turn_on', lightButton.entity,
                                                          { brightness_pct: value })
                            }
                        }
                    }
                }
            }
            Timer {
                id: backToHomeTimer
                interval: root.backToHomeScreen * 60 * 1000
                onTriggered: homeButton.checked = true
            }

            ButtonGroup {
                id: mainButtons
                exclusive: true
                onCheckedButtonChanged: {
                    for (let i = 0; i < buttons.length; ++i) {
                        if (checkedButton === buttons[i]) {
                            swipeView.currentIndex = buttons.length - 1 - i
                            break
                        }
                    }

                    if (checkedButton !== homeButton)
                        backToHomeTimer.restart()
                }
            }
        }
    }
    Item {
        visible: false
        focus: true
    }
}
