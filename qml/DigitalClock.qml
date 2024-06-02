// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window

Control {
    id: root
    spacing: font.pixelSize / 2

    property real timeDateSplitRatio: 2/3
    property bool showSeconds: false

    property int alternativeDateSwitchInterval: 30
    property alias alternativeDateText: alternative.text

    contentItem: ColumnLayout {
        Label {
            id: time
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: (date.font.pixelSize + time.font.pixelSize) * root.timeDateSplitRatio
//            height: root.height * root.timeDateSplitRatio

            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignBottom
            minimumPixelSize: root.font.pixelSize
            font.pixelSize: minimumPixelSize * 10
            fontSizeMode: Text.Fit
            font.bold: true
        }

        SwipeView {
            id: dateSwipe
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.preferredHeight: (date.font.pixelSize + time.font.pixelSize) * (1 - root.timeDateSplitRatio)

            clip: true
            interactive: false
            orientation: Qt.Vertical

            Label {
                id: date

                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignTop
                minimumPixelSize: time.minimumPixelSize / 2
                font.pixelSize: time.font.pixelSize / 2
                fontSizeMode: Text.Fit
                font.bold: true
            }

            Label {
                id: alternative
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignTop
                minimumPixelSize: date.minimumPixelSize
                font.pixelSize: date.font.pixelSize
                fontSizeMode: Text.Fit
                font.bold: true
                wrapMode: Text.Wrap

                text: root.alternativeDateText

                SequentialAnimation {
                    running: alternative.text !== ''
                    loops: Animation.Infinite
                    alwaysRunToEnd: true
                    PauseAnimation { duration: root.alternativeDateSwitchInterval * 1000 }
                    PropertyAction { target: dateSwipe; property: "currentIndex"; value: 1 }
                    PauseAnimation { duration: root.alternativeDateSwitchInterval * 1000 }
                    PropertyAction { target: dateSwipe; property: "currentIndex"; value: 0 }
                }
            }
        }
    }
    Timer {
        id: timer
        interval: 1
        running: true
        repeat: true
        onTriggered: {
            var d = new Date()
            time.text = d.toLocaleTimeString(Qt.locale("de"), root.showSeconds ? "hh:mm:ss" : "hh:mm")
            date.text = d.toLocaleDateString(Qt.locale("de"), "dddd\nd. MMMM yyyy")

            if (root.showSeconds)
                interval = 1000 - d.getMilliseconds()
            else
                interval = 1000 * (60 - d.getSeconds())
        }
    }
    Timer {
        id: noSecondsTimer
        interval: 15 * 60 * 1000 // 15min
        onTriggered: root.showSeconds = false
    }

    onShowSecondsChanged: {
        timer.interval = 1
        noSecondsTimer.start()
    }
}
