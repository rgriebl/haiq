// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls


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
            icon: 'mdi/refresh'
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
