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
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Universal 2.12

Pane {
    id: root
    property alias headerText: header.text
    property color headerColor: {
        let col = Universal.accent
        let luma = 0.3 * col.r + 0.59 * col.g + 0.11 * col.b
        return luma <= 0.5 ? Qt.lighter(col) : col
    }
    property alias headerStatusText: headerStatus.text


    padding: 0

    background: Rectangle {
        anchors.fill: parent
        radius: root.font.pixelSize / 1.5
        color: Universal.background
    }

    default property alias content: content.data

    Label {
        id: header
        width: parent.width
        font.bold: true
        font.pixelSize: root.font.pixelSize / 3 * 2
        horizontalAlignment: Text.AlignHCenter
        anchors.top: parent.top
        color: root.headerColor
    }
    Label {
        id: headerStatus
        color: root.headerColor
        width: parent.width
        height: header.height
        font.bold: false
        font.pixelSize: root.font.pixelSize / 2
        horizontalAlignment: Text.AlignRight
        verticalAlignment: Text.AlignVCenter
        rightPadding: height / 2
        anchors.top: parent.top
    }
    Rectangle {
        anchors.top: header.bottom
        anchors.topMargin: 3
        width: parent.width
        height: 1
        gradient: Gradient {
            orientation: Qt.Horizontal
            GradientStop { position:   0; color: Universal.background }
            GradientStop { position: 0.5; color: root.headerColor }
            GradientStop { position:   1; color: Universal.background }
        }
    }

    Item {
        id: content
        anchors {
            top: header.bottom
            topMargin: 8
            left: parent.left
            leftMargin: 5
            right: parent.right
            rightMargin: 5
            bottom: parent.bottom
            bottomMargin: 5
        }
    }
}
