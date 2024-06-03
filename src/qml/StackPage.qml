// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import Ui


Page {
    id: root

    property alias actionIcon: action.icon

    signal actionClicked()
    
    header: Control {
        background: Rectangle {
            color: Qt.rgba(1, 1, 1, 0.3) //Universal.foreground
        }
        contentItem: RowLayout {
            anchors.fill: parent
            spacing: root.font.pixelSize  / 3
            
            SceneButton {
                icon.name: 'fa/angle-left-solid'
                background: null
                onClicked: root.StackView.view.pop()
            }
            Label {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignHCenter
                text: root.title
            }
            SceneButton {
                id: action
                background: null
                onClicked: {
                    root.actionClicked()
                }
            }
        }
    }
}
