// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

pragma ComponentBehavior: Bound
import Qt5Compat.GraphicalEffects
import QtQuick.Controls.Universal
import QtQuick.Shapes as Shapes
import Ui


Slider {
    id: control

    enum SliderType {
        PlainType,
        BrightnessType,
        VolumeType,
        RGBType,
        HeatingType,
        CustomType
    }

    property int sliderType: SceneSlider.PlainType
    property var valueToHandleText: function(value) { return Math.round(value) }
    property var valueToHandleColor: function(value) { return Universal.accent }
    property bool showLabel: (sliderType === SceneSlider.HeatingType)
    property bool showIcon: (sliderType === SceneSlider.VolumeType
                             || sliderType === SceneSlider.BrightnessType) && !_showLabelTemporary
    property Gradient customGradient
    property real scale: 1

    live: true

    property bool _showLabelTemporary: false

    onPressedChanged: {
        if (pressed)
            _showLabelTemporary = true
        else
            _showLabelTemporaryTimer.restart()
    }
    Timer {
        id: _showLabelTemporaryTimer
        interval: 2000
        onTriggered: control._showLabelTemporary = false
    }

    implicitWidth: font.pixelSize * 8 * control.scale
    implicitHeight: font.pixelSize * 2 * control.scale

    background: Item {
        x: control.leftPadding + control.font.pixelSize / 2
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: control.availableWidth - control.font.pixelSize
        height: control.availableHeight

        RectangularGlow {
            anchors.fill: bgRect
            visible: control.sliderType !== SceneSlider.VolumeType
            glowRadius: 5
            spread: 0.5
            color: control.Universal.background
            cornerRadius: bgRect.radius + glowRadius
            cached: true
        }

        Rectangle {
            id: bgRect
            anchors.fill: parent
            visible: control.sliderType !== SceneSlider.VolumeType

            radius: control.font.pixelSize / 4
            color: control.Universal.foreground

            gradient: {
                switch (control.sliderType) {
                case SceneSlider.BrightnessType: return brightnessGradient
                case SceneSlider.RGBType:        return rgbGradient
                case SceneSlider.HeatingType:    return heatingGradient
                case SceneSlider.CustomType:     return control.customGradient
                default:                         return null
                }
            }

            property Gradient brightnessGradient: Gradient {
                orientation: Qt.Horizontal
                GradientStop { position: 0; color: Qt.hsla(0, 0, 0) }
                GradientStop { position: 1; color: Qt.hsla(0, 0, 1) }
            }
            property Gradient heatingGradient: Gradient {
                orientation: Qt.Horizontal
                GradientStop { position:    0; color: Qt.hsla(4/6, 1, 0.3) }
                GradientStop { position: 0.48; color: Qt.hsla(4/6, 1, 0.8) }
                GradientStop { position: 0.52; color: Qt.hsla(0/6, 1, 0.8) }
                GradientStop { position:    1; color: Qt.hsla(0/6, 1, 0.3) }
            }
            property Gradient rgbGradient: Gradient {
                orientation: Qt.Horizontal
                GradientStop { position: 0/6; color: Qt.hsva(0/6, 1, 1, 1) }
                GradientStop { position: 1/6; color: Qt.hsva(1/6, 1, 1, 1) }
                GradientStop { position: 2/6; color: Qt.hsva(2/6, 1, 1, 1) }
                GradientStop { position: 3/6; color: Qt.hsva(3/6, 1, 1, 1) }
                GradientStop { position: 4/6; color: Qt.hsva(4/6, 1, 1, 1) }
                GradientStop { position: 5/6; color: Qt.hsva(5/6, 1, 1, 1) }
                GradientStop { position: 6/6; color: Qt.hsva(6/6, 1, 1, 1) }
            }
        }
        Shapes.Shape {
            id: triangle
            z: 2
            anchors.fill: parent
            visible: control.sliderType === SceneSlider.VolumeType
            antialiasing: true
            layer.enabled: true
            layer.samples: 4
            layer.effect: Glow {
                radius: 10
                spread: 0.2
                color: control.Universal.background
                cached: true
            }

            property real radius: control.font.pixelSize / 4
            Shapes.ShapePath {
                fillColor: control.Universal.foreground
                fillGradient: Shapes.LinearGradient {
                    id: volumeGradient
                    x1: 0; x2: triangle.width
                    y1: 0; y2: 0
                    property real lightness: 0.4

                    GradientStop { position:  0/10; color: Qt.hsla(120/360, 1, volumeGradient.lightness) }
                    GradientStop { position:  1/10; color: Qt.hsla(110/360, 1, volumeGradient.lightness) }
                    GradientStop { position:  2/10; color: Qt.hsla(100/360, 1, volumeGradient.lightness) }
                    GradientStop { position:  3/10; color: Qt.hsla( 90/360, 1, volumeGradient.lightness) }
                    GradientStop { position:  4/10; color: Qt.hsla( 80/360, 1, volumeGradient.lightness) }
                    GradientStop { position:  5/10; color: Qt.hsla( 70/360, 1, volumeGradient.lightness) }
                    GradientStop { position:  6/10; color: Qt.hsla( 60/360, 1, volumeGradient.lightness) }
                    GradientStop { position:  7/10; color: Qt.hsla( 50/360, 1, volumeGradient.lightness) }
                    GradientStop { position:  8/10; color: Qt.hsla( 40/360, 1, volumeGradient.lightness) }
                    GradientStop { position:  9/10; color: Qt.hsla( 30/360, 1, volumeGradient.lightness) }
                    GradientStop { position: 10/10; color: Qt.hsla( 20/360, 1, volumeGradient.lightness) }
                }
                startX: 0
                startY: triangle.height
                PathLine {
                    x: triangle.width - triangle.radius; y: triangle.height
                }
                PathArc {
                    x: triangle.width; y: triangle.height - triangle.radius
                    radiusX: triangle.radius; radiusY: triangle.radius
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: triangle.width; y: 0 + triangle.radius
                }
                PathArc { x: triangle.width - triangle.radius; y: 0
                    radiusX: triangle.radius; radiusY: triangle.radius
                    direction: PathArc.Counterclockwise
                }
                PathLine {
                    x: 0; y: triangle.height
                }
            }
        }
    }

    handle: Item {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + control.availableHeight / 2 - height / 2
        width: control.font.pixelSize * 2 * control.scale
        height: control.font.pixelSize * 2 * control.scale

        RectangularGlow {
            anchors.fill: bg
            glowRadius: 5
            spread: 0.5
            color: control.Universal.background
            cornerRadius: bg.radius + glowRadius
            cached: true
        }
        Rectangle {
            id: bg
            anchors.fill: parent
            radius: height / 2
            color: control.sliderType === SceneSlider.RGBType ? Qt.hsva(control.position, 1, 1, 1)
                                                              : control.valueToHandleColor(control.value)
        }

        Label {
            anchors.fill: parent
            opacity: (control.showLabel || control._showLabelTemporary) ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 500 } }
            text: control.valueToHandleText(control.value)
            style: Text.Outline
            styleColor: Qt.rgba(control.Universal.background.r, control.Universal.background.g, control.Universal.background.b, 0.5)
            color: control.Universal.foreground
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            textFormat: Text.RichText
            font.pixelSize: control.font.pixelSize * control.scale
        }
        SvgIcon {
            anchors.fill: parent
            opacity: control.showIcon ? 1 : 0
            Behavior on opacity { NumberAnimation { duration: 500 } }
            source: control.sliderType === SceneSlider.VolumeType ? '/icons/mdi/volume-high'
                                                                  : '/icons/mdi/brightness-5'
            color: control.Universal.foreground
            scale: control.scale
            size: control.font.pixelSize
        }
    }
    Tracer { }
}
