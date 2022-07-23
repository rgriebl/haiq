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
