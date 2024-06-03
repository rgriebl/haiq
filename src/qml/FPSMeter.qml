// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import Ui


Rectangle {
    id: root
    width: text.paintedWidth
    height: text.paintedHeight

    property bool active: false;

    visible: active && (fpsProbe.fps >= 0)
    color: {
        if (fpsProbe.fps < 30)
            return "red";
        if (fpsProbe.fps < 45)
            return "orange"
        else
            return "green"
    }

    Text {
        id: text
        font.pixelSize: 20;
        text: fpsProbe.fps + " fps"
    }

    Timer {
        id: fpsProbe

        property int fps: -1
        property int frames: 0

        property double previousTime: 0

        repeat: true
        interval: 1000
        running: root.active
        
        onTriggered: {
            if (!previousTime)
                previousTime = new Date().getTime();

            var currentTime = new Date().getTime();

            fps = frames / ((currentTime - previousTime) / 1000);
            frames = 0;

            previousTime = currentTime;
        }

        property real frameObserver
        NumberAnimation on frameObserver {
            from: 0; to: 1;
            loops: Animation.Infinite;
            duration: 1000
            running: root.active
        }

        onFrameObserverChanged: {
            frames++;
            root.update();
        }
    }
}
