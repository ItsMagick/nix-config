import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtCore
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window

    property int activeHourIndex: {
        if (window.weatherView !== 0 || !window.weatherData || !window.weatherData.forecast || !window.weatherData.forecast[0] || !window.weatherData.forecast[0].hourly)
            return -1;

        let ch = window.currentTime.getHours();
        let hrArr = window.weatherData.forecast[0].hourly.slice(0, 8);
        let bestIdx = -1;
        let minDiff = 999;

        for (let i = 0; i < hrArr.length; i++) {
            let timeStr = hrArr[i].time || "00:00";
            let h = parseInt(timeStr.split(":")[0]);
            let diff = Math.abs(h - ch);
            if (diff < minDiff) {
                minDiff = diff;
                bestIdx = i;
            }
        }
        return bestIdx !== -1 ? bestIdx : 0;
    }
    property color activeWeatherHex: weatherData && weatherData.forecast && weatherData.forecast[weatherView] ? weatherData.forecast[weatherView].hex : window.mauve
    readonly property color base: _theme.base
    readonly property color blue: _theme.blue
    readonly property color crust: _theme.crust
    property real currentEpoch: currentTime.getTime() / 1000

    // -------------------------------------------------------------------------
    // STATE & TIME (WITH SECOND PULSE)
    // -------------------------------------------------------------------------
    property var currentTime: new Date()
    property real globalOrbitAngle: 0
    readonly property color green: _theme.green

    // -------------------------------------------------------------------------
    // ANIMATIONS & INTRO
    // -------------------------------------------------------------------------
    property real introState: 0.0
    readonly property color mantle: _theme.mantle
    readonly property color mauve: _theme.mauve

    // -------------------------------------------------------------------------
    // CALENDAR GRID LOGIC
    // -------------------------------------------------------------------------
    property int monthOffset: 0
    readonly property color overlay0: _theme.overlay0
    readonly property color overlay1: _theme.overlay1
    readonly property color overlay2: _theme.overlay2
    readonly property color peach: _theme.peach
    readonly property color pink: _theme.pink
    readonly property color red: _theme.red
    readonly property color sapphire: _theme.sapphire

    // -------------------------------------------------------------------------
    // SCHEDULE DATA
    // -------------------------------------------------------------------------
    property var scheduleData: {
        "header": "Loading Schedule...",
        "link": "",
        "lessons": []
    }
    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/calendar"
    property real secondPulse: 1.0
    readonly property color subtext0: _theme.subtext0
    readonly property color subtext1: _theme.subtext1
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    property string targetMonthName: ""
    readonly property color teal: _theme.teal
    readonly property color text: _theme.text
    readonly property color timeAccent: {
        let h = window.currentTime.getHours();
        if (h >= 5 && h < 12)
            return window.yellow;     // Morning Accent
        if (h >= 12 && h < 17)
            return window.teal;      // Afternoon Accent
        if (h >= 17 && h < 21)
            return window.pink;      // Evening Accent
        return window.mauve;                            // Night Accent
    }

    // -------------------------------------------------------------------------
    // TIME OF DAY DYNAMIC COLORS
    // -------------------------------------------------------------------------
    readonly property color timeColor: {
        let h = window.currentTime.getHours();
        if (h >= 5 && h < 12)
            return window.peach;      // Morning
        if (h >= 12 && h < 17)
            return window.sapphire;  // Afternoon
        if (h >= 17 && h < 21)
            return window.mauve;     // Evening
        return window.blue;                             // Night
    }

    // -------------------------------------------------------------------------
    // WEATHER DATA & DYNAMIC TIME CALCULATION
    // -------------------------------------------------------------------------
    property var weatherData: null
    property int weatherView: 0
    readonly property color yellow: _theme.yellow

    function updateCalendarGrid() {
        let d = new Date(window.currentTime.getTime());
        d.setDate(1);
        d.setMonth(d.getMonth() + window.monthOffset);

        let targetMonth = d.getMonth();
        let targetYear = d.getFullYear();

        let actualToday = new Date();
        let isRealCurrentMonth = (actualToday.getMonth() === targetMonth && actualToday.getFullYear() === targetYear);
        let todayDate = actualToday.getDate();

        window.targetMonthName = Qt.formatDateTime(d, "MMMM yyyy");

        let firstDay = new Date(targetYear, targetMonth, 1).getDay();
        firstDay = (firstDay === 0) ? 6 : firstDay - 1;

        let daysInMonth = new Date(targetYear, targetMonth + 1, 0).getDate();
        let daysInPrevMonth = new Date(targetYear, targetMonth, 0).getDate();

        calendarModel.clear();

        for (let i = firstDay - 1; i >= 0; i--) {
            calendarModel.append({
                dayNum: (daysInPrevMonth - i).toString(),
                isCurrentMonth: false,
                isToday: false
            });
        }
        for (let i = 1; i <= daysInMonth; i++) {
            calendarModel.append({
                dayNum: i.toString(),
                isCurrentMonth: true,
                isToday: (isRealCurrentMonth && i === todayDate)
            });
        }
        let remaining = 42 - calendarModel.count;
        for (let i = 1; i <= remaining; i++) {
            calendarModel.append({
                dayNum: i.toString(),
                isCurrentMonth: false,
                isToday: false
            });
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
            duration: 1200
            easing.type: Easing.OutExpo
        }
    }
    NumberAnimation on secondPulse {
        id: pulseReset

        duration: 600
        easing.type: Easing.OutQuint
        running: false
        to: 1.0
    }

    Component.onCompleted: {
        introState = 1.0;
        updateCalendarGrid();
    }
    onMonthOffsetChanged: updateCalendarGrid()

    // -------------------------------------------------------------------------
    // KEYBOARD SHORTCUTS
    // (Escape is handled by Main.qml now)
    // -------------------------------------------------------------------------
    Shortcut {
        sequence: "Left"

        onActivated: {
            if (calHover.hovered) {
                window.monthOffset--;
            } else {
                if (window.weatherView > 0)
                    window.weatherView--;
            }
        }
    }
    Shortcut {
        sequence: "Right"

        onActivated: {
            if (calHover.hovered) {
                window.monthOffset++;
            } else {
                if (window.weatherView < 4 && window.weatherData)
                    window.weatherView++;
            }
        }
    }

    // -------------------------------------------------------------------------
    // COLORS (Dynamic Matugen Palette)
    // -------------------------------------------------------------------------
    MatugenColors {
        id: _theme
    }
    Timer {
        interval: 1000
        repeat: true
        running: true

        onTriggered: {
            window.currentTime = new Date();
            window.secondPulse = 1.06; // Gentle pulse
            pulseReset.start();

            if (window.currentTime.getHours() === 0 && window.currentTime.getMinutes() === 0 && window.currentTime.getSeconds() === 0) {
                updateCalendarGrid();
            }
        }
    }
    Process {
        id: weatherPoller

        command: ["zsh", window.scriptsDir + "/weather.sh", "--json"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        window.weatherData = JSON.parse(txt);
                    } catch (e) {}
                }
            }
        }
    }
    Timer {
        interval: 150000
        repeat: true
        running: true

        onTriggered: weatherPoller.running = true
    }
    Process {
        id: schedulePoller

        command: ["zsh", window.scriptsDir + "/schedule/schedule_manager.sh"]
        running: true

        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        window.scheduleData = JSON.parse(txt);
                    } catch (e) {
                        console.log("Schedule Parse Error:", e);
                    }
                }
            }
        }
    }
    Timer {
        interval: 600000
        repeat: true
        running: true

        onTriggered: schedulePoller.running = true
    }
    ListModel {
        id: calendarModel
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        opacity: introState
        scale: 0.90 + (0.10 * introState)

        Rectangle {
            anchors.fill: parent
            border.color: window.surface0
            border.width: 1
            clip: true
            color: window.base
            radius: 35

            // =======================================================
            // AMBIENT WIDGET COLOR BLOBS (Spread Out)
            // =======================================================
            // Primary Weather Blob
            Rectangle {
                color: window.activeWeatherHex
                height: width
                opacity: 0.025
                radius: width / 2
                width: parent.width * 0.5
                x: (parent.width * 0.75 - width / 2) + Math.cos(window.globalOrbitAngle * 1.5) * 350
                y: (parent.height * 0.3 - height / 2) + Math.sin(window.globalOrbitAngle * 1.5) * 200

                Behavior on color {
                    ColorAnimation {
                        duration: 1000
                    }
                }
            }

            // Time of Day Blob
            Rectangle {
                color: window.timeColor
                height: width
                opacity: 0.02
                radius: width / 2
                width: parent.width * 0.6
                x: (parent.width * 0.25 - width / 2) + Math.sin(window.globalOrbitAngle * 1.2) * -300
                y: (parent.height * 0.7 - height / 2) + Math.cos(window.globalOrbitAngle * 1.2) * -250

                Behavior on color {
                    ColorAnimation {
                        duration: 1000
                    }
                }
            }

            // Time Accent Blob
            Rectangle {
                color: window.timeAccent
                height: width
                opacity: 0.015
                radius: width / 2
                width: parent.width * 0.45
                x: (parent.width * 0.5 - width / 2) + Math.cos(window.globalOrbitAngle * -1.8) * 400
                y: (parent.height * 0.5 - height / 2) + Math.sin(window.globalOrbitAngle * -1.8) * -350

                Behavior on color {
                    ColorAnimation {
                        duration: 1000
                    }
                }
            }

            // Big Parallax Weather Icon
            Text {
                property real drift: 0

                anchors.centerIn: parent
                anchors.verticalCenterOffset: -100
                color: window.activeWeatherHex
                font.family: "FiraCode Nerd Font Mono"
                font.pixelSize: 800
                opacity: 0.03 + (0.01 * Math.sin(window.globalOrbitAngle * 4))
                text: window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].icon : ""
                z: 0

                Behavior on color {
                    ColorAnimation {
                        duration: 1500
                    }
                }
                SequentialAnimation on drift {
                    loops: Animation.Infinite

                    NumberAnimation {
                        duration: 6000
                        easing.type: Easing.InOutSine
                        to: -20
                    }
                    NumberAnimation {
                        duration: 6000
                        easing.type: Easing.InOutSine
                        to: 0
                    }
                }
                transform: Translate {
                    y: parent.drift
                }
            }

            // =======================================================
            // CENTRAL HERO: THE BREATHING TIME HUB & 3D HOURLY ORBIT
            // =======================================================
            Item {
                property real levitation: 0

                anchors.centerIn: parent
                anchors.verticalCenterOffset: -100
                height: 1
                width: 1
                z: 5

                SequentialAnimation on levitation {
                    loops: Animation.Infinite

                    NumberAnimation {
                        duration: 4000
                        easing.type: Easing.InOutSine
                        to: -15
                    }
                    NumberAnimation {
                        duration: 4000
                        easing.type: Easing.InOutSine
                        to: 0
                    }
                }
                transform: Translate {
                    y: parent.levitation
                }

                Canvas {
                    height: 280
                    opacity: 0.25
                    width: 640
                    x: -320
                    y: -140
                    z: -10

                    Behavior on opacity {
                        NumberAnimation {
                            duration: 1500
                        }
                    }

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        ctx.beginPath();
                        for (var i = 0; i <= Math.PI * 2; i += 0.05) {
                            var xx = width / 2 + Math.cos(i) * 320;
                            var yy = height / 2 + Math.sin(i) * 140;
                            if (i === 0)
                                ctx.moveTo(xx, yy);
                            else
                                ctx.lineTo(xx, yy);
                        }
                        ctx.strokeStyle = window.activeWeatherHex;
                        ctx.lineWidth = 1.5;
                        ctx.setLineDash([4, 10]);
                        ctx.stroke();
                    }
                }

                // Core Clock
                ColumnLayout {
                    anchors.centerIn: parent
                    scale: 0.95 + (0.05 * window.secondPulse)
                    spacing: 0
                    z: 0

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 2

                        Text {
                            color: window.text
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 84
                            font.weight: Font.Black
                            style: Text.Outline
                            styleColor: Qt.alpha(window.crust, 0.4)
                            text: Qt.formatTime(window.currentTime, "HH:mm")
                        }
                        Text {
                            Layout.alignment: Qt.AlignBottom
                            Layout.bottomMargin: 15
                            color: window.activeWeatherHex
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 32
                            font.weight: Font.Bold
                            opacity: window.secondPulse > 1.02 ? 1.0 : 0.6
                            style: Text.Outline
                            styleColor: Qt.alpha(window.crust, 0.4)
                            text: Qt.formatTime(window.currentTime, ":ss")

                            Behavior on color {
                                ColorAnimation {
                                    duration: 1000
                                }
                            }
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        color: window.subtext0
                        font.family: "FiraCode Nerd Font Mono"
                        font.pixelSize: 16
                        font.weight: Font.Bold
                        opacity: 0.9
                        text: Qt.formatDateTime(window.currentTime, "dddd, MMMM dd")
                    }
                }

                // TRUE 3D ORBITAL HOURLY FORECAST
                Repeater {
                    id: hourRepeater

                    model: window.weatherData && window.weatherData.forecast[window.weatherView] && window.weatherData.forecast[window.weatherView].hourly ? window.weatherData.forecast[window.weatherView].hourly.slice(0, 8) : []

                    delegate: Item {
                        property bool isHighlighted: isToday && index === window.activeHourIndex
                        property bool isToday: window.weatherView === 0
                        property int mCount: hourRepeater.count
                        property real orbitOffset: isToday ? 0 : (window.globalOrbitAngle * (180 / Math.PI) * -1.5)
                        property real osc: isToday ? (Math.sin(window.globalOrbitAngle * 10 + index) * 5) : 0
                        property real rad: (targetAngleDeg + orbitOffset + osc) * (Math.PI / 180)
                        property int relIdx: isToday ? (index - window.activeHourIndex) : index
                        property real rx: 320
                        property real ry: 140
                        property real targetAngleDeg: isToday ? (65 + (relIdx * 30)) : (index * (360 / Math.max(1, mCount)))

                        height: 95
                        opacity: isHighlighted ? 1.0 : (isToday ? (0.7 + 0.3 * ((Math.sin(rad) + 1) / 2)) : (0.65 + 0.35 * ((Math.sin(rad) + 1) / 2)))
                        scale: isHighlighted ? 1.4 : (isToday ? (0.95 + 0.20 * Math.sin(rad)) : (0.90 + 0.25 * Math.sin(rad)))
                        width: 56
                        x: Math.cos(rad) * rx - width / 2
                        y: Math.sin(rad) * ry - height / 2
                        z: Math.sin(rad) * 100

                        Rectangle {
                            anchors.fill: parent
                            border.color: isHighlighted ? "transparent" : (hrMa.containsMouse ? window.activeWeatherHex : window.surface1)
                            border.width: 1
                            color: isHighlighted ? window.activeWeatherHex : (hrMa.containsMouse ? window.surface2 : window.surface0)
                            radius: 28

                            Behavior on color {
                                ColorAnimation {
                                    duration: 200
                                }
                            }

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    color: isHighlighted ? window.mantle : (hrMa.containsMouse ? window.text : window.overlay1)
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 12
                                    font.weight: Font.Bold
                                    text: modelData.time
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    color: isHighlighted ? window.base : (modelData.hex || window.activeWeatherHex)
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 18
                                    text: modelData.icon || (window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].icon : "")

                                    transform: Translate {
                                        y: hrMa.containsMouse ? -3 : 0
                                    }
                                    Behavior on transform {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutBack
                                        }
                                    }
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    color: isHighlighted ? window.base : window.text
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 14
                                    font.weight: Font.Black
                                    text: modelData.temp + "°"
                                }
                            }
                        }
                        MouseArea {
                            id: hrMa

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true
                        }
                    }
                }
            }

            // =======================================================
            // LEFT WING: FLOATING GLASS CALENDAR
            // =======================================================
            Rectangle {
                id: calendarRect

                anchors.left: parent.left
                anchors.margins: 40
                anchors.top: parent.top
                border.color: Qt.alpha(window.surface1, 0.4)
                border.width: 1
                color: Qt.alpha(window.surface0, 0.2)
                height: 420
                radius: 30
                width: 320
                z: 10

                HoverHandler {
                    id: calHover
                }
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 25
                    spacing: 15

                    RowLayout {
                        Layout.fillWidth: true

                        // Spacer to maintain perfect center alignment for the month text
                        Item {
                            height: 32
                            width: 32
                        }
                        Rectangle {
                            color: prevMa.containsMouse ? window.surface1 : "transparent"
                            height: 32
                            radius: 16
                            width: 32

                            Text {
                                anchors.centerIn: parent
                                color: window.text
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 16
                                text: ""
                            }
                            MouseArea {
                                id: prevMa

                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: window.monthOffset--
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            color: window.text
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 16
                            font.weight: Font.Black
                            horizontalAlignment: Text.AlignHCenter
                            text: window.targetMonthName.toUpperCase()
                        }
                        Rectangle {
                            color: nextMa.containsMouse ? window.surface1 : "transparent"
                            height: 32
                            radius: 16
                            width: 32

                            Text {
                                anchors.centerIn: parent
                                color: window.text
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 16
                                text: ""
                            }
                            MouseArea {
                                id: nextMa

                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: window.monthOffset++
                            }
                        }

                        // THE NEW DIARY BUTTON
                        Rectangle {
                            color: diaryMa.containsMouse ? window.surface1 : "transparent"
                            height: 32
                            radius: 16
                            width: 32

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                color: diaryMa.containsMouse ? window.mauve : window.text
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 32
                                text: "+"
                            }
                            MouseArea {
                                id: diaryMa

                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: Quickshell.execDetached(["zsh", window.scriptsDir + "/diary_manager.sh"])
                            }
                        }
                    }
                    RowLayout {
                        Layout.fillWidth: true

                        Repeater {
                            model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]

                            Text {
                                Layout.fillWidth: true
                                color: window.overlay0
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 14
                                font.weight: Font.Black
                                horizontalAlignment: Text.AlignHCenter
                                text: modelData
                            }
                        }
                    }
                    GridLayout {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        columnSpacing: 6
                        columns: 7
                        rowSpacing: 6

                        Repeater {
                            model: calendarModel

                            Rectangle {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                border.color: isToday ? window.surface0 : (dayMa.containsMouse ? window.overlay0 : "transparent")
                                border.width: isToday || dayMa.containsMouse ? 1 : 0
                                color: isToday ? window.activeWeatherHex : (dayMa.containsMouse ? Qt.alpha(window.surface2, 0.4) : "transparent")
                                radius: 14
                                scale: dayMa.containsMouse ? 1.2 : 1.0

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 150
                                    }
                                }
                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutBack
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    color: isToday ? window.base : (isCurrentMonth ? window.text : window.surface0)
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 14
                                    font.weight: isToday ? Font.Black : Font.Bold
                                    text: dayNum

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                                MouseArea {
                                    id: dayMa

                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 20
                        visible: window.monthOffset !== 0

                        Text {
                            anchors.centerIn: parent
                            color: resetMa.containsMouse ? window.text : window.overlay0
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 14
                            font.weight: Font.Bold
                            text: "Return to Today"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }
                        }
                        MouseArea {
                            id: resetMa

                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: window.monthOffset = 0
                        }
                    }
                }
            }

            // =======================================================
            // RIGHT WING: ORGANIC FLOATING WEATHER STATS
            // =======================================================
            Item {
                anchors.margins: 40
                anchors.right: parent.right
                anchors.top: parent.top
                height: 420
                width: 320
                z: 10

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 20

                    RowLayout {
                        Layout.alignment: Qt.AlignRight | Qt.AlignTop
                        spacing: 20

                        MouseArea {
                            id: wPrevMa

                            property real pulseOffset: 0

                            height: 30
                            hoverEnabled: true
                            width: 30

                            SequentialAnimation on pulseOffset {
                                loops: Animation.Infinite
                                running: true

                                NumberAnimation {
                                    duration: 1000
                                    easing.type: Easing.InOutSine
                                    to: -3
                                }
                                NumberAnimation {
                                    duration: 1000
                                    easing.type: Easing.InOutSine
                                    to: 0
                                }
                            }

                            onClicked: if (window.weatherView > 0)
                                window.weatherView--

                            Text {
                                anchors.centerIn: parent
                                color: parent.containsMouse ? window.activeWeatherHex : window.overlay1
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 18
                                text: ""

                                transform: Translate {
                                    x: parent.containsMouse ? -5 : wPrevMa.pulseOffset
                                }
                                Behavior on transform {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutBack
                                    }
                                }
                            }
                        }
                        Text {
                            color: window.text
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 16
                            font.weight: Font.Black
                            text: window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].day_full.toUpperCase() : "LOADING..."
                        }
                        MouseArea {
                            id: wNextMa

                            property real pulseOffset: 0

                            height: 30
                            hoverEnabled: true
                            width: 30

                            SequentialAnimation on pulseOffset {
                                loops: Animation.Infinite
                                running: true

                                NumberAnimation {
                                    duration: 1000
                                    easing.type: Easing.InOutSine
                                    to: 3
                                }
                                NumberAnimation {
                                    duration: 1000
                                    easing.type: Easing.InOutSine
                                    to: 0
                                }
                            }

                            onClicked: if (window.weatherView < 4 && window.weatherData)
                                window.weatherView++

                            Text {
                                anchors.centerIn: parent
                                color: parent.containsMouse ? window.activeWeatherHex : window.overlay1
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 18
                                text: ""

                                transform: Translate {
                                    x: parent.containsMouse ? 5 : wNextMa.pulseOffset
                                }
                                Behavior on transform {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutBack
                                    }
                                }
                            }
                        }
                    }
                    ColumnLayout {
                        Layout.alignment: Qt.AlignRight
                        spacing: -5

                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            color: window.text
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 84
                            font.weight: Font.Black
                            style: Text.Outline
                            styleColor: Qt.alpha(window.crust, 0.4)
                            text: window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].max + "°" : ""
                        }
                        Text {
                            Layout.alignment: Qt.AlignHCenter
                            color: window.activeWeatherHex
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            text: window.weatherData && window.weatherData.forecast[window.weatherView] ? window.weatherData.forecast[window.weatherView].desc : ""

                            Behavior on color {
                                ColorAnimation {
                                    duration: 1000
                                }
                            }
                        }
                    }
                    Item {
                        Layout.fillHeight: true
                    }
                    RowLayout {
                        Layout.alignment: Qt.AlignRight
                        Layout.fillWidth: true
                        Layout.rightMargin: 10
                        spacing: 20

                        Repeater {
                            model: window.weatherData && window.weatherData.forecast[window.weatherView] ? [
                                {
                                    icon: "",
                                    val: window.weatherData.forecast[window.weatherView].wind + "m/s",
                                    lbl: "WIND",
                                    fill: Math.min(1.0, window.weatherData.forecast[window.weatherView].wind / 25.0)
                                },
                                {
                                    icon: "",
                                    val: window.weatherData.forecast[window.weatherView].humidity + "%",
                                    lbl: "HUMID",
                                    fill: window.weatherData.forecast[window.weatherView].humidity / 100.0
                                },
                                {
                                    icon: "",
                                    val: window.weatherData.forecast[window.weatherView].pop + "%",
                                    lbl: "RAIN",
                                    fill: window.weatherData.forecast[window.weatherView].pop / 100.0
                                },
                                {
                                    icon: "",
                                    val: window.weatherData.forecast[window.weatherView].feels_like + "°",
                                    lbl: "FEELS",
                                    fill: Math.max(0.0, Math.min(1.0, (window.weatherData.forecast[window.weatherView].feels_like + 15) / 55.0))
                                }
                            ] : []

                            Item {
                                height: 100
                                scale: gaugeMa.containsMouse ? 1.15 : 1.0
                                width: 68

                                Behavior on scale {
                                    NumberAnimation {
                                        duration: 250
                                        easing.type: Easing.OutBack
                                    }
                                }

                                Rectangle {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    color: window.activeWeatherHex
                                    height: 68
                                    opacity: gaugeMa.containsMouse ? 0.3 : 0.0
                                    radius: 34
                                    width: 68

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                                Item {
                                    id: circleItem

                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    height: 68
                                    width: 68

                                    Canvas {
                                        id: gaugeCanvas

                                        property real animProgress: 0
                                        property real progress: modelData.fill

                                        anchors.fill: parent
                                        rotation: -90

                                        NumberAnimation on animProgress {
                                            duration: 1500
                                            easing.type: Easing.OutExpo
                                            running: true
                                            to: gaugeCanvas.progress
                                        }
                                        Behavior on progress {
                                            NumberAnimation {
                                                duration: 1000
                                                easing.type: Easing.OutExpo
                                            }
                                        }

                                        onAnimProgressChanged: requestPaint()
                                        onPaint: {
                                            var ctx = getContext("2d");
                                            ctx.clearRect(0, 0, width, height);
                                            var r = width / 2;

                                            ctx.beginPath();
                                            ctx.arc(r, r, r - 4, 0, 2 * Math.PI);
                                            ctx.strokeStyle = Qt.alpha(window.text, 0.1);
                                            ctx.lineWidth = 3;
                                            ctx.stroke();

                                            if (animProgress > 0) {
                                                ctx.beginPath();
                                                ctx.arc(r, r, r - 4, 0, animProgress * 2 * Math.PI);
                                                var grad = ctx.createLinearGradient(0, 0, width, height);
                                                grad.addColorStop(0, window.activeWeatherHex);
                                                grad.addColorStop(1, window.blue);
                                                ctx.strokeStyle = grad;
                                                ctx.lineWidth = 4;
                                                ctx.lineCap = "round";
                                                ctx.stroke();
                                            }
                                        }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        color: window.text
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 14
                                        font.weight: Font.Black
                                        text: modelData.val
                                    }
                                }
                                RowLayout {
                                    anchors.bottom: parent.bottom
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    spacing: 4

                                    Text {
                                        color: gaugeMa.containsMouse ? window.activeWeatherHex : window.overlay0
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 14
                                        text: modelData.icon

                                        Behavior on color {
                                            ColorAnimation {
                                                duration: 200
                                            }
                                        }
                                    }
                                    Text {
                                        color: window.overlay0
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 12
                                        font.weight: Font.Bold
                                        text: modelData.lbl
                                    }
                                }
                                MouseArea {
                                    id: gaugeMa

                                    anchors.fill: parent
                                    hoverEnabled: true
                                }
                            }
                        }
                    }
                }
            }

            // =======================================================
            // BOTTOM SECTION: FRAMELESS FLUID DATA STREAM (SCHEDULE)
            // =======================================================
            Item {
                id: bottomSection

                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 240
                z: 20

                Rectangle {
                    anchors.fill: parent

                    gradient: Gradient {
                        GradientStop {
                            color: "transparent"
                            position: 0.0
                        }
                        GradientStop {
                            color: Qt.alpha(window.crust, 0.6)
                            position: 1.0
                        }
                    }
                }
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    color: Qt.alpha(window.surface1, 0.5)
                    height: 1
                }
                Canvas {
                    property real phase1: 0
                    property real phase2: 0
                    property real phase3: 0

                    anchors.fill: parent
                    opacity: 0.15
                    z: -1

                    NumberAnimation on phase1 {
                        duration: 4000
                        from: 0
                        loops: Animation.Infinite
                        running: true
                        to: Math.PI * 2
                    }
                    NumberAnimation on phase2 {
                        duration: 5500
                        from: 0
                        loops: Animation.Infinite
                        running: true
                        to: Math.PI * 2
                    }
                    NumberAnimation on phase3 {
                        duration: 7000
                        from: 0
                        loops: Animation.Infinite
                        running: true
                        to: Math.PI * 2
                    }

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.clearRect(0, 0, width, height);
                        var cy = height / 2;

                        ctx.beginPath();
                        ctx.moveTo(0, cy);
                        for (var x = 0; x <= width; x += 10)
                            ctx.lineTo(x, cy + Math.sin(x / 100 + phase1) * 30);
                        ctx.strokeStyle = window.mauve;
                        ctx.lineWidth = 2;
                        ctx.stroke();

                        ctx.beginPath();
                        ctx.moveTo(0, cy);
                        for (var x = 0; x <= width; x += 10)
                            ctx.lineTo(x, cy + Math.sin(x / 120 - phase2) * 40);
                        ctx.strokeStyle = window.sapphire;
                        ctx.lineWidth = 2;
                        ctx.stroke();

                        ctx.beginPath();
                        ctx.moveTo(0, cy);
                        for (var x = 0; x <= width; x += 10)
                            ctx.lineTo(x, cy + Math.sin(x / 80 + phase3) * 20);
                        ctx.strokeStyle = window.peach;
                        ctx.lineWidth = 2;
                        ctx.stroke();
                    }
                    onPhase1Changed: requestPaint()
                }
                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 25
                    spacing: 15

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 15

                        Rectangle {
                            color: window.surface0
                            height: 40
                            radius: 20
                            width: 40

                            Text {
                                anchors.centerIn: parent
                                color: window.timeAccent
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 18
                                text: ""
                            }
                        }
                        Text {
                            color: window.overlay0
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 16
                            font.weight: Font.Bold
                            text: window.scheduleData ? window.scheduleData.header : "Loading Schedule..."
                        }
                        Item {
                            Layout.fillWidth: true
                        }
                        Rectangle {
                            border.color: window.mauve
                            border.width: 1
                            color: schLinkMa.containsMouse ? window.mauve : Qt.alpha(window.surface1, 0.5)
                            height: 36
                            radius: 18
                            width: 120

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            RowLayout {
                                anchors.centerIn: parent
                                spacing: 6

                                Text {
                                    color: schLinkMa.containsMouse ? window.base : window.text
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    text: "Open Web"
                                }
                                Text {
                                    color: schLinkMa.containsMouse ? window.base : window.text
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 14
                                    text: ""
                                }
                            }
                            MouseArea {
                                id: schLinkMa

                                anchors.fill: parent
                                hoverEnabled: true

                                onClicked: if (window.scheduleData && window.scheduleData.link)
                                    Quickshell.execDetached(["xdg-open", window.scheduleData.link])
                            }
                        }
                    }
                    Item {
                        Layout.fillHeight: true
                        Layout.fillWidth: true

                        Text {
                            anchors.centerIn: parent
                            color: window.overlay0
                            font.family: "FiraCode Nerd Font Mono"
                            font.italic: true
                            font.pixelSize: 14
                            text: "Data stream offline. No scheduled events."
                            visible: window.scheduleData && window.scheduleData.lessons.length === 0
                        }
                        Rectangle {
                            anchors.left: parent.left
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            color: Qt.alpha(window.surface1, 0.4)
                            height: 2
                            visible: window.scheduleData && window.scheduleData.lessons.length > 0
                        }
                        ScrollView {
                            id: schedScroll

                            ScrollBar.horizontal.policy: ScrollBar.AsNeeded
                            ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                            anchors.fill: parent
                            clip: true
                            contentHeight: parent.height
                            contentWidth: scheduleRow.width
                            visible: window.scheduleData && window.scheduleData.lessons.length > 0

                            Row {
                                id: scheduleRow

                                property real scaleRatio: schedScroll.width / 750.0

                                height: parent.height
                                spacing: 0

                                Repeater {
                                    model: window.scheduleData ? window.scheduleData.lessons : []

                                    delegate: Item {
                                        property int baseDataWidth: modelData.width || 100
                                        property bool isClass: modelData.type === "class"

                                        height: parent.height
                                        width: baseDataWidth * scheduleRow.scaleRatio

                                        Item {
                                            id: classNode

                                            property bool isActive: parent.isClass && window.currentEpoch >= (modelData.start || 0) && window.currentEpoch <= (modelData.end || 0)
                                            property bool isPast: parent.isClass && window.currentEpoch > (modelData.end || 0)

                                            anchors.bottomMargin: 10
                                            anchors.fill: parent
                                            anchors.topMargin: 10
                                            visible: parent.isClass

                                            Canvas {
                                                property real wavePhase: 0

                                                anchors.fill: parent
                                                opacity: classMa.containsMouse ? 0.2 : 0.08
                                                visible: classMa.containsMouse || classNode.isActive

                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: 200
                                                    }
                                                }
                                                NumberAnimation on wavePhase {
                                                    duration: 2000
                                                    from: 0
                                                    loops: Animation.Infinite
                                                    running: parent.visible
                                                    to: Math.PI * 2
                                                }

                                                onPaint: {
                                                    var ctx = getContext("2d");
                                                    ctx.clearRect(0, 0, width, height);
                                                    ctx.beginPath();
                                                    ctx.moveTo(0, height);
                                                    for (var x = 0; x <= width; x += 10) {
                                                        ctx.lineTo(x, height / 2 + Math.sin(x / 25 + wavePhase) * 20);
                                                    }
                                                    ctx.lineTo(width, height);
                                                    ctx.lineTo(0, height);
                                                    var grad = ctx.createLinearGradient(0, 0, width, 0);
                                                    grad.addColorStop(0, window.mauve);
                                                    grad.addColorStop(1, "transparent");
                                                    ctx.fillStyle = grad;
                                                    ctx.fill();
                                                }
                                                onWavePhaseChanged: requestPaint()
                                            }
                                            Rectangle {
                                                id: accentLine

                                                anchors.bottom: parent.bottom
                                                anchors.left: parent.left
                                                anchors.top: parent.top
                                                color: classNode.isActive ? window.mauve : (classNode.isPast ? window.surface1 : window.surface2)
                                                radius: 2
                                                width: classNode.isActive || classMa.containsMouse ? 4 : 2

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 200
                                                    }
                                                }
                                                Behavior on width {
                                                    NumberAnimation {
                                                        duration: 200
                                                        easing.type: Easing.OutBack
                                                    }
                                                }
                                            }
                                            ColumnLayout {
                                                anchors.left: accentLine.right
                                                anchors.leftMargin: classMa.containsMouse ? 25 : 15
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 6

                                                Behavior on anchors.leftMargin {
                                                    NumberAnimation {
                                                        duration: 300
                                                        easing.type: Easing.OutBack
                                                    }
                                                }

                                                Text {
                                                    Layout.fillWidth: true
                                                    color: classNode.isActive ? window.mauve : (classNode.isPast ? window.overlay0 : window.text)
                                                    elide: Text.ElideRight
                                                    font.family: "FiraCode Nerd Font Mono"
                                                    font.pixelSize: 16
                                                    font.weight: Font.Black
                                                    text: modelData.subject || ""
                                                }
                                                RowLayout {
                                                    spacing: 8
                                                    visible: !modelData.is_compact

                                                    Text {
                                                        color: classNode.isActive ? window.mauve : window.overlay1
                                                        font.family: "FiraCode Nerd Font Mono"
                                                        font.pixelSize: 14
                                                        text: "󰅐"
                                                    }
                                                    Text {
                                                        color: classNode.isActive ? window.text : window.overlay1
                                                        font.family: "FiraCode Nerd Font Mono"
                                                        font.pixelSize: 14
                                                        font.weight: Font.Bold
                                                        text: modelData.time || ""
                                                    }
                                                }
                                                RowLayout {
                                                    spacing: 8
                                                    visible: !modelData.is_compact && (modelData.room || "") !== ""

                                                    Text {
                                                        color: classNode.isPast ? window.surface2 : window.peach
                                                        font.family: "FiraCode Nerd Font Mono"
                                                        font.pixelSize: 14
                                                        text: ""
                                                    }
                                                    Text {
                                                        Layout.fillWidth: true
                                                        color: window.subtext1
                                                        elide: Text.ElideRight
                                                        font.family: "FiraCode Nerd Font Mono"
                                                        font.pixelSize: 14
                                                        font.weight: Font.Bold
                                                        text: modelData.room || ""
                                                    }
                                                }
                                            }
                                            MouseArea {
                                                id: classMa

                                                anchors.fill: parent
                                                hoverEnabled: parent.visible
                                            }
                                        }
                                        Item {
                                            anchors.fill: parent
                                            visible: !parent.isClass

                                            Rectangle {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: gapMa.containsMouse ? window.mauve : "transparent"
                                                height: gapMa.containsMouse ? 4 : 2

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 150
                                                    }
                                                }
                                                Behavior on height {
                                                    NumberAnimation {
                                                        duration: 150
                                                        easing.type: Easing.OutBack
                                                    }
                                                }
                                            }
                                            Rectangle {
                                                anchors.centerIn: parent
                                                border.color: window.surface2
                                                border.width: 1
                                                color: window.mantle
                                                height: 24
                                                opacity: gapMa.containsMouse ? 1.0 : 0.0
                                                radius: 12
                                                scale: gapMa.containsMouse ? 1.0 : 0.8
                                                width: breakText.width + 16

                                                Behavior on opacity {
                                                    NumberAnimation {
                                                        duration: 150
                                                    }
                                                }
                                                Behavior on scale {
                                                    NumberAnimation {
                                                        duration: 150
                                                        easing.type: Easing.OutBack
                                                    }
                                                }

                                                Text {
                                                    id: breakText

                                                    anchors.centerIn: parent
                                                    color: window.mauve
                                                    font.family: "FiraCode Nerd Font Mono"
                                                    font.pixelSize: 14
                                                    font.weight: Font.Bold
                                                    text: modelData.desc || ""
                                                }
                                            }
                                            MouseArea {
                                                id: gapMa

                                                anchors.fill: parent
                                                hoverEnabled: parent.visible
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
