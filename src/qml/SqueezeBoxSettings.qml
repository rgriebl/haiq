// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

pragma ComponentBehavior: Bound
import HAiQ
import Ui


Popup {
    id: root

    property string entity

    modal: true
    Overlay.modal: DarkOverlay { }
    background: Rectangle {
        color: Qt.rgba(28/255, 28/255, 30/255)
        radius: root.font.pixelSize
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
        onTriggered: root.close()
    }

    ListView {
        anchors.fill: parent
        model: root.favorites
        spacing: root.font.pixelSize / 4

        ScrollIndicator.vertical: ScrollIndicator { }

        delegate: RowLayout {
            id: delegate
            required property var modelData
            width: ListView.view.width
            spacing: root.font.pixelSize / 2

            SceneButton {
                icon.name: 'fa/play-solid'
                onClicked: {
                    HomeAssistant.callService('squeezebox.call_method',
                                               root.entity,
                                               {
                                                   command: 'favorites',
                                                   parameters: [ 'playlist', 'play', 'item_id:' + delegate.modelData.id ]
                                               })
                }
            }
            Label {
                Layout.fillWidth: true
                text: delegate.modelData.name
                elide: Text.ElideRight
            }
        }
    }
}
