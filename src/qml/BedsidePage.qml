// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick.Controls.Universal
import HAiQ
import Ui


Control {
    id: root
    required property Item mainStack

    required property string blindsEntity
    required property string ceilingLightEntity
    required property string ceilingLightIcon
    required property string wardrobeLightEntity
    required property string wardrobeLightIcon

    GridLayout {
        id: topLayout

        property real spacing: root.font.pixelSize  / 3

        anchors.fill: parent
        anchors.margins: spacing / 2
        rowSpacing: spacing
        columnSpacing: spacing

        columns: 3

        SceneButton {
            Layout.row: 0
            Layout.column: 0
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop

            visible: root.ceilingLightEntity !== 'none'

            icon.name: root.ceilingLightIcon
            Universal.accent: Qt.rgba(0.5, 0.5, 1, 0.9)
            onClicked: HomeAssistant.callService("switch.toggle", root.ceilingLightEntity)
        }
        SceneButton {
            Layout.row: 1
            Layout.column: 0
            Layout.alignment: Qt.AlignLeft | Qt.AlignTop

            visible: root.wardrobeLightEntity !== 'none'

            icon.name: root.wardrobeLightIcon
            Universal.accent: Qt.rgba(0.5, 0.5, 1, 0.9)
            onClicked: HomeAssistant.callService("switch.toggle", root.wardrobeLightEntity)
        }
        SwipeView {
            id: alarmBar

            Layout.row: 3
            Layout.column: 0
            Layout.columnSpan: 3
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignLeft | Qt.AlignBottom

            interactive: false
            orientation: Qt.Horizontal
            clip: true

            currentIndex: SqueezeBoxServer.thisPlayer && SqueezeBoxServer.thisPlayer.alarmActive ? 1 : 0

            property color barColor: alarmBar.currentIndex === 1 ? 'transparent' : Qt.rgba(1, 1, 1, 0.3)

            background: Rectangle {
                color: alarmBar.barColor
                radius: alarmButton.font.pixelSize / 2
            }

            RowLayout {
                id: alarmRow
                spacing: topLayout.spacing

                SceneButton {
                    id: alarmButton
                    icon.name: 'mdi-rounded/alarm'

                    property bool alarmsEnabled: SqueezeBoxServer.thisPlayer ? SqueezeBoxServer.thisPlayer.alarmsEnabled : false
                    Universal.accent: alarmsEnabled ? Qt.rgba(0.8, 0.8, 0.1, 1) : alarmBar.barColor
                    onClicked: if (SqueezeBoxServer.thisPlayer) SqueezeBoxServer.thisPlayer.alarmsEnabled = !alarmsEnabled
                }
                Label {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter


                    property string nextTime: SqueezeBoxServer.thisPlayer && SqueezeBoxServer.thisPlayer.nextAlarm
                                              ? SqueezeBoxServer.thisPlayer.nextAlarm.toLocaleTimeString('H:mm')
                                              : ''

                    font.pixelSize: root.font.pixelSize * 1.3
                    text: nextTime

                    MouseArea {
                        anchors.fill: parent
                        onClicked: {
                            if (SqueezeBoxServer.thisPlayer)
                                root.mainStack.push("BedsideAlarm.qml", { player: SqueezeBoxServer.thisPlayer })
                        }
                    }
                }
                SceneButton {
                    id: alarmMenu
                    background: null
                    icon.name: 'fa/angle-right-solid'
                    onClicked: root.mainStack.push("BedsideSelectPlayer.qml", { players: SqueezeBoxServer.players })
                }
            }

            // if alarm is active...
            RowLayout {
                id: alarmActiveRow
                spacing: topLayout.spacing

                RoundButton {
                    id: snoozeButton
                    text: "Snooze"
                    enabled: SqueezeBoxServer.thisPlayer
                             && SqueezeBoxServer.thisPlayer.alarmActive
                             && !SqueezeBoxServer.thisPlayer.snoozing
                    onClicked: if (SqueezeBoxServer.thisPlayer) SqueezeBoxServer.thisPlayer.alarmSnooze()

                    horizontalPadding: font.pixelSize / 2
                    highlighted: true
                    radius: font.pixelSize / 2

                    Layout.fillWidth: true
                    Layout.preferredWidth: Math.max(snoozeButton.implicitWidth, stopButton.implicitWidth)
                }
                RoundButton {
                    id: stopButton
                    text: "Stop"
                    enabled: SqueezeBoxServer.thisPlayer && SqueezeBoxServer.thisPlayer.alarmActive
                    onClicked: if (SqueezeBoxServer.thisPlayer) SqueezeBoxServer.thisPlayer.alarmStop()

                    horizontalPadding: font.pixelSize / 2
                    highlighted: true
                    radius: font.pixelSize / 2

                    Layout.fillWidth: true
                    Layout.preferredWidth: snoozeButton.Layout.preferredWidth
                }
            }
        }

        DigitalClock {
            id: clock
            Layout.row: 0
            Layout.rowSpan: 3
            Layout.column: 1
            Layout.alignment: Qt.AlignCenter
            Layout.fillHeight: true
            Layout.fillWidth: true

            timeDateSplitRatio: 0.7
            alternativeDateText: upcoming.nextEntry
            alternativeDateSwitchInterval: 10

            Timer {
                interval: 30 /* minutes */ * (60 * 1000)
                triggeredOnStart: true
                repeat: true
                running: true
                onTriggered: MainCalendar.reload()
            }

            Connections {
                target: MainCalendar
                function onLoadingChanged() {
                    if (!MainCalendar.loading)
                        upcoming.updateFromTo()
                }
            }

            UpcomingCalendarEntries {
                id: upcoming
                calendar: MainCalendar
                property string nextEntry

                function updateFromTo() {
                    let now = new Date()
                    let until = new Date()
                    until.setTime(now.getTime() + 12 *60*60*1000)
                    from = now
                    to = until

                    let newNextEntry = ''

                    for (let i = 0; i < count; ++i) {
                        let e = get(i)
                        if (!e.allDay && e.sameDay) {
                            newNextEntry = e.startDateTime.toLocaleString(Qt.locale("de_DE"), "hh:mm")
                                    + " " + e.summary
                            break
                        }
                    }
                    if (newNextEntry !== nextEntry)
                        nextEntry = newNextEntry
                }
            }
        }

        SceneButton {
            Layout.row: 0
            Layout.column: 2
            Layout.alignment: Qt.AlignRight | Qt.AlignTop

            icon.name: 'fa/angle-double-up-solid'
            Universal.accent: Qt.rgba(0.5, 1, 0.5, 0.9)
            onClicked: HomeAssistant.callService("cover.open_cover", root.blindsEntity)
        }
        SceneButton {
            Layout.row: 1
            Layout.column: 2
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter

            icon.name: 'fa/stop-solid'
            Universal.accent: Qt.rgba(1, 0.5, 0.5, 0.9)
            onClicked: HomeAssistant.callService("cover.stop_cover", root.blindsEntity)
        }
        SceneButton {
            Layout.row: 2
            Layout.column: 2
            Layout.alignment: Qt.AlignRight | Qt.AlignBottom

            icon.name: 'fa/angle-double-down-solid'
            Universal.accent: Qt.rgba(0.5, 1, 0.5, 0.9)
            onClicked: HomeAssistant.callService("cover.close_cover", root.blindsEntity)
        }
    }
}
