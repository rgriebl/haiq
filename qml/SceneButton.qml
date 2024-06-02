// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Universal
import Qt5Compat.GraphicalEffects

Button {
    id: root

    icon.color: Universal.foreground

    property bool round: false
    property real scale: 1

    implicitHeight: font.pixelSize * 2
    implicitWidth: implicitHeight

    contentItem: SvgIcon {
        id: svgicon
        name: root.icon.name
        source: root.icon.source
        scale: root.scale
        color: !root.enabled ? Qt.darker(root.icon.color, 1.6)
                             : root.down ? Qt.darker(root.icon.color, 1.1)
                                         : root.icon.color
    }
    background: Item {
        RectangularGlow {
            anchors.fill: bg
            glowRadius: 10
            spread: 0.5
            color: root.checked || root.highlighted ? Universal.foreground
                                                    : Universal.background
            cornerRadius: bg.radius + glowRadius
            cached: true
        }
        Rectangle {
            id: bg
            anchors.fill: parent
            radius: root.round ? height / 2 : root.font.pixelSize / 2
            color: !root.enabled ? Qt.darker(Universal.accent, 1.6)
                                 : root.down ? Qt.darker(Universal.accent, 1.1)
                                             : Universal.accent

            // poor man's glow...
            border.width: GraphicsInfo.api === GraphicsInfo.Software ? (root.checked || root.highlighted ? 4 : 2) : 0
            border.color: root.checked || root.highlighted ? Universal.foreground
                                                           : Universal.background
        }
    }
    Tracer { }
}
