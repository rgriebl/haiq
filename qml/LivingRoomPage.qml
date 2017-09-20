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
import QtQml 2.12
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Universal 2.12
import org.griebl.haiq 1.0

Control {
    id: root

    property real rowSpacing: defaultRowSpacing
    property real columnSpacing: defaultColumnSpacing

    topPadding: rowSpacing
    bottomPadding: 0
    leftPadding: 0
    rightPadding: columnSpacing * 2

    contentItem: GridLayout {
        id: grid
        columns: 2
        rowSpacing: root.rowSpacing
        columnSpacing: root.columnSpacing

        SceneLabel {
            icon.name: 'oa/light_led_stripe'
            text: "Szenen"
        }
        RowLayout {
            spacing: root.columnSpacing
            Layout.fillWidth: true

            SceneButton {
                icon.name: 'mdi/bed'
                onClicked: HomeAssistant.callService('scene.turn_on', 'scene.wohnzimmer_bett')
            }
            SceneButton {
                icon.name: 'mdi/weather-night'
                onClicked: HomeAssistant.callService('scene.turn_on', 'scene.wohnzimmer_abends')
            }
            SceneButton {
                icon.name: 'mdi/television'
                onClicked: HomeAssistant.callService('scene.turn_on', 'scene.wohnzimmer_tv')
            }
            SceneButton {
                icon.name: 'mdi/lightbulb-on-outline'
                onClicked: HomeAssistant.callService('scene.turn_on', 'scene.wohnzimmer_voll')
            }
        }
        SceneLabel {
            icon.name: 'oa/light_dinner_table'
            text: "Esstisch"
        }
        RowLayout {
            id: esstisch
            spacing: root.columnSpacing
            Layout.fillWidth: true

            property string entity: 'light.oeq0105649'
            property string entityState: ''

            SceneButton {
                icon.name: 'mdi/power-off'
                enabled: parent.entityState !== 'off'
                onClicked: HomeAssistant.callService('light.turn_off', parent.entity)
            }
            SceneButton {
                icon.name: 'mdi/brightness-6'
                opacity: 0.01
                enabled: false
            }
            SceneButton {
                icon.name: 'mdi/brightness-7'
                property int brightness: 100
                enabled: parent.entityState !== 'on'
                onClicked: HomeAssistant.callService('light.turn_on', parent.entity)
            }
            Component.onCompleted: {
                HomeAssistant.subscribe(entity, function(state, attributes) {
                    entityState = state
                })
            }
        }
        SceneLabel {
            icon.name: 'world-map'
            text: "Weltkarte"
        }
        RowLayout {
            id: weltkarte
            spacing: root.columnSpacing
            Layout.fillWidth: true

            property string entity: 'light.wohnzimmer_weltkarte'

            SceneButton {
                icon.name: 'mdi/power-off'
                enabled: weltkarteSlider.value !== 0
                onClicked: HomeAssistant.callService('light.turn_off', weltkarte.entity)
            }
            SceneButton {
                icon.name: 'mdi/brightness-6'
                property int brightness: 35
                enabled: weltkarteSlider.value !== brightness
                onClicked: HomeAssistant.callService('light.turn_on', weltkarte.entity,
                                                      { brightness_pct: brightness })
            }
            SceneButton {
                icon.name: 'mdi/brightness-7'
                property int brightness: 100
                enabled: weltkarteSlider.value !== brightness
                onClicked: HomeAssistant.callService('light.turn_on', weltkarte.entity,
                                                      { brightness_pct: brightness })
            }
            SceneSlider {
                Layout.fillWidth: true

                id: weltkarteSlider
                from: 0; to: 100; stepSize: 5
                 sliderType: SceneSlider.BrightnessType

                onMoved: HomeAssistant.callService('light.turn_on', weltkarte.entity,
                                                    { brightness_pct: value })
            }
            Component.onCompleted: {
                HomeAssistant.subscribe(weltkarte.entity, function(state, attributes) {                    
                    if (!weltkarteSlider.pressed)
                        weltkarteSlider.value = 100 * (attributes.brightness || 0) / 255
                })
            }
        }
        SceneLabel {
            icon.name: 'oa/light_wall_1'
            text: "Deckenfluter"
        }
        GridLayout {
            id: decke
            columnSpacing: root.columnSpacing
            rowSpacing: root.rowSpacing
            Layout.fillWidth: true
            columns: 6

            property string entity: 'light.wohnzimmer_deckenlicht'
            property string fensterEntity: 'light.wohnzimmer_fensterfront'
            property alias slider: deckeSlider

            SceneButton {
                icon.name: 'mdi/power-off'
                enabled: parent.slider.value !== 0
                onClicked: HomeAssistant.callService('light.turn_off', parent.entity)
            }
            SceneButton {
                icon.name: 'mdi/brightness-6'
                property int brightness: 35
                enabled: parent.slider.value !== brightness
                onClicked: HomeAssistant.callService('light.turn_on', parent.entity,
                                                      { brightness_pct: brightness })
            }
            SceneButton {
                icon.name: 'mdi/brightness-7'
                property int brightness: 100
                enabled: parent.slider.value !== brightness
                onClicked: HomeAssistant.callService('light.turn_on', parent.entity,
                                                      { brightness_pct: brightness })
            }
            SceneSlider {
                Layout.fillWidth: true
                Layout.columnSpan: 3

                id: deckeSlider
                from: 0; to: 100; stepSize: 5
                sliderType: SceneSlider.BrightnessType

                onMoved: HomeAssistant.callService('light.turn_on', parent.entity,
                                                    { brightness_pct: value })
            }
            SceneSlider {
                Layout.fillWidth: true
                Layout.columnSpan: 3

                id: fensterRgbSlider
                from: 0
                to: 360
                stepSize: 1

                sliderType: SceneSlider.RGBType

                onMoved: HomeAssistant.callService('light.turn_on', parent.fensterEntity,
                                                    { hs_color: [value, 100] })
            }
            SceneSlider {
                Layout.fillWidth: true
                Layout.columnSpan: 3

                id: fensterSlider
                from: 0; to: 100; stepSize: 5
                sliderType: SceneSlider.BrightnessType

                onMoved: HomeAssistant.callService('light.turn_on', parent.fensterEntity,
                                                    { brightness_pct: value })
            }
            Component.onCompleted: {
                HomeAssistant.subscribe(entity, function(state, attributes) {
                    if (!slider.pressed)
                        slider.value = 100 * (attributes.brightness || 0) / 255
                })
                HomeAssistant.subscribe(fensterEntity, function(state, attributes) {
                    if (!fensterSlider.pressed)
                        fensterSlider.value = 100 * (attributes.brightness || 0) / 255
                    if (!fensterRgbSlider.pressed)
                        fensterRgbSlider.value = (attributes.hs_color[0] || 0)
                })
            }
        }
        SceneLabel {
            icon.name: 'oa/light_cabinet'
            text: "Vitrinen"
        }
        RowLayout {
            id: vitrinen
            spacing: root.columnSpacing
            Layout.fillWidth: true

            property var entities_upper: [ 'light.wohnzimmer_vitrine_oben', 'light.wohnzimmer_highboard_oben' ]
            property var entities_lower: [ 'light.wohnzimmer_vitrine_unten', 'light.wohnzimmer_highboard_unten' ]
            property var entities_both: entities_lower.concat(entities_upper)

            SceneButton {
                icon.name: 'mdi/power-off'
                onClicked: HomeAssistant.callService('light.turn_off', vitrinen.entities_both)
            }
            SceneButton {
                icon.name: 'mdi/brightness-6'
                onClicked: {
                    HomeAssistant.callService('light.turn_on', vitrinen.entities_upper,
                                               { effect: 'None', brightness_pct: 50 })
                    HomeAssistant.callService('light.turn_on', vitrinen.entities_lower,
                                               { effect: 'Rainbow', brightness_pct: 50 })
                }
            }
            SceneButton {
                icon.name: 'mdi/brightness-7'
                onClicked: HomeAssistant.callService('light.turn_on', vitrinen.entities_both,
                                                      { effect: 'None', brightness_pct: 100 })
            }
            SceneSlider {
                Layout.fillWidth: true

                id: vitrinenSlider
                from: 0
                to: 100
                stepSize: 5
                sliderType: SceneSlider.BrightnessType

                onMoved: HomeAssistant.callService('light.turn_on', vitrinen.entities_both,
                                                    { effect: 'None', brightness_pct: value })
            }
            Component.onCompleted: {
                HomeAssistant.subscribe(vitrinen.entities_upper[0], function(state, attributes) {
                    if (!vitrinenSlider.pressed)
                        vitrinenSlider.value = 100 * (attributes.brightness || 0) / 255
                })
            }
        }
        SceneLabel {
            icon.name: 'oa/light_television_backlight'
            text: "Fernseher"
        }
        RowLayout {
            id: ambilight
            spacing: root.columnSpacing
            Layout.fillWidth: true

            property string hyperion_entity: "light.tina_hyperion"
            property string wled_entity: "light.tina_wled"
            property var both_entities: [ hyperion_entity, wled_entity ]

            property int dimPercent: 30
            property bool hyperionActive: false
            property bool wledActive: false

            SceneButton {
                icon.name: 'mdi/power-off'
                enabled: ambilightSlider.value !== 0
                onClicked: HomeAssistant.callService('light.turn_off', ambilight.both_entities)
            }
            SceneButton {
                icon.name: 'mdi/brightness-6'
                highlighted: !parent.hyperionActive && parent.wledActive
                enabled: ambilightSlider.value !== parent.dimPercent
                onClicked: {
                    HomeAssistant.callService('light.turn_off', ambilight.hyperion_entity)
                    HomeAssistant.callService('light.turn_on', ambilight.wled_entity,
                                              {
                                                  brightness_pct: ambilight.dimPercent,
                                                  white_value: 255
                                              })
                }
            }
            SceneButton {
                icon.name: 'mdi/kodi'
                highlighted: parent.hyperionActive && parent.wledActive
                onClicked: {
                    HomeAssistant.callService('light.turn_on', ambilight.hyperion_entity)
                }
            }
            SceneSlider {
                Layout.fillWidth: true

                id: ambilightSlider
                from: 0; to: 100; stepSize: 5
                sliderType: SceneSlider.BrightnessType

                onMoved: HomeAssistant.callService('light.turn_on', ambilight.wled_entity,
                                                    { brightness_pct: value })
            }
            Component.onCompleted: {
                HomeAssistant.subscribe(wled_entity, function(state, attributes) {
                    if (!ambilightSlider.pressed)
                        ambilightSlider.value = 100 * (attributes.brightness || 0) / 255
                    ambilight.wledActive = (state === 'on')
                })
                HomeAssistant.subscribe(hyperion_entity, function(state, attributes) {
                    ambilight.hyperionActive = (state === 'on')
                })
            }
        }
        Item { Layout.minimumHeight: 0; Layout.fillHeight: true }
    }
}
