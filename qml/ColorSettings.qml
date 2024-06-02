// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQml
import QtQuick.Window
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.griebl.haiq 1.0
import QtQuick.Controls.Universal

Control {
    id: root

    function updateStyle() {
        if (Window.window)
            Window.window.Universal.accent = Qt.hsla(hue.value/360, saturation.value/100, lightness.value/100)
    }

    function initialize() {
        let col = Window.window.Universal.accent
        //console.log("color initialize from " + col)
        hue.value = col.hslHue * hue.to
        saturation.value = col.hslSaturation * saturation.to
        lightness.value = col.hslLightness * lightness.to
    }

    property bool _portrait: Window.height > Window.width

    contentItem: GridLayout {
        id: grid
        columns: _portrait ? 1 : 2
        rowSpacing: 7
        columnSpacing: 7

        Label {            
            leftPadding: 10
            text: 'Farbe'
            font.pixelSize: root.font.pixelSize * (_portrait ? 0.5 : 1)
        }
        SceneSlider {
            id: hue
            Layout.fillWidth: true

            from: 0
            to: 360
            stepSize: 1

            sliderType: SceneSlider.RGBType
            onMoved: root.updateStyle()
        }
        Label {
            leftPadding: 10
            text: 'Sättigung'
            font.pixelSize: root.font.pixelSize * (_portrait ? 0.5 : 1)
        }
        SceneSlider {
            id: saturation
            Layout.fillWidth: true

            from: 0
            to: 100
            stepSize: 1

            sliderType: SceneSlider.CustomType
            customGradient: Gradient {
                orientation: Qt.Horizontal
                GradientStop { position: 0; color: Qt.hsla(hue.value/360, 0, 0.5) }
                GradientStop { position: 1; color: Qt.hsla(hue.value/360, 1, 0.5) }
            }
            valueToHandleColor: function(value) { return Qt.hsla(hue.value/360, saturation.position, 0.5) }            
            onMoved: root.updateStyle()
        }
        Label {
            leftPadding: 10
            text: 'Helligkeit'
            font.pixelSize: root.font.pixelSize * (_portrait ? 0.5 : 1)
        }
        SceneSlider {
            id: lightness
            Layout.fillWidth: true

            from: 0
            to: 100
            stepSize: 1

            sliderType: SceneSlider.CustomType
            customGradient: Gradient {
                orientation: Qt.Horizontal
                GradientStop { position:   0; color: Qt.hsla(hue.value/360, saturation.value/100,   0) }
                GradientStop { position: 0.5; color: Qt.hsla(hue.value/360, saturation.value/100, 0.5) }
                GradientStop { position:   1; color: Qt.hsla(hue.value/360, saturation.value/100,   1) }
            }
            valueToHandleColor: function(value) { return Qt.hsla(hue.value/360, saturation.value/100, lightness.position) }
            onMoved: root.updateStyle()
        }
        Flow {
            Layout.columnSpan: _portrait ? 1 : 2
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignCenter
            spacing: 12

            Repeater {
                id: predefined
                property var colors: {
                    // iOS dark
                    'apple': [
                                '#0a84ff', // Blue
                                '#30d158', // Green
                                '#5e5ce6', // Indigo
                                '#ff9f0a', // Orange
                                '#ff375f', // Pink
                                '#bf5af2', // Purple
                                '#ff453a', // Red
                                '#64d2ff', // Teal
                                '#ffd60a', // Yellow
                            ],
                    // Material
                    'android': [
                                '#F44336', // Red
                                '#E91E63', // Pink
                                '#9C27B0', // Purple
                                '#673AB7', // DeepPurple
                                '#3F51B5', // Indigo
                                '#2196F3', // Blue
                                '#03A9F4', // LightBlue
                                '#00BCD4', // Cyan
                                '#009688', // Teal
                                '#4CAF50', // Green
                                '#8BC34A', // LightGreen
                                '#CDDC39', // Lime
                                '#FFEB3B', // Yellow
                                '#FFC107', // Amber
                                '#FF9800', // Orange
                                '#FF5722', // DeepOrange
                                '#795548', // Brown
                                '#9E9E9E', // Grey
                                '#607D8B', // BlueGrey
                            ]
                }

                property var sortedColors: {
                    let result = []
                    for (let vendor in colors) {
                        for (let color of colors[vendor]) {
                            let col = Qt.tint(color, 'transparent')
                            result.push({ 'color': col, 'vendor': vendor })
                        }
                    }
                    return result.sort(function(a, b) {
                        return a['color'].hslHue - b['color'].hslHue
                    })
                }

                model: sortedColors.length
                SceneButton {
                    Universal.accent: predefined.sortedColors[index]['color']
                    onClicked: {
                        let col = this.Universal.accent
                        hue.value = col.hslHue * hue.to
                        saturation.value = col.hslSaturation * saturation.to
                        lightness.value = col.hslLightness * lightness.to
                        root.updateStyle()
                    }
                    icon.name: 'mdi/' + predefined.sortedColors[index]['vendor']
                }
            }
        }
    }
}
