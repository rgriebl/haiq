// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import QtQuick
import QtQuick.Controls
import QtWebEngine

Page {
    id: root

    WebEngineView {
        id: view
        anchors.fill: parent
        zoomFactor: 2
        url: "http://marvin.home:8123"

        profile: WebEngineProfile {
            storageName: "ha-profile"
            offTheRecord: false
            persistentCookiesPolicy: WebEngineProfile.ForcePersistentCookies
        }
    }
}
