// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

pragma ComponentBehavior: Bound
import QtQml.XmlListModel
import Ui


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
                    root.lastUpdate = new Date()
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

        //headerPositioning: ListView.PullBackHeader
        header: Item {
            width: parent.width
            height: normalHeader.font.pixelSize * 1.5

            property real dx: width * (1 - root.textPercentage) / 2

            Label {
                id: normalHeader
                anchors.right: parent.right
                anchors.rightMargin: parent.dx + font.pixelSize
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
            id: delegate
            required property string duration
            required property string durationInTraffic
            required property bool realtime
            required property int index

            width: parent.width
            height: root.font.pixelSize * 1.5

            property real dx: width * (1 - root.textPercentage) / 2

            Label {
                id: textCol
                x: 5
                anchors.verticalCenter: parent.verticalCenter
                text: delegate.index < 0 ? '' : Object.keys(root.destinations[delegate.index])[0]
            }
            Label {
                property int minutes: Number(delegate.duration) / 60

                id: normalCol
                anchors.right: normalUnitCol.left
                anchors.rightMargin: 5
                anchors.baseline: textCol.baseline
                text: minutes
            }
            Label {
                id: normalUnitCol
                anchors.right: parent.right
                anchors.rightMargin: delegate.dx + font.pixelSize
                anchors.baseline: textCol.baseline
                text: root.unit
                font.pixelSize: normalCol.font.pixelSize / 2
            }
            Label {
                property int minutesDelay: (Number(delegate.durationInTraffic) / 60) - normalCol.minutes

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
