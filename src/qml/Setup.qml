// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

pragma ComponentBehavior: Bound
import Ui


ApplicationWindow {
    id: root

    visible: true
    title: qsTr("HAiQ Initial Setup")

    property string selectedVariant: ""

    minimumHeight: layout.implicitHeight + footer.implicitHeight
    minimumWidth: Math.max(layout.implicitWidth, footer.implicitWidth)

    ColumnLayout {
        id: layout
        spacing: root.font.pixelSize / 2
        anchors.fill: parent
        anchors.margins: (root.visibility == Window.Windowed) ? 2 * spacing : 12 * spacing

        Label {
            font.bold: true
            font.pixelSize: root.font.pixelSize * 2
            text: root.title
            Layout.fillWidth: true
            horizontalAlignment: Text.Center
        }

        MenuSeparator { Layout.fillWidth: true }
        Label {
            text: qsTr("Config hostname or IP:")
            font.bold: true
        }
        TextField {
            Layout.fillWidth: true

            id: configHostname
            Component.onCompleted: { text = SetupProperties.configHostname }
        }

        Label {
            text: qsTr("Config download Token:")
            font.bold: true
        }
        TextField {
            Layout.fillWidth: true

            id: configToken
            Component.onCompleted: { text = SetupProperties.configToken }
        }

        Label {
            text: qsTr("UI Variant:")
            font.bold: true
            visible: variantList.visible
        }
        ScrollView {
            id: variantList
            Layout.fillWidth: true
            Layout.fillHeight: true

            ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

            visible: SetupProperties.possibleVariants.length > 0

            ListView {
                implicitHeight: contentHeight / count * 6.5
                clip: true

                model: SetupProperties.possibleVariants
                delegate: RadioDelegate {
                    required property var modelData
                    width: ListView.view.width
                    text: modelData
                    checked: root.selectedVariant === modelData
                    onToggled: {
                        if (checked)
                            root.selectedVariant = modelData
                    }
                }
                ScrollIndicator.vertical: ScrollIndicator { active: true }
            }
        }
    }
    footer: DialogButtonBox {
        standardButtons: DialogButtonBox.Save | DialogButtonBox.Cancel
        onClicked: function(button) {
            if (button === standardButton(DialogButtonBox.Save)) {
                SetupProperties.selectedVariant = root.selectedVariant
                SetupProperties.configHostname = configHostname.text
                SetupProperties.configToken = configToken.text
            }
            Qt.quit();
        }
    }
}
