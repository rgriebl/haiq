// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQml
import QtQuick.Window
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HAiQ
import QtQuick.Controls.Universal

Control {
    id: root

    property real rowSpacing: defaultRowSpacing
    property real columnSpacing: defaultColumnSpacing

    topPadding: rowSpacing
    bottomPadding: 0
    leftPadding: 0
    rightPadding: columnSpacing

    contentItem: GridLayout {
        id: grid
        columns: 2
        rowSpacing: root.rowSpacing
        columnSpacing: root.columnSpacing

        SceneLabel {
            icon.name: 'oa/light_led_stripe'
            text: "Licht"
        }
        RowLayout {
            spacing: root.columnSpacing
            Layout.fillWidth: true

            SceneButton {
                icon.name: 'mdi/power-off'
                onClicked: HomeAssistant.callService('scene.turn_on', 'scene.terrassenlicht_aus')
            }
            SceneButton {
                icon.name: 'mdi/power-on'
                onClicked: HomeAssistant.callService('scene.turn_on', 'scene.terrassenlicht_voll')
            }
            SceneButton {
                icon.name: 'mdi/silverware'
                onClicked: HomeAssistant.callService('scene.turn_on', 'scene.terrassenlicht_essen')
            }
            SceneSlider {
                Layout.fillWidth: true

                id: terraceSlider
                from: 0; to: 100; stepSize: 5
                sliderType: SceneSlider.BrightnessType

//                onMoved: HomeAssistant.callService('light.turn_on', weltkarte.entity,
//                                                    { brightness_pct: value })
            }
//            Component.onCompleted: {
//                HomeAssistant.subscribe(weltkarte.entity, function(state, attributes) {
//                    if (!terraceSlider.pressed)
//                        terraceSlider.value = 100 * (attributes.brightness || 0) / 255
//                })
//            }
        }
        SceneLabel {
            icon.name: 'oa/fts_sunblind_volant'
            text: "Markise"
        }
        RowLayout {
            id: markise
            spacing: root.columnSpacing
            Layout.fillWidth: true

            property string hentity: 'cover.markise'
            property string ventity: 'cover.vertikalmarkise'

            SceneButton {
                icon.name: 'mdi/arrow-bottom-left'
                onClicked: HomeAssistant.callService('cover.close_cover', markise.hentity)
            }
            SceneButton {
                icon.name: 'mdi/arrow-top-right'
                onClicked: HomeAssistant.callService('cover.open_cover', markise.hentity)
            }
            SceneButton {
                icon.name: 'mdi/stop'
                onClicked: HomeAssistant.callService('cover.stop_cover', markise.hentity)
            }
            Item {
                Layout.fillWidth: true
            }
            SceneButton {
                icon.name: 'mdi/arrow-down'
                onClicked: HomeAssistant.callService('cover.close_cover', markise.ventity)
            }
            SceneButton {
                icon.name: 'mdi/arrow-up'
                onClicked: HomeAssistant.callService('cover.open_cover', markise.ventity)
            }
            SceneButton {
                icon.name: 'mdi/stop'
                onClicked: HomeAssistant.callService('cover.stop_cover', markise.ventity)
            }
        }
        SceneLabel {
            icon.name: 'oa/audio_sound'
            text: "Radio"
        }
        RowLayout {
            id: radioTerrace
            spacing: root.columnSpacing
            Layout.fillWidth: true

            property string entity: 'media_player.terrasse'
            property string masterEntity: 'media_player.kueche'
            property real volume : 0
            property bool synced : false

            SceneButton {
                icon.name: 'mdi/volume-off'

                highlighted: !parent.synced
                onClicked: {
                    if (!parent.synced) {
                        HomeAssistant.callService('squeezebox.sync', parent.masterEntity,
                                                  { 'other_player': parent.entity })
                    } else {
                        HomeAssistant.callService('squeezebox.unsync', parent.entity)
                    }
                    parent.synced = !parent.synced
                }
            }
            SceneSlider {
                Layout.fillWidth: true

                from: 0; to: 100; stepSize: 1
                sliderType: SceneSlider.VolumeType

                property int volume: 100 * parent.volume
                onVolumeChanged: if (!pressed) value = volume
                onMoved: HomeAssistant.callService('media_player.volume_set', parent.entity,
                                                   { volume_level: value / 100 })
            }

            Component.onCompleted: {
                HomeAssistant.subscribe(entity, function(state, attributes) {
                    volume = attributes.volume_level || 0
                    synced = attributes.sync_group.length > 0
                })
            }
        }
        SceneLabel {
            icon.name: 'mdi/grill-outline'
            text: "Grill"
        }
        RowLayout {
            id: grillLicht
            spacing: root.columnSpacing
            Layout.fillWidth: true

            property string entity: 'switch.garten_grill_relay2'
            property string entityState: ''

            SceneButton {
                icon.name: 'mdi/power-off'
                enabled: parent.entityState !== 'off'
                onClicked: HomeAssistant.callService('switch.turn_off', parent.entity)
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
                onClicked: HomeAssistant.callService('switch.turn_on', parent.entity)
            }
            Component.onCompleted: {
                HomeAssistant.subscribe(entity, function(state, attributes) {
                    entityState = state
                })
            }
        }

        Item { Layout.fillHeight: true }
    }
}
