import QtQuick
import QtQuick.Layouts
import QtQuick.Window
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window

    readonly property color ambientPrimary: window.batColorStart

    // Keep the background blobs distinct and interesting by using alternative Matugen palette colors
    readonly property color ambientSecondary: {
        if (powerProfile === "performance")
            return window.peach;
        if (powerProfile === "power-saver")
            return window.teal;
        return window.sapphire;
    }
    property real animCapacity: 0
    readonly property color base: _theme.base

    // -------------------------------------------------------------------------
    // STATE & POLLING
    // -------------------------------------------------------------------------
    property int batCapacity: 0

    // Mathematically derive a cohesive, realistic end color instead of arbitrarily mapping to Teal/Sapphire/Maroon
    readonly property color batColorEnd: Qt.lighter(batColorStart, 1.15)

    // Use a unified hue for the start colors
    readonly property color batColorStart: {
        if (isCharging)
            return window.green;
        if (batCapacity >= 70)
            return window.blue;
        if (batCapacity >= 30)
            return window.yellow;
        return window.red;
    }
    property string batStatus: "Unknown"
    readonly property color blue: _theme.blue
    readonly property color crust: _theme.crust
    property real globalOrbitAngle: 0
    readonly property color green: _theme.green
    property real introState: 0.0
    readonly property bool isCharging: batStatus === "Charging"
    property bool isDraggingBri: false

    // Anti-Jitter Sync States
    property bool isDraggingVol: false
    readonly property color mantle: _theme.mantle
    readonly property color maroon: _theme.maroon
    readonly property color mauve: _theme.mauve
    readonly property color overlay0: _theme.overlay0
    readonly property color overlay1: _theme.overlay1
    readonly property color peach: _theme.peach
    readonly property color pink: _theme.pink
    property string powerProfile: "balanced"
    readonly property color profileEnd: Qt.lighter(profileStart, 1.15)
    readonly property color profileStart: {
        if (powerProfile === "performance")
            return window.red;
        if (powerProfile === "power-saver")
            return window.green;
        return window.blue;
    }
    readonly property color red: _theme.red
    readonly property color sapphire: _theme.sapphire
    readonly property color subtext0: _theme.subtext0
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    property real sysBrightness: 0
    property bool sysMuted: false
    property real sysVolume: 0
    readonly property color teal: _theme.teal
    readonly property color text: _theme.text
    property int upHours: 0
    property int upMins: 0
    readonly property color yellow: _theme.yellow

    Behavior on animCapacity {
        NumberAnimation {
            duration: 1200
            easing.type: Easing.OutQuint
        }
    }
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
    onAnimCapacityChanged: batCanvas.requestPaint()
    onBatColorStartChanged: batCanvas.requestPaint()

    // -------------------------------------------------------------------------
    // COLORS (Dynamic Matugen Palette)
    // -------------------------------------------------------------------------
    MatugenColors {
        id: _theme
    }
    Timer {
        id: volSyncDelay

        interval: 800
        triggeredOnStart: true

        onTriggered: window.isDraggingVol = false
    }
    Timer {
        id: briSyncDelay

        interval: 800
        triggeredOnStart: true

        onTriggered: window.isDraggingBri = false
    }
    Process {
        id: sysPoller

        command: ["zsh", "-c", "cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo '0'; " + "cat /sys/class/power_supply/BAT0/status 2>/dev/null || echo 'Unknown'; " + "powerprofilesctl get 2>/dev/null || echo 'balanced'; " + "awk '{print int($1/3600)\"h \"int(($1%3600)/60)\"m\"}' /proc/uptime 2>/dev/null || echo '0h 0m'; " + "wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null | awk '{print int($2*100), ($3==\"[MUTED]\"?\"off\":\"on\")}' || echo '0 on'; " + "brightnessctl -m 2>/dev/null | awk -F, '{print substr($4, 1, length($4)-1)}' || echo '0'"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let lines = this.text.trim().split("\n");
                if (lines.length >= 6) {
                    if (window.batCapacity !== parseInt(lines[0])) {
                        window.batCapacity = parseInt(lines[0]);
                        window.animCapacity = window.batCapacity;
                    }
                    window.batStatus = lines[1];
                    window.powerProfile = lines[2];

                    let upParts = lines[3].split("h ");
                    if (upParts.length === 2) {
                        window.upHours = parseInt(upParts[0]) || 0;
                        window.upMins = parseInt(upParts[1].replace("m", "")) || 0;
                    }

                    if (!window.isDraggingVol) {
                        let volParts = (lines[4] || "0 on").trim().split(" ");
                        window.sysVolume = parseInt(volParts[0]) || 0;
                        window.sysMuted = (volParts[1] === "off");
                    }

                    if (!window.isDraggingBri) {
                        window.sysBrightness = parseInt(lines[5]) || 0;
                    }
                }
            }
        }
    }
    Timer {
        interval: 1500
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: sysPoller.running = true
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        opacity: introState
        scale: 0.95 + (0.05 * introState)

        // Outer Border
        Rectangle {
            anchors.fill: parent
            border.color: window.surface0
            border.width: 1
            clip: true
            color: window.base
            radius: 30

            // Rotating Background Blobs
            Rectangle {
                color: window.ambientPrimary
                height: width
                opacity: 0.08
                radius: width / 2
                width: parent.width * 0.8
                x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * 150
                y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * 100

                Behavior on color {
                    ColorAnimation {
                        duration: 1000
                    }
                }
            }
            Rectangle {
                color: window.ambientSecondary
                height: width
                opacity: 0.06
                radius: width / 2
                width: parent.width * 0.9
                x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * -150
                y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * -100

                Behavior on color {
                    ColorAnimation {
                        duration: 1000
                    }
                }
            }

            // Radar Rings
            Item {
                id: radarItem

                anchors.fill: parent

                Repeater {
                    model: 3

                    Rectangle {
                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: -70
                        border.color: window.ambientSecondary
                        border.width: 1
                        color: "transparent"
                        height: width
                        opacity: 0.06 - (index * 0.02)
                        radius: width / 2
                        width: 320 + (index * 170)

                        Behavior on border.color {
                            ColorAnimation {
                                duration: 1000
                            }
                        }
                    }
                }
            }

            // ==========================================
            // TOP: UPTIME COMPONENT
            // ==========================================
            Row {
                anchors.left: parent.left
                anchors.margins: 25
                anchors.top: parent.top
                opacity: introState
                spacing: 6

                transform: Translate {
                    y: -15 * (1.0 - introState)
                }

                // Hours Box
                Rectangle {
                    border.color: "#1affffff"
                    border.width: 1
                    color: "#0dffffff"
                    height: 48
                    radius: 12
                    width: 44

                    Rectangle {
                        anchors.fill: parent
                        color: window.ambientPrimary
                        opacity: 0.05
                        radius: 12

                        Behavior on color {
                            ColorAnimation {
                                duration: 1000
                            }
                        }
                    }
                    Column {
                        anchors.centerIn: parent

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: window.ambientPrimary
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 18
                            font.weight: Font.Black
                            text: window.upHours.toString().padStart(2, '0')

                            Behavior on color {
                                ColorAnimation {
                                    duration: 1000
                                }
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: window.subtext0
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 8
                            font.weight: Font.Bold
                            text: "HR"
                        }
                    }
                }

                // Pulsing Colon
                Text {
                    property real uptimePulse: 1.0

                    anchors.verticalCenter: parent.verticalCenter
                    color: window.ambientPrimary
                    font.family: "FiraCode Nerd Font Mono"
                    font.pixelSize: 22
                    font.weight: Font.Black
                    opacity: uptimePulse
                    text: ":"

                    Behavior on color {
                        ColorAnimation {
                            duration: 1000
                        }
                    }
                    SequentialAnimation on uptimePulse {
                        loops: Animation.Infinite
                        running: true

                        NumberAnimation {
                            duration: 800
                            easing.type: Easing.InOutSine
                            to: 0.2
                        }
                        NumberAnimation {
                            duration: 800
                            easing.type: Easing.InOutSine
                            to: 1.0
                        }
                    }
                }

                // Mins Box
                Rectangle {
                    border.color: "#1affffff"
                    border.width: 1
                    color: "#0dffffff"
                    height: 48
                    radius: 12
                    width: 44

                    Rectangle {
                        anchors.fill: parent
                        color: window.ambientSecondary
                        opacity: 0.05
                        radius: 12

                        Behavior on color {
                            ColorAnimation {
                                duration: 1000
                            }
                        }
                    }
                    Column {
                        anchors.centerIn: parent

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: window.ambientSecondary
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 18
                            font.weight: Font.Black
                            text: window.upMins.toString().padStart(2, '0')

                            Behavior on color {
                                ColorAnimation {
                                    duration: 1000
                                }
                            }
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: window.subtext0
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 8
                            font.weight: Font.Bold
                            text: "MIN"
                        }
                    }
                }
            }

            // Simple top-right logout icon
            Rectangle {
                anchors.margins: 25
                anchors.right: parent.right
                anchors.top: parent.top
                border.color: logoutMa.containsMouse ? "#33ffffff" : "transparent"
                color: logoutMa.containsMouse ? "#1affffff" : "transparent"
                height: 44
                radius: 22
                width: 44

                Behavior on color {
                    ColorAnimation {
                        duration: 150
                    }
                }

                Text {
                    anchors.centerIn: parent
                    color: logoutMa.containsMouse ? window.red : window.overlay0
                    font.family: "FiraCode Nerd Font Mono"
                    font.pixelSize: 18
                    text: "󰍃"

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }
                }
                MouseArea {
                    id: logoutMa

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onClicked: {
                        Quickshell.execDetached(["sh", "-c", "loginctl terminate-user $USER"]);
                        Quickshell.execDetached(["sh", "-c", "echo 'close' > /tmp/qs_widget_state"]);
                    }
                }
            }

            // ==========================================
            // CENTRAL CORE & BATTERY RING
            // ==========================================
            Item {
                anchors.fill: parent
                z: 1

                // --- CLEAN OUTSIDE GLOW HALO ---
                Rectangle {
                    anchors.centerIn: centralCore
                    color: centralCore.isDangerState ? window.red : window.ambientPrimary
                    height: width
                    opacity: centralCore.isDangerState ? 0.25 : 0.15
                    radius: width / 2
                    width: centralCore.width + 45
                    z: 0

                    Behavior on color {
                        ColorAnimation {
                            duration: 400
                        }
                    }
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: true

                        NumberAnimation {
                            duration: heroMa.containsMouse ? 800 : 2000
                            easing.type: Easing.InOutSine
                            to: heroMa.containsMouse ? 1.15 : 1.08
                        }
                        NumberAnimation {
                            duration: heroMa.containsMouse ? 800 : 2000
                            easing.type: Easing.InOutSine
                            to: 1.0
                        }
                    }
                }
                // -------------------------------

                Rectangle {
                    id: centralCore

                    property bool isDangerState: !window.isCharging && window.batCapacity < 15

                    anchors.centerIn: parent
                    anchors.verticalCenterOffset: -70
                    height: width
                    radius: width / 2
                    width: 260
                    z: 1

                    gradient: Gradient {
                        orientation: Gradient.Vertical

                        GradientStop {
                            color: window.surface0
                            position: 0.0
                        }
                        GradientStop {
                            color: window.base
                            position: 1.0
                        }
                    }
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        running: true

                        NumberAnimation {
                            duration: heroMa.containsMouse ? 1200 : (centralCore.isDangerState ? 600 : 2500)
                            easing.type: Easing.InOutSine
                            to: heroMa.containsMouse ? 1.05 : (centralCore.isDangerState ? 1.04 : 1.01)
                        }
                        NumberAnimation {
                            duration: heroMa.containsMouse ? 1200 : (centralCore.isDangerState ? 600 : 2500)
                            easing.type: Easing.InOutSine
                            to: 1.0
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: window.maroon
                        opacity: centralCore.isDangerState ? 0.15 : 0.0
                        radius: width / 2

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 1000
                            }
                        }
                        SequentialAnimation on opacity {
                            loops: Animation.Infinite
                            running: centralCore.isDangerState

                            NumberAnimation {
                                duration: 600
                                easing.type: Easing.InOutSine
                                to: 0.25
                            }
                            NumberAnimation {
                                duration: 600
                                easing.type: Easing.InOutSine
                                to: 0.15
                            }
                        }
                    }
                    Item {
                        property real dischargePhase: 1.0
                        property real pumpPhase: 0.0
                        property real textPulse: 0.0

                        anchors.fill: parent

                        NumberAnimation on dischargePhase {
                            duration: 1600
                            easing.type: Easing.InOutSine
                            from: 1.0
                            loops: Animation.Infinite
                            running: heroMa.containsMouse && !window.isCharging
                            to: 0.0

                            onStopped: batCanvas.requestPaint()
                        }
                        NumberAnimation on pumpPhase {
                            duration: 1200
                            easing.type: Easing.InOutSine
                            from: 0.0
                            loops: Animation.Infinite
                            running: heroMa.containsMouse && window.isCharging
                            to: 1.0

                            onStopped: batCanvas.requestPaint()
                        }
                        SequentialAnimation on textPulse {
                            loops: Animation.Infinite
                            running: true

                            NumberAnimation {
                                duration: 1200
                                easing.type: Easing.InOutSine
                                from: 0.0
                                to: 1.0
                            }
                            NumberAnimation {
                                duration: 1200
                                easing.type: Easing.InOutSine
                                from: 1.0
                                to: 0.0
                            }
                        }

                        onDischargePhaseChanged: {
                            if (heroMa.containsMouse && !window.isCharging)
                                batCanvas.requestPaint();
                        }
                        onPumpPhaseChanged: {
                            if (heroMa.containsMouse && window.isCharging)
                                batCanvas.requestPaint();
                        }

                        Canvas {
                            id: batCanvas

                            anchors.fill: parent
                            rotation: 180

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);

                                var centerX = width / 2;
                                var centerY = height / 2;
                                var radius = (width / 2) - 18;
                                var endAngle = (window.animCapacity / 100) * 2 * Math.PI;

                                ctx.lineCap = "round";

                                ctx.lineWidth = 8;
                                ctx.beginPath();
                                ctx.arc(centerX, centerY, radius, 0, 2 * Math.PI);
                                ctx.strokeStyle = "#0dffffff";
                                ctx.stroke();

                                var fillGrad = ctx.createLinearGradient(0, height, width, 0);
                                fillGrad.addColorStop(0, window.batColorStart.toString());
                                fillGrad.addColorStop(1, window.batColorEnd.toString());

                                ctx.globalAlpha = 1.0;
                                ctx.lineWidth = 14;
                                ctx.beginPath();
                                ctx.arc(centerX, centerY, radius, 0, endAngle);
                                ctx.strokeStyle = fillGrad;
                                ctx.stroke();

                                if (heroMa.containsMouse && endAngle > 0.1) {
                                    if (window.isCharging) {
                                        var surgeAngle = parent.pumpPhase * (endAngle + 0.6) - 0.3;
                                        if (surgeAngle > 0 && surgeAngle < endAngle) {
                                            var sStart = Math.max(0, surgeAngle - 0.4);
                                            var sEnd = Math.min(endAngle, surgeAngle + 0.4);
                                            ctx.beginPath();
                                            ctx.arc(centerX, centerY, radius, sStart, sEnd);
                                            ctx.lineWidth = 22;
                                            ctx.strokeStyle = window.batColorStart.toString();
                                            ctx.globalAlpha = 0.5 * Math.sin(parent.pumpPhase * Math.PI);
                                            ctx.stroke();

                                            sStart = Math.max(0, surgeAngle - 0.2);
                                            sEnd = Math.min(endAngle, surgeAngle + 0.2);
                                            ctx.beginPath();
                                            ctx.arc(centerX, centerY, radius, sStart, sEnd);
                                            ctx.lineWidth = 28;
                                            ctx.strokeStyle = window.batColorEnd.toString();
                                            ctx.globalAlpha = 0.8 * Math.sin(parent.pumpPhase * Math.PI);
                                            ctx.stroke();
                                        }

                                        if (parent.pumpPhase > 0.7) {
                                            var flarePhase = (parent.pumpPhase - 0.7) / 0.3;
                                            var hitX = centerX + Math.cos(endAngle) * radius;
                                            var hitY = centerY + Math.sin(endAngle) * radius;
                                            ctx.beginPath();
                                            ctx.arc(hitX, hitY, 7 + (flarePhase * 15), 0, 2 * Math.PI);
                                            ctx.fillStyle = window.batColorEnd.toString();
                                            ctx.globalAlpha = (1.0 - flarePhase) * 0.6;
                                            ctx.fill();
                                        }
                                    } else {
                                        var drainCenter = parent.dischargePhase * endAngle;
                                        for (var d = 0; d < 2; d++) {
                                            var dSpread = 0.2 + (d * 0.15);
                                            var dStart = Math.max(0, drainCenter - dSpread);
                                            var dEnd = Math.min(endAngle, drainCenter + dSpread);

                                            if (dStart < dEnd) {
                                                ctx.beginPath();
                                                ctx.arc(centerX, centerY, radius, dStart, dEnd);
                                                ctx.lineWidth = 14 + (1 - d) * 2;
                                                ctx.strokeStyle = window.batColorEnd.toString();
                                                ctx.globalAlpha = 0.2 * Math.sin(parent.dischargePhase * Math.PI);
                                                ctx.stroke();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    ColumnLayout {
                        anchors.centerIn: parent
                        spacing: -2

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 8

                            Text {
                                color: window.batColorStart
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 32
                                text: window.isCharging ? "󰂄" : (window.batCapacity > 20 ? "󰁹" : "󰂃")

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 400
                                    }
                                }
                            }
                            Text {
                                color: window.text
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 54
                                font.weight: Font.Black
                                text: Math.round(window.animCapacity) + "%"
                            }
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            color: window.isCharging ? Qt.tint(window.green, Qt.rgba(1, 1, 1, parent.textPulse * 0.4)) : (centralCore.isDangerState ? Qt.tint(window.red, Qt.rgba(1, 1, 1, parent.textPulse * 0.3)) : window.subtext0)
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 13
                            font.weight: Font.Bold
                            text: window.batStatus.toUpperCase()

                            Behavior on color {
                                ColorAnimation {
                                    duration: 300
                                }
                            }
                        }
                    }
                }
                MouseArea {
                    id: heroMa

                    anchors.fill: centralCore
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true

                    onEntered: batCanvas.requestPaint()
                    onExited: batCanvas.requestPaint()
                }
            }

            // ==========================================
            // BOTTOM DOCKS
            // ==========================================
            ColumnLayout {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.margins: 25
                anchors.right: parent.right
                opacity: introState
                spacing: 15

                transform: Translate {
                    y: 20 * (1.0 - introState)
                }

                // 1. HARDWARE CONTROLS DOCK (Sliders)
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 96
                    border.color: "#1affffff"
                    border.width: 1
                    color: "#05ffffff"
                    radius: 24

                    ColumnLayout {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 12

                        // Brightness Slider
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 15

                            Item {
                                Layout.preferredHeight: 32
                                Layout.preferredWidth: 32

                                Text {
                                    anchors.centerIn: parent
                                    color: window.ambientPrimary
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 22
                                    text: window.sysBrightness > 66 ? "󰃠" : (window.sysBrightness > 33 ? "󰃟" : "󰃞")

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                                height: 18

                                Timer {
                                    id: briCmdThrottle

                                    property int targetPct: -1

                                    interval: 50

                                    onTriggered: {
                                        if (targetPct >= 0) {
                                            Quickshell.execDetached(["brightnessctl", "set", targetPct + "%"]);
                                            targetPct = -1;
                                        }
                                    }
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    border.color: "#1affffff"
                                    border.width: 1
                                    clip: true
                                    color: "#0dffffff"
                                    radius: 9

                                    Rectangle {
                                        height: parent.height
                                        opacity: briMa.containsMouse ? 1.0 : 0.85
                                        radius: 9
                                        width: parent.width * (window.sysBrightness / 100)

                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal

                                            GradientStop {
                                                color: window.batColorStart
                                                position: 0.0

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 300
                                                    }
                                                }
                                            }
                                            GradientStop {
                                                color: window.batColorEnd
                                                position: 1.0

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 300
                                                    }
                                                }
                                            }
                                        }
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 200
                                            }
                                        }
                                        Behavior on width {
                                            enabled: !window.isDraggingBri

                                            NumberAnimation {
                                                duration: 200
                                                easing.type: Easing.OutQuint
                                            }
                                        }
                                    }
                                }
                                MouseArea {
                                    id: briMa

                                    function updateBri(mx) {
                                        let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100)));
                                        window.sysBrightness = pct;
                                        briCmdThrottle.targetPct = pct;
                                        if (!briCmdThrottle.running)
                                            briCmdThrottle.start();
                                    }

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    onPositionChanged: mouse => {
                                        if (pressed)
                                            updateBri(mouse.x);
                                    }
                                    onPressed: mouse => {
                                        briSyncDelay.stop();
                                        window.isDraggingBri = true;
                                        updateBri(mouse.x);
                                    }
                                    onReleased: {
                                        briSyncDelay.restart();
                                    }
                                }
                            }
                        }

                        // Volume Slider
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 15

                            Rectangle {
                                Layout.preferredHeight: 32
                                Layout.preferredWidth: 32
                                border.color: volIconMa.containsMouse ? window.profileStart : "transparent"
                                color: volIconMa.containsMouse ? "#1affffff" : "transparent"
                                radius: 16

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    color: window.sysMuted ? window.overlay0 : window.profileStart
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 22
                                    text: window.sysMuted || window.sysVolume === 0 ? "󰖁" : (window.sysVolume > 50 ? "󰕾" : "󰖀")

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                                MouseArea {
                                    id: volIconMa

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    onClicked: {
                                        volSyncDelay.stop();
                                        window.isDraggingVol = true;
                                        window.sysMuted = !window.sysMuted;
                                        Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"]);
                                        volSyncDelay.restart();
                                    }
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                                height: 18

                                Timer {
                                    id: volCmdThrottle

                                    property int targetPct: -1

                                    interval: 50

                                    onTriggered: {
                                        if (targetPct >= 0) {
                                            if (targetPct > 0 && window.sysMuted) {
                                                window.sysMuted = false;
                                                Quickshell.execDetached(["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "0"]);
                                            }
                                            Quickshell.execDetached(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", targetPct + "%"]);
                                            targetPct = -1;
                                        }
                                    }
                                }
                                Rectangle {
                                    anchors.fill: parent
                                    border.color: "#1affffff"
                                    border.width: 1
                                    clip: true
                                    color: "#0dffffff"
                                    radius: 9

                                    Rectangle {
                                        height: parent.height
                                        opacity: window.sysMuted ? 0.5 : (volMa.containsMouse ? 1.0 : 0.85)
                                        radius: 9
                                        width: parent.width * (window.sysVolume / 100)

                                        gradient: Gradient {
                                            orientation: Gradient.Horizontal

                                            GradientStop {
                                                color: window.sysMuted ? window.surface2 : window.profileStart
                                                position: 0.0

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 300
                                                    }
                                                }
                                            }
                                            GradientStop {
                                                color: window.sysMuted ? Qt.lighter(window.surface2, 1.15) : window.profileEnd
                                                position: 1.0

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 300
                                                    }
                                                }
                                            }
                                        }
                                        Behavior on opacity {
                                            NumberAnimation {
                                                duration: 200
                                            }
                                        }
                                        Behavior on width {
                                            enabled: !window.isDraggingVol

                                            NumberAnimation {
                                                duration: 200
                                                easing.type: Easing.OutQuint
                                            }
                                        }
                                    }
                                }
                                MouseArea {
                                    id: volMa

                                    function updateVol(mx) {
                                        let pct = Math.max(0, Math.min(100, Math.round((mx / width) * 100)));
                                        window.sysVolume = pct;
                                        volCmdThrottle.targetPct = pct;
                                        if (!volCmdThrottle.running)
                                            volCmdThrottle.start();
                                    }

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    onPositionChanged: mouse => {
                                        if (pressed)
                                            updateVol(mouse.x);
                                    }
                                    onPressed: mouse => {
                                        volSyncDelay.stop();
                                        window.isDraggingVol = true;
                                        updateVol(mouse.x);
                                    }
                                    onReleased: {
                                        volSyncDelay.restart();
                                    }
                                }
                            }
                        }
                    }
                }

                // 2. SYSTEM ACTIONS DOCK
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 75
                    spacing: 12

                    Repeater {
                        delegate: Rectangle {
                            id: actionCapsule

                            // -------------------------------------

                            property real fillLevel: 0.0
                            property real flashOpacity: 0.0
                            property bool triggered: false

                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            border.color: actionMa.containsMouse ? c1 : "#1affffff"
                            border.width: actionMa.containsMouse ? 2 : 1
                            color: actionMa.containsMouse ? "#1affffff" : "#0dffffff"
                            radius: 18

                            // --- CLEAN STIFF RESISTANCE EFFECT ---
                            scale: actionMa.pressed ? (0.98 - (0.01 * weight)) : (actionMa.containsMouse ? 1.08 : 1.0)

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
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.OutQuart
                                }
                            }

                            Canvas {
                                id: actionWaveCanvas

                                property real wavePhase: 0.0

                                anchors.fill: parent

                                NumberAnimation on wavePhase {
                                    duration: 800
                                    from: 0
                                    loops: Animation.Infinite
                                    running: actionCapsule.fillLevel > 0.0 && actionCapsule.fillLevel < 1.0
                                    to: Math.PI * 2
                                }

                                onPaint: {
                                    var ctx = getContext("2d");
                                    ctx.clearRect(0, 0, width, height);
                                    if (actionCapsule.fillLevel <= 0.001)
                                        return;

                                    var r = 18;
                                    var fillY = height * (1.0 - actionCapsule.fillLevel);
                                    ctx.save();
                                    ctx.beginPath();
                                    ctx.moveTo(r, 0);
                                    ctx.lineTo(width - r, 0);
                                    ctx.arcTo(width, 0, width, r, r);
                                    ctx.lineTo(width, height - r);
                                    ctx.arcTo(width, height, width - r, height, r);
                                    ctx.lineTo(r, height);
                                    ctx.arcTo(0, height, 0, height - r, r);
                                    ctx.lineTo(0, r);
                                    ctx.arcTo(0, 0, r, 0, r);
                                    ctx.closePath();
                                    ctx.clip();

                                    ctx.beginPath();
                                    ctx.moveTo(0, fillY);
                                    if (actionCapsule.fillLevel < 0.99) {
                                        var waveAmp = 10 * Math.sin(actionCapsule.fillLevel * Math.PI);
                                        var cp1y = fillY + Math.sin(wavePhase) * waveAmp;
                                        var cp2y = fillY + Math.cos(wavePhase + Math.PI) * waveAmp;
                                        ctx.bezierCurveTo(width * 0.33, cp2y, width * 0.66, cp1y, width, fillY);
                                        ctx.lineTo(width, height);
                                        ctx.lineTo(0, height);
                                    } else {
                                        ctx.lineTo(width, 0);
                                        ctx.lineTo(width, height);
                                        ctx.lineTo(0, height);
                                    }
                                    ctx.closePath();

                                    var grad = ctx.createLinearGradient(0, 0, 0, height);
                                    grad.addColorStop(0, c1);
                                    grad.addColorStop(1, c2);
                                    ctx.fillStyle = grad;
                                    ctx.fill();
                                    ctx.restore();
                                }
                                onWavePhaseChanged: requestPaint()

                                Connections {
                                    function onFillLevelChanged() {
                                        actionWaveCanvas.requestPaint();
                                    }

                                    target: actionCapsule
                                }
                            }
                            Rectangle {
                                anchors.fill: parent
                                color: "#ffffff"
                                opacity: actionCapsule.flashOpacity
                                radius: 18

                                PropertyAnimation on opacity {
                                    id: cardFlashAnim

                                    duration: 500
                                    easing.type: Easing.OutExpo
                                    to: 0
                                }
                            }
                            ColumnLayout {
                                id: baseTextCol

                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    color: actionMa.containsMouse ? window.text : window.subtext0
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 22
                                    text: icon

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    color: actionMa.containsMouse ? window.text : window.subtext0
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                    text: actionCapsule.fillLevel > 0.1 ? "Hold" : lbl

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }
                            }
                            Item {
                                anchors.bottom: parent.bottom
                                anchors.left: parent.left
                                anchors.right: parent.right
                                clip: true
                                height: actionCapsule.height * actionCapsule.fillLevel

                                ColumnLayout {
                                    height: baseTextCol.height
                                    spacing: 4
                                    width: baseTextCol.width
                                    x: baseTextCol.x
                                    y: baseTextCol.y - (actionCapsule.height - parent.height)

                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        color: window.crust
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 22
                                        text: icon
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        color: window.crust
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                        text: actionCapsule.fillLevel > 0.1 ? "Hold" : lbl
                                    }
                                }
                            }
                            MouseArea {
                                id: actionMa

                                anchors.fill: parent
                                cursorShape: actionCapsule.triggered ? Qt.ArrowCursor : Qt.PointingHandCursor
                                hoverEnabled: true

                                onPressed: {
                                    if (!actionCapsule.triggered) {
                                        drainAnim.stop();
                                        fillAnim.start();
                                    }
                                }
                                onReleased: {
                                    if (!actionCapsule.triggered && actionCapsule.fillLevel < 1.0) {
                                        fillAnim.stop();
                                        drainAnim.start();
                                    }
                                }
                            }
                            NumberAnimation {
                                id: fillAnim

                                duration: (550 * weight) * (1.0 - actionCapsule.fillLevel)
                                easing.type: Easing.InSine
                                property: "fillLevel"
                                target: actionCapsule
                                to: 1.0

                                onFinished: {
                                    actionCapsule.triggered = true;
                                    actionCapsule.flashOpacity = 0.6;
                                    cardFlashAnim.start();
                                    window.introState = 0.0;
                                    exitTimer.start();
                                }
                            }
                            NumberAnimation {
                                id: drainAnim

                                duration: 1500 * actionCapsule.fillLevel
                                easing.type: Easing.OutQuad
                                property: "fillLevel"
                                target: actionCapsule
                                to: 0.0
                            }
                            Timer {
                                id: exitTimer

                                interval: 500

                                onTriggered: {
                                    Quickshell.execDetached(["sh", "-c", cmd]);
                                    Quickshell.execDetached(["sh", "-c", "echo 'close' > /tmp/qs_widget_state"]);
                                }
                            }
                        }
                        model: ListModel {
                            ListElement {
                                c1: "#cba6f7"
                                c2: "#f5c2e7"
                                cmd: "lock-screen"
                                icon: ""
                                lbl: "Lock"
                                weight: 1.0
                            }
                            ListElement {
                                c1: "#89b4fa"
                                c2: "#74c7ec"
                                cmd: "lock-screen && systemctl suspend"
                                icon: "ᶻ 𝗓 𐰁"
                                lbl: "Sleep"
                                weight: 1.0
                            }
                            ListElement {
                                c1: "#f9e2af"
                                c2: "#fab387"
                                cmd: "systemctl reboot"
                                icon: "󰑓"
                                lbl: "Reboot"
                                weight: 2.5
                            }
                            ListElement {
                                c1: "#f38ba8"
                                c2: "#eba0ac"
                                cmd: "systemctl poweroff"
                                icon: ""
                                lbl: "Power"
                                weight: 3.5
                            }
                        }
                    }
                }

                // 3. POWER PROFILES DOCK
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 54
                    border.color: "#1affffff"
                    border.width: 1
                    color: "#0dffffff"
                    radius: 27

                    Rectangle {
                        id: sliderPill

                        height: parent.height - 2
                        radius: 26
                        width: (parent.width - 2) / 3
                        x: {
                            if (window.powerProfile === "performance")
                                return 1;
                            if (window.powerProfile === "balanced")
                                return width + 1;
                            return (width * 2) + 1;
                        }
                        y: 1

                        gradient: Gradient {
                            orientation: Gradient.Horizontal

                            GradientStop {
                                color: window.profileStart
                                position: 0.0

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 400
                                    }
                                }
                            }
                            GradientStop {
                                color: window.profileEnd
                                position: 1.0

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 400
                                    }
                                }
                            }
                        }
                        Behavior on x {
                            NumberAnimation {
                                duration: 400
                                easing.overshoot: 1.2
                                easing.type: Easing.OutBack
                            }
                        }
                    }
                    RowLayout {
                        anchors.fill: parent
                        spacing: 0

                        Repeater {
                            delegate: Item {
                                Layout.fillHeight: true
                                Layout.fillWidth: true

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8

                                    Text {
                                        color: window.powerProfile === name ? window.crust : (profileMa.containsMouse ? window.text : window.subtext0)
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 18
                                        text: icon

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 200
                                            }
                                        }
                                    }
                                    Text {
                                        color: window.powerProfile === name ? window.crust : (profileMa.containsMouse ? window.text : window.subtext0)
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 13
                                        font.weight: Font.Black
                                        text: label

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 200
                                            }
                                        }
                                    }
                                }
                                MouseArea {
                                    id: profileMa

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    onClicked: {
                                        Quickshell.execDetached(["powerprofilesctl", "set", name]);
                                        sysPoller.running = true;
                                    }
                                }
                            }
                            model: ListModel {
                                ListElement {
                                    icon: "󰓅"
                                    label: "Perform"
                                    name: "performance"
                                }
                                ListElement {
                                    icon: "󰗑"
                                    label: "Balance"
                                    name: "balanced"
                                }
                                ListElement {
                                    icon: "󰌪"
                                    label: "Saver"
                                    name: "power-saver"
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
