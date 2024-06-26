// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

pragma ComponentBehavior: Bound
import HAiQ
import Ui


Control {
    id: root

    property real textPercentage: 0.6

    BusyIndicator {
        anchors.centerIn: parent
        opacity: running ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
        running: listview.model.calendar.loading
        width: parent.width / 4
        height: width
    }

    ListView {
        id: listview
        clip: true
        anchors.fill: parent

        ScrollIndicator.vertical: ScrollIndicator { }

        PullToRefreshListHeader {
            onRefresh: upcoming.calendar.reload()
        }

        Timer {
            interval: 0.1 * 60 * 1000
            running: !listview.atYBeginning
            onTriggered: listview.positionViewAtBeginning()
        }

        model: UpcomingCalendarEntries {
            id: upcoming
            calendar: MainCalendar
            property int lastDate: -1

            function updateFromTo() {
                var now = new Date()
                if (now.getDate() !== upcoming.lastDate) {
                    now.setHours(0, 0, 0, 0) // clear time
                    var until = new Date(now)
                    until.setDate(now.getDate() + 62)
                    upcoming.from = now
                    upcoming.to = until
                    upcoming.lastDate = now.getDate();
                }
            }
        }

        Timer {
            interval: 10 /* minutes */ * (60 * 1000)
            triggeredOnStart: true
            repeat: true
            running: true
            onTriggered: {
                upcoming.calendar.reload()
                upcoming.updateFromTo()
            }
        }

        //headerPositioning: ListView.PullBackHeader
        header: Item {
            width: ListView.view.width
            height: startEndHeader.font.pixelSize * 1.5
            z: 1
            clip: true

            property real dx: width * (1 - root.textPercentage)

            Label {
                id: startEndHeader
                anchors.left: parent.left
                width: parent.dx
                horizontalAlignment: Text.AlignHCenter
                text: "Zeitpunkt"
                font.pixelSize: root.font.pixelSize / 2
            }
            Label {
                id: summaryHeader
                anchors.left: startEndHeader.right
                anchors.right: parent.right
                horizontalAlignment: Text.AlignHCenter
                text: "Beschreibung"
                font.pixelSize: startEndHeader.font.pixelSize
            }
        }
        delegate: Item {
            id: delegate
            required property int index
            required property var model

            width: ListView.view.width
            height: root.font.pixelSize * 3

            property real dx: width * (1 - root.textPercentage)
            property bool lastItem: (index === ListView.view.count - 1)

            property var locale: Qt.locale("de_DE")
//            property bool allDay: (model.startDateTime.getHours() === 0 && model.startDateTime.getMinutes() === 0)
//                                  && ((model.endDateTime.getHours() === 0 && model.endDateTime.getMinutes() === 0)
//                                      || (model.endDateTime.getHours() === 23 && model.endDateTime.getMinutes() === 59))
//            property bool sameDay: (model.startDateTime.getDate() === model.endDateTime.getDate())
//                                   && (model.startDateTime.getMonth() === model.endDateTime.getMonth())
//                                   && (model.startDateTime.getFullYear() === model.endDateTime.getFullYear())
//            property bool noDuration: !allDay && ((model.startDateTime.getHours() === model.endDateTime.getHours())
//                                          && (model.startDateTime.getMinutes() === model.endDateTime.getMinutes()))

            Label {
                id: dateLabel
                anchors.top: parent.top
                anchors.topMargin: font.pixelSize / 8
                anchors.left: parent.left
                width: delegate.dx
                horizontalAlignment: Text.AlignHCenter
                text: (delegate.model.sameDay ? delegate.model.startDateTime.toLocaleDateString(Qt.locale("de_DE"), "ddd ") : "")
                      + Qt.formatDate(delegate.model.startDateTime, "dd.MM.")
                      + (delegate.model.sameDay ? "" : (" - " + Qt.formatDate(delegate.model.endDateTime, "dd.MM.")))

            }
            Label {
                id: timeLabel
                anchors.top: dateLabel.bottom
                anchors.left: parent.left
                width: delegate.dx
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: dateLabel.font.pixelSize
                color: Qt.darker(dateLabel.color, 1.5)
                text: delegate.model.allDay ? ""
                                   : (Qt.formatTime(delegate.model.startDateTime, "hh:mm")
                                      + (delegate.model.duration ? (" - " + Qt.formatTime(delegate.model.endDateTime, "hh:mm")) : '' ))
            }
            Label {
                id: summaryLabel
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                anchors.left: dateLabel.right
                anchors.right: parent.right
                anchors.rightMargin: parent.ListView.view.ScrollIndicator.vertical.width
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: delegate.model.summary
                fontSizeMode: Text.Fit
                minimumPixelSize: font.pixelSize / 2
                wrapMode: Text.Wrap
                maximumLineCount: 2
                elide: Text.ElideRight
            }
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.topMargin: 3
                width: parent.width
                height: 1
                visible: !parent.lastItem
                gradient: Gradient {
                    orientation: Qt.Horizontal
                    GradientStop { position: 0.0; color: "#88000000" }
                    GradientStop { position: 0.5; color: "#ff888888" }
                    GradientStop { position: 1.0; color: "#88000000" }
                }
            }
        }
    }
}
