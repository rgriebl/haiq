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
import QtQuick 2.12
import QtQuick.Window 2.12
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.XmlListModel 2.0
import QtQml 2.2
//import QtLocation 5.11
//import QtPositioning 5.11

Control {
    id: root

//    Plugin {
//        id: mapPlugin
//        name: "mapbox"
//        PluginParameter {
//            name: "mapbox.access_token"
//            value: "pk.eyJ1IjoiaGFpcSIsImEiOiJjazZqeHV5Z2kwMTE2M2Ruc3V0OXc1OXNsIn0.m5nW1kABbSJG7JVOtPEIvA"
//        }
//        PluginParameter {
//            name: "mapboxgl.mapping.additional_style_urls"
//            value: "mapbox://styles/haiq/ck6k3jbtj0e2u1ioai4slh5mu"
//        }
//        PluginParameter {
//            name: "mapbox.mapping.additional_map_ids"
//            value: "haiq.ck6k3jbtj0e2u1ioai4slh5mu"
//        }
//    }

//    Popup {
//        id: mapPopup
//        modal: true
//        Overlay.modal: Rectangle {
//            color: Qt.rgba(0, 0, 0, 0.8)
//            Behavior on opacity { NumberAnimation { duration: 200 } }
//        }

//        margins: parent.Window.width / 30

//        Map {
//            id: map
//            gesture.enabled: true
//            anchors.fill: parent
//            plugin: mapPlugin
//            center: QtPositioning.coordinate(59.91, 10.75) // Oslo
//            zoomLevel: 14

//            activeMapType: supportedMapTypes[supportedMapTypes.length - 1]

////            Component.onCompleted: {
////                console.log(supportedMapTypes.length)
////                for (let i = 0; i < supportedMapTypes.length; ++i)
////                    console.log(i + ": " + JSON.stringify(supportedMapTypes[i]))
////            }
////            onSupportedMapTypesChanged:{
////                console.log(supportedMapTypes.length)
////                for (let i = 0; i < supportedMapTypes.length; ++i)
////                    console.log(i + ": " + JSON.stringify(supportedMapTypes[i]))
////            }
//        }
//    }

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

            namespaceDeclarations: "declare namespace rtcm = 'http://www.navteq.com/lbsp/Routing-CalculateMatrix/1';"

            source: "http://matrix.route.cit.api.here.com/routing/7.2/calculatematrix.xml"
                    + "?app_id=" + root.appId
                    + "&app_code=" + root.appCode
                    + "&mode=fastest;car;traffic:enabled"
                    + "&departure=now"
                    + "&summaryAttributes=traveltime"
                    + "&start0=" + encodeURIComponent(root.origin)
                    + encodeDestinations()

            query: "/rtcm:CalculateMatrix/Response/MatrixEntry"

            XmlRole { name: "duration"; query: "Summary/TravelTime/number()" }
            XmlRole { name: "durationInTraffic"; query: "Summary/TravelTime/number()" }

            onStatusChanged: {
                if (status == XmlListModel.Error)
                    console.warn("Could not retrieve Here Maps Calculate Matrix XML data: " + errorString())
                if (status == XmlListModel.Ready)
                    lastUpdate = new Date()
                //console.warn("Got Here Maps Calculate Matrix XML data: " + count + " for: " + source)
            }
        }
        Timer {
            running: true // mapsModel.status === XmlListModel.Ready
            repeat: true
            interval: root.reloadInterval * 1000
            onTriggered: mapsModel.reload()
        }

        headerPositioning: ListView.PullBackHeader
        header: Item {
            width: ListView.view.width
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
                anchors.rightMargin: parent.ListView.view.ScrollIndicator.vertical.width
                horizontalAlignment: Text.AlignRight
                text: "Verzög."
                font.pixelSize: normalHeader.font.pixelSize
            }

        }
        delegate: Item {
            id: delegate
            width: ListView.view.width
            height: root.font.pixelSize * 1.5

            property real dx: width * (1 - root.textPercentage) / 2

//            MouseArea {
//                anchors.fill: parent
//                onClicked: mapPopup.open()
//            }
            Label {
                id: textCol
                x: 5
                anchors.verticalCenter: parent.verticalCenter
                text: model.index < 0 ? '' : Object.keys(root.destinations[model.index])[0]
            }
            Label {
                property int minutes: duration / 60

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
                property int minutesDelay: (durationInTraffic / 60) - normalCol.minutesLeft

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

