// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.impl

IconImage {
    id: root

    required property real size
    property real scale: 1

    color: palette.text

    fillMode: Image.PreserveAspectFit
    sourceSize.height: root.size * root.scale
}
