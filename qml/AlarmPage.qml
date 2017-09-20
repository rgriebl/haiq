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
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.12
import QtMultimedia 5.15
import org.griebl.haiq 1.0


Pane {
    id: root
    background: null

    GridLayout {
        id: grid
        anchors.fill: parent
        columns: 2
        rows: 4
        rowSpacing: 7
        columnSpacing: 7

        function preferredTileWidth(tile) {
            return (grid.width - (grid.columns - 1) * grid.columnSpacing) / grid.columns * tile.Layout.columnSpan + (tile.Layout.columnSpan - 1) * grid.columnSpacing
        }
        function preferredTileHeight(tile) {
            return (grid.height - (grid.rows - 1) * grid.rowSpacing) / grid.rows * tile.Layout.rowSpan + (tile.Layout.rowSpan - 1) * grid.rowSpacing
        }

        Tile {
            headerText: "Temperatur Fühler 1"

            Layout.row: 0
            Layout.column: 0
            Layout.preferredWidth: grid.preferredTileWidth(this) * 2 / 3
            Layout.preferredHeight: grid.preferredTileHeight(this)

            TemperatureProbe {
                id: tempProbe1
                anchors.fill: parent
                font.pixelSize: root.font.pixelSize * 4
                entity: "sensor.terrasse_licht_temperatur_1"
            }

            headerStatusText: tempProbe1.lastUpdate.toLocaleTimeString('hh:mm')
        }
        Tile {
            headerText: "Temperatur Fühler 2"

            Layout.row: 1
            Layout.column: 0
            Layout.preferredWidth: grid.preferredTileWidth(this) * 2 / 3
            Layout.preferredHeight: grid.preferredTileHeight(this)

            TemperatureProbe {
                id: tempProbe2
                anchors.fill: parent
                font.pixelSize: root.font.pixelSize * 4
                entity: "sensor.terrasse_licht_temperatur_2"
            }

            headerStatusText: tempProbe2.lastUpdate.toLocaleTimeString('hh:mm')
        }
        Tile {
            headerText: "Temperatur Fühler 3"

            Layout.row: 2
            Layout.column: 0
            Layout.preferredWidth: grid.preferredTileWidth(this) * 2 / 3
            Layout.preferredHeight: grid.preferredTileHeight(this)

            TemperatureProbe {
                id: tempProbe3
                anchors.fill: parent
                font.pixelSize: root.font.pixelSize * 4
                entity: "sensor.terrasse_licht_temperatur_3"
            }

            headerStatusText: tempProbe3.lastUpdate.toLocaleTimeString('hh:mm')
        }
        Tile {
            headerText: "Temperatur Fühler 4"

            Layout.row: 3
            Layout.column: 0
            Layout.preferredWidth: grid.preferredTileWidth(this) * 2 / 3
            Layout.preferredHeight: grid.preferredTileHeight(this)

            TemperatureProbe {
                id: tempProbe4
                anchors.fill: parent
                font.pixelSize: root.font.pixelSize * 4
                entity: "sensor.terrasse_licht_temperatur_4"
            }

            headerStatusText: tempProbe4.lastUpdate.toLocaleTimeString('hh:mm')
        }
        Tile {
            headerText: "Timer"

            Layout.row: 0
            Layout.rowSpan: 4
            Layout.column: 1
            Layout.preferredWidth: grid.preferredTileWidth(this) * 4 / 3
            Layout.preferredHeight: grid.preferredTileHeight(this)

            KitchenTimer {
                font.pixelSize: root.font.pixelSize * 2
                anchors.fill: parent
                MediaPlayer {
                    id: alarmSound
                    audioRole: MediaPlayer.AlarmRole
                    source: Qt.resolvedUrl('/sounds/alarm.wav')
                    volume: 0.7
                }

                onTimerTriggered: {
                    console.log("TIMER!")
                    alarmSound.play()
                }

                Tracer { }
            }
        }
    }
}
