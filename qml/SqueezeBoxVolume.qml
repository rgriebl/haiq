// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQml
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import org.griebl.haiq 1.0


Popup {
    id: root

    property var entities: []

    modal: true
    Overlay.modal: defaultOverlay
    background: Rectangle {
        color: Qt.rgba(28/255, 28/255, 30/255)
        radius: parent.font.pixelSize
    }
    padding: font.pixelSize
    anchors.centerIn: Overlay.overlay
    width: parent.Window.width * 0.8
    height: parent.Window.height * 0.8

    Timer {
        interval: 5 * 60 * 1000
        running: root.opened
        onTriggered: close()
    }

    property var volumeModel: []

    Component {
        id: volumeComponent

        QtObject {
            id: item
            property int index
            property string name
            property bool master
            property string entity
            property int volume
            property bool muted
            property bool power
            property bool synced

            function setMuted(newMuted) {
                HomeAssistant.callService('media_player.volume_mute', entity,
                                           { "is_volume_muted": newMuted })
                muted = newMuted
            }

            function togglePower() {
                HomeAssistant.callService('media_player.turn_' + (power ? 'off' : 'on'), entity)
                power = !power
            }
            function setSync(sync) {
                if (sync === synced)
                    return

                if (sync) {
                    let master = root.volumeModel.find(e => e.master)
                    if (master)
                        HomeAssistant.callService('squeezebox.sync', master.entity, { 'other_player': entity})
                } else {
                    HomeAssistant.callService('squeezebox.unsync', entity)
                }
                synced = !synced
            }

            function setVolume(newVolume) {
                HomeAssistant.callService('media_player.volume_set', entity, { volume_level: newVolume / 100 })
            }

            Component.onCompleted: {
                HomeAssistant.subscribe(entity, function(state, attributes) {
                    volume = 100 * (attributes.volume_level || 0)
                    muted = attributes.is_volume_muted || false
                    power = (state !== 'off')
                    synced = attributes.sync_group.length > 0
                })
            }
        }
    }

    onEntitiesChanged: {
        var model = []
        for (var i = 0; i < entities.length; ++i) {
            var item = volumeComponent.createObject(root,
                                                    {
                                                        "index": i,
                                                        "entity": entities[i].entity,
                                                        "name": entities[i].name,
                                                        "master": entities[i].master || false
                                                    })
            model.push(item)

        }
        root.volumeModel = model
    }


    GridLayout {
        anchors.fill: parent
        rowSpacing: font.pixelSize * 0.5
        columnSpacing: rowSpacing
        columns: 3
        rows: volumeModel.length

        Repeater {
            model: parent.rows
            Label {
                Layout.row: index
                Layout.column: 0
                Layout.fillWidth: true
                text: root.volumeModel[index].name
            }
        }
        Repeater {
            model: parent.rows
            SceneSlider {
                id: volumeSlider
                Layout.row: index
                Layout.column: 1
                Layout.fillWidth: true

                sliderType: SceneSlider.VolumeType
                from: 0; to: 100; stepSize: 1

                property real exponent: 1 // 2.2

                property int volume: 100 * Math.pow(root.volumeModel[index].volume / 100, 1 / exponent)
                onVolumeChanged: if (!pressed) value = volume
                onMoved: { root.volumeModel[index].setVolume(100 * Math.pow(value / 100, exponent)) }
            }
        }
        Repeater {
            model: parent.rows
            SceneButton {
                Layout.row: index
                Layout.column: 2
                icon.name: 'mdi/volume-off'
                highlighted: root.volumeModel[index].master ? root.volumeModel[index].muted
                                                            : !root.volumeModel[index].synced
                onClicked: {
                    if (root.volumeModel[index].master)
                        root.volumeModel[index].setMuted(!root.volumeModel[index].muted)
                    else
                        root.volumeModel[index].setSync(!root.volumeModel[index].synced)
                }
            }
        }
    }
}
