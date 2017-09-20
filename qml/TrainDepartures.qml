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
import QtQuick.Controls 2.12
import QtQuick.Layouts 1.12
import QtQuick.XmlListModel 2.0
import QtQml 2.12

Control {
    id: root

    property real textPercentage: 0.7
    property string unit: "min"
    property date lastUpdate

    property int reloadInterval: 60

    BusyIndicator {
        anchors.centerIn: parent
        opacity: running ? 0.5 : 0
        Behavior on opacity { NumberAnimation { duration: 100 } }
        running: mvvModel.status === XmlListModel.Loading
        width: parent.width / 4
        height: width
    }

    ListView {
        id: list
        clip: true

        ScrollIndicator.vertical: ScrollIndicator { }

        anchors.fill: parent

        PullToRefreshListHeader {
            onRefresh: mvvModel.reload()
        }

        Timer {
            interval: 0.1 * 60 * 1000
            running: !list.atYBeginning
            onTriggered: list.positionViewAtBeginning()
        }

        model: XmlListModel {
            id: mvvModel
            // 1004020 == Zorneding the rest of the query string is from Oeffi's backend
            // https://github.com/schildbach/public-transport-enabler - Bayern / Efa provider
            // NB: the MVV provider does not support realtime infos!
            source: "http://mobile.defas-fgi.de/beg/XML_DM_REQUEST?outputFormat=XML&language=de&type_dm=stop&name_dm=1004020&useRealtime=1&mode=direct&ptOptionsActive=1&mergeDep=1&limit=10"
            query: "/efa/dps/dp[m/n='S-Bahn']"

            XmlRole { name: "line"; query: "m/nu/string()" }
            XmlRole { name: "destination"; query: "m/des/string()" }
            XmlRole { name: "realtime"; query: "boolean(realtime)" }
            // we need to convert the German date/time spec to an ISO datetime spec
            XmlRole { name: "timePlanned"; query: 'concat(substring(st/da,1,4),"/",substring(st/da,5,2),"/",substring(st/da,7,2),"T",dt/t/string())' }
            XmlRole { name: "timeExpected"; query: 'concat(substring(st/rda,1,4),"/",substring(st/rda,5,2),"/",substring(st/rda,7,2),"T",dt/rt/string())' }

            onStatusChanged: {
                if (status == XmlListModel.Error)
                    console.warn("Could not retrieve EFA XML data: " + errorString() + ")")
                else if (status == XmlListModel.Ready)
                    lastUpdate = new Date()

                list.positionViewAtBeginning()
            }
        }
        Timer {
            running: true // mvvModel.status === XmlListModel.Ready
            repeat: true
            interval: root.reloadInterval * 1000
            onTriggered: mvvModel.reload()
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
                text: "Abfahrt"
                font.pixelSize: root.font.pixelSize / 2
            }
            Label {
                id: delayedHeader
                anchors.right: parent.right
                anchors.rightMargin: parent.ListView.view.ScrollIndicator.vertical.width
                horizontalAlignment: Text.AlignRight
                text: "Verspät."
                font.pixelSize: normalHeader.font.pixelSize
            }

        }

        delegate: Item {
            width: ListView.view.width
            height: root.font.pixelSize * 1.5

            property real dx: width * (1 - root.textPercentage) / 2

            function sbahnColor(sline) {
                switch(sline) {
                case 'S1': return { 'bg': '#00ccff', 'fg': 'white' }
                case 'S2': return { 'bg': '#66cc00', 'fg': 'white' }
                case 'S3': return { 'bg': '#880099', 'fg': 'white' }
                case 'S4': return { 'bg': '#ff0033', 'fg': 'white' }
                case 'S6': return { 'bg': '#00aa66', 'fg': 'white' }
                case 'S7': return { 'bg': '#993333', 'fg': 'white' }
                case 'S8': return { 'bg': 'black', 'fg': '#ffcc00' }
                case 'S20': return { 'bg': 'black', 'fg': '#ffaaaa' }
                case 'S27': return { 'bg': '#ffaaaa', 'fg': 'white' }
                case 'SA': return { 'bg': '#231f20', 'fg': 'white' }
                }
                return { 'bg': 'gray', 'fg': 'white' }
            }

            Label {
                id: lineCol
                x: 5
                anchors.verticalCenter: parent.verticalCenter
                text: line
                font.bold: true
                font.pixelSize: textCol.font.pixelSize
                //topPadding: font.pixelSize / 8
                //bottomPadding: topPadding
                leftPadding: font.pixelSize / 3 * 2
                rightPadding: leftPadding
                color: sbahnColor(line).fg

                Rectangle {
                    z: -1
                    anchors.fill: parent
                    anchors.margins: parent.font.pixelSize / 8
                    color: sbahnColor(line).bg
                    radius: height / 2
                }
            }
            Label {
                id: textCol
                anchors.left: lineCol.right
                anchors.leftMargin: font.pixelSize / 2
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 2 * dx + delayedUnitCol.anchors.rightMargin
                text: destination.replace(/\(.*\)/, '')
                elide: Text.ElideRight
            }
            Label {
                property int minutesLeft: (Date.parse(timePlanned) - Date.now()) / (60 * 1000)

                id: normalCol
                anchors.right: normalUnitCol.left
                anchors.rightMargin: 5
                anchors.baseline: textCol.baseline
                text: minutesLeft > 0 ? minutesLeft : "Jetzt"
            }
            Label {
                id: normalUnitCol
                anchors.right: parent.right
                anchors.rightMargin: dx + delayedUnitCol.anchors.rightMargin
                anchors.baseline: textCol.baseline
                text: normalCol.minutesLeft <= 0 ? "" : root.unit
                font.pixelSize: normalCol.font.pixelSize / 2
            }
            Label {
                property int minutesLate: realtime ? ((Date.parse(timeExpected) - Date.now()) / (60 * 1000) - normalCol.minutesLeft) : -1

                id: delayedCol
                anchors.right: delayedUnitCol.left
                anchors.rightMargin: 5
                anchors.baseline: textCol.baseline
                text: minutesLate < 0 ? "n.v." : (minutesLate === 0 ? "-" : minutesLate)
                color: minutesLate < 0 ? normalCol.color : (minutesLate <= 2 ? "green" : (minutesLate <= 8 ? "yellow" : "red"))
            }
            Label {
                id: delayedUnitCol
                anchors.right: parent.right
                anchors.rightMargin: parent.ListView.view.ScrollIndicator.vertical.width
                anchors.baseline: textCol.baseline
                text: delayedCol.minutesLate <= 0 ? "" : root.unit
                font.pixelSize: delayedCol.font.pixelSize / 2
            }
        }
    }
}

