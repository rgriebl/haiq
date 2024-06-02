// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import org.griebl.haiq 1.0


StackPage {
    id: root

    property QtObject player

    padding: 0
    title: player.name
    actionIcon.name: 'mdi/plus'
    onActionClicked: player.newAlarm()

    contentItem: ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: player.alarms

        header: ItemDelegate {
            width: ListView.view.width
            horizontalPadding: font.pixelSize / 2
            contentItem: RowLayout {
                spacing: font.pixelSize
                SceneButton {
                    font.pixelSize: root.font.pixelSize * 0.75
                    icon.name: 'mdi-rounded/alarm'

                    property bool alarmsEnabled: root.player.alarmsEnabled

                    Universal.accent: alarmsEnabled ? Qt.rgba(0.8, 0.8, 0.1, 1) : root.header.background.color

                    onClicked: root.player.alarmsEnabled = !alarmsEnabled
                }
                Label {
                    Layout.fillWidth: true
                    text: 'Alle Wecker An/Aus'
                }
            }
        }

        delegate: SwipeDelegate {
            id: swipeDelegate
            width: ListView.view.width
            horizontalPadding: font.pixelSize / 2

            property var dow: modelData.dayOfWeek

            contentItem: Control {
                contentItem: RowLayout {
                    spacing: font.pixelSize
                    SceneButton {
                        font.pixelSize: root.font.pixelSize * 0.75
                        icon.name: 'mdi-rounded/alarm'
                        Universal.accent: modelData.enabled ? Qt.rgba(0.8, 0.8, 0.1, 1) : root.header.background.color
                        onClicked: modelData.enabled = !modelData.enabled
                    }
                    Label {
                        property date time: new Date(1970, 0, 1, 0, 0, modelData.time)

                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.preferredWidth: swipeDelegate.width * .25
                        text: time.toLocaleTimeString('H:mm')
                        //horizontalAlignment: Text.AlignHCenter
                        MouseArea {
                            anchors.fill: parent
                            enabled: swipeDelegate.swipe.position === 0
                            onClicked: {
                                let picker = root.StackView.view.push("BedsideTimePicker.qml", {
                                                                          title: "Weckzeit",
                                                                          minute: parent.time.getMinutes(),
                                                                          hour: parent.time.getHours()
                                                                      })
                                picker.done.connect(function() {
                                    modelData.time = (picker.minute + (picker.hour * 60)) * 60
                                })
                            }
                        }
                    }
                    ColumnLayout {
                        id: dayPicker
                        //Layout.fillWidth: true
                        Layout.fillHeight: true
                        //Layout.preferredWidth: swipeDelegate.width * .75

                        TapHandler {
                            enabled: swipeDelegate.swipe.position === 0
                            onTapped: {
                                let picker = root.StackView.view.push("BedsideDayPicker.qml", {
                                                                          title: "Wecktage",
                                                                          dayOfWeek: modelData.dayOfWeek
                                                                      })
                                picker.done.connect(function() {
                                    modelData.dayOfWeek = picker.dayOfWeek
                                })
                            }
                        }

                        RowLayout {
                            //Layout.fillWidth: true
                            Repeater {
                                model: 5

                                Rectangle {
                                    implicitWidth: dayLabel.font.pixelSize * 1.5
                                    implicitHeight: dayLabel.implicitHeight
                                    Label {
                                        id: dayLabel
                                        anchors.fill: parent
                                        font.pixelSize: root.font.pixelSize / 1.6
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Qt.locale('de').dayName(index + 1, Locale.NarrowFormat)
                                    }
                                    color: swipeDelegate.dow.includes(index + 1) ? Universal.accent : 'transparent'
                                    radius: font.pixelSize / 2
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignCenter
                            Repeater {
                                model: 2
                                Rectangle {
                                    implicitWidth: dayLabel2.font.pixelSize * 1.5
                                    implicitHeight: dayLabel2.implicitHeight
                                    Label {
                                        id: dayLabel2
                                        font.pixelSize: root.font.pixelSize / 1.6
                                        anchors.fill: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Qt.locale('de').dayName(index ? 0 : 6, Locale.NarrowFormat)
                                    }
                                    radius: font.pixelSize / 2
                                    color: swipeDelegate.dow.includes(index ? 0 : 6) ? Universal.accent : 'transparent'
                                }
                            }
                        }

                    }
                    //                Label {
                    //                    Layout.fillWidth: true
                    //                    Layout.fillHeight: true
                    //                    Layout.preferredWidth: swipeDelegate.width * .75
                    //                    text: 'M D M D F\nS S'//modelData.dayOfWeekString
                    //                    horizontalAlignment: Text.AlignHCenter
                    //                    font.pixelSize: root.font.pixelSize * 5/8
                    //                    MouseArea {
                    //                        anchors.fill: parent
                    //                        enabled: swipeDelegate.swipe.position === 0
                    //                        onClicked: {
                    //                            let picker = root.StackView.view.push("BedsideDayPicker.qml", {
                    //                                                                      title: "Wecktage",
                    //                                                                      dayOfWeek: modelData.dayOfWeek
                    //                                                                  })
                    //                            picker.done.connect(function() {
                    //                                modelData.dayOfWeek = picker.dayOfWeek
                    //                            })
                    //                        }
                    //                    }
                    //                }
                    SceneButton {
                        icon.name: 'fa/angle-right-solid'
                        background: null
                        font.pixelSize: root.font.pixelSize * 0.75
                        onClicked: {
                            //                            let picker = root.StackView.view.push("BedsideAudioPicker.qml", {
                            //                                                                      title: "Wecktage",
                            //                                                                      dayOfWeek: modelData.dayOfWeek
                            //                                                                  })
                            //                            picker.done.connect(function() {
                            //                                modelData.dayOfWeek = picker.dayOfWeek
                            //                            })
                        }
                    }
                }

            }
            onClicked: if (swipe.position) swipe.close()

            swipe.right: Label {
                id: deleteLabel
                text: "Löschen"
                color: "white"
                verticalAlignment: Label.AlignVCenter
                height: parent.height
                anchors.right: parent.right
                leftPadding: font.pixelSize * 2
                rightPadding: leftPadding

                background: Rectangle {
                    color: deleteLabel.SwipeDelegate.pressed ? Qt.darker("tomato", 1.1) : "tomato"
                }
                SwipeDelegate.onClicked: {
                    swipeDelegate.swipe.close()
                    root.player.deleteAlarm(modelData.alarmId)
                }
            }
        }
        ScrollIndicator.vertical: ScrollIndicator { }
    }
}
