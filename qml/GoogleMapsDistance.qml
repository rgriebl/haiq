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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQml.XmlListModel
import QtQml

ScrollView {
    id: root
    clip: true

    property string origin
    property var destinations: []
    property string apiKey

    property real textPercentage: 0.7
    property string unit: "min"
    property date lastUpdate

    property int reloadInterval: 5 * 60 // every 5 minutes

    ScrollBar.vertical.policy: ScrollBar.AlwaysOn
    ScrollBar.horizontal.policy: ScrollBar.AlwaysOff
    ScrollBar.vertical.interactive: false

    property int googleApiQuota: (24*60*60) / reloadInterval * destinations.length
    onGoogleApiQuotaChanged: {
        if (googleApiQuota >= 2500) {
            reloadInterval = 24*60*60 / 2500 * destinations.length
            console.warn("WARNING: Google Distance Matrix - poll interval too high, exceeding quota. Resetting to " + reloadInterval + " seconds");
        }
    }

    ListView {
        id: list
        anchors.fill: parent

        model: XmlListModel {
            id: mapsModel

            source: "https://maps.googleapis.com/maps/api/distancematrix/xml?"
                    + "origins=" + encodeURIComponent(root.origin)
                    + "&destinations=" + encodeURIComponent(root.destinations.map(function(o) { return o[Object.keys(o)[0]]; }).join('|'))
                    + "&mode=driving&language=de-DE&departure_time=now&key=" + root.apiKey

            query: "/DistanceMatrixResponse/row/element"

            XmlListModelRole { name: "duration"; elementName: "duration/value" }
            XmlListModelRole { name: "durationInTraffic"; elementName: "duration_in_traffic/value" }
            XmlListModelRole { name: "realtime"; elementName: "realtime" }

            onStatusChanged: {
                if (status == XmlListModel.Error)
                    console.warn("Could not retrieve Google Maps Distance Matrix XML data: " + errorString())
                if (status == XmlListModel.Ready)
                    lastUpdate = new Date()
                //console.warn("Got Google Maps Distance Matrix XML data: " + count + "for: " + source)
            }
        }
        Timer {
            running: true // mapsModel.status === XmlListModel.Ready
            repeat: true
            interval: root.reloadInterval * 1000
            onTriggered: mapsModel.reload()
        }
        MouseArea {
            anchors.fill: parent
            onPressAndHold: mapsModel.reload()
        }

        headerPositioning: ListView.PullBackHeader
        header: Item {
            width: parent.width
            height: normalHeader.font.pixelSize * 1.5

            property real dx: width * (1 - root.textPercentage) / 2

            Label {
                id: normalHeader
                anchors.right: parent.right
                anchors.rightMargin: dx + font.pixelSize
                horizontalAlignment: Text.AlignRight
                text: "Normal"
                font.pixelSize: root.font.pixelSize / 2
            }
            Label {
                id: delayedHeader
                anchors.right: parent.right
                anchors.rightMargin: font.pixelSize
                horizontalAlignment: Text.AlignRight
                text: "Verzög."
                font.pixelSize: normalHeader.font.pixelSize
            }

        }
        delegate: Item {
            width: parent.width
            height: root.font.pixelSize * 1.5

            property real dx: width * (1 - root.textPercentage) / 2

            Label {
                id: textCol
                x: 5
                anchors.verticalCenter: parent.verticalCenter
                text: model.index < 0 ? '' : Object.keys(root.destinations[model.index])[0]
            }
            Label {
                property int minutes: Number(duration) / 60

                id: normalCol
                anchors.right: normalUnitCol.left
                anchors.rightMargin: 5
                anchors.baseline: textCol.baseline
                text: minutes
            }
            Label {
                id: normalUnitCol
                anchors.right: parent.right
                anchors.rightMargin: dx + font.pixelSize
                anchors.baseline: textCol.baseline
                text: root.unit
                font.pixelSize: normalCol.font.pixelSize / 2
            }
            Label {
                property int minutesDelay: (Number(durationInTraffic) / 60) - normalCol.minutesLeft

                id: delayedCol
                anchors.right: delayedUnitCol.left
                anchors.rightMargin: 5
                anchors.baseline: textCol.baseline
                text: minutesDelay <= 0 ? "-" : minutesDelay
                color: minutesDelay <= 2 ? "green" : (minutesDelay <= 8 ? "yellow" : "red")
            }
            Label {
                id: delayedUnitCol
                anchors.right: parent.right
                anchors.rightMargin: font.pixelSize
                anchors.baseline: textCol.baseline
                text: delayedCol.minutesDelay <= 0 ? "" : root.unit
                font.pixelSize: delayedCol.font.pixelSize / 2
            }
        }
    }
}
