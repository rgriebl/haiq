// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

pragma ComponentBehavior: Bound
import QtQml.XmlListModel
import Ui


Control {
    id: root

    property string origin
    property var destinations: []
    property string appId
    property string appCode

    property real textPercentage: 0.7
    property string unit: "min"
    property date lastUpdate

    property int reloadInterval: 5 * 60 // every 5 minutes

    property int hereApiQuota: (24*60*60) / reloadInterval * destinations.length
    onHereApiQuotaChanged: {
        if (hereApiQuota >= 15000) {
            reloadInterval = 24*60*60 / 15000 * destinations.length
            console.warn("WARNING: Here Calculate Matrix - poll interval too high, exceeding quota. Resetting to " + reloadInterval + " seconds");
        }
    }

    BusyIndicator {
        anchors.centerIn: parent
        opacity: running ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
        running: mapsModel.status === XmlListModel.Loading
        width: parent.width / 4
        height: width
    }

    ListView {
        id: list
        anchors.fill: parent
        clip: true

        ScrollIndicator.vertical: ScrollIndicator { }

        PullToRefreshListHeader {
            onRefresh: mapsModel.reload()
        }

        Timer {
            interval: 0.1 * 60 * 1000
            running: !list.atYBeginning
            onTriggered: list.positionViewAtBeginning()
        }

        model: XmlListModel {
            id: mapsModel

            function encodeDestinations()
            {
                var str = ""
                var destList = root.destinations.map(function(o) { return o[Object.keys(o)[0]]; })
                destList.forEach(function(dest, idx) { str = str + "&destination" + idx + "=" + encodeURIComponent(dest) })
                return str
            }

            source: "http://matrix.route.cit.api.here.com/routing/7.2/calculatematrix.xml"
                    + "?app_id=" + root.appId
                    + "&app_code=" + root.appCode
                    + "&mode=fastest;car;traffic:enabled"
                    + "&departure=now"
                    + "&summaryAttributes=traveltime"
                    + "&start0=" + encodeURIComponent(root.origin)
                    + encodeDestinations()

            query: "/CalculateMatrix/Response/MatrixEntry"

            XmlListModelRole { name: "duration"; elementName: "Summary/TravelTime" }
            XmlListModelRole { name: "durationInTraffic"; elementName: "Summary/TravelTime" }

            onStatusChanged: {
                if (status == XmlListModel.Error)
                    console.warn("Could not retrieve Here Maps Calculate Matrix XML data: " + errorString())
                if (status == XmlListModel.Ready)
                    root.lastUpdate = new Date()
                //console.warn("Got Here Maps Calculate Matrix XML data: " + count + " for: " + source)
            }
        }
        Timer {
            running: true // mapsModel.status === XmlListModel.Ready
            repeat: true
            interval: root.reloadInterval * 1000
            onTriggered: mapsModel.reload()
        }

        //headerPositioning: ListView.PullBackHeader
        header: Item {
            width: ListView.view.width
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
                anchors.rightMargin: parent.ListView.view.ScrollIndicator.vertical.width
                horizontalAlignment: Text.AlignRight
                text: "Verzög."
                font.pixelSize: normalHeader.font.pixelSize
            }

        }
        delegate: Item {
            id: delegate
            required property string duration
            required property string durationInTraffic
            required property int index

            width: ListView.view.width
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
                anchors.rightMargin: parent.ListView.view.ScrollIndicator.vertical.width
                anchors.baseline: textCol.baseline
                text: delayedCol.minutesDelay <= 0 ? "" : root.unit
                font.pixelSize: delayedCol.font.pixelSize / 2
            }
        }
    }
}

