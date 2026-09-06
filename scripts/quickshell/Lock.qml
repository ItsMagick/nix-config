import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCore
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Services.Pam
import "../"

ShellRoot {
    id: root

    readonly property color base: _theme.base
    readonly property color blue: _theme.blue
    readonly property color crust: _theme.crust
    readonly property color green: _theme.green
    readonly property color mantle: _theme.mantle
    readonly property color mauve: _theme.mauve
    readonly property color overlay0: _theme.overlay0
    readonly property color overlay2: _theme.overlay2
    readonly property color peach: _theme.peach
    readonly property color red: _theme.red
    readonly property color subtext0: _theme.subtext0
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color text: _theme.text

    MatugenColors {
        id: _theme
    }

    // Persistent Settings
    Settings {
        id: lockSettings

        property bool hidePassword: false
        property int revealDuration: 300

        category: "QuickshellLockscreen"
    }

    // Shared state across all monitors
    QtObject {
        id: lockUI

        property bool authenticating: false
        property bool failed: false
        property string statusText: "Locked"
    }

    // System Authentication hook
    PamContext {
        id: pam

        Component.onCompleted: pam.start()
        onCompleted: result => {
            lockUI.authenticating = false;
            if (result === PamResult.Success) {
                rootLock.locked = false;
                Qt.quit();
            } else {
                lockUI.failed = true;
                lockUI.statusText = "Access Denied";
                pam.start();
            }
        }
    }
    WlSessionLock {
        id: rootLock

        locked: true

        WlSessionLockSurface {
            id: surface

            Item {
                id: screenRoot

                property string batPct: "100"
                property string batStatus: "AC"
                property string currentUser: "User"
                property real globalOrbitAngle: 0
                property bool inputActive: false

                // UI States
                property real introState: 0.0
                property string kbLayout: "US"
                property bool powerMenuOpen: false

                anchors.fill: parent

                NumberAnimation on globalOrbitAngle {
                    duration: 90000
                    from: 0
                    loops: Animation.Infinite
                    running: true
                    to: Math.PI * 2
                }
                Behavior on introState {
                    NumberAnimation {
                        duration: 1000
                        easing.type: Easing.OutQuint
                    }
                }

                Component.onCompleted: introState = 1.0

                // Auto-hide input field if empty and idle for 15 seconds
                Timer {
                    id: idleTimer

                    interval: 15000
                    repeat: false
                    running: screenRoot.inputActive && inputField.text.length === 0

                    onTriggered: screenRoot.inputActive = false
                }

                // ---------------------------------------------------------
                // BACKGROUND DATA POLLING (Separated for fast KB response)
                // ---------------------------------------------------------

                // Fast Poller for Keyboard (150ms)
                Process {
                    id: kbPoller

                    command: ["zsh", "-c", "hyprctl devices -j | jq -r '.keyboards[] | select(.main == true) | .active_keymap' | head -n1 | cut -c1-2 | tr '[:lower:]' '[:upper:]'"]

                    stdout: StdioCollector {
                        onStreamFinished: {
                            let layout = this.text.trim();
                            if (layout !== "" && layout !== "null") {
                                screenRoot.kbLayout = layout;
                            }
                        }
                    }
                }
                Timer {
                    interval: 150
                    repeat: true
                    running: true
                    triggeredOnStart: true

                    onTriggered: kbPoller.running = true
                }

                // Slow Poller for Battery (5000ms)
                Process {
                    id: batPoller

                    command: ["zsh", "-c", "cat /sys/class/power_supply/BAT*/capacity 2>/dev/null | head -n1 || echo '100'; cat /sys/class/power_supply/BAT*/status 2>/dev/null | head -n1 || echo 'AC'"]

                    stdout: StdioCollector {
                        onStreamFinished: {
                            let lines = this.text.trim().split("\n");
                            if (lines.length >= 2) {
                                screenRoot.batPct = lines[0] || "100";
                                screenRoot.batStatus = lines[1] || "Unknown";
                            }
                        }
                    }
                }
                Timer {
                    interval: 5000
                    repeat: true
                    running: true
                    triggeredOnStart: true

                    onTriggered: batPoller.running = true
                }

                // ---------------------------------------------------------
                // 1. LIVING BACKGROUND
                // ---------------------------------------------------------
                Rectangle {
                    anchors.fill: parent
                    color: Qt.rgba(root.base.r, root.base.g, root.base.b, 0.85)

                    Rectangle {
                        color: root.mauve
                        height: width
                        opacity: 0.05
                        radius: width / 2
                        scale: 1.0 + Math.sin(screenRoot.globalOrbitAngle * 6) * 0.05
                        width: parent.width * 0.8
                        x: (parent.width / 2 - width / 2) + Math.cos(screenRoot.globalOrbitAngle * 2) * 200
                        y: (parent.height / 2 - height / 2) + Math.sin(screenRoot.globalOrbitAngle * 2) * 150

                        Behavior on color {
                            ColorAnimation {
                                duration: 1000
                            }
                        }
                    }
                    Rectangle {
                        color: root.blue
                        height: width
                        opacity: 0.04
                        radius: width / 2
                        scale: 1.0 + Math.cos(screenRoot.globalOrbitAngle * 5) * 0.05
                        width: parent.width * 0.9
                        x: (parent.width / 2 - width / 2) + Math.sin(screenRoot.globalOrbitAngle * 1.5) * -200
                        y: (parent.height / 2 - height / 2) + Math.cos(screenRoot.globalOrbitAngle * 1.5) * -150

                        Behavior on color {
                            ColorAnimation {
                                duration: 1000
                            }
                        }
                    }
                    Item {
                        anchors.fill: parent
                        opacity: screenRoot.introState
                        scale: 1.1 - (0.1 * screenRoot.introState)

                        Repeater {
                            model: 4

                            Rectangle {
                                anchors.centerIn: parent
                                anchors.verticalCenterOffset: -40
                                border.color: lockUI.failed ? root.red : root.mauve
                                border.width: 1
                                color: "transparent"
                                height: width
                                opacity: lockUI.failed ? (0.1 - (index * 0.02)) : (0.04 - (index * 0.01))
                                radius: width / 2
                                width: 400 + (index * 220)

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 600
                                        easing.type: Easing.OutExpo
                                    }
                                }
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 600
                                        easing.type: Easing.OutExpo
                                    }
                                }
                            }
                        }
                    }
                }

                // ---------------------------------------------------------
                // 2. MAIN CONTENT LAYER (Cross-fading Clock & Auth)
                // ---------------------------------------------------------
                MouseArea {
                    anchors.fill: parent

                    onClicked: {
                        if (screenRoot.powerMenuOpen)
                            screenRoot.powerMenuOpen = false;
                        if (!screenRoot.inputActive)
                            screenRoot.inputActive = true;
                        inputField.forceActiveFocus();
                    }
                }
                Item {
                    anchors.fill: parent
                    opacity: screenRoot.introState

                    transform: Translate {
                        y: 30 * (1.0 - screenRoot.introState)
                    }

                    // --- CLOCK MODULE (Idle State) ---
                    ColumnLayout {
                        id: clockModule

                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: screenRoot.inputActive ? -120 : -40
                        opacity: screenRoot.inputActive ? 0.0 : 1.0
                        scale: screenRoot.inputActive ? 0.9 : 1.0
                        spacing: -10
                        visible: opacity > 0.01

                        Behavior on anchors.verticalCenterOffset {
                            NumberAnimation {
                                duration: 600
                                easing.type: Easing.OutExpo
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 500
                                easing.type: Easing.OutBack
                            }
                        }

                        Text {
                            id: clockText

                            Layout.alignment: Qt.AlignHCenter
                            color: root.text
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 140
                            font.weight: Font.Black

                            Behavior on color {
                                ColorAnimation {
                                    duration: 300
                                }
                            }
                        }
                        Text {
                            id: dateText

                            Layout.alignment: Qt.AlignHCenter
                            color: root.mauve
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 22
                            font.weight: Font.Bold
                        }
                        Timer {
                            interval: 1000
                            repeat: true
                            running: true
                            triggeredOnStart: true

                            onTriggered: {
                                let d = new Date();
                                clockText.text = Qt.formatDateTime(d, "hh:mm");
                                dateText.text = Qt.formatDateTime(d, "dddd, MMMM dd");
                            }
                        }
                    }

                    // --- AUTHENTICATION MODULE (Input State) ---
                    ColumnLayout {
                        id: authModule

                        anchors.centerIn: parent
                        anchors.verticalCenterOffset: screenRoot.inputActive ? -40 : 40
                        opacity: screenRoot.inputActive ? 1.0 : 0.0
                        scale: screenRoot.inputActive ? 1.0 : 0.9
                        spacing: 20
                        visible: opacity > 0.01

                        Behavior on anchors.verticalCenterOffset {
                            NumberAnimation {
                                duration: 600
                                easing.type: Easing.OutExpo
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 400
                                easing.type: Easing.OutCubic
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 500
                                easing.type: Easing.OutBack
                            }
                        }

                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 12

                            Rectangle {
                                border.color: lockUI.failed ? root.red : (lockUI.authenticating ? root.peach : root.surface2)
                                border.width: 1
                                color: lockUI.failed ? Qt.rgba(root.red.r, root.red.g, root.red.b, 0.2) : (lockUI.authenticating ? Qt.rgba(root.peach.r, root.peach.g, root.peach.b, 0.2) : "transparent")
                                height: 36
                                radius: 18
                                width: 36

                                Behavior on border.color {
                                    ColorAnimation {
                                        duration: 300
                                    }
                                }
                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    color: lockUI.failed ? root.red : (lockUI.authenticating ? root.peach : root.subtext0)
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 18
                                    text: lockUI.failed ? "󰌾" : (lockUI.authenticating ? "󰌿" : "")

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 300
                                        }
                                    }
                                }
                            }
                            Text {
                                color: lockUI.failed ? root.red : (lockUI.authenticating ? root.peach : root.subtext0)
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 16
                                font.weight: Font.Bold
                                text: lockUI.statusText

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                    }
                                }
                            }
                        }
                        Rectangle {
                            id: pinPill

                            Layout.alignment: Qt.AlignHCenter
                            border.color: {
                                if (lockUI.failed)
                                    return root.red;
                                if (lockUI.authenticating)
                                    return root.peach;
                                if (inputField.text.length > 0)
                                    return root.mauve;
                                return Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08);
                            }
                            border.width: 2
                            clip: true
                            color: lockUI.failed ? Qt.rgba(root.red.r, root.red.g, root.red.b, 0.1) : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.5)
                            height: 60
                            radius: 30
                            scale: lockUI.failed ? 1.05 : (lockUI.authenticating ? 0.98 : 1.0)
                            width: 280

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 250
                                    easing.type: Easing.OutExpo
                                }
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 250
                                    easing.type: Easing.OutExpo
                                }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 300
                                    easing.type: Easing.OutBack
                                }
                            }

                            // Hidden input to capture keystrokes perfectly
                            TextInput {
                                id: inputField

                                property string oldText: ""

                                anchors.fill: parent
                                echoMode: TextInput.Password
                                opacity: 0

                                Component.onCompleted: forceActiveFocus()
                                Keys.onPressed: event => {
                                    if (event.key === Qt.Key_Escape) {
                                        screenRoot.inputActive = false;
                                        text = "";
                                        passModel.clear();
                                        event.accepted = true;
                                    } else if (!screenRoot.inputActive) {
                                        screenRoot.inputActive = true;
                                    }
                                }
                                onAccepted: {
                                    if (text.length > 0 && pam.responseRequired && !lockUI.authenticating) {
                                        lockUI.authenticating = true;
                                        lockUI.statusText = "Authenticating...";
                                        lockUI.failed = false;
                                        pam.respond(text);
                                        text = "";
                                        oldText = "";
                                        passModel.clear();
                                    }
                                }
                                onActiveFocusChanged: {
                                    if (!activeFocus && !screenRoot.powerMenuOpen) {
                                        forceActiveFocus();
                                    }
                                }
                                onTextChanged: {
                                    if (lockUI.authenticating)
                                        return;

                                    if (text.length > 0 && !screenRoot.inputActive) {
                                        screenRoot.inputActive = true;
                                    }

                                    idleTimer.restart();

                                    if (text !== oldText) {
                                        if (text.length > oldText.length) {
                                            for (let i = oldText.length; i < text.length; i++) {
                                                passModel.append({
                                                    "charStr": text.charAt(i),
                                                    "isDot": lockSettings.hidePassword
                                                });
                                            }
                                        } else if (text.length < oldText.length) {
                                            let diff = oldText.length - text.length;
                                            for (let i = 0; i < diff; i++) {
                                                passModel.remove(passModel.count - 1);
                                            }
                                        } else {
                                            passModel.clear();
                                            for (let i = 0; i < text.length; i++) {
                                                passModel.append({
                                                    "charStr": text.charAt(i),
                                                    "isDot": lockSettings.hidePassword
                                                });
                                            }
                                        }
                                        oldText = text;
                                    }

                                    if (text.length > 0) {
                                        lockUI.failed = false;
                                        lockUI.statusText = "Enter PIN";
                                    } else {
                                        if (!lockUI.failed)
                                            lockUI.statusText = "Locked";
                                    }
                                }
                            }
                            ListModel {
                                id: passModel
                            }
                            Item {
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20
                                clip: true

                                Row {
                                    id: dotRow

                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 4
                                    x: width > parent.width ? parent.width - width : (parent.width - width) / 2

                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 150
                                            easing.type: Easing.OutQuad
                                        }
                                    }

                                    Repeater {
                                        model: passModel

                                        delegate: Item {
                                            height: 30
                                            width: charText.implicitWidth

                                            // Secure, independent timer for each specific letter reacting to persistent settings
                                            Timer {
                                                interval: lockSettings.revealDuration
                                                running: !model.isDot && !lockSettings.hidePassword

                                                onTriggered: {
                                                    if (index >= 0 && index < passModel.count) {
                                                        passModel.setProperty(index, "isDot", true);
                                                    }
                                                }
                                            }
                                            Text {
                                                id: charText

                                                anchors.centerIn: parent
                                                color: lockUI.failed ? root.red : (lockUI.authenticating ? root.peach : root.text)
                                                font.family: "FiraCode Nerd Font Mono"
                                                font.pixelSize: model.isDot ? 32 : 24
                                                font.weight: Font.Bold
                                                text: model.isDot ? "•" : model.charStr

                                                NumberAnimation on opacity {
                                                    duration: 150
                                                    from: 0
                                                    to: 1
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ---------------------------------------------------------
                // 3. BOTTOM SYSTEM INFO PILLS (Enlarged)
                // ---------------------------------------------------------
                RowLayout {
                    anchors.bottom: parent.bottom
                    anchors.bottomMargin: 40
                    anchors.horizontalCenter: parent.horizontalCenter
                    opacity: screenRoot.introState
                    spacing: 16

                    transform: Translate {
                        y: 20 * (1.0 - screenRoot.introState)
                    }

                    // KB Layout Pill
                    Rectangle {
                        property bool isHovered: kbMouse.containsMouse

                        Layout.preferredHeight: 48
                        Layout.preferredWidth: kbLayoutRow.implicitWidth + 36
                        border.color: isHovered ? root.mauve : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08)
                        border.width: 1
                        color: isHovered ? Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.6) : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.4)
                        radius: 24
                        scale: isHovered ? 1.05 : 1.0

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
                                duration: 250
                                easing.type: Easing.OutExpo
                            }
                        }

                        RowLayout {
                            id: kbLayoutRow

                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                color: parent.parent.isHovered ? root.mauve : root.overlay2
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 18
                                text: "󰌌"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                            }
                            Text {
                                color: root.text
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 14
                                font.weight: Font.Black
                                text: screenRoot.kbLayout
                            }
                        }
                        MouseArea {
                            id: kbMouse

                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }

                    // Battery Pill
                    Rectangle {
                        property bool isHovered: batMouse.containsMouse

                        Layout.preferredHeight: 48
                        Layout.preferredWidth: batLayoutRow.implicitWidth + 36
                        border.color: isHovered ? batLayoutRow.dynamicBatColor : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.08)
                        border.width: 1
                        color: isHovered ? Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.6) : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.4)
                        radius: 24
                        scale: isHovered ? 1.05 : 1.0

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
                                duration: 250
                                easing.type: Easing.OutExpo
                            }
                        }

                        RowLayout {
                            id: batLayoutRow

                            // Fully Matugen Dynamic Color Logic
                            property color dynamicBatColor: {
                                if (screenRoot.batStatus === "Charging")
                                    return root.green;
                                let pct = parseInt(screenRoot.batPct);
                                if (pct >= 60)
                                    return root.green;
                                if (pct >= 25)
                                    return root.peach;
                                return root.red;
                            }

                            anchors.centerIn: parent
                            spacing: 8

                            Text {
                                color: batLayoutRow.dynamicBatColor
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 20
                                text: screenRoot.batStatus === "Charging" ? "󰂄" : (parseInt(screenRoot.batPct) < 20 ? "󰂃" : "󰁹")

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                            }
                            Text {
                                color: batLayoutRow.dynamicBatColor
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 14
                                font.weight: Font.Black
                                text: screenRoot.batPct + "%"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                            }
                        }
                        MouseArea {
                            id: batMouse

                            anchors.fill: parent
                            hoverEnabled: true
                        }
                    }
                }

                // ---------------------------------------------------------
                // 4. POWER MENU (Enlarged, Persistent Settings, Matugen)
                // ---------------------------------------------------------
                Rectangle {
                    id: powerMenu

                    anchors.bottom: powerBtn.top
                    anchors.bottomMargin: 15
                    anchors.right: parent.right
                    anchors.rightMargin: 40
                    border.color: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.1)
                    border.width: 1
                    clip: true
                    color: Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.95)
                    height: screenRoot.powerMenuOpen ? (menuLayout.implicitHeight + 20) : 0
                    opacity: screenRoot.powerMenuOpen ? 1 : 0
                    radius: 18
                    width: 280

                    Behavior on height {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutExpo
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 250
                        }
                    }

                    ColumnLayout {
                        id: menuLayout

                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.top: parent.top
                        anchors.topMargin: 10
                        spacing: 6

                        // --- SETTINGS SECTION ---
                        Text {
                            Layout.bottomMargin: 4
                            Layout.leftMargin: 18
                            Layout.topMargin: 4
                            color: root.subtext0
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 12
                            font.weight: Font.Black
                            text: "SETTINGS"
                        }

                        // Hide Password Toggle
                        RowLayout {
                            Layout.fillWidth: true
                            Layout.leftMargin: 18
                            Layout.rightMargin: 18
                            Layout.topMargin: 4

                            Text {
                                Layout.fillWidth: true
                                color: root.text
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                text: "Hide password"
                            }
                            Rectangle {
                                color: lockSettings.hidePassword ? root.mauve : root.surface2
                                height: 22
                                radius: 11
                                width: 40

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 250
                                    }
                                }

                                Rectangle {
                                    color: root.base
                                    height: 18
                                    radius: 9
                                    width: 18
                                    x: lockSettings.hidePassword ? 20 : 2
                                    y: 2

                                    Behavior on x {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                }
                                MouseArea {
                                    anchors.fill: parent

                                    onClicked: {
                                        lockSettings.hidePassword = !lockSettings.hidePassword;
                                        if (lockSettings.hidePassword) {
                                            for (let i = 0; i < passModel.count; i++)
                                                passModel.setProperty(i, "isDot", true);
                                        }
                                    }
                                }
                            }
                        }

                        // Reveal Delay Slider
                        ColumnLayout {
                            Layout.bottomMargin: 8
                            Layout.fillWidth: true
                            Layout.leftMargin: 18
                            Layout.rightMargin: 18
                            Layout.topMargin: 8
                            opacity: lockSettings.hidePassword ? 0.3 : 1.0
                            spacing: 8

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    Layout.fillWidth: true
                                    color: root.text
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    text: "Reveal delay"
                                }
                                Text {
                                    color: root.peach
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 13
                                    font.weight: Font.Bold
                                    text: lockSettings.revealDuration >= 1000 ? (lockSettings.revealDuration / 1000).toFixed(1) + " s" : lockSettings.revealDuration + " ms"
                                }
                            }
                            Item {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 28

                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: root.surface2
                                    height: 8
                                    radius: 4
                                    width: parent.width

                                    Rectangle {
                                        color: root.mauve
                                        height: parent.height
                                        radius: 4
                                        width: ((lockSettings.revealDuration - 100) / 2900) * parent.width
                                    }
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter
                                    border.color: root.crust
                                    border.width: 2
                                    color: root.peach
                                    height: 20
                                    radius: 10

                                    // Bouncing scale effect on hover/press
                                    scale: sliderMouse.pressed ? 1.3 : (sliderMouse.containsMouse ? 1.15 : 1.0)
                                    width: 20
                                    x: Math.max(0, Math.min(((lockSettings.revealDuration - 100) / 2900) * parent.width - 10, parent.width - 20))

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 150
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                }
                                MouseArea {
                                    id: sliderMouse

                                    function updateVal(mouseX) {
                                        let pct = Math.max(0, Math.min(1, mouseX / width));
                                        let ms = Math.round(100 + (pct * 2900));
                                        if (ms % 100 < 10)
                                            ms -= (ms % 100);
                                        else if (ms % 100 > 90)
                                            ms += (100 - (ms % 100));
                                        lockSettings.revealDuration = ms;
                                    }

                                    anchors.fill: parent
                                    enabled: !lockSettings.hidePassword
                                    hoverEnabled: true
                                    preventStealing: true

                                    // FIX: Only update if the mouse button is actively held down
                                    onPositionChanged: mouse => {
                                        if (pressed) {
                                            updateVal(mouse.x);
                                        }
                                    }
                                    onPressed: mouse => updateVal(mouse.x)
                                }
                            }
                        }

                        // Separator
                        Rectangle {
                            Layout.bottomMargin: 8
                            Layout.fillWidth: true
                            Layout.leftMargin: 18
                            Layout.preferredHeight: 1
                            Layout.rightMargin: 18
                            Layout.topMargin: 4
                            color: Qt.rgba(root.text.r, root.text.g, root.text.b, 0.1)
                        }

                        // --- SYSTEM ACTIONS SECTION ---

                        // Reload Button (Blue)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 10
                            Layout.preferredHeight: 48
                            Layout.rightMargin: 10
                            color: ma1.containsMouse ? Qt.rgba(root.blue.r, root.blue.g, root.blue.b, 0.1) : "transparent"
                            radius: 12
                            scale: ma1.pressed ? 0.95 : (ma1.containsMouse ? 1.02 : 1.0)

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutBack
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 0

                                Text {
                                    color: ma1.containsMouse ? root.blue : Qt.rgba(root.blue.r, root.blue.g, root.blue.b, 0.6)
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 18
                                    text: "󰜉"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                                Item {
                                    Layout.fillWidth: true
                                } // Spacer
                                Text {
                                    color: ma1.containsMouse ? root.blue : Qt.rgba(root.blue.r, root.blue.g, root.blue.b, 0.6)
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 15
                                    font.weight: Font.Medium
                                    text: "Reload"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                            }
                            MouseArea {
                                id: ma1

                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: {
                                    screenRoot.powerMenuOpen = false;
                                    Qt.createQmlObject('import Quickshell; Process { command: ["zsh", "-c", "hyprctl reload"]; running: true }', screenRoot);
                                }
                            }
                        }

                        // Suspend Button (Mauve)
                        Rectangle {
                            Layout.fillWidth: true
                            Layout.leftMargin: 10
                            Layout.preferredHeight: 48
                            Layout.rightMargin: 10
                            color: ma2.containsMouse ? Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.1) : "transparent"
                            radius: 12
                            scale: ma2.pressed ? 0.95 : (ma2.containsMouse ? 1.02 : 1.0)

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutBack
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 0

                                Text {
                                    color: ma2.containsMouse ? root.mauve : Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.6)
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 18
                                    text: "󰒲"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                                Item {
                                    Layout.fillWidth: true
                                } // Spacer
                                Text {
                                    color: ma2.containsMouse ? root.mauve : Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.6)
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 15
                                    font.weight: Font.Medium
                                    text: "Suspend"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                            }
                            MouseArea {
                                id: ma2

                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: {
                                    screenRoot.powerMenuOpen = false;
                                    Qt.createQmlObject('import Quickshell; Process { command: ["zsh", "-c", "systemctl suspend"]; running: true }', screenRoot);
                                }
                            }
                        }

                        // Power Off Button (Red)
                        Rectangle {
                            Layout.bottomMargin: 8
                            Layout.fillWidth: true
                            Layout.leftMargin: 10
                            Layout.preferredHeight: 48
                            Layout.rightMargin: 10
                            color: ma3.containsMouse ? Qt.rgba(root.red.r, root.red.g, root.red.b, 0.1) : "transparent"
                            radius: 12
                            scale: ma3.pressed ? 0.95 : (ma3.containsMouse ? 1.02 : 1.0)

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }
                            Behavior on scale {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutBack
                                }
                            }

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 16
                                anchors.rightMargin: 16
                                spacing: 0

                                Text {
                                    color: ma3.containsMouse ? root.red : Qt.rgba(root.red.r, root.red.g, root.red.b, 0.6)
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 18
                                    text: ""

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                                Item {
                                    Layout.fillWidth: true
                                } // Spacer
                                Text {
                                    color: ma3.containsMouse ? root.red : Qt.rgba(root.red.r, root.red.g, root.red.b, 0.6)
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 15
                                    font.weight: Font.Medium
                                    text: "Power Off"

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                            }
                            MouseArea {
                                id: ma3

                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: {
                                    screenRoot.powerMenuOpen = false;
                                    Qt.createQmlObject('import Quickshell; Process { command: ["zsh", "-c", "systemctl poweroff"]; running: true }', screenRoot);
                                }
                            }
                        }
                    }
                }

                // Enlarged Power Button
                Rectangle {
                    id: powerBtn

                    anchors.bottom: parent.bottom
                    anchors.margins: 40
                    anchors.right: parent.right
                    border.color: screenRoot.powerMenuOpen ? root.mauve : Qt.rgba(root.text.r, root.text.g, root.text.b, 0.15)
                    border.width: 1
                    color: screenRoot.powerMenuOpen ? root.surface2 : (powerBtnMa.containsMouse ? Qt.rgba(root.surface1.r, root.surface1.g, root.surface1.b, 0.8) : Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.4))
                    height: 52
                    opacity: screenRoot.introState
                    radius: 26
                    scale: powerBtnMa.pressed ? 0.9 : (powerBtnMa.containsMouse ? 1.08 : 1.0)
                    width: 52

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
                            duration: 300
                            easing.type: Easing.OutBack
                        }
                    }
                    transform: Translate {
                        y: 20 * (1.0 - screenRoot.introState)
                    }

                    Text {
                        anchors.centerIn: parent
                        color: screenRoot.powerMenuOpen ? root.red : (powerBtnMa.containsMouse ? root.text : root.subtext0)
                        font.family: "FiraCode Nerd Font Mono"
                        font.pixelSize: 22
                        text: ""

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }
                        }
                    }
                    MouseArea {
                        id: powerBtnMa

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: {
                            screenRoot.powerMenuOpen = !screenRoot.powerMenuOpen;
                            if (!screenRoot.powerMenuOpen)
                                inputField.forceActiveFocus();
                        }
                    }
                }
            }
        }
    }
}
