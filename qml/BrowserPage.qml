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
import QtWebEngine
import org.griebl.xbrowsersync 1.0

Page {
    id: root

    readonly property Action newTabAction: Action {
        text: qsTr("New tab")
        shortcut: StandardKey.AddTab
        onTriggered: root.createNewTab({url: "about:blank"})
    }

    title: tabStack.currentTab ? tabStack.currentTab.title : ""

    header: WebTabBar {
        id: tabBar

        z: 1

        newTabAction: root.newTabAction
    }

    WebTabStack {
        id: tabStack

        z: 0
        anchors.fill: parent

        profile: WebEngineProfile {
            storageName: "profile"
            offTheRecord: false
            persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies


        }
        Component.onCompleted: {
            console.log("cache", profile.cachePath, profile.persistentStoragePath)
            console.log("cookies", profile.persistentCookiesPolicy)
        }

        currentIndex: tabBar.currentIndex
        freezeDelay: 60
        discardDelay: 60*60

        onCloseRequested: function(index) {
            root.closeTab(index)
        }

        onDrawerRequested: drawer.toggle()
    }

    Drawer {
        id: drawer

        edge: Qt.RightEdge
        interactive: true
        dragMargin: 0
        modal: true
        height: root.height
        width: 2 * root.width / 3

        property var bookmarksStack: []

        ColumnLayout {
            anchors.fill: parent

            ItemDelegate {
                Layout.fillWidth: true

                id: bookmarksHeader
                text: "Bookmarks"
                icon.name: { (drawer.bookmarksStack.length === 0) ? "mdi/close" : "mdi/arrow-left" }

                font.capitalization: Font.SmallCaps

                onClicked: {
                    if (drawer.bookmarksStack.length === 0) {
                        drawer.close()
                    } else {
                        bookmarksList.model = drawer.bookmarksStack.pop()
                        drawer.bookmarksStack = drawer.bookmarksStack
                    }
                }
            }
            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true

                ListView {
                    id: bookmarksList
                    clip: true
                    model: XBrowserSync.bookmarks
                    delegate: Control {
                        id: bookmarkDelegate

                        property var data: modelData
                        property var url: modelData.url
                        property string title: modelData.title ? modelData.title.replace(/^\[xbs\] /, "") : modelData.url

                        function activate() {
                            if (modelData.children) {
                                drawer.bookmarksStack.push(bookmarksList.model)
                                drawer.bookmarksStack = drawer.bookmarksStack
                                bookmarksList.model = modelData.children
                            } else {
                                tabStack.currentTab.url = modelData.url
                                drawer.close()
                            }

                        }

                        width: ListView.view.width
                        contentItem: ItemDelegate {
                            Layout.fillWidth: true

                            property bool isFolder: bookmarkDelegate.data.children ? true : false

                            text: bookmarkDelegate.title
                            // drawer.opened forces a reload of the icons
                            icon.source: isFolder ? ""
                                                  : bookmarkDelegate.url && drawer.opened
                                                    ? "image://favicon/" + bookmarkDelegate.url
                                                    : ""
                            icon.name: isFolder ? "mdi/arrow-right" : ""
                            icon.color: isFolder ? "white" : "transparent"
                            icon.cache: isFolder
                            icon.height: font.pixelSize * 1.5
                            icon.width: font.pixelSize * 1.5

                            onClicked: bookmarkDelegate.activate()
                        }
                    }
                }
            }
        }

        function toggle() {
            if (drawer.visible)
                drawer.close()
            else
                drawer.open()
        }
    }

    Component.onCompleted: {
        createNewTab({url: "about:blank"})
    }

    function createNewTab(properties) {
        const tab = tabStack.createNewTab(properties)
        tabBar.createNewTab({tab: tab})
        tabBar.currentIndex = tab.index
        return tab
    }

    function closeTab(index) {
        if (tabStack.count === 1)
            Qt.callLater(createNewTab, {url: "about:blank"})
        tabBar.closeTab(index)
        tabStack.closeTab(index)
    }
}
