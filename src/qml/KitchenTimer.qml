// Copyright (C) 2017-2024 Robert Griebl
// SPDX-License-Identifier: GPL-3.0-only

import Ui


Control {
    id: root

    property alias hours: hoursTumbler.currentIndex
    property alias minutes: minutesTumbler.currentIndex
    property alias seconds: secondsTumbler.currentIndex

    property bool timerActive: false
    property bool timerPaused: false
    property int timerInterval: 1000 * (seconds + 60 * (minutes + 60 * hours))
    property int timerRemaining

    Component.onCompleted: resetTimer()

    function resetTimer() {
        if (!timerActive)
            hours = minutes = seconds = 0
    }

    function startTimer() {
        if (!timerActive || timerPaused) {
            _timer.startTime = new Date().getTime()
            if (!timerActive)
                _timer.interval = timerInterval
            timerRemaining = _timer.interval
            timerActive = true
            timerPaused = false
            _timer.start()
        }
    }

    function pauseTimer() {
        if (timerActive && !timerPaused) {
            timerPaused = true
            _timer.stop()
            _timer.interval -= (new Date().getTime() - _timer.startTime)
        }
    }

    function stopTimer() {
        _timer.stop()
        _timer.startTime = 0
        timerPaused = false
        timerActive = false
    }

    Timer {
        id: _timer

        property real startTime: 0

        property Timer ticker: Timer {
            id: ticker
            interval: 1
            repeat: true
            running: _timer.running
            onTriggered: {
                let d = new Date()
                let elapsed = d.getTime() - _timer.startTime

                root.timerRemaining = _timer.interval - elapsed

                interval = 1000 - d.getMilliseconds()
            }
        }
        onTriggered: {
            root.stopTimer()
            root.timerTriggered()
        }
    }

    signal timerTriggered()

    ColumnLayout {
        anchors.fill: parent

        StackLayout {
            id: tumblerStack
            currentIndex: root.timerActive ? 1 : 0

            RowLayout {
                id: tumblerRow
                Layout.fillHeight: true

                Component {
                    id: delegateComponent

                    Label {
                        id: label
                        required property var index
                        required property var modelData
                        property real d: Tumbler.displacement / (Tumbler.tumbler.visibleItemCount / 2)

                        text: String(modelData).padStart(2, '0')
                        opacity: 1 - 0.8 * Math.abs(d)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        font.pixelSize: Tumbler.tumbler.font.pixelSize * (1 - 0.6 * Math.abs(d))
                        transform: Rotation {
                            origin { x: label.width / 2; y: label.height / 2 }
                            axis { x: 1; y: 0; z: 0 }
                            angle: Math.asin(label.d) * 180 / Math.PI
                        }
                    }
                }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 10
                    Tracer { }
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    text: "s "
                    opacity: 0

                    Tracer { }
                }
                Tumbler {
                    id: hoursTumbler
                    Layout.fillHeight: true
                    Layout.preferredWidth: implicitWidth * 2.5
                    visibleItemCount: 9
                    model: 24
                    delegate: delegateComponent
                    wrap: true

                    Tracer { }
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    text: "h  "

                    Tracer { }
                }
                Tumbler {
                    id: minutesTumbler
                    Layout.fillHeight: true
                    Layout.preferredWidth: implicitWidth * 2.5
                    visibleItemCount: 9
                    model: 60
                    delegate: delegateComponent
                    wrap: true

                    Tracer { }
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    text: "m  "

                    Tracer { }
                }
                Tumbler {
                    id: secondsTumbler
                    Layout.fillHeight: true
                    Layout.preferredWidth: implicitWidth * 2
                    visibleItemCount: 9
                    model: 60
                    delegate: delegateComponent
                    wrap: true

                    Tracer { }
                }
                Label {
                    Layout.alignment: Qt.AlignCenter
                    text: "s  "

                    Tracer { }
                }
                Item {
                    Layout.fillWidth: true
                    implicitHeight: 10
                    Tracer { }
                }
            }
            Label {
                id: remainingTime
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                text: {
                    let d = new Date()
                    d.setHours(0,0,0,0);
                    d.setMilliseconds(root.timerRemaining)
                    return Qt.formatTime(d, "hh:mm:ss")
                }
                minimumPixelSize: root.font.pixelSize
                font.pixelSize: root.font.pixelSize * 4
                fontSizeMode: Text.Fit
                font.bold: true
            }
        }
        RowLayout {
            Layout.leftMargin: root.font.pixelSize
            Layout.rightMargin: Layout.leftMargin
            Layout.topMargin: root.font.pixelSize / 2
            Layout.bottomMargin: Layout.topMargin

            SceneButton {
                Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
                icon.name: 'mdi/stop'
                scale: 2
                enabled: root.timerActive
                onClicked: root.stopTimer()
            }
            Item { Layout.fillWidth: true }
            SceneButton {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                icon.name: 'mdi/refresh'
                scale: 2
                enabled: !root.timerActive && (root.timerInterval !== 0)
                onClicked: root.resetTimer()
            }
            Item { Layout.fillWidth: true }
            SceneButton {
                Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                icon.name: (root.timerActive && !root.timerPaused) ? 'mdi/pause' : 'mdi/play'
                scale: 2
                enabled: root.timerInterval > 0
                onClicked: (root.timerActive && !root.timerPaused) ? root.pauseTimer() : root.startTimer()
            }
        }
    }
    Rectangle {
        y: tumblerRow.y + tumblerRow.height / 2 - height / 2
        anchors.horizontalCenter: parent.horizontalCenter
        width: parent.width * 0.95
        height: parent.font.pixelSize
        color: Qt.rgba(1,1,1,0.3)
        radius: height / 4
        visible: tumblerStack.currentIndex === 0

        Tracer { }

    }
}
