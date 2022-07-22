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
import QtQuick.Window 2.12
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Universal 2.12
import QtQuick.Layouts 1.12
import QtQuick.VirtualKeyboard 2.15
import QtQuick.VirtualKeyboard.Settings 2.15
import org.griebl.haiq 1.0


TabletView {
    id: root

    screenWidth: 1920
    screenHeight: 1080

    font.family: "Noto Sans"
    font.bold: true
    font.pixelSize: height / 32

    property real defaultRowSpacing: font.pixelSize / 2
    property real defaultColumnSpacing: font.pixelSize / 4

    palette.text: Universal.foreground
    palette.window: Universal.background

    property Component defaultOverlay: Rectangle {
        color: Qt.rgba(0, 0, 0, 0.8)
        Behavior on opacity { NumberAnimation { duration: 200 } }
    }

    property int backToHomeScreen: 60 // min

    function showTimer() {
        alarmButton.checked = true
    }

    function showWeather() {
        weatherButton.checked = true
    }

    property int nightTimeStart: 23
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
            when: Qt.inputMethod.visible
            PropertyChanges {
                target: inputPanel
                y: root.height - inputPanel.height

            }
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
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.leftMargin: 25
            Layout.topMargin: 0
            Layout.bottomMargin: 10

            KitchenPage { }
            WeatherPage { entity: "sensor.wetter" }
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
                rowSpacing: defaultRowSpacing / 2
                columnSpacing: defaultColumnSpacing

                SceneButton {
                    id: homeButton
                    Layout.margins: defaultRowSpacing
                    icon.name: 'mdi/view-grid'
                    scale: 2
                    checkable: true
                    checked: true
                    ButtonGroup.group: mainButtons
                }
                SceneButton {
                    id: weatherButton
                    Layout.margins: defaultRowSpacing
                    icon.name: 'mdi/weather-partly-rainy'
                    scale: 2
                    checkable: true
                    ButtonGroup.group: mainButtons
                }
                SceneButton {
                    id: alarmButton
                    Layout.margins: defaultRowSpacing
                    icon.name: 'mdi-rounded/alarm'
                    scale: 2
                    checkable: true
                    ButtonGroup.group: mainButtons
                }
                SceneButton {
                    id: haButton
                    Layout.margins: defaultRowSpacing
                    icon.name: 'mdi/home-assistant'
                    scale: 2
                    checkable: true
                    ButtonGroup.group: mainButtons
                }
                SceneButton {
                    id: browserButton
                    Layout.margins: defaultRowSpacing
                    icon.name: 'mdi/firefox'
                    scale: 2
                    checkable: true
                    ButtonGroup.group: mainButtons
                }
                SceneButton {
                    property string entity: 'light.kueche_arbeitslicht'
                    property string entityState: ''

                    id: lightButton
                    Layout.margins: defaultRowSpacing
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
                        interval: 5000
                        onTriggered: lightPopup.close()
                    }

                    Popup {
                        id: lightPopup
                        width: root.contentItem.width - 2 * (root.contentItem.width - d) - 40
                        x: -20 - width
                        height: lightPopupSlider.implicitHeight

                        // force re-evaluation on show/hide
                        property real d: { if (visible || !visible) return lightButton.parent.mapToItem(root.contentItem, lightButton.x, 0).x }

                        padding: 0
                        background: null

                        SceneSlider {
                            font: lightButton.font
                            anchors.fill: parent

                            id: lightPopupSlider
                            from: 0; to: 100; stepSize: 5
                            sliderType: SceneSlider.BrightnessType

                            onMoved: HomeAssistant.callService('light.turn_on', lightButton.entity,
                                                               { brightness_pct: value })
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
