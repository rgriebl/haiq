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
import QtQuick.Layouts 1.12
import QtQuick.Controls.Universal 2.12
import org.griebl.haiq 1.0


StackPage {
    id: root

    property var dayOfWeek: []

    signal done()

    actionIcon.name: 'fa/check-solid'
    onActionClicked: {
        root.done()
        root.StackView.view.pop()
    }
    horizontalPadding: font.pixelSize / 2

    contentItem: GridLayout {
        columns: 2
        rowSpacing: root.horizontalPadding / 4
        columnSpacing: root.horizontalPadding
        Repeater {
            model: 7

            RoundButton {
                property int day: index == 6 ? 0 : index + 1

                Layout.row: (index < 5 ? index : index + 1) / 2
                Layout.column: (index < 5 ? index : index + 1) % 2
                Layout.preferredWidth: 100000
                Layout.fillWidth: true

                //horizontalPadding: font.pixelSize
                radius: font.pixelSize / 2
                highlighted: root.dayOfWeek.includes(day)

                text: Qt.locale('de').standaloneDayName(day)

                onClicked: {
                    if (highlighted)
                        root.dayOfWeek = root.dayOfWeek.filter(d => d !== day)
                    else
                        root.dayOfWeek = root.dayOfWeek.concat([day])
                }
            }
        }
    }
}
