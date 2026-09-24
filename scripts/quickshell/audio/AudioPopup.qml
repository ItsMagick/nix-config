import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window

    // -------------------------------------------------------------------------
    // STATE
    // -------------------------------------------------------------------------
    property real globalOrbitAngle: 0
    property real introState: 0.0
    property bool rescanSpinning: false
    property bool switching: false

    readonly property color base: _theme.base
    readonly property color blue: _theme.blue
    readonly property color crust: _theme.crust
    readonly property color green: _theme.green
    readonly property color mantle: _theme.mantle
    readonly property color mauve: _theme.mauve
    readonly property color overlay0: _theme.overlay0
    readonly property color peach: _theme.peach
    readonly property color pink: _theme.pink
    readonly property color red: _theme.red
    readonly property color sapphire: _theme.sapphire
    readonly property color subtext0: _theme.subtext0
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color teal: _theme.teal
    readonly property color text: _theme.text
    readonly property color yellow: _theme.yellow

    NumberAnimation on globalOrbitAngle {
        duration: 90000
        from: 0
        loops: Animation.Infinite
        running: true
        to: Math.PI * 2
    }
    Behavior on introState {
        NumberAnimation {
            duration: 800
            easing.type: Easing.OutQuint
        }
    }

    Component.onCompleted: introState = 1.0

    // -------------------------------------------------------------------------
    // COLORS (Dynamic Matugen Palette)
    // -------------------------------------------------------------------------
    MatugenColors {
        id: _theme
    }
    ListModel {
        id: sinksModel
    }
    ListModel {
        id: sourcesModel
    }

    // -------------------------------------------------------------------------
    // NATIVE SYSTEM PROCESSES
    // -------------------------------------------------------------------------
    // Lazy, on-demand detection: runs once when the popup is created and again
    // only on Rescan / after switching a device. No persistent daemon — see
    // audio/audio_devices.py --watch for the optional live-cache mode if a
    // topbar indicator is ever wanted outside this popup.
    function applyDeviceData(data) {
        sinksModel.clear();
        sourcesModel.clear();

        let sinks = data.sinks || [];
        for (let i = 0; i < sinks.length; i++) {
            let s = sinks[i];
            sinksModel.append({
                id: s.id,
                name: s.name,
                isDefault: s.default,
                volume: s.volume,
                muted: s.muted
            });
        }

        let sources = data.sources || [];
        for (let i = 0; i < sources.length; i++) {
            let s = sources[i];
            sourcesModel.append({
                id: s.id,
                name: s.name,
                isDefault: s.default,
                volume: s.volume,
                muted: s.muted
            });
        }

        window.switching = false;
        window.rescanSpinning = false;
    }

    Process {
        id: audioPoller

        command: ["zsh", "-c", "~/.config/hypr/scripts/audio_devices.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    window.applyDeviceData(JSON.parse(this.text.trim()));
                } catch (e) {
                    window.switching = false;
                    window.rescanSpinning = false;
                }
            }
        }
    }
    Process {
        id: switchProc

        command: ["zsh", "-c", "echo"]
        running: false

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    window.applyDeviceData(JSON.parse(this.text.trim()));
                } catch (e) {
                    window.switching = false;
                }
            }
        }
    }

    function setDefault(kind, id) {
        if (window.switching)
            return;
        window.switching = true;
        switchProc.command = ["zsh", "-c", "~/.config/hypr/scripts/audio_devices.sh " + (kind === "sink" ? "--set-sink" : "--set-source") + " " + id];
        switchProc.running = true;
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        opacity: introState
        scale: 0.95 + (0.05 * introState)

        Rectangle {
            anchors.fill: parent
            border.color: window.surface0
            border.width: 1
            clip: true
            color: window.base
            radius: 30

            Rectangle {
                color: window.blue
                height: width
                opacity: 0.04
                radius: width / 2
                width: parent.width * 0.8
                x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * 150
                y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * 100
            }
            Rectangle {
                color: window.green
                height: width
                opacity: 0.04
                radius: width / 2
                width: parent.width * 0.9
                x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * -150
                y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * -100
            }

            // ==========================================
            // RESCAN (manual, lazy re-detection — no daemon)
            // ==========================================
            Item {
                id: rescanBtn

                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.top: parent.top
                anchors.topMargin: 16
                height: 30
                width: 30
                z: 20

                Rectangle {
                    anchors.fill: parent
                    border.color: rescanMa.containsMouse ? window.blue : window.surface1
                    border.width: 1
                    color: rescanMa.containsMouse ? window.surface0 : "transparent"
                    radius: 15

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 200
                        }
                    }

                    Text {
                        anchors.centerIn: parent
                        color: rescanMa.containsMouse ? window.blue : window.subtext0
                        font.family: "FiraCode Nerd Font Mono"
                        font.pixelSize: 15
                        rotation: window.rescanSpinning ? 360 : 0
                        text: "󰑐"

                        Behavior on rotation {
                            NumberAnimation {
                                duration: 500
                                easing.type: Easing.OutCubic
                            }
                        }
                    }
                }
                MouseArea {
                    id: rescanMa

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        window.rescanSpinning = !window.rescanSpinning;
                        audioPoller.running = true;
                    }
                }
            }

            // ==========================================
            // TWO COLUMNS: OUTPUT / INPUT
            // ==========================================
            RowLayout {
                anchors.fill: parent
                anchors.margins: 28
                anchors.topMargin: 56
                spacing: 24

                // ---- OUTPUT ----
                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    spacing: 12

                    RowLayout {
                        spacing: 8

                        Text {
                            color: window.blue
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 16
                            text: "󰓃"
                        }
                        Text {
                            color: window.text
                            font.bold: true
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 15
                            text: "Output"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Repeater {
                            model: sinksModel

                            delegate: Rectangle {
                                id: sinkPill

                                required property bool isDefault
                                required property int id
                                required property bool muted
                                required property string name
                                required property int volume

                                Layout.fillWidth: true
                                Layout.preferredHeight: 60
                                border.color: isDefault ? window.blue : (sinkMa.containsMouse ? window.surface2 : window.surface1)
                                border.width: isDefault ? 2 : 1
                                color: isDefault ? Qt.rgba(window.blue.r, window.blue.g, window.blue.b, 0.10) : (sinkMa.containsMouse ? window.surface0 : "transparent")
                                radius: 16

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 12

                                    Text {
                                        color: isDefault ? window.blue : window.subtext0
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 16
                                        text: muted ? "󰝟" : "󰓃"
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            color: window.text
                                            elide: Text.ElideRight
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 13
                                            text: name
                                        }
                                        Text {
                                            color: window.overlay0
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 10
                                            text: muted ? "muted" : (volume + "%")
                                        }
                                    }
                                    Text {
                                        color: window.blue
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 14
                                        opacity: isDefault ? 1.0 : 0.0
                                        text: "󰄬"

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 200
                                            }
                                        }
                                    }
                                }
                                MouseArea {
                                    id: sinkMa

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    onClicked: window.setDefault("sink", sinkPill.id)
                                }
                            }
                        }

                        Text {
                            Layout.topMargin: 8
                            color: window.overlay0
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 11
                            text: "No output devices found"
                            visible: sinksModel.count === 0
                        }
                    }
                    Item {
                        Layout.fillHeight: true
                    }
                }

                // divider
                Rectangle {
                    Layout.fillHeight: true
                    color: window.surface0
                    width: 1
                }

                // ---- INPUT ----
                ColumnLayout {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    spacing: 12

                    RowLayout {
                        spacing: 8

                        Text {
                            color: window.green
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 16
                            text: "󰍬"
                        }
                        Text {
                            color: window.text
                            font.bold: true
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 15
                            text: "Input"
                        }
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Repeater {
                            model: sourcesModel

                            delegate: Rectangle {
                                id: sourcePill

                                required property bool isDefault
                                required property int id
                                required property bool muted
                                required property string name
                                required property int volume

                                Layout.fillWidth: true
                                Layout.preferredHeight: 60
                                border.color: isDefault ? window.green : (sourceMa.containsMouse ? window.surface2 : window.surface1)
                                border.width: isDefault ? 2 : 1
                                color: isDefault ? Qt.rgba(window.green.r, window.green.g, window.green.b, 0.10) : (sourceMa.containsMouse ? window.surface0 : "transparent")
                                radius: 16

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 14
                                    spacing: 12

                                    Text {
                                        color: isDefault ? window.green : window.subtext0
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 16
                                        text: muted ? "󰍭" : "󰍬"
                                    }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            Layout.fillWidth: true
                                            color: window.text
                                            elide: Text.ElideRight
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 13
                                            text: name
                                        }
                                        Text {
                                            color: window.overlay0
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 10
                                            text: muted ? "muted" : (volume + "%")
                                        }
                                    }
                                    Text {
                                        color: window.green
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 14
                                        opacity: isDefault ? 1.0 : 0.0
                                        text: "󰄬"

                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 200
                                            }
                                        }
                                    }
                                }
                                MouseArea {
                                    id: sourceMa

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    onClicked: window.setDefault("source", sourcePill.id)
                                }
                            }
                        }

                        Text {
                            Layout.topMargin: 8
                            color: window.overlay0
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 11
                            text: "No input devices found"
                            visible: sourcesModel.count === 0
                        }
                    }
                    Item {
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
