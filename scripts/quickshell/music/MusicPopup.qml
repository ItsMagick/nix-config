import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtQuick.Shapes
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: root

    property string accumulatedEqOut: ""

    // Accumulators for Process standard output
    property string accumulatedMusicOut: ""

    // Theme Colors
    readonly property color base: _theme.base

    // PROPER EXCEPTION-FREE FIX: Explicit bindings so GradientStop actually repaints
    property color bc1: borderColors[0] || root.mauve
    property color bc2: borderColors[1] || root.blue
    property color bc3: borderColors[2] || root.red
    property color bc4: borderColors[3] || root.mauve
    readonly property color blue: _theme.blue

    // --- FIXED COLOR PARSING LOGIC ---
    property var borderColors: {
        var defaultColors = [root.mauve, root.blue, root.red, root.mauve];
        if (!root.musicData || !root.musicData.grad)
            return defaultColors;

        var hexRegex = /#[0-9a-fA-F]{6}/g;
        var matches = root.musicData.grad.match(hexRegex);

        if (matches && matches.length >= 3) {
            return [matches[0], matches[1], matches[2], matches[0]]; // Wrap around for looping
        }
        return defaultColors;
    }

    // Decoupled Global Animation States
    property real catppuccinFlowOffset: 0
    property color dynamicTextColor: {
        if (root.musicData && root.musicData.textColor) {
            var c = String(root.musicData.textColor).trim();
            // Securely extract exactly #RRGGBB, ignoring any alpha leak from the shell
            var match = c.match(/^(#[0-9a-fA-F]{6})/);
            if (match)
                return match[1];
        }
        return root.text;
    }
    property var eqData: {
        "b1": 0,
        "b2": 0,
        "b3": 0,
        "b4": 0,
        "b5": 0,
        "b6": 0,
        "b7": 0,
        "b8": 0,
        "b9": 0,
        "b10": 0,
        "preset": "Flat",
        "pending": false
    }
    property real eqLightningFade: 1.0 // 1.0 = fully faded out

    // --- CANVAS LIGHTNING ANIMATION STATE ---
    property real eqLightningProgress: 0.0
    property real globalOrbitAngle: 0
    property real introCover: 0
    property real introEq: 0

    // --- STARTUP ANIMATION STATES ---
    property real introMain: 0
    property real introText: 0

    // ANTI-JITTER LOCK: Prevents background polling from reverting UI during processing
    property real lastEqUpdate: 0

    // --- GLOBAL PLAY/PAUSE EVENT LISTENER ---
    property string lastMusicStatus: "Stopped"
    readonly property color lavender: _theme.blue // Mapped to blue as Matugen template lacks lavender
    readonly property color mauve: _theme.mauve

    // Data State Properties
    property var musicData: {
        "title": "Loading...",
        "artist": "",
        "status": "Stopped",
        "percent": 0,
        "lengthStr": "00:00",
        "positionStr": "00:00",
        "timeStr": "--:-- / --:--",
        "source": "Offline",
        "playerName": "",
        "blur": "",
        "grad": "",
        "textColor": "#cdd6f4",
        "deviceIcon": "󰓃",
        "deviceName": "Speaker",
        "artUrl": ""
    }
    readonly property color overlay0: _theme.overlay0
    readonly property color overlay1: _theme.overlay1
    readonly property color overlay2: _theme.overlay2
    readonly property color pink: _theme.pink
    readonly property color red: _theme.red
    readonly property color sapphire: _theme.sapphire
    readonly property color subtext0: _theme.subtext0
    readonly property color subtext1: _theme.subtext1
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color text: _theme.text

    // UI State for debouncing the slider and play button
    property bool userIsSeeking: false
    property bool userToggledPlay: false
    readonly property color yellow: _theme.yellow

    function applyPresetOptimistically(presetName) {
        var presets = {
            "Flat": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            "Bass": [5, 7, 5, 2, 1, 0, 0, 0, 1, 2],
            "Treble": [-2, -1, 0, 1, 2, 3, 4, 5, 6, 6],
            "Vocal": [-2, -1, 1, 3, 5, 5, 4, 2, 1, 0],
            "Pop": [2, 4, 2, 0, 1, 2, 4, 2, 1, 2],
            "Rock": [5, 4, 2, -1, -2, -1, 2, 4, 5, 6],
            "Jazz": [3, 3, 1, 1, 1, 1, 2, 1, 2, 3],
            "Classic": [0, 1, 2, 2, 2, 2, 1, 2, 3, 4]
        };
        if (presets[presetName]) {
            var temp = Object.assign({}, root.eqData);
            for (var i = 0; i < 10; i++) {
                temp["b" + (i + 1)] = presets[presetName][i];
            }
            temp.preset = presetName;
            temp.pending = false;
            root.eqData = temp;

            // Blind the polling process to stop it from fetching old data
            root.lastEqUpdate = Date.now();

            root.triggerEqLightning();
            execCmd(`$HOME/.config/hypr/scripts/quickshell/music/equalizer.sh preset ${presetName}`);
        }
    }

    // --- UTILITIES & OPTIMISTIC UPDATES ---
    function execCmd(cmdStr) {
        var safeCmd = cmdStr.replace(/`/g, "\\`");
        var p = Qt.createQmlObject(`
            import Quickshell.Io
            Process {
                command: ["zsh", "-c", \`${safeCmd}\`]
                running: true
                onExited: (exitCode) => destroy()
            }
        `, root);
    }
    function triggerEqLightning() {
        eqLightningAnim.restart();
    }

    NumberAnimation on catppuccinFlowOffset {
        duration: 8000 // Slowed down significantly for a graceful, constant flow
        from: 0
        loops: Animation.Infinite
        running: true
        to: 1.0
    }
    NumberAnimation on globalOrbitAngle {
        duration: 90000
        from: 0
        loops: Animation.Infinite
        running: true
        to: Math.PI * 2
    }

    onMusicDataChanged: {
        if (musicData && musicData.status && musicData.status !== lastMusicStatus) {
            if (musicData.status === "Playing") {
                playPulse.trigger();
            }
            lastMusicStatus = musicData.status;
        }
    }

    // Theme Colors
    MatugenColors {
        id: _theme
    }
    SequentialAnimation {
        id: eqLightningAnim

        running: false

        ScriptAction {
            script: {
                root.eqLightningFade = 0.0;
                root.eqLightningProgress = 0.0;
            }
        }
        NumberAnimation {
            duration: 650 // Fast, snappy, energetic strike
            easing.type: Easing.OutSine
            from: 0.0
            property: "eqLightningProgress"
            target: root
            to: 10.0 // 10 points = 9 segments
        }
        PauseAnimation {
            duration: 150
        } // Hold the core flash at the end
        NumberAnimation {
            duration: 800 // Smooth dissipation
            easing.type: Easing.OutQuad
            from: 0.0
            property: "eqLightningFade"
            target: root
            to: 1.0
        }
        ScriptAction {
            script: {
                root.eqLightningProgress = 0.0;
            }
        }
    }
    ParallelAnimation {
        running: true

        NumberAnimation {
            duration: 700
            easing.type: Easing.OutQuart
            from: 0
            property: "introMain"
            target: root
            to: 1.0
        }
        NumberAnimation {
            duration: 800
            easing.type: Easing.OutExpo
            from: 0
            property: "introCover"
            target: root
            to: 1.0
        }
        NumberAnimation {
            duration: 900
            easing.type: Easing.OutExpo
            from: 0
            property: "introText"
            target: root
            to: 1.0
        }
        NumberAnimation {
            duration: 1000
            easing.type: Easing.OutExpo
            from: 0
            property: "introEq"
            target: root
            to: 1.0
        }
    }

    // --- DATA POLLING ---
    Timer {
        id: seekDebounceTimer

        interval: 2500

        onTriggered: root.userIsSeeking = false
    }
    Timer {
        id: playDebounceTimer

        interval: 1500

        onTriggered: root.userToggledPlay = false
    }
    Timer {
        interval: 500
        repeat: true
        running: true
        triggeredOnStart: true

        onTriggered: {
            if (!musicProc.running)
                musicProc.running = true;
            if (!eqProc.running)
                eqProc.running = true;
        }
    }
    Process {
        id: musicProc

        command: ["zsh", "-c", "$HOME/.config/hypr/scripts/quickshell/music/music_info.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    var outStr = this.text.trim();
                    if (outStr.length > 0) {
                        try {
                            var newData = JSON.parse(outStr);
                            if (root.userToggledPlay) {
                                newData.status = root.musicData.status;
                            }
                            root.musicData = newData;
                        } catch (e) {}
                    }
                }
            }
        }
    }
    Process {
        id: eqProc

        command: ["zsh", "-c", "$HOME/.config/hypr/scripts/quickshell/music/equalizer.sh get"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text) {
                    // Ignore background data entirely if we recently pushed an optimistic update
                    if (Date.now() - root.lastEqUpdate < 2000)
                        return;

                    var outStr = this.text.trim();
                    if (outStr.length > 0) {
                        try {
                            root.eqData = JSON.parse(outStr);
                        } catch (e) {}
                    }
                }
            }
        }
    }

    // --- UI LAYOUT ---
    Item {
        id: mainWrapper

        anchors.fill: parent
        opacity: root.introMain
        scale: 0.95 + (0.05 * root.introMain)

        // OUTER ANIMATED BORDER WITH PROPER CLIPPING
        Item {
            anchors.fill: parent

            Shape {
                id: maskRectOuter

                property real arcLines: 2 * Math.PI * r
                property real drawProgress: 0
                property real h: height
                property real inset: (sw / 2) + 0.5
                property real perimeter: straightLines + arcLines
                property real r: 15 - inset

                // Mathematical perimeter
                property real straightLines: 2 * (w - 2 * inset - 2 * r) + 2 * (h - 2 * inset - 2 * r)
                property real sw: 6
                property real w: width

                anchors.fill: parent
                layer.enabled: true
                preferredRendererType: Shape.GeometryRenderer // Fixes lag by hardware accelerating the stroke

                visible: false // Hidden because MultiEffect will render it as a mask

                NumberAnimation on drawProgress {
                    id: chargeAnim

                    duration: 1200 // The time it takes to "charge" the whole wick
                    easing.type: Easing.OutCubic
                    from: 0
                    running: true // Ensure it starts reliably
                    to: maskRectOuter.perimeter
                }

                ShapePath {
                    capStyle: ShapePath.FlatCap
                    dashOffset: (maskRectOuter.perimeter - maskRectOuter.drawProgress) / maskRectOuter.sw

                    // QML Shape dash patterns are measured in units of strokeWidth!
                    dashPattern: [maskRectOuter.perimeter / maskRectOuter.sw, maskRectOuter.perimeter / maskRectOuter.sw]
                    fillColor: "transparent"

                    // Start exactly at Bottom-Left corner, going UP clockwise
                    startX: maskRectOuter.inset
                    startY: maskRectOuter.h - maskRectOuter.inset - maskRectOuter.r
                    strokeColor: "black"
                    strokeWidth: maskRectOuter.sw

                    // 1. Up to top-left corner
                    PathLine {
                        x: maskRectOuter.inset
                        y: maskRectOuter.inset + maskRectOuter.r
                    }
                    // 2. Arc top-left
                    PathArc {
                        direction: PathArc.Clockwise
                        radiusX: maskRectOuter.r
                        radiusY: maskRectOuter.r
                        x: maskRectOuter.inset + maskRectOuter.r
                        y: maskRectOuter.inset
                    }
                    // 3. Right to top-right corner
                    PathLine {
                        x: maskRectOuter.w - maskRectOuter.inset - maskRectOuter.r
                        y: maskRectOuter.inset
                    }
                    // 4. Arc top-right
                    PathArc {
                        direction: PathArc.Clockwise
                        radiusX: maskRectOuter.r
                        radiusY: maskRectOuter.r
                        x: maskRectOuter.w - maskRectOuter.inset
                        y: maskRectOuter.inset + maskRectOuter.r
                    }
                    // 5. Down to bottom-right corner
                    PathLine {
                        x: maskRectOuter.w - maskRectOuter.inset
                        y: maskRectOuter.h - maskRectOuter.inset - maskRectOuter.r
                    }
                    // 6. Arc bottom-right
                    PathArc {
                        direction: PathArc.Clockwise
                        radiusX: maskRectOuter.r
                        radiusY: maskRectOuter.r
                        x: maskRectOuter.w - maskRectOuter.inset - maskRectOuter.r
                        y: maskRectOuter.h - maskRectOuter.inset
                    }
                    // 7. Left to bottom-left corner
                    PathLine {
                        x: maskRectOuter.inset + maskRectOuter.r
                        y: maskRectOuter.h - maskRectOuter.inset
                    }
                    // 8. Arc bottom-left to finish
                    PathArc {
                        direction: PathArc.Clockwise
                        radiusX: maskRectOuter.r
                        radiusY: maskRectOuter.r
                        x: maskRectOuter.inset
                        y: maskRectOuter.h - maskRectOuter.inset - maskRectOuter.r
                    }
                }
            }
            Item {
                id: gradContainer

                anchors.fill: parent
                clip: true // Prevents the rotated gradient bounding box from bulging out the sides!

                visible: false // Hidden for MultiEffect mapping

                Rectangle {
                    anchors.centerIn: parent
                    height: width
                    width: Math.max(parent.width, parent.height) * 2

                    gradient: Gradient {
                        // FIXED: Using securely unpacked color bindings
                        GradientStop {
                            color: root.bc1
                            position: 0.0

                            Behavior on color {
                                ColorAnimation {
                                    duration: 800
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }
                        GradientStop {
                            color: root.bc2
                            position: 0.33

                            Behavior on color {
                                ColorAnimation {
                                    duration: 800
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }
                        GradientStop {
                            color: root.bc3
                            position: 0.66

                            Behavior on color {
                                ColorAnimation {
                                    duration: 800
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }
                        GradientStop {
                            color: root.bc4
                            position: 1.0

                            Behavior on color {
                                ColorAnimation {
                                    duration: 800
                                    easing.type: Easing.InOutQuad
                                }
                            }
                        }
                    }
                    NumberAnimation on rotation {
                        duration: 5000
                        from: 0
                        loops: Animation.Infinite
                        running: true
                        to: 360
                    }
                }
            }
            MultiEffect {
                anchors.fill: parent
                maskEnabled: true
                maskSource: maskRectOuter
                source: gradContainer
            }
        }

        // INNER WINDOW BOX
        Rectangle {
            id: innerBg

            anchors.fill: parent
            anchors.margins: 3
            color: root.base

            // FIX: This forces the entire background to render as a single hardware texture,
            // preventing the UI from dragging and causing "shadow boxes" during the StackView transition!
            layer.enabled: true
            radius: 12

            // Provide a perfectly rounded mask for the inner content
            Rectangle {
                id: innerBgMask

                anchors.fill: parent

                // FIX: Masks in MultiEffect strictly require layer.enabled to correctly capture the radius during scaling!
                layer.enabled: true
                radius: 12
                visible: false
            }
            Item {
                id: bgEffectsLayer

                anchors.fill: parent

                // This correctly clamps the blur and orbit circles to the 12px radius corners
                layer.enabled: true

                layer.effect: MultiEffect {
                    maskEnabled: true
                    maskSource: innerBgMask
                }

                // LAYER 1: Background Blur (Smooth fade-in)
                Image {
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    opacity: status === Image.Ready ? 0.9 : 0.0
                    source: root.musicData.blur ? "file://" + root.musicData.blur : ""

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 800
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                // LAYER 1.5: Flowing Orbits
                Rectangle {
                    color: root.musicData.status === "Playing" ? root.mauve : root.surface2
                    height: width
                    opacity: root.musicData.status === "Playing" ? 0.08 : 0.04
                    radius: width / 2
                    width: parent.width * 0.8
                    x: (parent.width / 2 - width / 2) + Math.cos(root.globalOrbitAngle * 2) * 150
                    y: (parent.height / 2 - height / 2) + Math.sin(root.globalOrbitAngle * 2) * 100

                    Behavior on color {
                        ColorAnimation {
                            duration: 1000
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 1000
                        }
                    }
                }
                Rectangle {
                    color: root.musicData.status === "Playing" ? root.blue : root.surface1
                    height: width
                    opacity: root.musicData.status === "Playing" ? 0.08 : 0.02
                    radius: width / 2
                    width: parent.width * 0.9
                    x: (parent.width / 2 - width / 2) + Math.sin(root.globalOrbitAngle * 1.5) * -150
                    y: (parent.height / 2 - height / 2) + Math.cos(root.globalOrbitAngle * 1.5) * -100

                    Behavior on color {
                        ColorAnimation {
                            duration: 1000
                        }
                    }
                    Behavior on opacity {
                        NumberAnimation {
                            duration: 1000
                        }
                    }
                }
            }

            // LAYER 2: UI Content
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 0

                // ==========================================
                // TOP INFO SECTION
                // ==========================================
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                    spacing: 25

                    // Cover Art Wrapper (Provides Intro slide + Play/Pause elastic zoom)
                    Item {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredHeight: 220
                        Layout.preferredWidth: 220
                        opacity: root.introCover

                        // Elastic response to play/pause state
                        scale: root.musicData.status === "Playing" ? 1.0 : 0.90

                        Behavior on scale {
                            NumberAnimation {
                                duration: 800
                                easing.overshoot: 1.2
                                easing.type: Easing.OutElastic
                            }
                        }
                        transform: Translate {
                            x: -30 * (1 - root.introCover)
                        }

                        Rectangle {
                            anchors.fill: parent
                            border.color: root.musicData.status === "Playing" ? root.mauve : root.overlay0
                            border.width: 4
                            color: root.surface1
                            radius: 110

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 500
                                }
                            }
                            NumberAnimation on rotation {
                                duration: 8000
                                from: 0
                                loops: Animation.Infinite
                                paused: root.musicData.status !== "Playing"
                                running: true
                                to: 360
                            }

                            // Glow Effect surrounding the thumbnail
                            Rectangle {
                                anchors.centerIn: parent
                                color: root.mauve
                                height: parent.height + 20
                                layer.enabled: true
                                opacity: root.musicData.status === "Playing" ? 0.5 : 0.0
                                radius: width / 2
                                width: parent.width + 20
                                z: -1

                                layer.effect: MultiEffect {
                                    blur: 1.0
                                    blurEnabled: true
                                    blurMax: 32
                                }
                                Behavior on opacity {
                                    NumberAnimation {
                                        duration: 500
                                    }
                                }
                            }
                            Item {
                                anchors.fill: parent
                                anchors.margins: 4

                                Image {
                                    id: artImg

                                    anchors.fill: parent
                                    fillMode: Image.PreserveAspectCrop
                                    source: root.musicData.artUrl ? "file://" + root.musicData.artUrl : ""
                                    visible: false
                                }
                                Rectangle {
                                    id: maskRect

                                    anchors.fill: parent
                                    layer.enabled: true
                                    radius: width / 2
                                    visible: false
                                }
                                MultiEffect {
                                    anchors.fill: parent
                                    maskEnabled: true
                                    maskSource: maskRect
                                    opacity: artImg.status === Image.Ready ? 1.0 : 0.0
                                    source: artImg

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 800
                                        }
                                    }
                                }

                                // NEW: Dimmed slightly by tinting with the primary mauve accent, as requested
                                Rectangle {
                                    anchors.fill: parent
                                    color: Qt.rgba(root.mauve.r, root.mauve.g, root.mauve.b, 0.2)
                                    opacity: artImg.status === Image.Ready ? 1.0 : 0.0
                                    radius: width / 2

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 800
                                        }
                                    }
                                }
                                Rectangle {
                                    anchors.centerIn: parent
                                    color: "#000000"
                                    height: 40
                                    opacity: 0.8
                                    radius: 20
                                    width: 40
                                }
                            }
                        }
                    }
                    ColumnLayout {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.fillWidth: true

                        // Elegant slide in for the text info
                        opacity: root.introText
                        spacing: 15

                        transform: Translate {
                            x: 30 * (1 - root.introText)
                        }

                        ColumnLayout {
                            spacing: 6

                            Text {
                                Layout.fillWidth: true
                                color: root.dynamicTextColor
                                elide: Text.ElideRight
                                font.bold: true
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 20
                                maximumLineCount: 2
                                text: root.musicData.title
                                wrapMode: Text.Wrap

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 600
                                    }
                                }
                            }
                            Text {
                                Layout.fillWidth: true
                                color: root.subtext0 // Better matugen match
                                elide: Text.ElideRight
                                font.bold: true
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 14
                                text: root.musicData.artist ? "BY " + root.musicData.artist : ""
                            }
                            RowLayout {
                                spacing: 10

                                Rectangle {
                                    Layout.preferredHeight: 24
                                    Layout.preferredWidth: pillContent.width + 20
                                    color: "#1AFFFFFF"
                                    radius: 4

                                    RowLayout {
                                        id: pillContent

                                        anchors.centerIn: parent
                                        spacing: 6

                                        Text {
                                            color: root.mauve
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 14
                                            text: root.musicData.deviceIcon || "󰓃"
                                        }
                                        Text {
                                            color: root.overlay2
                                            font.bold: true
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 12
                                            text: root.musicData.deviceName || "Speaker"
                                        }
                                    }
                                }
                                Text {
                                    color: root.overlay2 // Better matugen match
                                    font.bold: true
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.italic: true
                                    font.pixelSize: 12
                                    text: "VIA " + (root.musicData.source || "Offline")
                                }
                            }
                        }

                        // Progress Area
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 5

                            Slider {
                                id: progBar

                                Layout.fillWidth: true
                                Layout.preferredHeight: 20
                                from: 0
                                to: 100

                                background: Item {
                                    height: 12
                                    width: progBar.availableWidth
                                    x: progBar.leftPadding
                                    y: progBar.topPadding + (progBar.availableHeight - 12) / 2

                                    // Shadows mimicking the EQ slider background
                                    Rectangle {
                                        anchors.fill: parent
                                        // Dynamic tint: surface0 with 70% opacity for a softer dark look
                                        color: Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.7)
                                        layer.enabled: true
                                        radius: 6

                                        layer.effect: MultiEffect {
                                            shadowBlur: 0.5
                                            shadowColor: "#000000"
                                            shadowEnabled: true
                                            shadowOpacity: 0.9
                                            shadowVerticalOffset: 1
                                        }
                                    }

                                    // Masked Gradient Fill (Completely redesigned for smooth, light, synergistic palette)
                                    Item {
                                        height: parent.height
                                        layer.enabled: true
                                        width: progBar.handle.x - progBar.leftPadding + (progBar.handle.width / 2)

                                        layer.effect: MultiEffect {
                                            maskEnabled: true
                                            maskSource: sliderFillMask
                                        }

                                        Rectangle {
                                            id: sliderFillMask

                                            height: parent.height
                                            layer.enabled: true
                                            radius: 6
                                            visible: false
                                            width: parent.width
                                        }
                                        Rectangle {
                                            height: parent.height
                                            width: 2000
                                            // Sliding the gradient perfectly by exactly half its width (1000px)
                                            x: -(root.catppuccinFlowOffset * 1000)

                                            gradient: Gradient {
                                                orientation: Gradient.Horizontal

                                                // Mathematically precise loops with lighter, cooler colors & theme change support
                                                GradientStop {
                                                    color: Qt.lighter(root.blue, 1.2)
                                                    position: 0.0000

                                                    Behavior on color {
                                                        ColorAnimation {
                                                            duration: 800
                                                        }
                                                    }
                                                }
                                                GradientStop {
                                                    color: Qt.lighter(root.sapphire, 1.15)
                                                    position: 0.1666

                                                    Behavior on color {
                                                        ColorAnimation {
                                                            duration: 800
                                                        }
                                                    }
                                                }
                                                GradientStop {
                                                    color: Qt.lighter(root.mauve, 1.15)
                                                    position: 0.3333

                                                    Behavior on color {
                                                        ColorAnimation {
                                                            duration: 800
                                                        }
                                                    }
                                                }
                                                GradientStop {
                                                    color: Qt.lighter(root.blue, 1.2)
                                                    position: 0.5000

                                                    Behavior on color {
                                                        ColorAnimation {
                                                            duration: 800
                                                        }
                                                    }
                                                }
                                                GradientStop {
                                                    color: Qt.lighter(root.sapphire, 1.15)
                                                    position: 0.6666

                                                    Behavior on color {
                                                        ColorAnimation {
                                                            duration: 800
                                                        }
                                                    }
                                                }
                                                GradientStop {
                                                    color: Qt.lighter(root.mauve, 1.15)
                                                    position: 0.8333

                                                    Behavior on color {
                                                        ColorAnimation {
                                                            duration: 800
                                                        }
                                                    }
                                                }
                                                GradientStop {
                                                    color: Qt.lighter(root.blue, 1.2)
                                                    position: 1.0000

                                                    Behavior on color {
                                                        ColorAnimation {
                                                            duration: 800
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                                handle: Rectangle {
                                    color: root.text
                                    height: 18
                                    implicitHeight: 18
                                    implicitWidth: 18
                                    radius: 9
                                    scale: progBar.pressed ? 1.3 : 1.0
                                    width: 18
                                    x: progBar.leftPadding + progBar.visualPosition * (progBar.availableWidth - width)
                                    y: progBar.topPadding + (progBar.availableHeight - height) / 2

                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 150
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                }
                                Behavior on value {
                                    enabled: !progBar.pressed && !root.userIsSeeking

                                    NumberAnimation {
                                        duration: 400
                                        easing.type: Easing.OutSine
                                    }
                                }

                                onPressedChanged: {
                                    if (pressed) {
                                        root.userIsSeeking = true;
                                        seekDebounceTimer.stop();
                                    } else {
                                        var temp = Object.assign({}, root.musicData);
                                        temp.percent = value;
                                        root.musicData = temp;

                                        var safePlayer = root.musicData.playerName ? root.musicData.playerName : "";
                                        root.execCmd(`$HOME/.config/hypr/scripts/quickshell/music/player_control.sh seek ${value.toFixed(2)} ${root.musicData.length} "${safePlayer}"`);

                                        seekDebounceTimer.restart();
                                    }
                                }

                                Connections {
                                    function onMusicDataChanged() {
                                        if (!progBar.pressed && !root.userIsSeeking) {
                                            if (root.musicData && root.musicData.percent !== undefined) {
                                                var p = Number(root.musicData.percent);
                                                if (!isNaN(p))
                                                    progBar.value = p;
                                            }
                                        }
                                    }

                                    target: root
                                }
                            }
                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    color: root.overlay2
                                    font.bold: true
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 13
                                    text: root.musicData.positionStr || "00:00"
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                                Text {
                                    color: root.overlay2
                                    font.bold: true
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 13
                                    text: root.musicData.lengthStr || "00:00"
                                }
                            }
                        }

                        // Media Controls
                        RowLayout {
                            Layout.alignment: Qt.AlignHCenter
                            spacing: 30

                            MouseArea {
                                cursorShape: Qt.PointingHandCursor
                                height: 30
                                width: 30

                                onClicked: root.execCmd("playerctl previous")

                                Text {
                                    anchors.centerIn: parent
                                    color: parent.pressed ? root.text : root.overlay2
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 24
                                    text: ""
                                }
                            }
                            MouseArea {
                                id: playPauseBtn

                                cursorShape: Qt.PointingHandCursor
                                height: 50
                                width: 50

                                onClicked: {
                                    root.userToggledPlay = true;
                                    playDebounceTimer.restart();
                                    var temp = Object.assign({}, root.musicData);
                                    temp.status = (temp.status === "Playing" ? "Paused" : "Playing");
                                    root.musicData = temp;
                                    root.execCmd("playerctl play-pause");
                                }

                                // Fluid Ripple Animation Element
                                Rectangle {
                                    id: playPulse

                                    function trigger() {
                                        playPulseScaleAnim.restart();
                                        playPulseFadeAnim.restart();
                                    }

                                    anchors.centerIn: parent
                                    color: root.mauve
                                    height: parent.height
                                    opacity: 0
                                    radius: width / 2
                                    scale: 1
                                    width: parent.width

                                    NumberAnimation {
                                        id: playPulseScaleAnim

                                        duration: 500
                                        easing.type: Easing.OutQuart
                                        from: 1.0
                                        property: "scale"
                                        target: playPulse
                                        to: 1.8
                                    }
                                    NumberAnimation {
                                        id: playPulseFadeAnim

                                        duration: 500
                                        easing.type: Easing.OutQuart
                                        from: 0.5
                                        property: "opacity"
                                        target: playPulse
                                        to: 0.0
                                    }
                                }
                                Text {
                                    anchors.centerIn: parent
                                    color: parent.pressed ? root.pink : root.mauve
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 42
                                    scale: parent.pressed ? 0.8 : 1.0
                                    text: root.musicData.status === "Playing" ? "" : ""

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                    Behavior on scale {
                                        NumberAnimation {
                                            duration: 150
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                }
                            }
                            MouseArea {
                                cursorShape: Qt.PointingHandCursor
                                height: 30
                                width: 30

                                onClicked: root.execCmd("playerctl next")

                                Text {
                                    anchors.centerIn: parent
                                    color: parent.pressed ? root.text : root.overlay2
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 24
                                    text: ""
                                }
                            }
                        }
                    }
                }

                // ==========================================
                // SEPARATOR
                // ==========================================
                Rectangle {
                    Layout.bottomMargin: 20
                    Layout.fillWidth: true
                    Layout.preferredHeight: 2
                    Layout.topMargin: 20
                    color: "#1AFFFFFF"
                    opacity: root.introEq
                    radius: 1

                    transform: Translate {
                        y: 15 * (1 - root.introEq)
                    }
                }

                // ==========================================
                // EQUALIZER
                // ==========================================
                ColumnLayout {
                    Layout.fillWidth: true

                    // Elegant slide up for EQ
                    opacity: root.introEq
                    spacing: 15

                    transform: Translate {
                        y: 25 * (1 - root.introEq)
                    }

                    // Header Row
                    RowLayout {
                        Layout.fillWidth: true

                        Text {
                            Layout.fillWidth: true
                            color: root.mauve
                            font.bold: true
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 16
                            text: "Equalizer"
                        }

                        // Redesigned Apply Button
                        Rectangle {
                            Layout.preferredHeight: 28
                            Layout.preferredWidth: applyTxt.width + 30
                            border.color: root.eqData.pending ? root.mauve : root.surface2
                            border.width: 1
                            color: root.eqData.pending ? root.mauve : root.surface1
                            layer.enabled: root.eqData.pending
                            radius: 14

                            Behavior on border.color {
                                ColorAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 300
                                    easing.type: Easing.OutCubic
                                }
                            }
                            layer.effect: MultiEffect {
                                shadowBlur: 0.6
                                shadowColor: root.mauve
                                shadowEnabled: true
                                shadowOpacity: 0.4
                            }

                            Text {
                                id: applyTxt

                                anchors.centerIn: parent
                                color: root.eqData.pending ? root.base : root.subtext0
                                font.bold: true
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 12
                                text: root.eqData.pending ? "Apply" : "Saved"

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 300
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent
                                cursorShape: root.eqData.pending ? Qt.PointingHandCursor : Qt.ArrowCursor

                                onClicked: {
                                    if (root.eqData.pending) {
                                        var temp = Object.assign({}, root.eqData);
                                        temp.pending = false;
                                        root.eqData = temp;

                                        // Blind the polling process to stop it from fetching old data
                                        root.lastEqUpdate = Date.now();

                                        root.triggerEqLightning();
                                        root.execCmd("$HOME/.config/hypr/scripts/quickshell/music/equalizer.sh apply");
                                    }
                                }
                            }
                        }
                        Text {
                            Layout.leftMargin: 15
                            color: root.subtext0
                            font.bold: true
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 14
                            text: root.eqData.preset || "Flat"
                        }
                    }

                    // Eq Sliders Container with Canvas Lightning Overlay
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 180

                        Row {
                            id: eqSliderRow

                            anchors.fill: parent
                            z: 1 // Ensures sliders (and their handles) render over the lightning

                            Repeater {
                                model: [
                                    {
                                        "idx": 1,
                                        "lbl": "31"
                                    },
                                    {
                                        "idx": 2,
                                        "lbl": "63"
                                    },
                                    {
                                        "idx": 3,
                                        "lbl": "125"
                                    },
                                    {
                                        "idx": 4,
                                        "lbl": "250"
                                    },
                                    {
                                        "idx": 5,
                                        "lbl": "500"
                                    },
                                    {
                                        "idx": 6,
                                        "lbl": "1k"
                                    },
                                    {
                                        "idx": 7,
                                        "lbl": "2k"
                                    },
                                    {
                                        "idx": 8,
                                        "lbl": "4k"
                                    },
                                    {
                                        "idx": 9,
                                        "lbl": "8k"
                                    },
                                    {
                                        "idx": 10,
                                        "lbl": "16k"
                                    }
                                ]

                                delegate: Item {
                                    id: sliderDelegate

                                    // Mathematical evaluation mapping to the exact timeline of the strike
                                    property real dist: root.eqLightningProgress - (modelData.idx - 1)
                                    property real flashFade: 0.0
                                    property bool hasFired: false
                                    property real hitPulse: dist >= 0 && dist < 1.0 ? Math.sin((dist) * Math.PI) : 0.0
                                    property real ringPulse: 0.0

                                    // Massive Energy Pulses
                                    property real trackPulse: 0.0

                                    height: eqSliderRow.height
                                    width: eqSliderRow.width / 10

                                    onDistChanged: {
                                        // Reset the fire lock when the animation sweeps past or starts over
                                        if (dist <= 0.05) {
                                            hasFired = false;
                                        } else if (dist > 0.4 && !hasFired) {
                                            // Trigger strictly once per bolt passing over
                                            hasFired = true;
                                            trackPulseAnim.restart();
                                            ringPulseAnim.restart();
                                            flashFadeAnim.restart();
                                        }
                                    }

                                    SequentialAnimation {
                                        id: trackPulseAnim

                                        // Animates the bolt perfectly down the track
                                        NumberAnimation {
                                            duration: 1000
                                            easing.type: Easing.OutQuart
                                            from: 0.0
                                            property: "trackPulse"
                                            target: sliderDelegate
                                            to: 1.0
                                        }
                                    }
                                    SequentialAnimation {
                                        id: ringPulseAnim

                                        // Explodes outward creating a physical shockwave
                                        NumberAnimation {
                                            duration: 1500
                                            easing.type: Easing.OutExpo
                                            from: 1.0
                                            property: "ringPulse"
                                            target: sliderDelegate
                                            to: 0.0
                                        }
                                    }
                                    SequentialAnimation {
                                        id: flashFadeAnim

                                        // Slowly cools the inner track gradient back to normal
                                        NumberAnimation {
                                            duration: 1500
                                            easing.type: Easing.OutSine
                                            from: 1.0
                                            property: "flashFade"
                                            target: sliderDelegate
                                            to: 0.0
                                        }
                                    }
                                    ColumnLayout {
                                        anchors.fill: parent
                                        spacing: 5

                                        Slider {
                                            id: eqSlider

                                            Layout.alignment: Qt.AlignHCenter
                                            Layout.fillHeight: true
                                            from: -12
                                            orientation: Qt.Vertical
                                            stepSize: 1
                                            to: 12

                                            background: Rectangle {
                                                id: trackBg

                                                // Dynamic tint: surface0 with 70% opacity for a softer dark look
                                                color: Qt.rgba(root.surface0.r, root.surface0.g, root.surface0.b, 0.7)
                                                height: eqSlider.availableHeight
                                                implicitHeight: 150
                                                implicitWidth: 10
                                                layer.enabled: true
                                                radius: 5
                                                width: 10
                                                x: eqSlider.leftPadding + (eqSlider.availableWidth - width) / 2
                                                y: eqSlider.topPadding

                                                layer.effect: MultiEffect {
                                                    id: trackEffect

                                                    shadowBlur: 0.5
                                                    shadowColor: "#000000"
                                                    shadowEnabled: true
                                                    shadowOpacity: 0.9
                                                    shadowVerticalOffset: 1
                                                }

                                                // MASSIVE Outer Energy Shockwave Ring
                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    border.color: root.mauve
                                                    border.width: 2 + sliderDelegate.ringPulse * 4
                                                    color: "transparent"
                                                    height: parent.height + 20 + sliderDelegate.ringPulse * 60
                                                    layer.enabled: true
                                                    opacity: sliderDelegate.ringPulse * 0.8 * (1.0 - root.eqLightningFade)
                                                    radius: parent.radius + 10 + sliderDelegate.ringPulse * 20
                                                    width: parent.width + 20 + sliderDelegate.ringPulse * 40
                                                    z: -1

                                                    layer.effect: MultiEffect {
                                                        blur: 1.0
                                                        blurEnabled: true
                                                        blurMax: 32
                                                    }
                                                }

                                                // The Track Fill Base (FIXED THE SQUARE CORNERS ISSUE)
                                                Item {
                                                    height: (1 - eqSlider.visualPosition) * parent.height
                                                    layer.enabled: true
                                                    width: parent.width
                                                    y: eqSlider.visualPosition * parent.height

                                                    layer.effect: MultiEffect {
                                                        maskEnabled: true
                                                        maskSource: eqFillMask
                                                    }

                                                    Rectangle {
                                                        id: eqFillMask

                                                        anchors.fill: parent
                                                        layer.enabled: true
                                                        radius: 5
                                                        visible: false
                                                    }
                                                    Rectangle {
                                                        anchors.fill: parent
                                                        color: root.blue

                                                        // Track Override: Changes entire gradient of track
                                                        Rectangle {
                                                            anchors.fill: parent
                                                            opacity: sliderDelegate.flashFade

                                                            gradient: Gradient {
                                                                orientation: Gradient.Vertical

                                                                GradientStop {
                                                                    color: root.mauve
                                                                    position: 0.0
                                                                }
                                                                GradientStop {
                                                                    color: root.blue
                                                                    position: 0.5
                                                                }
                                                                GradientStop {
                                                                    color: "transparent"
                                                                    position: 1.0
                                                                }
                                                            }
                                                        }

                                                        // The Internal Charging Surge Bolt
                                                        Rectangle {
                                                            height: 80 // Massive physical bolt
                                                            layer.enabled: true
                                                            opacity: Math.sin(sliderDelegate.trackPulse * Math.PI) * 2.0 * (1.0 - root.eqLightningFade)
                                                            width: parent.width
                                                            y: (sliderDelegate.trackPulse * (parent.height + height)) - height

                                                            gradient: Gradient {
                                                                orientation: Gradient.Vertical

                                                                GradientStop {
                                                                    color: "transparent"
                                                                    position: 0.0
                                                                }
                                                                GradientStop {
                                                                    color: root.blue
                                                                    position: 0.2
                                                                }
                                                                GradientStop {
                                                                    color: root.text
                                                                    position: 0.5
                                                                } // Theme integrated bright center
                                                                GradientStop {
                                                                    color: root.mauve
                                                                    position: 0.8
                                                                }
                                                                GradientStop {
                                                                    color: "transparent"
                                                                    position: 1.0
                                                                }
                                                            }
                                                            layer.effect: MultiEffect {
                                                                shadowBlur: 1.0
                                                                shadowColor: root.blue
                                                                shadowEnabled: true
                                                                shadowOpacity: 1.0
                                                            }
                                                        }
                                                    }
                                                }
                                            }
                                            handle: Rectangle {
                                                property var catColors: [root.mauve, root.pink, root.lavender, root.mauve, root.blue]

                                                color: root.text
                                                height: 18
                                                implicitHeight: 18
                                                implicitWidth: 18
                                                radius: 9

                                                // Pop the handle itself slightly as the beam passes
                                                scale: 1.0 + (sliderDelegate.hitPulse * 0.4 * (1.0 - root.eqLightningFade))
                                                width: 18
                                                x: eqSlider.leftPadding + (eqSlider.availableWidth - width) / 2
                                                y: eqSlider.topPadding + eqSlider.visualPosition * (eqSlider.availableHeight - height)

                                                // Core glow flare that cleanly fades out matching the canvas
                                                Rectangle {
                                                    anchors.centerIn: parent
                                                    color: parent.catColors[index % parent.catColors.length]
                                                    height: width
                                                    layer.enabled: true
                                                    opacity: sliderDelegate.hitPulse * (1.0 - root.eqLightningFade)
                                                    radius: width / 2
                                                    width: parent.width + 36 * sliderDelegate.hitPulse // Bigger bloom

                                                    layer.effect: MultiEffect {
                                                        blur: 1.0
                                                        blurEnabled: true
                                                        blurMax: 32
                                                    }
                                                }
                                            }
                                            Behavior on value {
                                                enabled: !eqSlider.pressed

                                                NumberAnimation {
                                                    duration: 350
                                                    easing.type: Easing.OutQuart
                                                }
                                            }

                                            onPressedChanged: {
                                                if (!pressed) {
                                                    var temp = Object.assign({}, root.eqData);
                                                    temp["b" + modelData.idx] = Math.round(value);
                                                    temp.preset = "Custom";
                                                    temp.pending = true;
                                                    root.eqData = temp;

                                                    // Set lock here too to protect individual slider tweaks
                                                    root.lastEqUpdate = Date.now();

                                                    root.execCmd(`$HOME/.config/hypr/scripts/quickshell/music/equalizer.sh set_band ${modelData.idx} ${Math.round(value)}`);
                                                }
                                            }

                                            Connections {
                                                function onEqDataChanged() {
                                                    if (!eqSlider.pressed) {
                                                        if (root.eqData && root.eqData["b" + modelData.idx] !== undefined) {
                                                            var p = Number(root.eqData["b" + modelData.idx]);
                                                            if (!isNaN(p))
                                                                eqSlider.value = p;
                                                        }
                                                    }
                                                }

                                                target: root
                                            }
                                        }
                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            color: root.overlay1
                                            font.bold: true
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 10
                                            text: modelData.lbl
                                        }
                                    }
                                }
                            }
                        }

                        // --- THE FLUID CANVAS LIGHTNING (Optimized for Realism and multiple waves) ---
                        Canvas {
                            id: lightningCanvas

                            anchors.fill: parent

                            // GPU Layer effect to provide bloom WITHOUT locking up the CPU via ctx.shadowBlur
                            layer.enabled: true
                            opacity: 1.0 - root.eqLightningFade

                            // Force hardware FBO backend instead of slow software rendering
                            renderTarget: Canvas.FramebufferObject
                            z: 0 // Draw securely behind the sliders

                            layer.effect: MultiEffect {
                                shadowBlur: 1.0 // 1.0 is max blur in MultiEffect
                                shadowColor: root.mauve
                                shadowEnabled: true
                                shadowHorizontalOffset: 0
                                shadowOpacity: 0.6
                                shadowVerticalOffset: 0
                            }

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.clearRect(0, 0, width, height);

                                if (root.eqLightningProgress <= 0.0 || root.eqLightningFade >= 1.0)
                                    return;

                                var time = Date.now() / 1000;
                                var maxIdx = root.eqLightningProgress; // 0 to 9

                                ctx.lineJoin = "round";
                                ctx.lineCap = "round";

                                // Step 1: Map the spatial coordinates of the 10 handles
                                var pts = [];
                                for (var i = 1; i <= 10; i++) {
                                    var val = root.eqData["b" + i] !== undefined ? Number(root.eqData["b" + i]) : 0;
                                    var norm = 1.0 - ((val + 12) / 24);

                                    // Py uses margins rough mapping to the handles visible track
                                    var py = 10 + norm * (height - 35);
                                    var px = (i - 0.5) * (width / 10);
                                    pts.push({
                                        x: px,
                                        y: py
                                    });
                                }

                                // Step 2: Draw the multi-wave arcing structure
                                // Strand 0: Slow erratic mauve glow/wave
                                // Strand 1: Complex pink glow
                                // Strand 2: Crackling secondary core
                                // Strand 3: Hot white center core
                                for (var s = 0; s < 4; s++) {
                                    ctx.beginPath();
                                    ctx.moveTo(pts[0].x, pts[0].y);

                                    for (var i = 0; i < pts.length - 1; i++) {
                                        if (i > maxIdx)
                                            break; // Stop drawing ahead of current progress

                                        var p1 = pts[i];
                                        var p2 = pts[i + 1];

                                        var fraction = 1.0;
                                        if (maxIdx < i + 1) {
                                            fraction = maxIdx - i;
                                        }

                                        // Subdivision steps create the crackle noise
                                        var steps = s === 3 ? 6 : 8; // Ultra smooth subdivision, s=3 core has less subdiv for straighter look
                                        for (var j = 1; j <= steps; j++) {
                                            var t = j / steps;
                                            if (t > fraction)
                                                t = fraction;

                                            var cx = p1.x + (p2.x - p1.x) * t;
                                            var cy = p1.y + (p2.y - p1.y) * t;

                                            // Wave calculations: create distinct arcs and noise branching
                                            var envelope = Math.sin(t * Math.PI);

                                            // s=3 core noise (straightest) to s=0 outer glow noise (most waves)
                                            var noiseAmpX = s === 3 ? 1.0 : (4 - s) * 4;
                                            var noiseAmpY = s === 3 ? 1.0 : (4 - s) * 5;

                                            // Combine multiple frequencies for complex branching/crackle appearance
                                            // Glow strands (0, 1) also get a sweeping sine wave applied to create distinct separating waves
                                            var sepWaveX = (s < 2) ? Math.sin(time * 3 + i + j + s) * 10 * envelope : 0;
                                            var sepWaveY = (s < 2) ? Math.cos(time * 2.5 + i - j - s) * 15 * envelope : 0;

                                            // Primary erratic crackle noise using high frequency combined sine/cos
                                            var noiseX = Math.sin(time * (10 + s) + i + j) * Math.cos(time * 8 - i + j) * noiseAmpX * envelope * (1 - root.eqLightningFade);
                                            var noiseY = Math.cos(time * (9 - s) + i - j) * Math.sin(time * 7 + i - j) * noiseAmpY * envelope * (1 - root.eqLightningFade);

                                            ctx.lineTo(cx + sepWaveX + noiseX, cy + sepWaveY + noiseY);

                                            if (t === fraction)
                                                break;
                                        }
                                    }

                                    // Step 3: Theme and render each distinct strand
                                    if (s === 0) { // Massive Sweeping Outer Glow (Mauve)
                                        ctx.lineWidth = 20;
                                        ctx.strokeStyle = root.mauve;
                                        ctx.globalAlpha = 0.2;
                                    } else if (s === 1) { // Medium Sweeping Wave (Pink)
                                        ctx.lineWidth = 8;
                                        ctx.strokeStyle = root.pink;
                                        ctx.globalAlpha = 0.45;
                                    } else if (s === 2) { // Tight erratic core (Lavender)
                                        ctx.lineWidth = 3.5;
                                        ctx.strokeStyle = root.lavender;
                                        ctx.globalAlpha = 0.85;
                                    } else if (s === 3) { // Pure white straight hot core - heavily transparent
                                        ctx.lineWidth = 1.0;
                                        ctx.strokeStyle = "#ffffff";
                                        ctx.globalAlpha = 0.1;
                                    }

                                    ctx.stroke();
                                }
                            }

                            Timer {
                                interval: 16 // ~60fps for silky smooth arcs
                                repeat: true
                                running: root.eqLightningFade < 1.0 && root.eqLightningProgress > 0.0

                                onTriggered: lightningCanvas.requestPaint()
                            }
                        }
                    }

                    // Presets Grid
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Repeater {
                                model: ["Flat", "Bass", "Treble", "Vocal"]

                                delegate: PresetButton {
                                    name: modelData
                                }
                            }
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            Repeater {
                                model: ["Pop", "Rock", "Jazz", "Classic"]

                                delegate: PresetButton {
                                    name: modelData
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // --- HELPER COMPONENT FOR PRESETS ---
    component PresetButton: Rectangle {
        property bool isActivePreset: root.eqData && root.eqData.preset === name
        property bool isHovered: hoverMa.containsMouse
        property string name: ""

        Layout.fillWidth: true
        Layout.preferredHeight: 32
        color: isActivePreset ? root.mauve : (isHovered ? root.surface1 : "#BF1E1E2E")
        radius: 8
        scale: isHovered && !isActivePreset ? 1.05 : 1.0

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

        Text {
            anchors.centerIn: parent
            color: parent.isActivePreset ? root.base : (parent.isHovered ? root.text : root.subtext0)
            font.bold: true
            font.family: "FiraCode Nerd Font Mono"
            font.pixelSize: 12
            text: parent.name

            Behavior on color {
                ColorAnimation {
                    duration: 200
                }
            }
        }
        MouseArea {
            id: hoverMa

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            hoverEnabled: true

            onClicked: root.applyPresetOptimistically(parent.name)
        }
    }
}
