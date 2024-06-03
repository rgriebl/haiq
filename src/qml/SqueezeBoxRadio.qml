// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import HAiQ
import Ui


Control {
    id: root
    property string entity

    property string _currentPlaylistName
    property string _currentTitle
    property string _currentArtist
    property string _currentAlbum
    property url _coverArt
    property bool _playing: false
    property bool _muted: false
    property real volume: 0

    Component.onCompleted: {
        HomeAssistant.subscribe(root.entity, function(state, attributes) {
            _muted = attributes.is_volume_muted
            _playing = (state === 'playing')
            _currentPlaylistName = '' // attributes.media_content_id || ''
            _currentTitle = attributes.media_title || ''
            _currentArtist = attributes.media_artist || ''
            _currentAlbum = attributes.media_album_name || ''
            _coverArt = attributes.entity_picture ? HomeAssistant.baseUrl + attributes.entity_picture : ''
            volume = attributes.volume_level || 0
        })
    }

    SwipeView {
        id: coverArt

        interactive: false
        anchors.fill: parent
        anchors.margins: 5
        opacity: root._playing ? 0.5 : 0
        clip: true

        property url source: root._coverArt

        property var _images: [ covertArtLeft, covertArtRight ]

        onSourceChanged: {
            let i = 1 - currentIndex
            _images[i].source = source
            if (_images[i].status !== Image.Loading) {
                currentIndex = i
            } else {
                let f = function() {
                    coverArt.currentIndex = i
                    _images[i].statusChanged.disconnect(f)
                }
                _images[i].statusChanged.connect(f);
            }
        }

        states: [
            State {
                name: "showcover"
                PropertyChanges { coverArt.opacity: 1 }
                PropertyChanges { playButton.opacity: 0 }
                PropertyChanges { favoritesButton.opacity: 0 }
                PropertyChanges { volumeButton.opacity: 0 }
                PropertyChanges { playing.opacity: 0 }
            }
        ]
        transitions: [
            Transition {
                to: "*"
                NumberAnimation { properties: "opacity"; duration: 500; easing.type: Easing.InOutQuad }
            }
        ]
        Image {
            id: covertArtLeft
            cache: false
            fillMode: Image.PreserveAspectFit
            onStatusChanged: { if (status === Image.Error) source = '' }
        }
        Image {
            id: covertArtRight
            cache: false
            fillMode: Image.PreserveAspectFit
            onStatusChanged: { if (status === Image.Error) source = '' }
        }
    }
    Rectangle {
        radius: root.font.pixelSize / 2 + border.width

        anchors.fill: coverArt
        anchors.margins: -radius / 4
        color: 'transparent'
        border.width: 20
        border.color: 'black'
        opacity: 1

        MouseArea {
            enabled: root._playing
            anchors.fill: parent
            onClicked: {
                coverArt.state = (coverArt.state === "showcover" ? "" : "showcover")
                if (coverArt.state !== "")
                    hideCoverTimer.restart()
            }
        }
        Timer {
            id: hideCoverTimer
            interval: 5000
            onTriggered: coverArt.state = ""
        }
    }

    SceneButton {
        id: favoritesButton

        anchors.verticalCenter: playButton.verticalCenter
        anchors.left: parent.left
        anchors.margins: root.font.pixelSize

        icon.name: 'fa/heart-solid'
        font.pixelSize: root.font.pixelSize * 2
        background: Rectangle {
            radius: width / 2
            color: Qt.hsla(0, 0, 0, 0.5)
            border.width: favoritesButton.down ? 5 : 2
            border.color: Qt.hsla(0, 0, 1, 0.5)
        }

        onClicked: {
            settingsDialog.open()
            settingsDialogTimer.restart()
        }

        SqueezeBoxSettings {
            id: settingsDialog
            entity: root.entity
        }

        Timer {
            id: settingsDialogTimer
            interval: 10000
            onTriggered: settingsDialog.close()
        }
    }

    SceneButton {
        id: playButton

        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.margins: root.font.pixelSize

        icon.name: 'fa/' + (root._playing ? 'pause' : 'play') + '-solid'
        font.pixelSize: root.font.pixelSize * 3
        background: Rectangle {
            radius: width / 2
            color: Qt.hsla(0, 0, 0, 0.5)
            border.width: playButton.down ? 5 : 2
            border.color: Qt.hsla(0, 0, 1, 0.5)
        }

        onClicked: HomeAssistant.callService('media_player.media_' + (root._playing ? 'pause' : 'play'), root.entity)
    }

    SceneButton {
        id: volumeButton

        anchors.verticalCenter: playButton.verticalCenter
        anchors.right: parent.right
        anchors.margins: root.font.pixelSize

        icon.name: 'fa/volume-up-solid'
        font.pixelSize: root.font.pixelSize * 2
        background: Rectangle {
            radius: width / 2
            color: Qt.hsla(0, 0, 0, 0.5)
            border.width: volumeButton.down ? 5 : 2
            border.color: Qt.hsla(0, 0, 1, 0.5)
        }

        onClicked: {
            volumeDialog.open()
            volumeDialogTimer.restart()
        }

        SqueezeBoxVolume {
            id: volumeDialog
            entities: [
                { "entity": root.entity,               "name": "Küche",     "master": true },
                { "entity": "media_player.wohnzimmer", "name": "Wohnzimmer" },
                { "entity": "media_player.terrasse",   "name": "Terrasse" },
                { "entity": "media_player.keller",     "name": "Waschküche" }
            ]
        }

        Timer {
            id: volumeDialogTimer
            interval: 10000
            onTriggered: volumeDialog.close()
        }
    }
    Label {
        id: playing

        anchors.bottom: parent.bottom
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: font.pixelSize
        style: Text.Outline
        styleColor: 'black'

        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        opacity: root._playing ? 1 : 0

        text: (root._currentTitle ? root._currentTitle : '')
              + (root._currentArtist ? '<br><i>' + root._currentArtist + '</i>' : '')
              + (root._currentAlbum ? '<br>' + root._currentAlbum : '')
        maximumLineCount: 5
        elide: Text.ElideRight
        wrapMode: Text.WordWrap
        clip: true

        font.pixelSize: root.font.pixelSize * 1.2
        minimumPixelSize: root.font.pixelSize * 0.8
        fontSizeMode: Text.Fit


    }
}
