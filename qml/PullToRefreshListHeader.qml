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


Control {
    id: root
    height: 60
    width: parent.width
    y: -pullOffset - height
    property var listView: root.parent
    property real pullOffset: listView.contentY - listView.originY
    property real neededPullOffset: -listView.height / 3
    property bool pulled: false
    property real pullProgress: 0

    signal refresh()

    Connections {
        target: root.listView
        function onDragEnded() {
            if (root.pulled) {
                root.pulled = false
                root.refresh()
            }
        }
        function onContentYChanged() {
            if (!root.pulled && root.listView.dragging) {
                if (root.pullOffset < root.neededPullOffset)
                    root.pulled = true
                else if (root.pullOffset < 0)
                    root.pullProgress = Math.min(1, root.pullOffset / root.neededPullOffset)
            }
        }
    }

    Row {
        spacing: 6
        height: childrenRect.height
        anchors.centerIn: parent

        SvgIcon {
            id: arrow
            icon: '../icons/mdi/refresh'
            size: root.font.pixelSize * 2
            transformOrigin: Item.Center
            rotation: root.pullProgress * 360
            opacity: root.pullProgress
            Behavior on rotation { NumberAnimation { duration: 50 } }

            RotationAnimation on rotation {
                running: root.pulled
                duration: 750
                from: 0
                to: 360
                loops: Animation.Infinite
            }
        }
    }
}
