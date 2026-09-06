import QtQuick
import QtQuick.Layouts
import QtQuick.Effects
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window

    // -------------------------------------------------------------------------
    // STATE & MATH
    // -------------------------------------------------------------------------
    property int activeEditIndex: 0
    property bool applyHovered: false
    property bool applyPressed: false
    readonly property color base: _theme.base
    readonly property color blue: _theme.blue
    readonly property color crust: _theme.crust
    property real currentSimH: monitorsModel.count > 0 ? monitorsModel.get(0).resH : 1080
    property real currentSimW: monitorsModel.count > 0 ? monitorsModel.get(0).resW : 1920
    property real globalOrbitAngle: 0
    readonly property color green: _theme.green
    property real introState: 0.0
    readonly property color mantle: _theme.mantle
    readonly property color mauve: _theme.mauve

    // Wayland Absolute Anchor tracking
    property int originalLayoutOriginX: 0
    property int originalLayoutOriginY: 0
    readonly property color overlay0: _theme.overlay0
    readonly property color peach: _theme.peach
    readonly property color pink: _theme.pink
    readonly property color red: _theme.red
    readonly property color sapphire: _theme.sapphire
    property color selectedRateAccent: window.blue

    // Replaced hardcoded accents with dynamic defaults
    property color selectedResAccent: window.mauve

    // Dynamically tracks whichever monitor is NOT currently selected
    property int stationaryIndex: monitorsModel.count === 2 ? (activeEditIndex === 0 ? 1 : 0) : 0
    readonly property color subtext0: _theme.subtext0
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color teal: _theme.teal
    readonly property color text: _theme.text
    property real uiScale: 0.10
    readonly property color yellow: _theme.yellow

    function forceLayoutUpdate() {
        if (monitorsModel.count === 2) {
            let mIdx = window.activeEditIndex;
            let sIdx = window.stationaryIndex;

            let sModel = monitorsModel.get(sIdx);
            let mModel = monitorsModel.get(mIdx);

            let sW = (sModel.resW / sModel.sysScale) * window.uiScale;
            let sH = (sModel.resH / sModel.sysScale) * window.uiScale;
            let mW = (mModel.resW / mModel.sysScale) * window.uiScale;
            let mH = (mModel.resH / mModel.sysScale) * window.uiScale;

            let snapped = window.getPerimeterSnap(mModel.uiX, mModel.uiY, sModel.uiX, sModel.uiY, sW, sH, mW, mH, 20);

            monitorsModel.setProperty(mIdx, "uiX", snapped.x);
            monitorsModel.setProperty(mIdx, "uiY", snapped.y);
        }
    }

    // MATHEMATICAL PERIMETER GLUE: Forces a proposed coordinate to perfectly touch the stationary monitor
    function getPerimeterSnap(pX, pY, sX, sY, sW, sH, mW, mH, snapT) {
        let edges = [
            {
                x1: sX - mW,
                x2: sX + sW,
                y1: sY - mH,
                y2: sY - mH
            } // Top Edge
            ,
            {
                x1: sX - mW,
                x2: sX + sW,
                y1: sY + sH,
                y2: sY + sH
            } // Bottom Edge
            ,
            {
                x1: sX - mW,
                x2: sX - mW,
                y1: sY - mH,
                y2: sY + sH
            } // Left Edge
            ,
            {
                x1: sX + sW,
                x2: sX + sW,
                y1: sY - mH,
                y2: sY + sH
            }  // Right Edge
        ];

        let bestX = pX;
        let bestY = pY;
        let minDist = 999999;

        for (let i = 0; i < 4; i++) {
            let e = edges[i];

            let cx = Math.max(e.x1, Math.min(pX, e.x2));
            let cy = Math.max(e.y1, Math.min(pY, e.y2));

            if (Math.abs(cx - sX) < snapT)
                cx = sX;
            if (Math.abs(cx - (sX + sW - mW)) < snapT)
                cx = sX + sW - mW;
            if (Math.abs(cx - (sX + sW / 2 - mW / 2)) < snapT)
                cx = sX + sW / 2 - mW / 2;

            if (Math.abs(cy - sY) < snapT)
                cy = sY;
            if (Math.abs(cy - (sY + sH - mH)) < snapT)
                cy = sY + sH - mH;
            if (Math.abs(cy - (sY + sH / 2 - mH / 2)) < snapT)
                cy = sY + sH / 2 - mH / 2;

            let dist = Math.hypot(pX - cx, pY - cy);
            if (dist < minDist) {
                minDist = dist;
                bestX = cx;
                bestY = cy;
            }
        }
        return {
            x: bestX,
            y: bestY
        };
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
    onActiveEditIndexChanged: {
        menuTransitionAnim.restart();
    }

    // -------------------------------------------------------------------------
    // COLORS (Dynamic Matugen Palette)
    // -------------------------------------------------------------------------
    MatugenColors {
        id: _theme
    }
    ListModel {
        id: monitorsModel
    }
    Timer {
        id: delayedLayoutUpdate

        interval: 10
        repeat: false
        running: false

        onTriggered: window.forceLayoutUpdate()
    }

    // -------------------------------------------------------------------------
    // NATIVE SYSTEM PROCESSES
    // -------------------------------------------------------------------------
    Process {
        id: displayPoller

        command: ["hyprctl", "monitors", "-j"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let data = JSON.parse(this.text.trim());
                    monitorsModel.clear();

                    let minX = 999999, minY = 999999;

                    for (let i = 0; i < data.length; i++) {
                        if (data[i].x < minX)
                            minX = data[i].x;
                        if (data[i].y < minY)
                            minY = data[i].y;
                    }

                    window.originalLayoutOriginX = minX !== 999999 ? minX : 0;
                    window.originalLayoutOriginY = minY !== 999999 ? minY : 0;

                    for (let i = 0; i < data.length; i++) {
                        let scl = data[i].scale !== undefined ? data[i].scale : 1.0;
                        let normalizedX = (data[i].x - minX) * window.uiScale;
                        let normalizedY = (data[i].y - minY) * window.uiScale;

                        monitorsModel.append({
                            name: data[i].name,
                            resW: data[i].width,
                            resH: data[i].height,
                            sysScale: scl,
                            rate: Math.round(data[i].refreshRate).toString(),
                            uiX: normalizedX,
                            uiY: normalizedY
                        });

                        if (data[i].focused)
                            window.activeEditIndex = i;
                    }

                    window.forceLayoutUpdate();
                } catch (e) {}
            }
        }
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
                color: window.selectedResAccent
                height: width
                opacity: 0.04
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
                color: window.selectedRateAccent
                height: width
                opacity: 0.04
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

            // ==========================================
            // LEFT SIDE VISUAL AREA
            // ==========================================
            Item {
                id: leftVisualArea

                anchors.left: parent.left
                anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                height: 300
                width: 380

                // --------------------------------------------------
                // MODE 1: SINGLE MONITOR
                // --------------------------------------------------
                Item {
                    anchors.fill: parent
                    visible: monitorsModel.count === 1

                    Item {
                        id: singleMonitorZoom

                        anchors.centerIn: parent
                        height: 280
                        scale: Math.min(1.0, 2200 / window.currentSimW)
                        width: 380

                        Behavior on scale {
                            NumberAnimation {
                                duration: 600
                                easing.type: Easing.OutQuint
                            }
                        }

                        Rectangle {
                            id: deskSurface

                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.top: standBase.bottom
                            border.color: window.surface0
                            border.width: 1
                            color: window.mantle
                            height: 14
                            radius: 6
                            width: 1000

                            Rectangle {
                                anchors.left: parent.left
                                anchors.leftMargin: 100
                                anchors.top: parent.bottom
                                anchors.topMargin: -5
                                color: window.crust
                                height: 350
                                radius: 4
                                width: 24
                                z: -1
                            }
                            Rectangle {
                                anchors.right: parent.right
                                anchors.rightMargin: 100
                                anchors.top: parent.bottom
                                anchors.topMargin: -5
                                color: window.crust
                                height: 350
                                radius: 4
                                width: 24
                                z: -1
                            }
                        }
                        Rectangle {
                            id: standBase

                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 20
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: window.surface1
                            height: 8
                            radius: 4
                            width: 130
                        }
                        Rectangle {
                            id: standNeck

                            anchors.bottom: standBase.top
                            anchors.horizontalCenter: parent.horizontalCenter
                            color: window.surface0
                            height: 70
                            width: 34

                            Rectangle {
                                anchors.centerIn: parent
                                color: window.base
                                height: 30
                                radius: 5
                                width: 10
                            }
                        }
                        Rectangle {
                            id: screenBezel

                            anchors.bottom: standNeck.top
                            anchors.bottomMargin: -10
                            anchors.horizontalCenter: parent.horizontalCenter
                            border.color: window.surface2
                            border.width: 2
                            color: window.crust
                            height: 90 + (90 * (window.currentSimH / 1080))
                            radius: 12
                            width: 140 + (180 * (window.currentSimW / 1920))

                            Behavior on height {
                                NumberAnimation {
                                    duration: 600
                                    easing.type: Easing.OutQuint
                                }
                            }
                            Behavior on width {
                                NumberAnimation {
                                    duration: 600
                                    easing.type: Easing.OutQuint
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                anchors.margins: 10
                                clip: true
                                color: window.surface0
                                radius: 6

                                gradient: Gradient {
                                    orientation: Gradient.Vertical

                                    GradientStop {
                                        color: Qt.tint(window.surface0, Qt.alpha(window.selectedResAccent, 0.15))
                                        position: 0.0

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 400
                                            }
                                        }
                                    }
                                    GradientStop {
                                        color: Qt.tint(window.surface0, Qt.alpha(window.selectedRateAccent, 0.1))
                                        position: 1.0

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 400
                                            }
                                        }
                                    }
                                }

                                Grid {
                                    anchors.centerIn: parent
                                    columns: 15
                                    rows: 10
                                    spacing: 20

                                    Repeater {
                                        model: 150

                                        Rectangle {
                                            color: Qt.alpha(window.text, 0.1)
                                            height: 2
                                            radius: 1
                                            width: 2
                                        }
                                    }
                                }
                                Item {
                                    anchors.centerIn: parent
                                    scale: 1.0 / singleMonitorZoom.scale

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            color: window.selectedResAccent
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 38
                                            text: "󰍹"

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 400
                                                }
                                            }
                                        }
                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            color: window.text
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 16
                                            font.weight: Font.Bold
                                            text: monitorsModel.count > 0 ? monitorsModel.get(0).name : "Unknown"
                                        }
                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            color: window.subtext0
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 12
                                            text: window.currentSimW + "x" + window.currentSimH + " @ " + (monitorsModel.count > 0 ? monitorsModel.get(0).rate : "60") + "Hz"
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // --------------------------------------------------
                // MODE 2: MULTI-MONITOR
                // --------------------------------------------------
                Item {
                    anchors.fill: parent
                    visible: monitorsModel.count > 1

                    Item {
                        id: multiMonitorView

                        // Centering math: Keep the bounding box perfectly centered in the 380x280 view
                        property real offsetX: {
                            if (monitorsModel.count < 2)
                                return 0;
                            let sModel = monitorsModel.get(window.stationaryIndex);
                            let mModel = monitorsModel.get(window.activeEditIndex);
                            let sW = (sModel.resW / sModel.sysScale) * window.uiScale;
                            let mW = (mModel.resW / mModel.sysScale) * window.uiScale;

                            let minX = Math.min(sModel.uiX, mModel.uiX);
                            let maxX = Math.max(sModel.uiX + sW, mModel.uiX + mW);
                            let centerX = minX + (maxX - minX) / 2;

                            return 190 - (centerX * targetScale);
                        }
                        property real offsetY: {
                            if (monitorsModel.count < 2)
                                return 0;
                            let sModel = monitorsModel.get(window.stationaryIndex);
                            let mModel = monitorsModel.get(window.activeEditIndex);
                            let sH = (sModel.resH / sModel.sysScale) * window.uiScale;
                            let mH = (mModel.resH / mModel.sysScale) * window.uiScale;

                            let minY = Math.min(sModel.uiY, mModel.uiY);
                            let maxY = Math.max(sModel.uiY + sH, mModel.uiY + mH);
                            let centerY = minY + (maxY - minY) / 2;

                            return 140 - (centerY * targetScale);
                        }

                        // Perfect mathematical scale: Centers the Bounding Box of both monitors
                        property real targetScale: {
                            if (monitorsModel.count < 2)
                                return 1.0;
                            let sModel = monitorsModel.get(window.stationaryIndex);
                            let mModel = monitorsModel.get(window.activeEditIndex);
                            let sW = (sModel.resW / sModel.sysScale) * window.uiScale;
                            let sH = (sModel.resH / sModel.sysScale) * window.uiScale;
                            let mW = (mModel.resW / mModel.sysScale) * window.uiScale;
                            let mH = (mModel.resH / mModel.sysScale) * window.uiScale;

                            let minX = Math.min(sModel.uiX, mModel.uiX);
                            let minY = Math.min(sModel.uiY, mModel.uiY);
                            let maxX = Math.max(sModel.uiX + sW, mModel.uiX + mW);
                            let maxY = Math.max(sModel.uiY + sH, mModel.uiY + mH);

                            let requiredW = (maxX - minX) + 80;
                            let requiredH = (maxY - minY) + 80;

                            return Math.min(1.8, Math.min(340 / requiredW, 240 / requiredH));
                        }

                        anchors.centerIn: parent
                        clip: true
                        height: 280
                        width: 380

                        Grid {
                            anchors.centerIn: parent
                            columns: 34
                            rows: 25
                            spacing: 18

                            Repeater {
                                model: 850

                                Rectangle {
                                    color: Qt.alpha(window.text, 0.1)
                                    height: 2
                                    radius: 1
                                    width: 2
                                }
                            }
                        }
                        Item {
                            id: transformNode

                            scale: multiMonitorView.targetScale
                            transformOrigin: Item.TopLeft
                            x: multiMonitorView.offsetX
                            y: multiMonitorView.offsetY

                            Behavior on scale {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.OutQuint
                                }
                            }
                            Behavior on x {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.OutQuint
                                }
                            }
                            Behavior on y {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.OutQuint
                                }
                            }

                            Repeater {
                                id: monitorRepeater

                                model: monitorsModel

                                Item {
                                    property bool isActive: window.activeEditIndex === index

                                    // THE VISIBLE SNAPPED MONITOR CARD
                                    Rectangle {
                                        id: monitorCard

                                        border.color: isActive ? window.selectedResAccent : window.surface2
                                        border.width: isActive ? 2 : 1
                                        color: isActive ? window.surface1 : window.crust
                                        height: (model.resH / model.sysScale) * window.uiScale
                                        radius: 8
                                        width: (model.resW / model.sysScale) * window.uiScale
                                        x: model.uiX
                                        y: model.uiY
                                        z: isActive ? 5 : 0

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
                                        Behavior on height {
                                            NumberAnimation {
                                                duration: 400
                                                easing.type: Easing.OutQuint
                                            }
                                        }
                                        Behavior on width {
                                            NumberAnimation {
                                                duration: 400
                                                easing.type: Easing.OutQuint
                                            }
                                        }
                                        Behavior on x {
                                            NumberAnimation {
                                                duration: 300
                                                easing.type: Easing.OutQuint
                                            }
                                        }
                                        Behavior on y {
                                            NumberAnimation {
                                                duration: 300
                                                easing.type: Easing.OutQuint
                                            }
                                        }

                                        Item {
                                            property real idealScale: Math.min(1.2, parent.width / 110, parent.height / 80) / transformNode.scale
                                            property real maxPhysicalScale: Math.min((parent.width * 0.9) / width, (parent.height * 0.9) / height)

                                            anchors.centerIn: parent
                                            height: 80
                                            scale: Math.min(idealScale, maxPhysicalScale)
                                            width: 110

                                            ColumnLayout {
                                                anchors.centerIn: parent
                                                spacing: 2

                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    color: isActive ? window.selectedResAccent : window.text
                                                    font.family: "FiraCode Nerd Font Mono"
                                                    font.pixelSize: 32
                                                    text: "󰍹"

                                                    Behavior on color {
                                                        ColorAnimation {
                                                            duration: 300
                                                        }
                                                    }
                                                }
                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    color: window.text
                                                    font.family: "FiraCode Nerd Font Mono"
                                                    font.pixelSize: 13
                                                    font.weight: Font.Black
                                                    text: model.name
                                                }
                                                Text {
                                                    Layout.alignment: Qt.AlignHCenter
                                                    color: window.subtext0
                                                    font.family: "FiraCode Nerd Font Mono"
                                                    font.pixelSize: 10
                                                    text: model.resW + "x" + model.resH + " @ " + model.rate + "Hz"
                                                }
                                            }
                                        }
                                    }

                                    // THE INVISIBLE GHOST DRAGGER
                                    Item {
                                        id: ghostDrag

                                        height: monitorCard.height
                                        width: monitorCard.width
                                        x: model.uiX
                                        y: model.uiY
                                        z: isActive ? 10 : 1

                                        MouseArea {
                                            id: ghostMa

                                            anchors.fill: parent
                                            drag.axis: Drag.XAndYAxis
                                            drag.target: ghostDrag

                                            onPositionChanged: {
                                                if (drag.active && monitorsModel.count === 2) {
                                                    let sIdx = window.stationaryIndex;
                                                    let sModel = monitorsModel.get(sIdx);

                                                    let sW = (sModel.resW / sModel.sysScale) * window.uiScale;
                                                    let sH = (sModel.resH / sModel.sysScale) * window.uiScale;
                                                    let mW = monitorCard.width;
                                                    let mH = monitorCard.height;

                                                    // Hard boundary limit: Stop the ghost from flying infinitely off the canvas
                                                    let padding = 40;
                                                    let minX = sModel.uiX - mW - padding;
                                                    let maxX = sModel.uiX + sW + padding;
                                                    let minY = sModel.uiY - mH - padding;
                                                    let maxY = sModel.uiY + sH + padding;

                                                    ghostDrag.x = Math.max(minX, Math.min(ghostDrag.x, maxX));
                                                    ghostDrag.y = Math.max(minY, Math.min(ghostDrag.y, maxY));

                                                    let snapped = window.getPerimeterSnap(ghostDrag.x, ghostDrag.y, sModel.uiX, sModel.uiY, sW, sH, mW, mH, 20);

                                                    monitorsModel.setProperty(index, "uiX", snapped.x);
                                                    monitorsModel.setProperty(index, "uiY", snapped.y);
                                                }
                                            }
                                            onPressed: {
                                                window.activeEditIndex = index;
                                                ghostDrag.x = model.uiX;
                                                ghostDrag.y = model.uiY;
                                            }
                                            onReleased: {
                                                ghostDrag.x = model.uiX;
                                                ghostDrag.y = model.uiY;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================================
            // INTERACTIVE SELECTION GRIDS
            // ==========================================
            Item {
                anchors.left: leftVisualArea.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 30
                anchors.verticalCenter: parent.verticalCenter
                height: 310

                SequentialAnimation {
                    id: menuTransitionAnim

                    ParallelAnimation {
                        ScaleAnimator {
                            duration: 200
                            easing.type: Easing.OutSine
                            from: 0.99
                            target: rightSideContainer
                            to: 1.0
                        }
                        NumberAnimation {
                            duration: 250
                            easing.type: Easing.OutQuad
                            from: 0.05
                            property: "opacity"
                            target: highlightFlash
                            to: 0.0
                        }
                    }
                }
                Rectangle {
                    id: highlightFlash

                    anchors.fill: rightSideContainer
                    anchors.margins: -10
                    color: window.selectedResAccent
                    opacity: 0.0
                    radius: 12
                }
                ColumnLayout {
                    id: rightSideContainer

                    anchors.fill: parent
                    spacing: 12

                    // --- RESOLUTION CARDS SECTION ---
                    GridLayout {
                        Layout.fillWidth: true
                        columnSpacing: 10
                        columns: 2
                        rowSpacing: 10

                        Repeater {
                            model: [
                                {
                                    resW: 3840,
                                    resH: 2160,
                                    label: "4K",
                                    accent: window.pink
                                },
                                {
                                    resW: 2560,
                                    resH: 1440,
                                    label: "QHD",
                                    accent: window.mauve
                                },
                                {
                                    resW: 1920,
                                    resH: 1080,
                                    label: "FHD",
                                    accent: window.blue
                                },
                                {
                                    resW: 1600,
                                    resH: 900,
                                    label: "HD+",
                                    accent: window.teal
                                },
                                {
                                    resW: 1366,
                                    resH: 768,
                                    label: "WXGA",
                                    accent: window.yellow
                                },
                                {
                                    resW: 1280,
                                    resH: 720,
                                    label: "HD",
                                    accent: window.peach
                                },
                                {
                                    resW: 1024,
                                    resH: 768,
                                    label: "XGA",
                                    accent: window.green
                                },
                                {
                                    resW: 800,
                                    resH: 600,
                                    label: "SVGA",
                                    accent: window.red
                                }
                            ]

                            delegate: Rectangle {
                                property color accentColor: modelData.accent
                                property bool isSel: {
                                    if (monitorsModel.count === 0)
                                        return false;
                                    let activeMon = monitorsModel.get(window.activeEditIndex);
                                    return activeMon.resW === modelData.resW && activeMon.resH === modelData.resH;
                                }

                                Layout.fillWidth: true
                                Layout.preferredHeight: 48
                                border.color: isSel ? accentColor : (resMa.containsMouse ? window.surface1 : "transparent")
                                border.width: isSel ? 2 : 1
                                color: isSel ? Qt.alpha(accentColor, 0.15) : (resMa.containsMouse ? window.surface0 : window.mantle)
                                radius: 12
                                scale: resMa.pressed ? 0.96 : 1.0

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
                                        duration: 150
                                        easing.type: Easing.OutSine
                                    }
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 8

                                    Text {
                                        color: isSel ? accentColor : window.text
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 16
                                        font.weight: isSel ? Font.Black : Font.Bold
                                        text: modelData.label

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 200
                                            }
                                        }
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        color: isSel ? window.text : window.overlay0
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 12
                                        text: modelData.resW + "x" + modelData.resH

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 200
                                            }
                                        }
                                    }
                                }
                                MouseArea {
                                    id: resMa

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    onClicked: {
                                        if (monitorsModel.count > 0) {
                                            window.selectedResAccent = accentColor;
                                            monitorsModel.setProperty(window.activeEditIndex, "resW", modelData.resW);
                                            monitorsModel.setProperty(window.activeEditIndex, "resH", modelData.resH);
                                            delayedLayoutUpdate.restart();
                                        }
                                    }
                                }
                            }
                        }
                    }
                    Item {
                        Layout.preferredHeight: 15
                    }

                    // --- REFRESH RATE SLIDER SECTION ---
                    Item {
                        id: sliderContainer

                        property int currentIndex: {
                            if (monitorsModel.count === 0)
                                return 0;
                            let currentVal = parseInt(monitorsModel.get(window.activeEditIndex).rate) || 60;
                            let closestIdx = 0;
                            let minDiff = 9999;
                            for (let i = 0; i < rates.length; i++) {
                                let diff = Math.abs(rates[i] - currentVal);
                                if (diff < minDiff) {
                                    minDiff = diff;
                                    closestIdx = i;
                                }
                            }
                            return closestIdx;
                        }
                        property var rateColors: [window.red, window.mauve, window.blue, window.sapphire, window.teal, window.green]
                        property var rates: [60, 75, 100, 120, 144, 240]
                        property real visualPct: currentIndex / (rates.length - 1)

                        Layout.fillWidth: true
                        Layout.leftMargin: 10
                        Layout.preferredHeight: 50
                        Layout.rightMargin: 10

                        onCurrentIndexChanged: {
                            if (!sliderMa.pressed)
                                visualPct = currentIndex / (rates.length - 1);
                        }

                        Rectangle {
                            id: track

                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.verticalCenterOffset: -10
                            border.color: window.crust
                            border.width: 1
                            color: window.mantle
                            height: 12
                            radius: 6

                            Rectangle {
                                color: window.selectedRateAccent
                                height: parent.height
                                radius: parent.radius
                                width: knob.x + knob.width / 2

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }
                            }
                        }
                        Repeater {
                            model: sliderContainer.rates.length

                            Item {
                                x: (index / (sliderContainer.rates.length - 1)) * track.width
                                y: track.y + 20

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    color: sliderContainer.currentIndex === index ? window.selectedRateAccent : window.overlay0
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 13
                                    font.weight: sliderContainer.currentIndex === index ? Font.Bold : Font.Normal
                                    text: sliderContainer.rates[index]

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                            }
                        }
                        Rectangle {
                            id: knob

                            anchors.verticalCenter: track.verticalCenter
                            border.color: Qt.alpha(window.selectedRateAccent, 0.3)
                            border.width: sliderMa.containsMouse ? 4 : 0
                            color: sliderMa.containsPress ? window.selectedRateAccent : window.text
                            height: 24
                            radius: 12
                            width: 24
                            x: (sliderContainer.visualPct * track.width) - width / 2

                            Behavior on border.width {
                                NumberAnimation {
                                    duration: 150
                                }
                            }
                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                            Behavior on x {
                                enabled: !sliderMa.pressed

                                NumberAnimation {
                                    duration: 250
                                    easing.type: Easing.OutCubic
                                }
                            }
                        }
                        MouseArea {
                            id: sliderMa

                            function updateSelection(mouseX, snapToGrid) {
                                if (monitorsModel.count === 0)
                                    return;
                                let pct = (mouseX - track.x) / track.width;
                                pct = Math.max(0, Math.min(1, pct));
                                let idx = Math.round(pct * (sliderContainer.rates.length - 1));

                                if (snapToGrid) {
                                    sliderContainer.visualPct = idx / (sliderContainer.rates.length - 1);
                                } else {
                                    sliderContainer.visualPct = pct;
                                }

                                monitorsModel.setProperty(window.activeEditIndex, "rate", sliderContainer.rates[idx].toString());
                                window.selectedRateAccent = sliderContainer.rateColors[idx];
                            }

                            anchors.fill: parent
                            anchors.margins: -15
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onCanceled: () => sliderContainer.visualPct = sliderContainer.currentIndex / (sliderContainer.rates.length - 1)
                            onPositionChanged: mouse => {
                                if (pressed)
                                    updateSelection(mouse.x, false);
                            }
                            onPressed: mouse => updateSelection(mouse.x, false)
                            onReleased: mouse => updateSelection(mouse.x, true)
                        }
                    }
                    Item {
                        Layout.fillHeight: true
                    }
                }
            }

            // ==========================================
            // FLOATING APPLY BUTTON
            // ==========================================
            Item {
                id: applyButtonContainer

                anchors.bottom: parent.bottom
                anchors.margins: 30
                anchors.right: parent.right
                height: 50
                width: 170

                MultiEffect {
                    anchors.fill: applyBtn
                    shadowBlur: window.applyHovered ? 1.2 : 0.6
                    shadowColor: window.selectedRateAccent
                    shadowEnabled: true
                    shadowOpacity: window.applyHovered ? 0.6 : 0.2
                    shadowVerticalOffset: 4
                    source: applyBtn
                    z: -1

                    Behavior on shadowBlur {
                        NumberAnimation {
                            duration: 300
                        }
                    }
                    Behavior on shadowColor {
                        ColorAnimation {
                            duration: 400
                        }
                    }
                    Behavior on shadowOpacity {
                        NumberAnimation {
                            duration: 300
                        }
                    }
                }
                Rectangle {
                    id: applyBtn

                    anchors.fill: parent
                    radius: 25
                    scale: window.applyPressed ? 0.94 : (window.applyHovered ? 1.04 : 1.0)

                    gradient: Gradient {
                        orientation: Gradient.Horizontal

                        GradientStop {
                            color: window.selectedResAccent
                            position: 0.0

                            Behavior on color {
                                ColorAnimation {
                                    duration: 400
                                }
                            }
                        }
                        GradientStop {
                            color: window.selectedRateAccent
                            position: 1.0

                            Behavior on color {
                                ColorAnimation {
                                    duration: 400
                                }
                            }
                        }
                    }
                    Behavior on scale {
                        NumberAnimation {
                            duration: 300
                            easing.type: Easing.OutBack
                        }
                    }

                    Rectangle {
                        id: flashRect

                        anchors.fill: parent
                        color: window.text
                        opacity: 0.0
                        radius: 25

                        PropertyAnimation on opacity {
                            id: applyFlashAnim

                            duration: 400
                            easing.type: Easing.OutExpo
                            to: 0.0
                        }
                    }
                    RowLayout {
                        anchors.centerIn: parent
                        spacing: 8

                        Text {
                            color: window.crust
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 20
                            text: "󰸵"
                        }
                        Text {
                            color: window.crust
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 14
                            font.weight: Font.Black
                            text: monitorsModel.count > 1 ? "Apply All" : "Apply"
                        }
                    }
                }
                MouseArea {
                    id: applyMa

                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    z: 10

                    onCanceled: window.applyPressed = false
                    onClicked: {
                        flashRect.opacity = 0.8;
                        applyFlashAnim.start();

                        if (monitorsModel.count === 0)
                            return;

                        if (monitorsModel.count === 1) {
                            let mon = monitorsModel.get(0);
                            let monitorStr = mon.name + "," + mon.resW + "x" + mon.resH + "@" + mon.rate + ",auto," + mon.sysScale;
                            Quickshell.execDetached(["notify-send", "Display Update", "Applied: " + mon.resW + "x" + mon.resH + " @ " + mon.rate + "Hz"]);
                            Quickshell.execDetached(["sh", "-c", "hyprctl keyword monitor " + monitorStr]);
                        } else {
                            let rects = [];
                            for (let i = 0; i < monitorsModel.count; i++) {
                                let m = monitorsModel.get(i);
                                let layoutW = Math.round(m.resW / m.sysScale);
                                let layoutH = Math.round(m.resH / m.sysScale);
                                let rawX = m.uiX / window.uiScale;
                                let rawY = m.uiY / window.uiScale;
                                rects.push({
                                    x: rawX,
                                    y: rawY,
                                    w: layoutW,
                                    h: layoutH,
                                    resW: m.resW,
                                    resH: m.resH,
                                    name: m.name,
                                    rate: m.rate,
                                    sysScale: m.sysScale
                                });
                            }

                            if (rects.length === 2) {
                                let r0 = rects[0];
                                let r1 = rects[1];

                                let snapped = window.getPerimeterSnap(r1.x, r1.y, r0.x, r0.y, r0.w, r0.h, r1.w, r1.h, 200);

                                r1.x = Math.round(snapped.x);
                                r1.y = Math.round(snapped.y);
                            }

                            let finalMinX = 999999;
                            let finalMinY = 999999;
                            for (let i = 0; i < rects.length; i++) {
                                if (rects[i].x < finalMinX)
                                    finalMinX = rects[i].x;
                                if (rects[i].y < finalMinY)
                                    finalMinY = rects[i].y;
                            }

                            let batchCmds = [];
                            let summaryString = "";
                            for (let i = 0; i < rects.length; i++) {
                                let r = rects[i];

                                r.x = Math.round((r.x - finalMinX) + window.originalLayoutOriginX);
                                r.y = Math.round((r.y - finalMinY) + window.originalLayoutOriginY);

                                let monitorStr = r.name + "," + r.resW + "x" + r.resH + "@" + r.rate + "," + r.x + "x" + r.y + "," + r.sysScale;
                                batchCmds.push("keyword monitor " + monitorStr);
                                summaryString += r.name + " ";
                            }

                            let fullCommand = "hyprctl --batch '" + batchCmds.join(" ; ") + "'";
                            Quickshell.execDetached(["sh", "-c", fullCommand]);
                            Quickshell.execDetached(["notify-send", "Display Update", "Applied layout for: " + summaryString]);
                        }
                    }
                    onEntered: window.applyHovered = true
                    onExited: window.applyHovered = false
                    onPressed: window.applyPressed = true
                    onReleased: window.applyPressed = false
                }
            }
        }
    }
}
