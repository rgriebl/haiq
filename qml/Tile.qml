// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal

Page {
    id: root
    property alias headerText: headerLabel.text
    property color headerColor: {
        let col = Universal.accent
        let luma = 0.3 * col.r + 0.59 * col.g + 0.11 * col.b
        return luma <= 0.5 ? Qt.lighter(col) : col
    }
    property alias headerStatusText: headerStatus.text

    background: Rectangle {
        anchors.fill: parent
        radius: root.font.pixelSize / 1.5
        color: Universal.background
    }

    header: Label {
        id: headerLabel
        width: parent.width
        font.bold: true
        font.pixelSize: root.font.pixelSize / 3 * 2
        horizontalAlignment: Text.AlignHCenter
        color: root.headerColor
        bottomPadding: 4

        Label {
            id: headerStatus
            color: root.headerColor
            anchors.fill: parent
            anchors.rightMargin: height / 2
            font.bold: false
            font.pixelSize: root.font.pixelSize / 2
            horizontalAlignment: Text.AlignRight
            verticalAlignment: Text.AlignVCenter
        }
        Rectangle {
            anchors.top: header.bottom
            anchors.topMargin: -3
            width: parent.width
            height: 1
            gradient: Gradient {
                orientation: Qt.Horizontal
                GradientStop { position:   0; color: Universal.background }
                GradientStop { position: 0.5; color: root.headerColor }
                GradientStop { position:   1; color: Universal.background }
            }
        }
    }
    topPadding: 8
    leftPadding: 5
    rightPadding: 5
    bottomPadding: 5
}
