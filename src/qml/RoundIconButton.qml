// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import Ui


RoundButton {
    id: root
    property alias scale: svgIcon.scale
    property real paddingScale: 2

    contentItem: SvgIcon {
        id: svgIcon
        anchors.centerIn: parent
        name: root.icon.name
        scale: 1.5
        size: root.font.pixelSize
        color: root.palette.buttonText
    }
    
    implicitHeight: Math.max(contentItem.implicitHeight, contentItem.implicitWidth) * paddingScale
    implicitWidth: implicitHeight
}
