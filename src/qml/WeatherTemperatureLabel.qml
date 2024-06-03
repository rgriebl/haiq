// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import Ui


Item {
    id: root
    property string prefix: ''
    property int temperature: 0
    property int temperatureFeelsLike: 0
    property bool showFeelsLike: false
    property int highTemperature: 20

    property alias padding: label.padding
    property alias verticalAlignment: label.verticalAlignment
    property alias horizontalAlignment: label.horizontalAlignment
    property alias font: label.font
    property alias minimumPixelSize: label.minimumPixelSize
    property alias fontSizeMode: label.fontSizeMode

    implicitWidth: label.implicitWidth / 2
    implicitHeight: label.implicitHeight

    function temperatureHtml(t) {
        var c = Qt.rgba(1, 1, 1, 1)
        if (t < 0)
            c = Qt.tint(c, Qt.rgba(0, 0, 1, 0.2 + t / -40))
        else if (t > highTemperature)
            c = Qt.tint(c, Qt.rgba(1, 0, 0, 0.2 + (t - highTemperature) / highTemperature))

        return '<font color="' + c + '">' + t + '</font>'
                + '<font size="1">°</font>'
    }

    Label {
        id: label
        anchors.fill: parent
        font.pixelSize: 30

        textFormat: Text.StyledText
        text: {
            var s = root.prefix + root.temperatureHtml(root.temperature)
            if (root.showFeelsLike && (Math.abs(root.temperature - root.temperatureFeelsLike) >= 3))
                s = s + ' (' + root.temperatureHtml(root.temperatureFeelsLike) + ')'
            return s
        }
    }
}
