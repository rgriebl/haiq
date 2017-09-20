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
import QtQuick.Layouts 1.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Universal 2.12
import QtQuick.Window 2.12


Drawer {
    id: root

    implicitHeight: parent.height
    implicitWidth: mainLayout.implicitWidth
    Overlay.modal: defaultOverlay

    property alias icon: headerIcon
    property string iconTitle: Qt.application.displayName
    property string iconSubtitle: "Version " + Qt.application.version
    property alias items: listView.model
    property alias index: listView.currentIndex

    background: Rectangle {
        anchors.fill: parent
        color: Universal.background

        Rectangle {
            width: 1
            height: parent.height
            anchors.right: parent.right
            anchors.rightMargin: -1
            color: Universal.foreground
            opacity: 0.4
        }
    }

    ColumnLayout {
        id: mainLayout

        spacing: 0
        anchors.margins: spacing
        anchors.fill: parent

        RowLayout { // header
            spacing: root.font.pixelSize / 2
            Layout.margins: spacing

            SvgIcon {
                id: headerIcon
                size: root.font.pixelSize * 2
            }

            ColumnLayout {
                spacing: 8
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                Label {
                    text: iconTitle
                    font.bold: true
                }

                Label {
                    opacity: 0.7
                    text: iconSubtitle
                    font.pixelSize: root.font.pixelSize * 0.7
                }
            }
        }

        ListView { // menu
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: -1

            interactive: contentHeight > height

            function delegateHeight(index) {
                let d = model.get(index)
                if (!d.spacer) {
                    return font.pixelSize * 2
                } else if (d.space && !d.stretch) {
                    return font.pixelSize * 0.5
                } else {
                    let h = height
                    for (let i = 0; i < count; ++i) {
                        if (i !== index)
                            h -= delegateHeight(i)
                    }
                    return Math.max(h, font.pixelSize * 0.5)
                }
            }

            delegate: ItemDelegate {
                id: delegate

                width: ListView.view.width
                highlighted: !model.spacer && ListView.isCurrentItem

                property bool lastItem: (index === ListView.view.count - 1)
                                        || (ListView.view.model.get(index + 1).spacer)

                background: Item {
                    visible: !model.spacer
                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1
                        anchors.bottomMargin: 1
                        color: Universal.foreground
                        opacity: delegate.pressed ? 0.4 : 0.11
                    }
                    Rectangle {
                        height: 1
                        width: parent.width
                        anchors.top: parent.top
                        color: Universal.foreground
                        opacity: 0.4
                    }
                    Rectangle {
                        height: 1
                        width: parent.width
                        anchors.bottom: parent.bottom
                        color: Universal.foreground
                        opacity: delegate.lastItem ? 0.4 : 0
                    }
                }

                Binding on icon.name {
                    value: model.iconName
                    when: !model.spacer || true
                }

                height: ListView.view.delegateHeight(index)

                text: model.text

                onClicked: {
                    ListView.currentIndex = index

                    if (model.action)
                        model.action()
                    root.close()
                }
            }

            ScrollIndicator.vertical: ScrollIndicator { }
        }
    }
}
