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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.Window 2.12

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
            time.text = Qt.formatTime(d, root.showSeconds ? "hh:mm:ss" : "hh:mm")
            date.text = Qt.formatDate(d, "dddd\nd. MMMM yyyy")

            if (root.showSeconds)
                interval = 1000 - d.getMilliseconds()
            else
                interval = 1000 * (60 - d.getSeconds())
        }
    }
    onShowSecondsChanged: {
        timer.interval = 1
    }
}
