// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl

IconImage {
    id: root

    property string prefix: ''
    property string icon
    property real size: font.pixelSize
    property real scale: 1

    fillMode: Image.PreserveAspectFit

    color: palette.text
//    sourceSize.width: root.size * root.scale
    sourceSize.height: root.size * root.scale
    source: root.icon ? Qt.resolvedUrl('/icons/' + root.prefix + root.icon + '.svg') : ''
}
