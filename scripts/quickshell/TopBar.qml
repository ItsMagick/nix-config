import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.SystemTray

PanelWindow {
    id: barWindow

    property string batIcon: "󰁹"
    property string batPercent: "100%"
    property string btDevice: ""
    property string btIcon: "󰂲"
    property string btStatus: "Off"
    property string dateStr: fullDateStr.substring(0, typeInIndex)
    property string fullDateStr: ""
    property bool isBtOn: barWindow.btStatus.toLowerCase() === "enabled" || barWindow.btStatus.toLowerCase() === "on"

    // Derived properties for UI logic
    property bool isMediaActive: barWindow.musicData.status !== "Stopped" && barWindow.musicData.title !== ""
    property bool isMuted: false

    // --- State Variables ---

    // Triggers layout animations immediately to feel fast
    property bool isStartupReady: false
    property bool isWifiOn: barWindow.wifiStatus.toLowerCase() === "enabled" || barWindow.wifiStatus.toLowerCase() === "on"
    property string kbLayout: "ge"
    property var musicData: {
        "status": "Stopped",
        "title": "",
        "artUrl": "",
        "timeStr": ""
    }

    // Prevents repeaters (Workspaces/Tray) from flickering on data updates
    property bool startupCascadeFinished: false
    property string timeStr: ""
    property int typeInIndex: 0
    property string volIcon: "󰕾"
    property string volPercent: "0%"
    property string weatherHex: mocha.yellow
    property string weatherIcon: ""
    property string weatherTemp: "--°"
    property string wifiIcon: "󰤮"
    property string wifiSsid: ""
    property string wifiStatus: "Off"
    property var workspacesData: []

    color: "transparent"

    // exclusiveZone = height (48) + top margin (4)
    exclusiveZone: 52

    // THICKER BAR, MINIMAL MARGINS
    height: 40

    anchors {
        left: true
        right: true
        top: true
    }
    margins {
        bottom: 0
        left: 4
        right: 4
        top: 8
    }

    // Dynamic Matugen Palette
    MatugenColors {
        id: mocha
    }
    Timer {
        interval: 10
        running: true

        onTriggered: barWindow.isStartupReady = true
    }
    Timer {
        interval: 1000
        running: true

        onTriggered: barWindow.startupCascadeFinished = true
    }

    // ==========================================
    // DATA FETCHING (PROCESSES & TIMERS)
    // ==========================================

    Process {
        id: wsDaemon

        command: ["zsh", "-c", "~/.config/hypr/scripts/quickshell/workspaces.sh > /tmp/qs_workspaces.json"]
        running: true
    }
    Process {
        id: wsPoller

        command: ["zsh", "-c", "tail -n 1 /tmp/qs_workspaces.json 2>/dev/null"]

        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        barWindow.workspacesData = JSON.parse(txt);
                    } catch (e) {}
                }
            }
        }
    }
    Timer {
        interval: 100
        repeat: true
        running: true

        onTriggered: wsPoller.running = true
    }
    Process {
        id: musicPoller

        command: ["zsh", "-c", "cat /tmp/music_info.json 2>/dev/null || zsh ~/.config/hypr/scripts/quickshell/music/music_info.sh"]

        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        barWindow.musicData = JSON.parse(txt);
                    } catch (e) {}
                }
            }
        }
    }
    Timer {
        interval: 500
        repeat: true
        running: true

        onTriggered: musicPoller.running = true
    }

    // SLOW POLLER: Battery, WiFi, Bluetooth (Updates every 5 seconds)
    Process {
        id: slowSysPoller

        command: ["zsh", "-c", `
            echo "$(~/.config/hypr/scripts/quickshell/sys_info.sh --wifi-status)"
            echo "$(~/.config/hypr/scripts/quickshell/sys_info.sh --wifi-icon)"
            echo "$(~/.config/hypr/scripts/quickshell/sys_info.sh --wifi-ssid)"
            echo "$(~/.config/hypr/scripts/quickshell/sys_info.sh --bt-status)"
            echo "$(~/.config/hypr/scripts/quickshell/sys_info.sh --bt-icon)"
            echo "$(~/.config/hypr/scripts/quickshell/sys_info.sh --bt-connected)"
            echo "$(~/.config/hypr/scripts/quickshell/sys_info.sh --battery-percent)"
            echo "$(~/.config/hypr/scripts/quickshell/sys_info.sh --battery-icon)"
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 8) {
                    barWindow.wifiStatus = lines[0];
                    barWindow.wifiIcon = lines[1];
                    barWindow.wifiSsid = lines[2];
                    barWindow.btStatus = lines[3];
                    barWindow.btIcon = lines[4];
                    barWindow.btDevice = lines[5];
                    barWindow.batPercent = lines[6];
                    barWindow.batIcon = lines[7];
                }
            }
        }
    }
    Timer {
        interval: 1500
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: slowSysPoller.running = true
    }

    // FAST POLLER: Volume and Layout (Updates every 150ms for instant feedback)
    Process {
        id: fastSysPoller

        command: ["zsh", "-c", `
            echo "$(~/.config/hypr/scripts/quickshell/sys_info.sh --volume)"
            echo "$(~/.config/hypr/scripts/quickshell/sys_info.sh --volume-icon)"
            echo "$(~/.config/hypr/scripts/quickshell/sys_info.sh --kb-layout)"
            echo "$(~/.config/hypr/scripts/quickshell/sys_info.sh --is-muted)"
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 4) {
                    barWindow.volPercent = lines[0];
                    barWindow.volIcon = lines[1];
                    barWindow.kbLayout = lines[2];
                    barWindow.isMuted = (lines[3].toLowerCase() === "true");
                }
            }
        }
    }
    Timer {
        interval: 150
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: fastSysPoller.running = true
    }
    Process {
        id: weatherPoller

        command: ["zsh", "-c", `
            echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-icon)"
            echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-temp)"
            echo "$(~/.config/hypr/scripts/quickshell/calendar/weather.sh --current-hex)"
        `]

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 3) {
                    barWindow.weatherIcon = lines[0];
                    barWindow.weatherTemp = lines[1];
                    barWindow.weatherHex = lines[2] || mocha.yellow;
                }
            }
        }
    }
    Timer {
        interval: 150000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: weatherPoller.running = true
    }

    // Native Qt Time Formatting
    Timer {
        interval: 1000
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            let d = new Date();
            barWindow.timeStr = Qt.formatDateTime(d, "hh:mm:ss");
            barWindow.fullDateStr = Qt.formatDateTime(d, "ddd, MMM dd");
            if (barWindow.typeInIndex >= barWindow.fullDateStr.length) {
                barWindow.typeInIndex = barWindow.fullDateStr.length;
            }
        }
    }

    // Typewriter effect timer for the date
    Timer {
        id: typewriterTimer

        interval: 40
        repeat: true
        running: barWindow.isStartupReady && barWindow.typeInIndex < barWindow.fullDateStr.length

        onTriggered: barWindow.typeInIndex += 1
    }

    // ==========================================
    // UI LAYOUT
    // ==========================================
    Item {
        anchors.fill: parent

        // ---------------- LEFT ----------------
        RowLayout {
            id: leftLayout

            property int moduleHeight: 40

            // Decoupled Main Transition
            property bool showLayout: false

            anchors.left: parent.left
            anchors.verticalCenter: parent.verticalCenter
            opacity: showLayout ? 1 : 0
            spacing: 4

            Behavior on opacity {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.OutCubic
                }
            }
            transform: Translate {
                x: leftLayout.showLayout ? 0 : -20

                Behavior on x {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Timer {
                interval: 10
                running: barWindow.isStartupReady

                onTriggered: leftLayout.showLayout = true
            }

            // Search
            Rectangle {
                property bool isHovered: searchMouse.containsMouse

                Layout.preferredHeight: parent.moduleHeight
                Layout.preferredWidth: 40
                border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, isHovered ? 0.15 : 0.05)
                border.width: 1
                color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.95) : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                radius: 24
                scale: isHovered ? 1.05 : 1.0

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutExpo
                    }
                }

                Text {
                    anchors.centerIn: parent
                    color: parent.isHovered ? mocha.blue : mocha.text
                    font.family: "FiraCode Nerd Font Mono"
                    font.pixelSize: 24
                    text: ""

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }
                MouseArea {
                    id: searchMouse

                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: Quickshell.execDetached(["zsh", "-c", "~/.config/hypr/scripts/rofi_show.sh drun"])
                }
            }

            // Notifications
            Rectangle {
                property bool isHovered: notifMouse.containsMouse

                Layout.preferredHeight: parent.moduleHeight
                Layout.preferredWidth: 40
                border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, isHovered ? 0.15 : 0.05)
                border.width: 1
                color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.95) : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                radius: 24
                scale: isHovered ? 1.05 : 1.0

                Behavior on color {
                    ColorAnimation {
                        duration: 200
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 250
                        easing.type: Easing.OutExpo
                    }
                }

                Text {
                    anchors.centerIn: parent
                    color: parent.isHovered ? mocha.yellow : mocha.text
                    font.family: "FiraCode Nerd Font Mono"
                    font.pixelSize: 18
                    text: ""

                    Behavior on color {
                        ColorAnimation {
                            duration: 200
                        }
                    }
                }
                MouseArea {
                    id: notifMouse

                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    anchors.fill: parent
                    hoverEnabled: true

                    onClicked: mouse => {
                        if (mouse.button === Qt.LeftButton)
                            Quickshell.execDetached(["swaync-client", "-t", "-sw"]);
                        if (mouse.button === Qt.RightButton)
                            Quickshell.execDetached(["swaync-client", "-d"]);
                    }
                }
            }

            // Workspaces
            Rectangle {
                property real targetWidth: barWindow.workspacesData.length > 0 ? wsLayout.implicitWidth + 20 : 0

                Layout.preferredHeight: parent.moduleHeight
                Layout.preferredWidth: targetWidth
                border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.05)
                border.width: 1
                clip: true
                color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                opacity: barWindow.workspacesData.length > 0 ? 1 : 0
                radius: 24
                visible: targetWidth > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                    }
                }
                Behavior on targetWidth {
                    NumberAnimation {
                        duration: 300
                        easing.type: Easing.OutExpo
                    }
                }

                RowLayout {
                    id: wsLayout

                    anchors.centerIn: parent
                    spacing: 6

                    Repeater {
                        model: barWindow.workspacesData

                        delegate: Rectangle {
                            id: wsPill

                            // Safe Instantiation Cascade logic
                            property bool initAnimTrigger: barWindow.startupCascadeFinished
                            property bool isHovered: wsPillMouse.containsMouse
                            property real targetWidth: modelData.state === "active" ? 36 : 32

                            Layout.preferredHeight: 24
                            Layout.preferredWidth: targetWidth

                            // IMPROVED WORKSPACE STATES - Clearer hierarchy for occupied vs empty
                            color: modelData.state === "active" ? mocha.mauve : (isHovered ? Qt.rgba(mocha.surface2.r, mocha.surface2.g, mocha.surface2.b, 0.9) : (modelData.state === "occupied" ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.9) : "transparent"))
                            opacity: initAnimTrigger ? 1 : 0
                            radius: 17

                            // ADDED TACTILE SCALE ANIMATION ON HOVER
                            scale: isHovered && modelData.state !== "active" ? 1.08 : 1.0

                            Behavior on color {
                                ColorAnimation {
                                    duration: 250
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 500
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutBack
                                }
                            }
                            Behavior on targetWidth {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutBack
                                }
                            }
                            transform: Translate {
                                y: wsPill.initAnimTrigger ? 0 : 15

                                Behavior on y {
                                    NumberAnimation {
                                        duration: 500
                                        easing.type: Easing.OutBack
                                    }
                                }
                            }

                            Component.onCompleted: {
                                if (!barWindow.startupCascadeFinished) {
                                    animTimer.interval = index * 60;
                                    animTimer.start();
                                }
                            }

                            Timer {
                                id: animTimer

                                repeat: false
                                running: false

                                onTriggered: wsPill.initAnimTrigger = true
                            }
                            Text {
                                anchors.centerIn: parent

                                // IMPROVED TEXT CONTRAST - Pop occupied text to true text color, fade empty out
                                color: modelData.state === "active" ? mocha.crust : (isHovered ? mocha.text : (modelData.state === "occupied" ? mocha.text : mocha.overlay0))
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 14
                                font.weight: modelData.state === "active" ? Font.Black : (modelData.state === "occupied" ? Font.Bold : Font.Medium)
                                text: modelData.id

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 250
                                    }
                                }
                            }
                            MouseArea {
                                id: wsPillMouse

                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: Quickshell.execDetached(["zsh", "-c", "~/.config/hypr/scripts/qs_manager.sh " + modelData.id])
                            }
                        }
                    }
                }
            }

            // Media Player
            Rectangle {
                id: mediaBox

                property real targetWidth: barWindow.isMediaActive ? mediaLayoutContainer.width + 24 : 0

                Layout.preferredHeight: parent.moduleHeight
                Layout.preferredWidth: targetWidth
                border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.05)
                border.width: 1
                clip: true
                color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                radius: 24
                visible: Layout.preferredWidth > 0

                Behavior on targetWidth {
                    NumberAnimation {
                        duration: 1400
                        easing.type: Easing.OutExpo
                    }
                }

                Item {
                    id: mediaLayoutContainer

                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    height: parent.height
                    width: innerMediaLayout.implicitWidth

                    RowLayout {
                        id: innerMediaLayout

                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 16

                        MouseArea {
                            id: mediaInfoMouse

                            Layout.fillHeight: true
                            Layout.preferredWidth: infoLayout.implicitWidth
                            hoverEnabled: true

                            onClicked: Quickshell.execDetached(["zsh", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle music"])

                            RowLayout {
                                id: infoLayout

                                anchors.verticalCenter: parent.verticalCenter
                                scale: mediaInfoMouse.containsMouse ? 1.02 : 1.0
                                spacing: 10

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutExpo
                                    }
                                }

                                Rectangle {
                                    Layout.preferredHeight: 32
                                    Layout.preferredWidth: 32
                                    border.color: mocha.mauve
                                    border.width: barWindow.musicData.status === "Playing" ? 1 : 0
                                    clip: true
                                    color: mocha.surface1
                                    radius: 8

                                    Image {
                                        anchors.fill: parent
                                        fillMode: Image.PreserveAspectCrop
                                        source: barWindow.musicData.artUrl || ""
                                    }

                                    // NEW: Dimmed slightly by tinting with the primary mauve accent, matching the weather icon
                                    Rectangle {
                                        anchors.fill: parent
                                        color: Qt.rgba(mocha.mauve.r, mocha.mauve.g, mocha.mauve.b, 0.2)
                                    }
                                }
                                ColumnLayout {
                                    Layout.preferredWidth: 180
                                    spacing: -2

                                    Text {
                                        Layout.fillWidth: true
                                        color: mocha.text // Fixed contrast
                                        elide: Text.ElideRight
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 13
                                        font.weight: Font.Black
                                        text: barWindow.musicData.title
                                    }
                                    Text {
                                        Layout.fillWidth: true
                                        color: mocha.subtext0
                                        elide: Text.ElideRight
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 10
                                        font.weight: Font.Black
                                        text: barWindow.musicData.timeStr
                                    }
                                }
                            }
                        }
                        RowLayout {
                            spacing: 8

                            Item {
                                Layout.preferredHeight: 24
                                Layout.preferredWidth: 24

                                Text {
                                    anchors.centerIn: parent
                                    color: prevMouse.containsMouse ? mocha.text : mocha.overlay2
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 26
                                    scale: prevMouse.containsMouse ? 1.1 : 1.0
                                    text: "󰒮"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                }
                                MouseArea {
                                    id: prevMouse

                                    anchors.fill: parent
                                    hoverEnabled: true

                                    onClicked: Quickshell.execDetached(["playerctl", "previous"])
                                }
                            }
                            Item {
                                Layout.preferredHeight: 28
                                Layout.preferredWidth: 28

                                Text {
                                    anchors.centerIn: parent
                                    color: playMouse.containsMouse ? mocha.green : mocha.text
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 30
                                    scale: playMouse.containsMouse ? 1.15 : 1.0
                                    text: barWindow.musicData.status === "Playing" ? "󰏤" : "󰐊"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                }
                                MouseArea {
                                    id: playMouse

                                    anchors.fill: parent
                                    hoverEnabled: true

                                    onClicked: Quickshell.execDetached(["playerctl", "play-pause"])
                                }
                            }
                            Item {
                                Layout.preferredHeight: 24
                                Layout.preferredWidth: 24

                                Text {
                                    anchors.centerIn: parent
                                    color: nextMouse.containsMouse ? mocha.text : mocha.overlay2
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 26
                                    scale: nextMouse.containsMouse ? 1.1 : 1.0
                                    text: "󰒭"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                }
                                MouseArea {
                                    id: nextMouse

                                    anchors.fill: parent
                                    hoverEnabled: true

                                    onClicked: Quickshell.execDetached(["playerctl", "next"])
                                }
                            }
                        }
                    }
                }
            }
        }

        // ---------------- CENTER ----------------
        Rectangle {
            id: centerBox

            property bool isHovered: centerMouse.containsMouse

            // Decoupled Center Startup Transition
            property bool showLayout: false

            anchors.centerIn: parent
            border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, isHovered ? 0.15 : 0.05)
            border.width: 1
            color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.95) : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
            height: 40
            opacity: showLayout ? 1 : 0
            radius: 24

            // Hover Scaling
            scale: isHovered ? 1.03 : 1.0
            width: centerLayout.implicitWidth + 36

            Behavior on color {
                ColorAnimation {
                    duration: 250
                }
            }
            Behavior on opacity {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.OutCubic
                }
            }
            Behavior on scale {
                NumberAnimation {
                    duration: 300
                    easing.type: Easing.OutExpo
                }
            }
            transform: Translate {
                y: centerBox.showLayout ? 0 : -20

                Behavior on y {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutBack
                    }
                }
            }
            Behavior on width {
                NumberAnimation {
                    duration: 400
                    easing.type: Easing.OutExpo
                }
            }

            Timer {
                interval: 10
                running: barWindow.isStartupReady

                onTriggered: centerBox.showLayout = true
            }
            MouseArea {
                id: centerMouse

                anchors.fill: parent
                hoverEnabled: true

                onClicked: Quickshell.execDetached(["bash", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle calendar"])
            }
            RowLayout {
                id: centerLayout

                anchors.centerIn: parent
                spacing: 24

                ColumnLayout {
                    spacing: -2

                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        color: mocha.blue
                        font.family: "FiraCode Nerd Font Mono"
                        font.pixelSize: 12
                        font.weight: Font.Black
                        text: barWindow.timeStr
                    }
                    Text {
                        color: mocha.subtext0
                        font.family: "FiraCode Nerd Font Mono"
                        font.pixelSize: 10
                        font.weight: Font.Bold
                        text: barWindow.dateStr
                    }
                }
            }
        }

        // ---------------- RIGHT ----------------
        RowLayout {
            id: rightLayout

            // Decoupled Right Startup Animation
            property bool showLayout: false

            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            opacity: showLayout ? 1 : 0
            spacing: 4

            Behavior on opacity {
                NumberAnimation {
                    duration: 600
                    easing.type: Easing.OutCubic
                }
            }
            transform: Translate {
                x: rightLayout.showLayout ? 0 : 20

                Behavior on x {
                    NumberAnimation {
                        duration: 600
                        easing.type: Easing.OutCubic
                    }
                }
            }

            Timer {
                interval: 10
                running: barWindow.isStartupReady

                onTriggered: rightLayout.showLayout = true
            }

            // Dedicated System Tray Pill
            Rectangle {
                property real targetWidth: trayRepeater.count > 0 ? trayLayout.implicitWidth + 24 : 0

                Layout.preferredWidth: targetWidth
                border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)
                border.width: 1
                color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                height: 40
                opacity: targetWidth > 0 ? 1 : 0
                radius: 24
                visible: targetWidth > 0

                Behavior on opacity {
                    NumberAnimation {
                        duration: 300
                    }
                }
                Behavior on targetWidth {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }
                }

                RowLayout {
                    id: trayLayout

                    anchors.centerIn: parent
                    spacing: 10

                    Repeater {
                        id: trayRepeater

                        model: SystemTray.items

                        delegate: Image {
                            id: trayIcon

                            property bool initAnimTrigger: barWindow.startupCascadeFinished
                            property bool isHovered: trayMouse.containsMouse

                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredHeight: 18
                            Layout.preferredWidth: 18
                            fillMode: Image.PreserveAspectFit
                            opacity: initAnimTrigger ? (isHovered ? 1.0 : 0.8) : 0.0
                            scale: initAnimTrigger ? (isHovered ? 1.15 : 1.0) : 0.0
                            source: modelData.icon || ""
                            sourceSize: Qt.size(18, 18)

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutBack
                                }
                            }

                            Component.onCompleted: {
                                if (!barWindow.startupCascadeFinished) {
                                    trayAnimTimer.interval = index * 50;
                                    trayAnimTimer.start();
                                }
                            }

                            Timer {
                                id: trayAnimTimer

                                repeat: false
                                running: false

                                onTriggered: trayIcon.initAnimTrigger = true
                            }
                            QsMenuAnchor {
                                id: menuAnchor

                                anchor.item: trayIcon
                                anchor.window: barWindow
                                menu: modelData.menu
                            }
                            MouseArea {
                                id: trayMouse

                                acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton
                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: mouse => {
                                    if (mouse.button === Qt.LeftButton) {
                                        modelData.activate();
                                    } else if (mouse.button === Qt.MiddleButton) {
                                        modelData.secondaryActivate();
                                    } else if (mouse.button === Qt.RightButton) {
                                        if (modelData.menu) {
                                            menuAnchor.open();
                                        } else if (typeof modelData.contextMenu === "function") {
                                            modelData.contextMenu(mouse.x, mouse.y);
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // System Elements Pill
            Rectangle {
                property real targetWidth: sysLayout.implicitWidth + 20

                Layout.preferredWidth: targetWidth
                border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.08)
                border.width: 1
                color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
                height: 40
                radius: 24

                Behavior on targetWidth {
                    NumberAnimation {
                        duration: 400
                        easing.type: Easing.OutExpo
                    }
                }

                RowLayout {
                    id: sysLayout

                    property int pillHeight: 24

                    anchors.centerIn: parent
                    spacing: 8

                    // KB
                    Rectangle {
                        property bool isHovered: kbMouse.containsMouse
                        property real targetWidth: kbLayoutRow.implicitWidth + 24

                        Layout.preferredHeight: sysLayout.pillHeight
                        Layout.preferredWidth: targetWidth
                        color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                        radius: 17
                        scale: isHovered ? 1.05 : 1.0

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutExpo
                            }
                        }
                        Behavior on targetWidth {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutExpo
                            }
                        }

                        RowLayout {
                            id: kbLayoutRow

                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                color: parent.parent.isHovered ? mocha.text : mocha.overlay2
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 16
                                text: "󰌌"
                            }
                            Text {
                                color: mocha.text
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 13
                                font.weight: Font.Black
                                text: barWindow.kbLayout
                            }
                        }
                        MouseArea {
                            id: kbMouse

                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }

                    // WiFi
                    Rectangle {
                        id: wifiPill

                        property bool isHovered: wifiMouse.containsMouse
                        property real targetWidth: wifiLayoutRow.implicitWidth + 24

                        Layout.preferredHeight: sysLayout.pillHeight
                        Layout.preferredWidth: targetWidth
                        color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                        radius: 17
                        scale: isHovered ? 1.05 : 1.0

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutExpo
                            }
                        }
                        Behavior on targetWidth {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutExpo
                            }
                        }

                        // Vibrant, guaranteed gradient contrast
                        Rectangle {
                            anchors.fill: parent
                            opacity: barWindow.isWifiOn ? 1.0 : 0.0
                            radius: 17

                            gradient: Gradient {
                                orientation: Gradient.Horizontal

                                GradientStop {
                                    color: mocha.blue
                                    position: 0.0
                                }
                                GradientStop {
                                    color: Qt.lighter(mocha.blue, 1.3)
                                    position: 1.0
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 300
                                }
                            }
                        }
                        RowLayout {
                            id: wifiLayoutRow

                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                color: barWindow.isWifiOn ? mocha.base : mocha.subtext0
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 16
                                text: barWindow.wifiIcon
                            }
                            Text {
                                Layout.maximumWidth: 100
                                color: barWindow.isWifiOn ? mocha.base : mocha.text
                                elide: Text.ElideRight
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 13
                                font.weight: Font.Black
                                text: barWindow.isWifiOn ? (barWindow.wifiSsid !== "" ? barWindow.wifiSsid : "On") : "Off"
                            }
                        }
                        MouseArea {
                            id: wifiMouse

                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: Quickshell.execDetached(["zsh", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle network wifi"])
                        }
                    }

                    // Bluetooth
                    Rectangle {
                        id: btPill

                        property bool isHovered: btMouse.containsMouse
                        property real targetWidth: btLayoutRow.implicitWidth + 24

                        Layout.preferredHeight: sysLayout.pillHeight
                        Layout.preferredWidth: targetWidth
                        clip: true
                        color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                        radius: 17
                        scale: isHovered ? 1.05 : 1.0

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutExpo
                            }
                        }
                        Behavior on targetWidth {
                            NumberAnimation {
                                duration: 350
                                easing.type: Easing.OutExpo
                            }
                        }

                        // Vibrant, guaranteed gradient contrast
                        Rectangle {
                            anchors.fill: parent
                            opacity: barWindow.isBtOn ? 1.0 : 0.0
                            radius: 17

                            gradient: Gradient {
                                orientation: Gradient.Horizontal

                                GradientStop {
                                    color: mocha.mauve
                                    position: 0.0
                                }
                                GradientStop {
                                    color: Qt.lighter(mocha.mauve, 1.3)
                                    position: 1.0
                                }
                            }
                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 300
                                }
                            }
                        }
                        RowLayout {
                            id: btLayoutRow

                            anchors.left: parent.left
                            anchors.leftMargin: 12
                            anchors.verticalCenter: parent.verticalCenter
                            spacing: barWindow.btDevice !== "" ? 8 : 0

                            Text {
                                color: barWindow.isBtOn ? mocha.base : mocha.subtext0
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 16
                                text: barWindow.btIcon
                            }
                            Text {
                                Layout.maximumWidth: 100
                                color: barWindow.isBtOn ? mocha.base : mocha.text
                                elide: Text.ElideRight
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 13
                                font.weight: Font.Black
                                text: barWindow.btDevice
                                visible: barWindow.btDevice !== ""
                            }
                        }
                        MouseArea {
                            id: btMouse

                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: Quickshell.execDetached(["zsh", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle network bt"])
                        }
                    }

                    // Volume
                    Rectangle {
                        property bool isHovered: volMouse.containsMouse
                        property real targetWidth: volLayoutRow.implicitWidth + 24

                        Layout.preferredHeight: sysLayout.pillHeight
                        Layout.preferredWidth: targetWidth
                        color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : (barWindow.isMuted ? Qt.rgba(0, 0, 0, 0.2) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4))
                        radius: 17
                        scale: isHovered ? 1.05 : 1.0

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutExpo
                            }
                        }
                        Behavior on targetWidth {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutExpo
                            }
                        }

                        RowLayout {
                            id: volLayoutRow

                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                color: barWindow.isMuted ? mocha.overlay0 : mocha.peach
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 16
                                text: barWindow.volIcon
                            }
                            Text {
                                color: barWindow.isMuted ? mocha.overlay0 : mocha.text
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 13
                                font.strikeout: barWindow.isMuted
                                font.weight: Font.Black
                                text: barWindow.volPercent
                            }
                        }
                        MouseArea {
                            id: volMouse

                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: Quickshell.execDetached(["pavucontrol"])
                        }
                    }

                    // Battery
                    Rectangle {
                        property bool isHovered: batMouse.containsMouse
                        property real targetWidth: batLayoutRow.implicitWidth + 24

                        Layout.preferredHeight: sysLayout.pillHeight
                        Layout.preferredWidth: targetWidth
                        color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.6) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                        radius: 17
                        scale: isHovered ? 1.05 : 1.0

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutExpo
                            }
                        }
                        Behavior on targetWidth {
                            NumberAnimation {
                                duration: 300
                                easing.type: Easing.OutExpo
                            }
                        }

                        RowLayout {
                            id: batLayoutRow

                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                color: parseInt(barWindow.batPercent) < 20 && barWindow.batIcon !== "󰂄" ? mocha.red : mocha.green
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 16
                                text: barWindow.batIcon
                            }
                            Text {
                                color: mocha.text
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 13
                                font.weight: Font.Black
                                text: barWindow.batPercent
                            }
                        }
                        MouseArea {
                            id: batMouse

                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: Quickshell.execDetached(["zsh", "-c", "~/.config/hypr/scripts/qs_manager.sh toggle battery"])
                        }
                    }
                }
            }
        }
    }
}
