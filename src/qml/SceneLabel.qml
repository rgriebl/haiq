// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import Qt5Compat.GraphicalEffects
import Ui


Control {
    id: root

    property string text
    property alias icon: svgicon
    property int margins: 0

    contentItem: RowLayout {
        SvgIcon {
            id: svgicon
            Layout.margins: root.margins
            Layout.alignment: Qt.AlignCenter
            Layout.preferredWidth: implicitHeight
            color: 'white'
            scale: 2
            size: root.font.pixelSize

            layer.enabled: true
            layer.samples: 4
            layer.effect: Glow {
                radius: 20
                spread: 0.2
                samples: 41
                color: '#808080'
                cached: true
            }
        }
    }
}
