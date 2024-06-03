// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

pragma ComponentBehavior: Bound
import Qt.labs.platform as Labs
import HAiQ
import Ui


ApplicationWindow {
    id: root
    title: "Raumsteuerung Büro"
    flags: Qt.Window | Qt.CustomizeWindowHint | Qt.WindowTitleHint | Qt.WindowSystemMenuHint | Qt.WindowCloseButtonHint
    property Control fontSizeDummy: Control { }
    font.pixelSize: fontSizeDummy.font.pixelSize * 1.3

    onClosing: function(close) { close.accepted = false; hide() }
    Shortcut { sequence: StandardKey.Cancel; onActivated: root.hide() }


    Labs.SystemTrayIcon {
        id: trayIcon
        icon.source: "qrc:/icons/haiq.png"
        icon.mask: true
        tooltip: root.title
        visible: true

        onActivated: function(reason) {
            switch (reason) {
            case Labs.SystemTrayIcon.Trigger:
            case Labs.SystemTrayIcon.DoubleClick:
                if (root.visible) {
                    root.hide()
                } else {
                    root.show()
                    root.raise()
                    root.requestActivate()
                }
                break;

            case Labs.SystemTrayIcon.MiddleClick:
                Qt.quit();
                break;
            }
        }

        menu: Labs.Menu {
            Labs.MenuItem {
                text: qsTr("Open Home-Assistant...")
                onTriggered: Qt.openUrlExternally(HomeAssistant.baseUrl)
            }
            Labs.MenuItem {
                text: qsTr("Open HomeMatic Web-UI...")
                onTriggered: Qt.openUrlExternally("http://ccu2.home/")
            }
            //            Labs.MenuItem { separator: true }
            //            Labs.MenuItem {
            //                text: qsTr("About")
            //                onTriggered: aboutDialog.show()

            //                Labs.Dialog {
            //                    id: aboutDialog
            //                }
            //            }
            Labs.MenuItem { separator: true }
            Labs.MenuItem {
                text: qsTr("Quit")
                onTriggered: Qt.quit()
            }
        }

        property var incomingCall: Item {
            id: incoming

            property string entity: "sensor.fritzbox"
            property string status
            property string caller

            Timer {
                id: delay
                interval: 500
                running: false
                repeat: false
                onTriggered: {
                    trayIcon.showMessage("Anruf",
                                         "Eingehender Anruf von\n\n" + incoming.caller,
                                         Labs.SystemTrayIcon.Information, 20 * 1000)
                }
            }
            Component.onCompleted: {
                HomeAssistant.subscribe(entity, function(state, attributes) {
                    status = state
                    if (attributes.from_name === '')
                        caller = attributes.from + " (Unbekannt)"
                    else
                        caller = attributes.from_name + " (" + attributes.from + ")"
                })
            }

            onStatusChanged: {
                if (status === 'ringing' && trayIcon.supportsMessages)
                delay.running = true
            }
        }
    }
    width: gridLayout.implicitWidth + 2 * gridLayout.anchors.margins
    height: gridLayout.implicitHeight + 2 * gridLayout.anchors.margins

    Component.onCompleted: {
        minimumWidth = width
        maximumWidth = width
        minimumHeight = height
        maximumHeight = height

        console.log("Tray icon:", trayIcon.available)
    }

    GridLayout {
        id: gridLayout
        anchors.fill: parent
        anchors.margins: 11
        columns: 5

        BlindsControl {
            title: "Rollladen Robert"
            Layout.fillHeight: true
            id: bll
            entity: 'cover.buero_robert_rollladen'

            Layout.minimumWidth: Math.max(bll.implicitWidth, blr.implicitWidth)
            Layout.minimumHeight: Math.max(bll.implicitHeight, blr.implicitHeight)
        }
        DimmerControl {
            title: "Licht Robert"
            Layout.fillHeight: true
            id: dil
            entity: 'light.buero_seilsystem_robert'

            Layout.minimumWidth: Math.max(dil.implicitWidth, dim.implicitWidth, dir.implicitWidth)
            Layout.minimumHeight: Math.max(dil.implicitHeight, dim.implicitHeight, dir.implicitHeight)
        }
        DimmerControl {
            Layout.fillHeight: true

            title: "Licht Mitte"
            id: dim
            entity: 'light.buero_seilsystem_mitte'
            focus: true

            Layout.minimumWidth: dil.Layout.minimumWidth
            Layout.minimumHeight: dil.Layout.minimumHeight
        }
        DimmerControl {
            Layout.fillHeight: true

            title: "Licht Sandra"
            id: dir
            entity: 'light.buero_seilsystem_sandra'

            Layout.minimumWidth: dil.Layout.minimumWidth
            Layout.minimumHeight: dil.Layout.minimumHeight
        }
        BlindsControl {
            Layout.fillHeight: true
            title: "Rollladen Sandra"
            id: blr
            entity: 'cover.buero_sandra_rollladen'

            LayoutMirroring.enabled: true
            LayoutMirroring.childrenInherit: true
            Layout.minimumWidth: bll.Layout.minimumWidth
            Layout.minimumHeight: bll.Layout.minimumHeight
        }

        GroupBox {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.columnSpan: 3
            title: "Heizung"


            ColumnLayout {
                anchors.fill: parent

                RowLayout {
                    id: heizung
                    property string entity: "climate.buero_heizkoerper"
                    property bool boostMode: false

                    Component.onCompleted: {
                        HomeAssistant.subscribe(heizung.entity, function(state, attributes) {
                            heizungSpin.value = Math.round(attributes.temperature)

                            for (var i = 0; i < modeGroup.buttons.length; ++i) {
                                if (modeGroup.buttons[i].hvacMode === state) {
                                    modeGroup.checkedButton = modeGroup.buttons[i]
                                    break
                                }
                            }
                            boostMode = attributes.preset_mode === 'boost'
                        })
                    }

                    SpinBox {
                        id: heizungSpin

                        from: 5; to: 30; stepSize: 1
                        textFromValue: function(value, locale) { return Math.round(value) + "°" }
                        valueFromText: function(text, locale) { return Number.fromLocaleString(locale, text) }
                        enabled: modeGroup.checkedButton && modeGroup.hvacMode !== "off"

                        font.pixelSize: root.font.pixelSize * 2

                        onValueModified: delayedSetTemp.restart()

                        Timer {
                            id: delayedSetTemp
                            interval: 1000
                            onTriggered: HomeAssistant.callService('climate.set_temperature',
                                                                   heizung.entity,
                                                                   { temperature: heizungSpin.value  })
                        }
                    }

                    component RoundHvacButton : RoundIconButton {
                        ButtonGroup.group: modeGroup
                        checkable: true
                        highlighted: checked
                        required property string hvacMode
                        ToolTip.delay: 500
                        ToolTip.visible: hovered
                    }

                    ButtonGroup {
                        id: modeGroup
                        property string hvacMode: 'off'
                        exclusive: true
                        onClicked: function(button) {
                            hvacMode = (button as RoundHvacButton).hvacMode
                            HomeAssistant.callService('climate.set_hvac_mode', heizung.entity,
                                                      { hvac_mode: hvacMode })
                        }
                    }

                    RoundHvacButton {
                        icon.name: 'mdi/power-off'
                        scale: 2
                        paddingScale: 2
                        hvacMode: "off"
                        ToolTip.text: "Aus"
                    }
                    RoundHvacButton {
                        icon.name: 'oa/sani_heating_automatic'
                        scale: 4
                        paddingScale: 1
                        hvacMode: "auto"
                        ToolTip.text: "Automatik Modus"
                    }
                    RoundHvacButton {
                        icon.name: 'oa/sani_heating_manual'
                        scale: 4
                        paddingScale: 1
                        hvacMode: "heat"
                        ToolTip.text: "Manueller Modus"
                    }
                    RoundIconButton {
                        icon.name: 'oa/temp_temperature_max'
                        scale: 4
                        paddingScale: 1
                        highlighted: heizung.boostMode
                        onClicked: HomeAssistant.callService('climate.set_preset_mode', heizung.entity,
                                                             { preset_mode: "boost" })
                        ToolTip.text: "15 Minuten Boost"
                        ToolTip.delay: 500
                        ToolTip.visible: hovered
                    }

                }
                RowLayout {
                    Switch {
                        id: heizPlatte
                        property string entity: "switch.buero_heizplatte_relais"
                        text: "Schreibtisch Robert"
                        onToggled: HomeAssistant.callService('switch.toggle', heizPlatte.entity)

                        Component.onCompleted: {
                            HomeAssistant.subscribe(heizPlatte.entity, function(state, attributes) {
                                heizPlatte.checked = (state === 'on')
                            })
                        }
                    }
                }

            }
        }

        GroupBox {
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.columnSpan: 2
            title: "Druckerstatus"

            ColumnLayout {
                anchors.fill: parent

                Label {
                    id: printerStatus
                    property string entity: "sensor.laserjet_status"

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.minimumWidth: fm.averageCharacterWidth * 25
                    Layout.minimumHeight: font.pixelSize * 3

                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    FontMetrics {
                        id: fm
                        font: printerStatus.font
                    }

                    Component.onCompleted: {
                        HomeAssistant.subscribe(entity, function(state, attributes) {
                            text = (state === "<offline>") ? "Ausgeschalten" : state
                        })
                    }
                    Tracer { }
                }
            }
        }


        GroupBox {
            Layout.fillWidth: true;
            Layout.fillHeight: true;
            Layout.columnSpan: 5
            title: "SqueezeBox Radio"
            id: sqb

            property string entity: "media_player.buero"

            Connections {
                target: HomeAssistant
                function onConnected() {
                    HomeAssistant.callService('squeezebox.call_query', sqb.entity,
                                              { command: 'favorites', parameters: [ 'items', 0, 100 ]})
                }
            }

            Component.onCompleted: {
                HomeAssistant.subscribe(sqb.entity, function(state, attributes) {
                    if (attributes.query_result
                            && attributes.query_result.title === 'Favorites'
                            && attributes.query_result.count !== playing.favorites.length) {
                        playing.favorites = attributes.query_result.loop_loop
                    }
                    playStatus.status = state
                    playing.currentPlaylistName = '' // attributes.media_content_id || ''
                    playing.currentTitle = attributes.media_title || ''
                    playing.currentArtist = attributes.media_artist || ''
                    playing.currentAlbum = attributes.media_album_name || ''
                    playing.coverArtSource = attributes.entity_picture ? HomeAssistant.baseUrl + attributes.entity_picture : ''
                    playVolume.volume = (attributes.volume_level || 0) * 100
                    playVolume.muted = attributes.is_volume_muted || false
                })
            }

            RowLayout {
                anchors.fill: parent

                Image {
                    source: playing.coverArtSource
                    fillMode: Image.PreserveAspectFit
                    cache: false
                    onStatusChanged: { if (status === Image.Error) source = '' }

                    Layout.maximumHeight: playVolume.implicitHeight
                    Layout.maximumWidth: Layout.maximumHeight

                    MouseArea {
                        anchors.fill: parent
                        onClicked: favorites.open()
                    }

                    Tracer { }
                }

                Label {
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    id: playing

                    property string currentPlaylistName
                    property string currentTitle
                    property string currentArtist
                    property string currentAlbum
                    property string coverArtSource
                    property var favorites: []

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter

                    text: (currentTitle ? currentTitle : '')
                          + (currentArtist ? '<br><i>' + currentArtist + '</i>' : '')
                          + (currentAlbum ? '<br>' +currentAlbum : '')

                    elide: Text.ElideRight
                    wrapMode: Text.WordWrap
                    clip: true
                    font.pixelSize: root.font.pixelSize * 1.2
                    minimumPixelSize: root.font.pixelSize * 0.8
                    fontSizeMode: Text.Fit

                    MouseArea {
                        anchors.fill: parent
                        onClicked: favorites.open()
                    }

                    Timer {
                        interval: 5 * 60 * 1000
                        running: favorites.opened
                        onTriggered: favorites.close()
                    }

                    Dialog {
                        id: favorites
                        modal: true
                        title: "Favoriten"
                        parent: Overlay.overlay
                        anchors.centerIn: parent
                        width: parent.width / 4 * 3
                        height: parent.height / 2
                        ScrollView {
                            anchors.fill: parent
                            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

                            ListView {
                                model: playing.favorites

                                delegate: ItemDelegate {
                                    required property var modelData

                                    width: ListView.view.width
                                    text: modelData.name
                                    icon.name: 'fa/play-solid'
                                    onClicked: {
                                        HomeAssistant.callService('squeezebox.call_method',
                                                                  sqb.entity,
                                                                  {
                                                                      command: 'favorites',
                                                                      parameters: [ 'playlist', 'play', 'item_id:' + modelData.id ]
                                                                  })
                                        favorites.close()
                                    }
                                }
                            }
                        }
                    }
                    Tracer { }
                }

                RoundIconButton {
                    id: playStatus

                    property string status: 'idle'

                    icon.name: (status === 'playing' ? 'fa/pause-solid' : 'fa/play-solid')
                    scale: 3

                    onClicked: { HomeAssistant.callService('media_player.media_' + (status === 'playing' ? 'pause' : 'play'), sqb.entity) }

                    Tracer { }
                }

                DialButton {
                    id: playVolume
                    property int volume: 0
                    property bool muted: false

                    stepSize: 1
                    value: volume
                    icon.name: muted ? 'mdi/volume-off' : 'mdi/volume-high'
                    dialColor: muted ? "gray" : "green"
                    scale: 3

                    onClicked: {
                        HomeAssistant.callService('media_player.volume_mute', sqb.entity,
                                                  { is_volume_muted: !muted })
                    }
                    onMoved: {
                        HomeAssistant.callService('media_player.volume_set', sqb.entity,
                                                  { volume_level: position / 100 })
                    }
                }
            }
        }
    }
}
