// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Window
import org.griebl.haiq 1.0


Popup {
    id: root

    property string entity

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


    property var favorites: []

    Connections {
        target: HomeAssistant
        function onConnected() {
            HomeAssistant.callService('squeezebox.call_query', root.entity,
                                      { command: 'favorites', parameters: [ 'items', 0, 100 ]})
        }
    }
    Component.onCompleted: {
        HomeAssistant.subscribe(root.entity, function(state, attributes) {
            if (attributes.query_result
                    && attributes.query_result.title === 'Favorites'
                    && attributes.query_result.count !== favorites.length) {
                favorites = attributes.query_result.loop_loop
            }
        })
    }

    Timer {
        interval: 5 * 60 * 1000
        running: root.opened
        onTriggered: close()
    }

    ListView {
        anchors.fill: parent
        model: root.favorites
        spacing: font.pixelSize / 4

        ScrollIndicator.vertical: ScrollIndicator { }

        delegate: RowLayout {
            width: ListView.view.width
            spacing: font.pixelSize / 2

            SceneButton {
                icon.name: 'fa/play-solid'
                onClicked: {
                    HomeAssistant.callService('squeezebox.call_method',
                                               root.entity,
                                               {
                                                   command: 'favorites',
                                                   parameters: [ 'playlist', 'play', 'item_id:' + modelData.id ]
                                               })
                }
            }
            Label {
                Layout.fillWidth: true
                text: modelData.name
                elide: Text.ElideRight
            }
        }
    }
}
