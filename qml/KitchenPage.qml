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
import QtQuick.Window 2.12
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import org.griebl.haiq 1.0


Pane {
    id: root
    //padding: 0
    background: null

    GridLayout {
        id: grid
        anchors.fill: parent
        columns: 3
        rows: 5
        rowSpacing: 7
        columnSpacing: 7

        function preferredTileWidth(tile) {
            return (grid.width - (grid.columns - 1) * grid.columnSpacing) / grid.columns * tile.Layout.columnSpan + (tile.Layout.columnSpan - 1) * grid.columnSpacing
        }
        function preferredTileHeight(tile) {
            return (grid.height - (grid.rows - 1) * grid.rowSpacing) / grid.rows * tile.Layout.rowSpan + (tile.Layout.rowSpan - 1) * grid.rowSpacing
        }

        Tile {
            headerText: "S-Bahn"

            Layout.row: 0
            Layout.column: 0
            Layout.rowSpan: 2
            Layout.preferredWidth: grid.preferredTileWidth(this)
            Layout.preferredHeight: grid.preferredTileHeight(this) * .95

            TrainDepartures {
                id: trainDepartures
                anchors.fill: parent
            }

            headerStatusText: trainDepartures.lastUpdate.toLocaleTimeString('hh:mm')
        }
        Tile {
            headerText: "Fahrzeit"

            Layout.row: 2
            Layout.column: 0
            Layout.preferredWidth: grid.preferredTileWidth(this)
            Layout.preferredHeight: grid.preferredTileHeight(this) * 1.1

            HereMapsDistance {
                id: distance
                anchors.fill: parent

                appId: "9EzX33lObO9ALe2TRwmU"
                appCode: "6_m2DLN1aPNBYCDdy_bgVg"
                origin: "48.085812,11.84113" /*"Zorneding,Herzog-Tassilo-Ring 52"*/
                destinations: [
                    { "Stachus": "48.136379,11.56607" /*"Muenchen,Josephspitalstrasse 15"*/ },
                    { "Gärtnerei": "48.103809,11.56317" /*"Muenchen,Schoenstrasse 85"*/ },
                    { "Gymnasium": "48.06664,11.89248" /*"Kichseeon,Gymnasium"*/ },
                ]
            }

            headerStatusText: distance.lastUpdate.toLocaleTimeString('hh:mm')
        }
        Tile {
            headerText: "Abfall"

            Layout.row: 3
            Layout.column: 0
            Layout.preferredWidth: grid.preferredTileWidth(this)
            Layout.preferredHeight: grid.preferredTileHeight(this)

            RowLayout {
                spacing: 0
                anchors.fill: parent

                KitchenTrashIcon {
                    color: "white"
                    entity: "sensor.abfall_rest_abholung"
                    Layout.fillWidth: true
                }
                KitchenTrashIcon {
                    color: "green"
                    entity: "sensor.abfall_bio_abholung"
                    Layout.fillWidth: true
                }
                KitchenTrashIcon {
                    color: "yellow"
                    entity: "sensor.abfall_gelber_sack_abholung"
                    isBag: true
                    Layout.fillWidth: true
                }
                KitchenTrashIcon {
                    color: "royalblue"
                    entity: "sensor.abfall_papier_abholung"
                    Layout.fillWidth: true
                }

            }
        }
        Tile {
            headerText: "Status"

            Layout.row: 4
            Layout.column: 0
            Layout.preferredWidth: grid.preferredTileWidth(this)
            Layout.preferredHeight: grid.preferredTileHeight(this)

            KitchenMail {
                anchors.fill: parent
            }
        }
        Tile {
            headerText: "Radio"

            Layout.row: 0
            Layout.column: 1
            Layout.rowSpan: 3
            Layout.preferredWidth: grid.preferredTileWidth(this)
            Layout.preferredHeight: grid.preferredTileHeight(this)

            SqueezeBoxRadio {
                id: sbRadio
                anchors.fill: parent
                entity: "media_player.kitchen"
            }

        }
        Tile {
            headerText: "Wetter"

            Layout.row: 3
            Layout.rowSpan: 2
            Layout.column: 1
            Layout.preferredWidth: grid.preferredTileWidth(this)
            Layout.preferredHeight: grid.preferredTileHeight(this)

            Control {
                id: weatherRow
                anchors.fill: parent

                property string entity: "sensor.wetter"
                spacing: font.pixelSize / 2

                MouseArea {
                    anchors.fill: parent
                    onClicked: Window.window.showWeather()
                }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: weatherRow.font.pixelSize / 2
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        spacing: weatherRow.font.pixelSize / 2

                        SvgIcon {
                            id: weatherIcon
                            size: weatherRow.font.pixelSize * 4

                            Component.onCompleted: {
                                HomeAssistant.subscribe(weatherRow.entity + "_icon_0d", function(state, attributes) {
                                    name = "darksky/" + state
                                })
                            }
                        }

                        WeatherTemperatureLabel {
                            id: weatherTemp
                            verticalAlignment: Text.AlignVCenter
                            font.pixelSize: weatherRow.font.pixelSize * 3
                            showFeelsLike: true

                            Component.onCompleted: {
                                HomeAssistant.subscribe(weatherRow.entity + "_temperature", function(state, attributes) {
                                    temperature = state
                                })
                                HomeAssistant.subscribe(weatherRow.entity + "_apparent_temperature", function(state, attributes) {
                                    temperatureFeelsLike = state
                                })
                            }
                        }
                    }
                    Label {
                        property string forecast

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        text: forecast
                        wrapMode: Text.WordWrap
                        font.pixelSize: weatherRow.font.pixelSize * 2
                        minimumPixelSize: weatherRow.font.pixelSize
                        fontSizeMode: Text.Fit
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter

                        Component.onCompleted: {
                            HomeAssistant.subscribe(weatherRow.entity + "_summary_0d", function(state, attributes) {
                                forecast = state
                            })
                        }
                    }
                }
            }
        }
        Tile {
            headerText: "Termine"

            Layout.row: 0
            Layout.column: 2
            Layout.rowSpan: 3
            Layout.preferredWidth: grid.preferredTileWidth(this)
            Layout.preferredHeight: grid.preferredTileHeight(this)

            CalendarEvents {
                anchors.fill: parent
            }
        }
        Tile {
            headerText: "Uhr"

            Layout.row: 3
            Layout.column: 2
            Layout.rowSpan: 2
            Layout.preferredWidth: grid.preferredTileWidth(this)
            Layout.preferredHeight: grid.preferredTileHeight(this)

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: font.pixelSize / 2
                DigitalClock {
                    id: clock

                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    TapHandler {
                        onTapped: clock.showSeconds = !clock.showSeconds
                        onLongPressed: parent.Window.window.showTimer()
                    }
                }
            }
        }
    }
}
