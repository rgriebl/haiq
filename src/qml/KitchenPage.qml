// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQml
import QtQuick.Window
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import HAiQ


Pane {
    id: root
    //padding: 0
    background: null

    Item {
        id: grid
        anchors.fill: parent
        property int columns: 3
        property int rows: 5
        property int rowSpacing: 7
        property int columnSpacing: 7

        onWidthChanged: updatePositions()
        onHeightChanged: updatePositions()
        onChildrenChanged: updatePositions()
        Component.onCompleted: updatePositions()

        function updatePositions() {
            for (let i = 0; i < grid.children.length; ++i) {
                let c = grid.children[i]

                let colw = (grid.width - (grid.columns - 1) * grid.columnSpacing) / grid.columns
                let rowh = (grid.height - (grid.rows - 1) * grid.rowSpacing) / grid.rows

                let x = (colw + grid.columnSpacing) * c.Layout.column
                let y = (rowh + grid.rowSpacing) * c.Layout.row
                let w = colw * c.Layout.columnSpan + ((c.Layout.columnSpan ?? 1) - 1) * grid.columnSpacing
                let h = rowh * c.Layout.rowSpan + ((c.Layout.rowSpan ?? 1) - 1) * grid.rowSpacing

                c.x = x
                c.y = y
                c.width = w
                c.height = h
            }
        }

        Tile {
            headerText: "S-Bahn"

            Layout.row: 0
            Layout.column: 0
            Layout.rowSpan: 2

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

            KitchenMail {
                anchors.fill: parent
            }
        }

        Tile {
            headerText: "Radio"

            Layout.row: 0
            Layout.column: 1
            Layout.rowSpan: 3

            SqueezeBoxRadio {
                id: sbRadio
                anchors.fill: parent
                entity: "media_player.kueche"
            }

        }
        Tile {
            headerText: "Wetter"

            Layout.row: 3
            Layout.rowSpan: 2
            Layout.column: 1

            Item {
                id: weatherRow
                anchors.fill: parent

                property string location: "osterseeon"
                //spacing: font.pixelSize / 2
                property alias font: root.font

                MouseArea {
                    anchors.fill: parent
                    onClicked: Window.window.showWeather()
                }

                Component.onCompleted: {
                    HomeAssistant.subscribe("weather." + location, function(state, attributes) {
                        weatherIcon.name = "darksky/" + state
                        weatherTemp.temperature = attributes.temperature
                        weatherTemp.temperatureFeelsLike = weatherTemp.temperature
                    })
                    HomeAssistant.subscribe("sensor." + location + "_weather_report", function(state, attributes) {
                        let lines = attributes.data.split('\n')
                        for (let line of lines) {
                            let s = ''
                            line = line.trim()
                            if (line === '' || line[0] === '*' || line[0] === '#' || line[line.length - 1] === '*')
                                continue
                            weatherForecast.text = line
                            break
                        }
                    })
                }

                Tracer { }

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: weatherRow.font.pixelSize / 2
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
                        spacing: weatherRow.font.pixelSize / 2

                        SvgIcon {
                            id: weatherIcon
                            size: weatherRow.font.pixelSize * 4
                        }

                        WeatherTemperatureLabel {
                            id: weatherTemp
                            Layout.fillWidth: true
                            verticalAlignment: Text.AlignVCenter
                            horizontalAlignment: Text.AlignHCenter
                            font.pixelSize: weatherRow.font.pixelSize * 3
                            minimumPixelSize: font.pixelSize / 2
                            fontSizeMode: Text.Fit
                            showFeelsLike: true
                        }
                    }
                    Label {
                        id: weatherForecast

                        Layout.fillWidth: true
                        Layout.fillHeight: true

                        wrapMode: Text.WordWrap
                        font.pixelSize: weatherRow.font.pixelSize * 2
                        minimumPixelSize: weatherRow.font.pixelSize / 2
                        fontSizeMode: Text.Fit
                        elide: Text.ElideRight
                        verticalAlignment: Text.AlignVCenter
                        horizontalAlignment: Text.AlignHCenter

                        Tracer { }
                    }
                }
            }
        }

        Tile {
            headerText: "Termine"

            Layout.row: 0
            Layout.column: 2
            Layout.rowSpan: 3

            CalendarEvents {
                anchors.fill: parent
            }
        }
        Tile {
            headerText: "Uhr"

            Layout.row: 3
            Layout.column: 2
            Layout.rowSpan: 2

            DigitalClock {
                id: clock

                anchors.fill: parent
                anchors.margins: font.pixelSize / 2

                MouseArea {
                    anchors.fill: parent
                    onClicked: clock.showSeconds = !clock.showSeconds
                }
            }
        }
    }
}
