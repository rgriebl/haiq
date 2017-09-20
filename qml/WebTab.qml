/****************************************************************************
**
** Copyright (C) 2019 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of the examples of the Qt Toolkit.
**
** $QT_BEGIN_LICENSE:BSD$
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** BSD License Usage
** Alternatively, you may use this file under the terms of the BSD license
** as follows:
**
** "Redistribution and use in source and binary forms, with or without
** modification, are permitted provided that the following conditions are
** met:
**   * Redistributions of source code must retain the above copyright
**     notice, this list of conditions and the following disclaimer.
**   * Redistributions in binary form must reproduce the above copyright
**     notice, this list of conditions and the following disclaimer in
**     the documentation and/or other materials provided with the
**     distribution.
**   * Neither the name of The Qt Company Ltd nor the names of its
**     contributors may be used to endorse or promote products derived
**     from this software without specific prior written permission.
**
**
** THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
** "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
** LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
** A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
** OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
** SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
** LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
** DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
** THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
** (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
** OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
**
** $QT_END_LICENSE$
**
****************************************************************************/

import QtQml 2.12
import QtQuick 2.12
import QtQuick.Controls 2.12
import QtQuick.Controls.Material 2.12
import QtQuick.Layouts 1.12
import QtWebEngine 1.11

ColumnLayout {
    id: root

    signal closeRequested
    signal drawerRequested

    property int freezeDelay
    property int discardDelay

    property alias icon : view.icon
    property alias loading : view.loading
    property alias url : view.url
    property alias lifecycleState : view.lifecycleState
    property alias recommendedState : view.recommendedState

    readonly property string title : {
        if (view.url == "about:blank")
            return qsTr("Neuer Tab")
        if (view.title)
            return view.title
        return view.url
    }

    readonly property Action backAction: Action {
        property WebEngineAction webAction: view.action(WebEngineView.Back)
        enabled: webAction.enabled
        shortcut: root.visible && StandardKey.Back
        onTriggered: webAction.trigger()
    }

    readonly property Action forwardAction: Action {
        property WebEngineAction webAction: view.action(WebEngineView.Forward)
        enabled: webAction.enabled
        shortcut: root.visible && StandardKey.Forward
        onTriggered: webAction.trigger()
    }

    readonly property Action reloadAction: Action {
        property WebEngineAction webAction: view.action(WebEngineView.Reload)
        enabled: webAction.enabled
        shortcut: root.visible && StandardKey.Refresh
        onTriggered: webAction.trigger()
    }

    readonly property Action stopAction: Action {
        property WebEngineAction webAction: view.action(WebEngineView.Stop)
        enabled: webAction.enabled
        shortcut: root.visible && StandardKey.Cancel
        onTriggered: webAction.trigger()
    }

    readonly property Action closeAction: Action {
        shortcut: root.visible && StandardKey.Close
        onTriggered: root.closeRequested()
    }

    readonly property Action activateAction: Action {
        text: qsTr("Active")
        checkable: true
        checked: view.lifecycleState === WebEngineView.LifecycleState.Active
        enabled: checked || (view.lifecycleState !== WebEngineView.LifecycleState.Active)
        onTriggered: view.lifecycleState = WebEngineView.LifecycleState.Active
    }

    readonly property Action freezeAction: Action {
        text: qsTr("Frozen")
        checkable: true
        checked: view.lifecycleState === WebEngineView.LifecycleState.Frozen
        enabled: checked || (!view.visible && view.lifecycleState === WebEngineView.LifecycleState.Active)
        onTriggered: view.lifecycleState = WebEngineView.LifecycleState.Frozen
    }

    readonly property Action discardAction: Action {
        text: qsTr("Discarded")
        checkable: true
        checked: view.lifecycleState === WebEngineView.LifecycleState.Discarded
        enabled: checked || (!view.visible && view.lifecycleState === WebEngineView.LifecycleState.Frozen)
        onTriggered: view.lifecycleState = WebEngineView.LifecycleState.Discarded
    }

    spacing: 0

    ToolBar {
        Layout.fillWidth: true
        Material.elevation: 0
        Material.background: Material.color(Material.Grey, Material.Shade800)

        RowLayout {
            anchors.fill: parent
            WebToolButton {
                action: root.backAction
                icon.name: "mdi/arrow-left"
                ToolTip.text: root.backAction.text
            }
            WebToolButton {
                action: root.forwardAction
                icon.name: "mdi/arrow-right"
                ToolTip.text: root.forwardAction.text
            }
            WebToolButton {
                action: root.reloadAction
                visible: root.reloadAction.enabled
                icon.name: "mdi/refresh"
                ToolTip.text: root.reloadAction.text
            }
            WebToolButton {
                action: root.stopAction
                visible: root.stopAction.enabled
                icon.name: "mdi/close"
                ToolTip.text: root.stopAction.text
            }
            TextField {
                id: urlEdit
                Layout.fillWidth: true
                Layout.topMargin: 6

                placeholderText: qsTr("Adresse oder Suchanfrage eingeben")
                text: view.url == "about:blank" ? "" : view.url
                selectByMouse: true

                rightPadding: 8 + (urlClear.visible ? urlClear.width : 0)

                inputMethodHints: Qt.ImhUrlCharactersOnly | Qt.ImhNoAutoUppercase | Qt.ImhNoPredictiveText

                onAccepted: {
                    let u = text
                    if (!u.startsWith("https://") && !u.startsWith("http://")) {
                        if (u.indexOf(' ') >= 0 || u.indexOf('.' < 0)) {
                            u = "https://google.de/search?q=" + encodeURIComponent(u)
                        } else {
                            u = "https://" + u
                        }
                    }
                    view.url = u
                }

                ToolButton {
                    id: urlClear
                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter
                    icon.name: "mdi/backspace"
                    icon.height: urlEdit.font.pixelSize
                    Binding {
                        target: urlClear
                        property: "icon.width"
                        value: urlClear.icon.height
                        delayed: true
                    }
                    visible: urlEdit.text !== ""
                    onClicked: urlEdit.clear()
                }
            }
            WebToolButton {
                icon.name: "mdi/menu"
                ToolTip.text: qsTr("Einstellungen")
                onClicked: root.drawerRequested()
            }
        }
    }

    WebEngineView {
        id: view
        Layout.fillHeight: true
        Layout.fillWidth: true
        zoomFactor: 2
    }

    Timer {
        interval: {
            switch (view.recommendedState) {
            case WebEngineView.LifecycleState.Active:
                return 1
            case WebEngineView.LifecycleState.Frozen:
                return root.freezeDelay * 1000
            case WebEngineView.LifecycleState.Discarded:
                return root.discardDelay * 1000
            }
        }
        running: interval && view.lifecycleState != view.recommendedState
        onTriggered: view.lifecycleState = view.recommendedState
    }
}
