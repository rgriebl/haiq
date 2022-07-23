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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import org.griebl.haiq 1.0


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
            spacing: font.pixelSize  / 3
            
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
