// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

pragma ComponentBehavior: Bound
import HAiQ
import Ui


StackPage {
    id: root

    required property SqueezeBoxPlayer player

    padding: 0
    title: player.name
    actionIcon.name: 'mdi/plus'
    onActionClicked: player.newAlarm()

    contentItem: ListView {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true
        model: root.player.alarms

        header: ItemDelegate {
            id: alarmsDelegate
            width: ListView.view.width
            horizontalPadding: font.pixelSize / 2
            contentItem: RowLayout {
                spacing: alarmsDelegate.font.pixelSize
                SceneButton {
                    font.pixelSize: root.font.pixelSize * 0.75
                    icon.name: 'mdi-rounded/alarm'

                    property bool alarmsEnabled: root.player.alarmsEnabled

                    Universal.accent: alarmsEnabled ? Qt.rgba(0.8, 0.8, 0.1, 1)
                                                    : Qt.rgba(1, 1, 1, 0.3)

                    onClicked: root.player.alarmsEnabled = !alarmsEnabled
                }
                Label {
                    Layout.fillWidth: true
                    text: 'Alle Wecker An/Aus'
                }
            }
        }

        delegate: SwipeDelegate {
            required property var modelData

            id: swipeDelegate
            width: ListView.view.width
            horizontalPadding: font.pixelSize / 2

            property var dow: modelData.dayOfWeek

            contentItem: Control {
                contentItem: RowLayout {
                    spacing: root.font.pixelSize
                    SceneButton {
                        font.pixelSize: root.font.pixelSize * 0.75
                        icon.name: 'mdi-rounded/alarm'
                        Universal.accent: swipeDelegate.modelData.enabled ? Qt.rgba(0.8, 0.8, 0.1, 1)
                                                                          : Qt.rgba(1, 1, 1, 0.3)
                        onClicked: swipeDelegate.modelData.enabled = !swipeDelegate.modelData.enabled
                    }
                    Label {
                        property date time: new Date(1970, 0, 1, 0, 0, swipeDelegate.modelData.time)

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
                                    swipeDelegate.modelData.time = (picker.minute + (picker.hour * 60)) * 60
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
                                                                          dayOfWeek: swipeDelegate.modelData.dayOfWeek
                                                                      })
                                picker.done.connect(function() {
                                    swipeDelegate.modelData.dayOfWeek = picker.dayOfWeek
                                })
                            }
                        }

                        RowLayout {
                            //Layout.fillWidth: true
                            Repeater {
                                model: 5

                                Rectangle {
                                    required property int index
                                    id: weekdayDelegate

                                    implicitWidth: dayLabel.font.pixelSize * 1.5
                                    implicitHeight: dayLabel.implicitHeight
                                    Label {
                                        id: dayLabel
                                        anchors.fill: parent
                                        font.pixelSize: root.font.pixelSize / 1.6
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Qt.locale('de').dayName(weekdayDelegate.index + 1, Locale.NarrowFormat)
                                    }
                                    color: swipeDelegate.dow.includes(weekdayDelegate.index + 1) ? Universal.accent : 'transparent'
                                    radius: root.font.pixelSize / 2
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignCenter
                            Repeater {
                                model: 2
                                Rectangle {
                                    required property int index
                                    id: weekendDelegate
                                    implicitWidth: dayLabel2.font.pixelSize * 1.5
                                    implicitHeight: dayLabel2.implicitHeight
                                    Label {
                                        id: dayLabel2
                                        font.pixelSize: root.font.pixelSize / 1.6
                                        anchors.fill: parent
                                        horizontalAlignment: Text.AlignHCenter
                                        text: Qt.locale('de').dayName(weekendDelegate.index ? 0 : 6, Locale.NarrowFormat)
                                    }
                                    radius: root.font.pixelSize / 2
                                    color: swipeDelegate.dow.includes(weekendDelegate.index ? 0 : 6) ? Universal.accent : 'transparent'
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
                    root.player.deleteAlarm(swipeDelegate.modelData.alarmId)
                }
            }
        }
        ScrollIndicator.vertical: ScrollIndicator { }
    }
}
