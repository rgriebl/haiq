// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQml
import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Universal
import HAiQ

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
            icon.name: 'oa/sani_heating'
            text: "Heizung"
        }
        GridLayout {
            id: heizungWohnzimmer
            columnSpacing: root.columnSpacing
            rowSpacing: root.rowSpacing
            columns: 7
            Layout.fillWidth: true

            property string entity: 'climate.wohnzimmer_wandthermostat'
            property string doorEntity: 'sensor.wohnzimmer_terassentuer_state'

            property bool boostMode: false
            property real currentTemperature: 0
            property bool doorOpen: false

            ButtonGroup {
                id: buttonsHeizungWohnzimmer
                exclusive: true
                onClicked: HomeAssistant.callService('climate.set_hvac_mode', heizungWohnzimmer.entity,
                                                     { hvac_mode: button.hvacMode })

                Component.onCompleted: {
                    HomeAssistant.subscribe(heizungWohnzimmer.entity, function(state, attributes) {
                        heatingSlider.value = Math.round(attributes.temperature)

                        for (var i = 0; i < buttons.length; ++i) {
                            if (buttons[i].hvacMode === state) {
                                checkedButton = buttons[i]
                                break
                            }
                        }
                        heizungWohnzimmer.boostMode = attributes.preset_mode === 'boost'
                        heizungWohnzimmer.currentTemperature = attributes.current_temperature
                    })
                    HomeAssistant.subscribe(heizungWohnzimmer.doorEntity, function(state, attributes) {
                        heizungWohnzimmer.doorOpen = (state !== 'closed')
                    })
                }
            }


            SceneButton {
                id: heatingOff
                icon.name: 'mdi/power-off'
                ButtonGroup.group: buttonsHeizungWohnzimmer
                checkable: true
                property string hvacMode: 'off'
            }
            SceneButton {
                icon.name: 'oa/sani_heating_automatic'
                ButtonGroup.group: buttonsHeizungWohnzimmer
                checkable: true
                scale: 3
                property string hvacMode: 'auto'
            }
            SceneButton {
                icon.name: 'oa/sani_heating_manual'
                ButtonGroup.group: buttonsHeizungWohnzimmer
                checkable: true
                scale: 3
                property string hvacMode: 'heat'
            }
            Item {
                Layout.fillWidth: true
            }
            SceneButton {
                icon.name: 'oa/temp_temperature_max'
                scale: 3
                highlighted: heizungWohnzimmer.boostMode
                onClicked: HomeAssistant.callService('climate.set_preset_mode', heizungWohnzimmer.entity, { preset_mode: "boost" })
            }
            SceneButton {
                opacity: 0
            }
            SceneButton {
                property bool _open: heizungWohnzimmer.doorOpen

                icon.name: 'oa/fts_door' + (_open ? '_open' : '')
                enabled: false
                scale: 3
                opacity: _open ? 1 : 0.3
                Universal.accent: _open ? Qt.hsla(0, 1, 0.5) : 'transparent'
                highlighted: _open
            }
            Label {
                id: currentTemp
                Layout.fillWidth: true
                Layout.columnSpan: 3
                text: "Raum: " + heizungWohnzimmer.currentTemperature + '°'
            }
            Item {
                Layout.fillWidth: true
            }
            SceneSlider {
                id: heatingSlider
                Layout.fillWidth: true
                Layout.columnSpan: 3

                from: 5; to: 30; stepSize: 1
                sliderType: SceneSlider.HeatingType
                valueToHandleText: function(value) { return Math.round(value) + '°' }
                enabled: !heatingOff.checked

                onMoved: HomeAssistant.callService('climate.set_temperature', heizungWohnzimmer.entity,
                                                    { temperature: value })
            }
        }
        SceneLabel {
            icon.name: 'oa/fts_shutter_60'
            text: "Rollläden"
        }
        RowLayout {
            id: rollladen
            Layout.fillWidth: true
            spacing: root.columnSpacing
            property string lentity: 'cover.wohnzimmer_fenster_rollladen'
            property string rentity: 'cover.wohnzimmer_tuer_rollladen'

            SceneButton {
                icon.name: 'mdi/arrow-down'
                onClicked: HomeAssistant.callService('cover.close_cover', parent.lentity)
            }
            SceneButton {
                icon.name: 'mdi/arrow-up'
                onClicked: HomeAssistant.callService('cover.open_cover', parent.lentity)
            }
            SceneButton {
                icon.name: 'mdi/stop'
                onClicked: HomeAssistant.callService('cover.stop_cover', parent.lentity)
            }
            Item {
                Layout.fillWidth: true
            }
            SceneButton {
                icon.name: 'mdi/arrow-down'
                onClicked: HomeAssistant.callService('cover.close_cover', parent.rentity)
            }
            SceneButton {
                icon.name: 'mdi/arrow-up'
                onClicked: HomeAssistant.callService('cover.open_cover', parent.rentity)
            }
            SceneButton {
                icon.name: 'mdi/stop'
                onClicked: HomeAssistant.callService('cover.stop_cover', parent.rentity)
            }
        }
        SceneLabel {
            icon.name: 'oa/audio_sound'
            text: "Radio"
        }
        RowLayout {
            id: radioTina
            spacing: root.columnSpacing
            Layout.fillWidth: true

            property string entity: 'media_player.wohnzimmer'
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
            icon.name: 'oa/scene_robo_vac_cleaner'
            text: "Staubsauger"
        }
        RowLayout {
            id: vacuum
            spacing: root.columnSpacing
            Layout.fillWidth: true

            property string entity: 'vacuum.rockrobo'
            property string entityState: '' // cleaning, docked, paused, idle, returning, error

            SceneButton {
                icon.name: 'mdi/play'
                onClicked: HomeAssistant.callService('vacuum.start', parent.entity)
                enabled: [ 'docked', 'paused', 'idle' ].includes(parent.entityState)
            }
            SceneButton {
                icon.name: 'mdi/pause'
                onClicked: HomeAssistant.callService('vacuum.pause', parent.entity)
                enabled: [ 'cleaning', 'returning' ].includes(parent.entityState)
            }
            SceneButton {
                icon.name: 'mdi/stop'
                onClicked: HomeAssistant.callService('vacuum.stop', parent.entity)
                enabled: [ 'cleaning', 'paused', 'returning' ].includes(parent.entityState)
            }
            Item {
                Layout.fillWidth: true
            }
            SceneButton {
                icon.name: 'mdi/broom'
                onClicked: HomeAssistant.callService('vacuum.clean_spot', parent.entity)
                enabled: [ 'idle' ].includes(parent.entityState)
            }
            SceneButton {
                icon.name: 'mdi/map-marker'
                onClicked: HomeAssistant.callService('vacuum.locate', parent.entity)
            }
            SceneButton {
                icon.name: 'mdi/home-map-marker'
                onClicked: HomeAssistant.callService('vacuum.return_to_base', parent.entity)
            }
            Component.onCompleted: {
                HomeAssistant.subscribe(entity, function(state, attributes) {
                    entityState = state
                })
            }

        }
        Item { Layout.minimumHeight: 0; Layout.fillHeight: true }
    }
}
