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


StackPage {
    id: root

    property list<QtObject> players

    title: "Auswahl Player"
    padding: font.pixelSize

    Component.onCompleted: console.log("font:" + font.family)

    contentItem: GridLayout {
        columns: 2
        rowSpacing: root.padding
        columnSpacing: root.padding

        Repeater {
            model: root.players

            RoundButton {
                horizontalPadding: font.pixelSize
                highlighted: true
                radius: font.pixelSize / 2
                Layout.fillWidth: true
                text: modelData.name
                onClicked: {
                    root.StackView.view.push("BedsideAlarm.qml", { player: modelData })
                }
            }
        }
    }
}
