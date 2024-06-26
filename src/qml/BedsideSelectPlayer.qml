// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

pragma ComponentBehavior: Bound
import HAiQ
import Ui


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
                required property SqueezeBoxPlayer modelData
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
