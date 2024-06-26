// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import HAiQ
import Ui


StackPage {
    id: root

    property alias minute: minuteTumbler.currentIndex
    property alias hour: hourTumbler.currentIndex

    signal done()

    actionIcon.name: 'fa/check-solid'
    onActionClicked: {
        root.done()
        root.StackView.view.pop()
    }
    padding: 0

    contentItem: Control {
        font.pixelSize: root.font.pixelSize * 1.5

        RowLayout {
            anchors.fill: parent
            Component {
                id: delegateComponent

                Label {
                    required property int index
                    required property var modelData
                    id: label
                    property real d: Tumbler.displacement / (Tumbler.tumbler.visibleItemCount / 2)

                    text: String(modelData).padStart(2, '0')
                    opacity: 1 - 0.8 * Math.abs(d)
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: Tumbler.tumbler.font.pixelSize * (1 - 0.6 * Math.abs(d))
                    transform: Rotation {
                        origin { x: label.width / 2; y: label.height / 2 }
                        axis { x: 1; y: 0; z: 0 }
                        angle: Math.asin(label.d) * 180 / Math.PI
                    }
                }
            }
            Item { Layout.fillWidth: true }

            Tumbler {
                id: hourTumbler
                Layout.fillHeight: true
                Layout.preferredWidth: implicitWidth * 2
                visibleItemCount: 7
                model: 24
                delegate: delegateComponent
            }
            Label {
                Layout.alignment: Qt.AlignCenter
                text: " \u2236 "  // RATIO .. a normal ':' looks off-center
            }
            Tumbler {
                id: minuteTumbler
                Layout.fillHeight: true
                Layout.preferredWidth: implicitWidth * 2
                visibleItemCount: 7
                model: 60
                delegate: delegateComponent
            }
            Item { Layout.fillWidth: true }
        }
        Rectangle {
            anchors.centerIn: parent
            width: parent.width * 0.8
            height: parent.font.pixelSize * 0.9
            color: Qt.rgba(1,1,1,0.3)
            radius: height / 4
        }
    }
}
