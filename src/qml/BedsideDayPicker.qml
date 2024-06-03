// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import HAiQ


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
