// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

pragma ComponentBehavior: Bound
import QtQuick.Controls.Universal
import Ui


Drawer {
    id: root

    implicitHeight: parent.height
    implicitWidth: mainLayout.implicitWidth
    Overlay.modal: DarkOverlay { }

    property string iconName
    property string iconTitle: Qt.application.name
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
            color: root.Universal.foreground
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
                name: root.iconName
                size: root.font.pixelSize * 2
                Tracer { }
            }

            ColumnLayout {
                spacing: 8
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter | Qt.AlignLeft

                Label {
                    text: root.iconTitle
                    font.bold: true
                }

                Label {
                    opacity: 0.7
                    text: root.iconSubtitle
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
                    return root.font.pixelSize * 2
                } else if (d.spacer && !d.stretch) {
                    return root.font.pixelSize * 0.5
                } else {
                    let h = height
                    for (let i = 0; i < count; ++i) {
                        if (i !== index)
                            h -= delegateHeight(i)
                    }
                    return Math.max(h, root.font.pixelSize * 0.5)
                }
            }

            delegate: ItemDelegate {
                id: delegate
                required property int index
                required property var model

                width: ListView.view.width
                highlighted: !model.spacer && ListView.isCurrentItem

                property bool lastItem: (index === ListView.view.count - 1)
                                        || (ListView.view.model.get(index + 1).spacer)

                background: Item {
                    visible: !delegate.model.spacer
                    Rectangle {
                        anchors.fill: parent
                        anchors.topMargin: 1
                        anchors.bottomMargin: 1
                        color: root.Universal.foreground
                        opacity: delegate.pressed ? 0.4 : 0.11
                    }
                    Rectangle {
                        height: 1
                        width: parent.width
                        anchors.top: parent.top
                        color: root.Universal.foreground
                        opacity: 0.4
                    }
                    Rectangle {
                        height: 1
                        width: parent.width
                        anchors.bottom: parent.bottom
                        color: root.Universal.foreground
                        opacity: delegate.lastItem ? 0.4 : 0
                    }
                }

                Binding on icon.name {
                    value: delegate.model.iconName
                    when: !delegate.model.spacer || true
                }

                height: listView.delegateHeight(index)

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
