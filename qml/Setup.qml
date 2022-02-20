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
import QtQuick.Window 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15


ApplicationWindow {
    id: root

    visible: true
    title: qsTr("HAiQ Initial Setup")

    property string selectedVariant: ""

    minimumHeight: layout.implicitHeight + footer.implicitHeight
    minimumWidth: Math.max(layout.implicitWidth, footer.implicitWidth)

    ColumnLayout {
        id: layout
        spacing: font.pixelSize / 2
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
                    width: ListView.view.width
                    text: modelData
                    checked: selectedVariant === modelData
                    onToggled: {
                        if (checked)
                            selectedVariant = modelData
                    }
                }
                ScrollIndicator.vertical: ScrollIndicator { active: true }
            }
        }
    }
    footer: DialogButtonBox {
        standardButtons: DialogButtonBox.Save | DialogButtonBox.Cancel
        onClicked: {
            if (button === standardButton(DialogButtonBox.Save)) {
                SetupProperties.selectedVariant = selectedVariant
                SetupProperties.configHostname = configHostname.text
                SetupProperties.configToken = configToken.text
            }
            Qt.quit();
        }
    }
}
