import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import QtCore
import Quickshell
import Quickshell.Io
import "../"

Item {
    id: window

    readonly property var activeDate: window.selectedAppClass === "" ? window.globalDate : window.appDate

    // Animation properties
    property real animatedTotalSeconds: 0
    property var appDate: new Date()
    property int averageSeconds: 0
    readonly property color base: _theme.base
    readonly property color blue: _theme.blue
    readonly property color crust: _theme.crust

    // -------------------------------------------------------------------------
    // STATE & POLLING PATHS
    // -------------------------------------------------------------------------
    property var globalDate: new Date()
    property real globalOrbitAngle: 0
    readonly property color green: _theme.green

    // 48 blocks for 30-minute intervals (2 bars per hour)
    property var hourlyData: new Array(48).fill(0)
    property real introState: 0.0
    property bool isFirstLoad: true
    readonly property bool isTodaySelected: window.selectedDateStr === getIsoDate(new Date())

    // UI State for Week Overview
    property bool isWeekView: false
    property string liveActiveApp: "Desktop"
    readonly property color mantle: _theme.mantle
    readonly property color mauve: _theme.mauve
    property real maxHourlyTotal: 1
    property real maxMonthTotal: 1
    property real maxWeekHour: 1
    property real maxWeekTotal: 1
    property var monthData: []
    readonly property var monthNames: ["January", "February", "March", "April", "May", "June", "July", "August", "September", "October", "November", "December"]
    readonly property color overlay0: _theme.overlay0
    readonly property color peach: _theme.peach
    property string peakUsageHours: "N/A"
    readonly property color pink: _theme.pink
    readonly property color red: _theme.red
    readonly property color sapphire: _theme.sapphire
    readonly property string scriptsDir: Quickshell.env("HOME") + "/.config/hypr/scripts/quickshell/focustime"
    property string selectedAppClass: ""
    property string selectedAppIcon: ""
    property string selectedAppName: ""
    property string selectedDateStr: ""
    readonly property string stateFilePath: window.xdgRuntime + "/focustime_state.json"
    readonly property color subtext0: _theme.subtext0
    readonly property color surface0: _theme.surface0
    readonly property color surface1: _theme.surface1
    readonly property color surface2: _theme.surface2
    readonly property color text: _theme.text
    property var topApps: []
    property int totalSeconds: 0

    // Week Overview specific data
    property var weekAppsData: []
    property var weekData: []
    property var weekHeatmapData: [[], [], [], [], [], [], []]
    property string weekRangeStr: ""
    readonly property string xdgRuntime: Quickshell.env("XDG_RUNTIME_DIR") || "/tmp"
    readonly property color yellow: _theme.yellow
    property int yesterdaySeconds: 0

    function changeDay(offsetDays) {
        let d = new Date(window.activeDate);
        d.setDate(d.getDate() + offsetDays);
        if (window.selectedAppClass === "") {
            window.globalDate = d;
        } else {
            window.appDate = d;
        }
        window.isFirstLoad = true;
        window.requestDataUpdate();
    }
    function changeToDate(clickedDateStr) {
        if (!clickedDateStr)
            return;
        let currentIso = getIsoDate(window.activeDate);
        if (clickedDateStr === currentIso)
            return;
        let dCurrent = new Date(currentIso + "T12:00:00");
        let dClicked = new Date(clickedDateStr + "T12:00:00");
        let diffDays = Math.round((dClicked - dCurrent) / (1000 * 60 * 60 * 24));
        if (diffDays !== 0)
            changeDay(diffDays);
    }
    function formatTimeLarge(secs) {
        let h = Math.floor(secs / 3600);
        let m = Math.floor((secs % 3600) / 60);
        if (h > 0)
            return h + "h " + m + "m";
        return m + "m";
    }
    function formatTimeList(secs) {
        let h = Math.floor(secs / 3600);
        let m = Math.floor((secs % 3600) / 60);
        if (h > 0)
            return h + "h " + m.toString().padStart(2, '0') + "m";
        return m + "m";
    }
    function getFancyDate(d) {
        let monthName = window.monthNames[d.getMonth()];
        let dateNum = d.getDate();
        let isToday = getIsoDate(d) === getIsoDate(new Date());
        return isToday ? "Today" : `${monthName} ${dateNum}`;
    }

    // --- DATE HELPERS ---
    function getIsoDate(d) {
        let z = d.getTimezoneOffset() * 60000;
        return (new Date(d - z)).toISOString().slice(0, 10);
    }

    // --- DATA FETCHING ROUTING ---
    function requestDataUpdate() {
        if (window.selectedAppClass === "" && getIsoDate(window.activeDate) === getIsoDate(new Date())) {
            liveFileReader.running = true;
        } else {
            let cmd = ["python3", window.scriptsDir + "/get_stats.py", getIsoDate(window.activeDate)];
            if (window.selectedAppClass !== "") {
                cmd.push("--app");
                cmd.push(window.selectedAppClass);
            }
            statsPoller.command = cmd;
            statsPoller.running = true;
        }
    }
    function syncAppsModel() {
        for (let i = 0; i < window.topApps.length; i++) {
            let app = window.topApps[i];
            if (i < appListModel.count) {
                appListModel.setProperty(i, "name", app.name);
                appListModel.setProperty(i, "appClass", app.class);
                appListModel.setProperty(i, "icon", app.icon || "");
                appListModel.setProperty(i, "seconds", app.seconds);
                appListModel.setProperty(i, "percent", app.percent);
            } else {
                appListModel.append({
                    name: app.name,
                    appClass: app.class,
                    icon: app.icon || "",
                    seconds: app.seconds,
                    percent: app.percent,
                    idx: i
                });
            }
        }
        while (appListModel.count > window.topApps.length) {
            appListModel.remove(appListModel.count - 1);
        }
    }
    function syncMonthModel() {
        let currentMax = 1;
        for (let i = 0; i < window.monthData.length; i++) {
            if (window.monthData[i].total > currentMax)
                currentMax = window.monthData[i].total;
        }
        window.maxMonthTotal = currentMax;

        for (let i = 0; i < window.monthData.length; i++) {
            let m = window.monthData[i];
            if (i < monthListModel.count) {
                monthListModel.setProperty(i, "dateStr", m.date);
                monthListModel.setProperty(i, "total", m.total);
                monthListModel.setProperty(i, "isTarget", m.is_target);
            } else {
                monthListModel.append({
                    dateStr: m.date,
                    total: m.total,
                    isTarget: m.is_target
                });
            }
        }
        while (monthListModel.count > window.monthData.length) {
            monthListModel.remove(monthListModel.count - 1);
        }
    }
    function syncWeekAppsModel() {
        for (let i = 0; i < window.weekAppsData.length; i++) {
            let app = window.weekAppsData[i];
            if (i < weekAppListModel.count) {
                weekAppListModel.setProperty(i, "name", app.name);
                weekAppListModel.setProperty(i, "appClass", app.class);
                weekAppListModel.setProperty(i, "icon", app.icon || "");
                weekAppListModel.setProperty(i, "seconds", app.seconds);
                weekAppListModel.setProperty(i, "percent", app.percent);
            } else {
                weekAppListModel.append({
                    name: app.name,
                    appClass: app.class,
                    icon: app.icon || "",
                    seconds: app.seconds,
                    percent: app.percent,
                    idx: i
                });
            }
        }
        while (weekAppListModel.count > window.weekAppsData.length) {
            weekAppListModel.remove(weekAppListModel.count - 1);
        }
    }
    function syncWeekModel() {
        let currentMax = 1;
        for (let i = 0; i < window.weekData.length; i++) {
            if (window.weekData[i].total > currentMax)
                currentMax = window.weekData[i].total;
        }
        window.maxWeekTotal = currentMax;

        for (let i = 0; i < window.weekData.length; i++) {
            let w = window.weekData[i];
            if (i < weekListModel.count) {
                weekListModel.setProperty(i, "dateStr", w.date);
                weekListModel.setProperty(i, "dayName", w.day);
                weekListModel.setProperty(i, "total", w.total);
                weekListModel.setProperty(i, "isTarget", w.is_target);
            } else {
                weekListModel.append({
                    dateStr: w.date,
                    dayName: w.day,
                    total: w.total,
                    isTarget: w.is_target
                });
            }
        }
        while (weekListModel.count > window.weekData.length) {
            weekListModel.remove(weekListModel.count - 1);
        }
    }

    // --- SHARED DATA INGESTION ---
    function updateFromData(data) {
        window.selectedDateStr = data.selected_date;
        window.totalSeconds = data.total || 0;
        window.averageSeconds = data.average || 0;
        window.yesterdaySeconds = data.yesterday || 0;
        window.weekRangeStr = data.week_range || "";
        window.liveActiveApp = data.current || "Unknown";

        if (window.isFirstLoad)
            firstLoadTimer.start();

        window.topApps = data.apps || [];
        syncAppsModel();

        window.weekAppsData = data.week_apps || [];
        syncWeekAppsModel();

        // Calculate maximum hourly segment and Peak Usage for the week heatmap
        window.weekHeatmapData = data.week_heatmap || [[], [], [], [], [], [], []];
        let mwh = 1;
        let hourSums = new Array(24).fill(0);

        for (let i = 0; i < 7; i++) {
            if (!window.weekHeatmapData[i])
                continue;
            for (let j = 0; j < 24; j++) {
                if (window.weekHeatmapData[i][j] > mwh)
                    mwh = window.weekHeatmapData[i][j];
                hourSums[j] += window.weekHeatmapData[i][j];
            }
        }
        window.maxWeekHour = mwh;

        let maxHourVal = -1;
        let peakH = 0;
        for (let h = 0; h < 24; h++) {
            if (hourSums[h] > maxHourVal) {
                maxHourVal = hourSums[h];
                peakH = h;
            }
        }

        function formatHour(h) {
            return h.toString().padStart(2, '0') + ":00";
        }

        // Use exact minute strings from backend if available, otherwise fallback to 24h fallback logic
        if (data.peak_usage_str && data.peak_usage_str !== "N/A") {
            window.peakUsageHours = data.peak_usage_str;
        } else if (maxHourVal > 0) {
            window.peakUsageHours = formatHour(peakH) + " - " + formatHour((peakH + 1) % 24);
        } else {
            window.peakUsageHours = "N/A";
        }

        let parsedWeek = data.week || [];
        if (JSON.stringify(window.weekData) !== JSON.stringify(parsedWeek)) {
            window.weekData = parsedWeek;
            syncWeekModel();
        }

        let parsedMonth = data.month || [];
        if (JSON.stringify(window.monthData) !== JSON.stringify(parsedMonth)) {
            window.monthData = parsedMonth;
            syncMonthModel();
        }

        window.hourlyData = data.hourly || new Array(48).fill(0);
        let currentMaxHour = 1;
        for (let i = 0; i < 48; i++) {
            if (window.hourlyData[i] > currentMaxHour)
                currentMaxHour = window.hourlyData[i];
        }
        window.maxHourlyTotal = currentMaxHour;
    }

    Behavior on animatedTotalSeconds {
        NumberAnimation {
            duration: 850
            easing.type: Easing.OutQuint
        }
    }
    NumberAnimation on globalOrbitAngle {
        duration: 120000
        from: 0
        loops: Animation.Infinite
        running: true
        to: Math.PI * 2
    }
    Behavior on introState {
        NumberAnimation {
            duration: 800
            easing.type: Easing.OutExpo
        }
    }

    Component.onCompleted: {
        introState = 1.0;
        requestDataUpdate();
    }
    onTotalSecondsChanged: {
        animatedTotalSeconds = totalSeconds;
    }

    // -------------------------------------------------------------------------
    // COLORS (Dynamic Matugen Palette)
    // -------------------------------------------------------------------------
    MatugenColors {
        id: _theme
    }

    // --- LIVE FILE READER (For Global Today) ---
    Process {
        id: liveFileReader

        command: ["cat", window.stateFilePath]

        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text.trim();
                if (raw === "")
                    return;
                try {
                    let data = JSON.parse(raw);
                    window.updateFromData(data);
                } catch (e) {}
            }
        }
    }
    Timer {
        interval: 1000
        repeat: true
        running: window.isTodaySelected

        onTriggered: window.requestDataUpdate()
    }

    // --- PYTHON STATS FETCHER (For History & Specific Apps) ---
    Process {
        id: statsPoller

        stdout: StdioCollector {
            onStreamFinished: {
                let raw = this.text.trim();
                if (raw === "")
                    return;
                try {
                    let data = JSON.parse(raw);
                    window.updateFromData(data);
                } catch (e) {}
            }
        }
    }
    Timer {
        id: firstLoadTimer

        interval: 1000

        onTriggered: window.isFirstLoad = false
    }
    ListModel {
        id: appListModel
    }
    ListModel {
        id: weekAppListModel
    }
    ListModel {
        id: weekListModel
    }
    ListModel {
        id: monthListModel
    }

    // -------------------------------------------------------------------------
    // KEYBOARD SHORTCUTS
    // -------------------------------------------------------------------------
    Shortcut {
        sequence: "Left"

        onActivated: changeDay(-1)
    }
    Shortcut {
        sequence: "Right"

        onActivated: changeDay(1)
    }
    Shortcut {
        sequence: "Home"

        onActivated: changeDay(-7)
    }
    Shortcut {
        sequence: "End"

        onActivated: changeDay(7)
    }

    // Escape key handling: Only intercepts if we are in a sub-view
    Shortcut {
        context: Qt.ApplicationShortcut
        enabled: window.selectedAppClass !== "" || window.isWeekView
        sequence: "Escape"

        onActivated: {
            if (window.selectedAppClass !== "") {
                window.selectedAppClass = "";
                window.selectedAppName = "";
                window.selectedAppIcon = "";
                window.requestDataUpdate();
            } else if (window.isWeekView) {
                window.isWeekView = false;
            }
        }
    }

    // -------------------------------------------------------------------------
    // UI LAYOUT
    // -------------------------------------------------------------------------
    Item {
        anchors.fill: parent
        opacity: introState
        scale: 0.97 + (0.03 * introState)

        Rectangle {
            anchors.fill: parent
            border.color: Qt.alpha(window.surface1, 0.2)
            border.width: 1
            clip: true
            color: window.crust
            radius: 28

            Rectangle {
                color: window.mauve
                height: width
                opacity: 0.015
                radius: width / 2
                width: parent.width * 1.2
                x: (parent.width / 2 - width / 2) + Math.cos(window.globalOrbitAngle * 2) * 150
                y: (parent.height / 2 - height / 2) + Math.sin(window.globalOrbitAngle * 2) * 100
            }
            Rectangle {
                color: window.blue
                height: width
                opacity: 0.010
                radius: width / 2
                width: parent.width * 1.1
                x: (parent.width / 2 - width / 2) + Math.sin(window.globalOrbitAngle * 1.5) * -150
                y: (parent.height / 2 - height / 2) + Math.cos(window.globalOrbitAngle * 1.5) * -100
            }
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 24
                spacing: 16

                // ==========================================
                // 1. HEADER
                // ==========================================
                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 40
                    Layout.topMargin: 4

                    // Left Buttons
                    Row {
                        Layout.preferredHeight: 40
                        Layout.preferredWidth: 84
                        spacing: 4

                        // Universal Return Arrow (Back to Daily / App List)
                        Rectangle {
                            color: backMa.containsMouse ? window.surface0 : "transparent"
                            height: 40
                            radius: 20
                            visible: window.selectedAppClass !== "" || window.isWeekView
                            width: 40

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                color: window.text
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 18
                                text: ""
                            }
                            MouseArea {
                                id: backMa

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: {
                                    if (window.selectedAppClass !== "") {
                                        window.selectedAppClass = "";
                                        window.selectedAppName = "";
                                        window.selectedAppIcon = "";
                                        window.requestDataUpdate();
                                    } else if (window.isWeekView) {
                                        window.isWeekView = false;
                                    }
                                }
                            }
                        }

                        // Week View Open Button
                        Rectangle {
                            color: weekMa.containsMouse ? window.surface0 : "transparent"
                            height: 40
                            radius: 20
                            visible: window.selectedAppClass === "" && !window.isWeekView
                            width: 40

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                color: window.text
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 18
                                text: "󰃭"
                            }
                            MouseArea {
                                id: weekMa

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: window.isWeekView = true
                            }
                        }

                        // Prev Week/Day Arrow
                        Rectangle {
                            color: prevWeekMa.containsMouse ? window.surface0 : "transparent"
                            height: 40
                            radius: 20
                            width: 40

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                }
                            }

                            Text {
                                anchors.centerIn: parent
                                color: window.text
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 18
                                text: ""
                            }
                            MouseArea {
                                id: prevWeekMa

                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                hoverEnabled: true

                                onClicked: changeDay(-1)
                            }
                        }
                    }

                    // Title Area
                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        Layout.fillWidth: true
                        spacing: 8

                        Item {
                            Layout.fillWidth: true
                        } // Left Spacer

                        Image {
                            Layout.alignment: Qt.AlignVCenter
                            Layout.preferredHeight: 20
                            Layout.preferredWidth: 20
                            fillMode: Image.PreserveAspectFit
                            source: window.selectedAppIcon.startsWith("/") ? "file://" + window.selectedAppIcon : "image://icon/" + window.selectedAppIcon
                            sourceSize: Qt.size(20, 20)
                            visible: window.selectedAppClass !== "" && window.selectedAppIcon !== "" && !window.isWeekView
                        }
                        Text {
                            color: window.text
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 18
                            font.weight: Font.DemiBold
                            horizontalAlignment: Text.AlignHCenter
                            text: window.isWeekView ? (window.weekRangeStr !== "" ? window.weekRangeStr : "Week Overview") : (window.selectedAppClass !== "" ? `${window.selectedAppName} - ${window.getFancyDate(window.activeDate)}` : window.getFancyDate(window.activeDate))
                            verticalAlignment: Text.AlignVCenter
                        }
                        Item {
                            Layout.fillWidth: true
                        } // Right Spacer
                    }

                    // Next Week/Day Arrow
                    Rectangle {
                        Layout.preferredHeight: 40
                        Layout.preferredWidth: 40
                        color: nextWeekMa.containsMouse ? window.surface0 : "transparent"
                        radius: 20

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            color: window.text
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 18
                            text: ""
                        }
                        MouseArea {
                            id: nextWeekMa

                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            hoverEnabled: true

                            onClicked: changeDay(1)
                        }
                    }
                }

                // ==========================================
                // NORMAL DAILY & APP VIEW WRAPPER
                // ==========================================
                ColumnLayout {
                    id: dailyViewWrapper

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    spacing: 16
                    visible: !window.isWeekView

                    // ==========================================
                    // 1.5 TOTAL TIME DISPLAY + AVERAGES (3 BOXES)
                    // ==========================================
                    RowLayout {
                        Layout.fillWidth: true
                        Layout.maximumHeight: 90
                        Layout.minimumHeight: 90
                        Layout.preferredHeight: 90
                        spacing: 16

                        // LEFT: Daily Average (2/7 weight = 200)
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Layout.preferredWidth: 200
                            border.color: Qt.alpha(window.surface1, 0.3)
                            border.width: 1
                            color: window.base
                            radius: 20

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 2

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    color: window.subtext0
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    text: "Daily average"
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    color: window.text
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 20
                                    font.weight: Font.Bold
                                    text: window.formatTimeList(window.averageSeconds)
                                }
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    color: window.overlay0
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    text: window.weekRangeStr
                                    visible: window.weekRangeStr !== ""
                                }
                            }
                        }

                        // CENTER: Usage Time (3/7 weight = 300)
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Layout.preferredWidth: 300
                            border.color: Qt.alpha(window.surface1, 0.3)
                            border.width: 1
                            color: window.base
                            radius: 20

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 0

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    color: window.text
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 36
                                    font.weight: Font.Black
                                    text: window.formatTimeLarge(window.animatedTotalSeconds)
                                }
                            }
                        }

                        // RIGHT: vs Yesterday (2/7 weight = 200)
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Layout.preferredWidth: 200
                            border.color: Qt.alpha(window.surface1, 0.3)
                            border.width: 1
                            color: window.base
                            radius: 20

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4

                                // Trend Row
                                RowLayout {
                                    Layout.alignment: Qt.AlignHCenter
                                    spacing: 6
                                    visible: !(window.totalSeconds === 0 && window.yesterdaySeconds === 0) && window.totalSeconds !== window.yesterdaySeconds

                                    Text {
                                        color: {
                                            let diff = window.totalSeconds - window.yesterdaySeconds;
                                            return diff > 0 ? window.peach : window.green;
                                        }
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 16
                                        font.weight: Font.Bold
                                        text: (window.totalSeconds - window.yesterdaySeconds) > 0 ? "↑" : "↓"
                                    }
                                    Text {
                                        color: {
                                            let diff = window.totalSeconds - window.yesterdaySeconds;
                                            return diff > 0 ? window.peach : window.green;
                                        }
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 16
                                        font.weight: Font.Bold
                                        text: {
                                            let diff = window.totalSeconds - window.yesterdaySeconds;
                                            return window.formatTimeList(Math.abs(diff));
                                        }
                                    }
                                }

                                // No Data / Same fallback
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    color: window.overlay0
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 15
                                    font.weight: Font.DemiBold
                                    text: (window.totalSeconds === 0 && window.yesterdaySeconds === 0) ? "No data" : "Same time"
                                    visible: (window.totalSeconds === 0 && window.yesterdaySeconds === 0) || window.totalSeconds === window.yesterdaySeconds
                                }

                                // Subtext
                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    color: window.subtext0
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    text: "vs yesterday"
                                    visible: !(window.totalSeconds === 0 && window.yesterdaySeconds === 0)
                                }
                            }
                        }
                    }

                    // ==========================================
                    // 2. MIDDLE CHARTS (Week + Heatmap)
                    // ==========================================
                    RowLayout {
                        id: middleSection

                        Layout.fillHeight: false
                        Layout.fillWidth: true
                        Layout.preferredHeight: 160
                        spacing: 16

                        // LEFT: Weekly Close-Knit Bar Chart
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Layout.preferredWidth: 400
                            border.color: Qt.alpha(window.surface1, 0.3)
                            border.width: 1
                            color: window.base
                            radius: 20

                            RowLayout {
                                anchors.centerIn: parent
                                height: parent.height - 32
                                spacing: 12

                                Repeater {
                                    model: weekListModel

                                    delegate: Item {
                                        Layout.fillHeight: true
                                        Layout.preferredWidth: 45

                                        MouseArea {
                                            id: barMa

                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            hoverEnabled: true

                                            onClicked: {
                                                window.changeToDate(model.dateStr);
                                            }
                                        }
                                        Item {
                                            anchors.bottom: dayLbl.top
                                            anchors.bottomMargin: 8
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            height: Math.max(4, (parent.height - 25) * (model.total / Math.max(window.maxWeekTotal, 1)))
                                            width: 45

                                            Behavior on height {
                                                NumberAnimation {
                                                    duration: window.isFirstLoad ? 800 : 600
                                                    easing.type: Easing.OutQuint
                                                }
                                            }

                                            Rectangle {
                                                anchors.fill: parent
                                                color: window.surface0
                                                opacity: barMa.containsMouse ? 0.7 : 1.0
                                                radius: 4
                                                visible: !model.isTarget

                                                Behavior on color {
                                                    ColorAnimation {
                                                        duration: 400
                                                        easing.type: Easing.OutCubic
                                                    }
                                                }
                                            }
                                            Rectangle {
                                                anchors.fill: parent
                                                opacity: barMa.containsMouse ? 0.7 : 1.0
                                                radius: 4
                                                visible: model.isTarget

                                                gradient: Gradient {
                                                    GradientStop {
                                                        color: window.mauve
                                                        position: 0.0
                                                    }
                                                    GradientStop {
                                                        color: window.blue
                                                        position: 1.0
                                                    }
                                                }
                                            }
                                        }
                                        Text {
                                            id: dayLbl

                                            anchors.bottom: parent.bottom
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            color: model.isTarget ? window.text : window.overlay0
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 12
                                            font.weight: Font.DemiBold
                                            text: model.dayName

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 400
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        // RIGHT: Calendar Month Heatmap
                        Rectangle {
                            Layout.fillHeight: true
                            Layout.fillWidth: true
                            Layout.preferredWidth: 300
                            border.color: Qt.alpha(window.surface1, 0.3)
                            border.width: 1
                            color: window.base
                            radius: 20

                            ColumnLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 8

                                Text {
                                    Layout.alignment: Qt.AlignHCenter
                                    color: window.text
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 14
                                    font.weight: Font.DemiBold
                                    text: window.monthNames[window.activeDate.getMonth()]
                                }
                                Grid {
                                    Layout.alignment: Qt.AlignCenter
                                    columns: 7
                                    flow: Grid.LeftToRight
                                    spacing: 6

                                    Repeater {
                                        model: monthListModel

                                        delegate: Rectangle {
                                            border.color: model.isTarget ? window.text : "transparent"
                                            border.width: model.isTarget ? 1 : 0
                                            color: model.total === -1 ? "transparent" : (model.total === 0 ? window.surface0 : Qt.rgba(window.mauve.r, window.mauve.g, window.mauve.b, Math.min(1.0, 0.3 + 0.7 * (model.total / window.maxMonthTotal))))
                                            height: 18
                                            radius: 4
                                            visible: model.total !== -1
                                            width: 18

                                            Behavior on border.color {
                                                ColorAnimation {
                                                    duration: 300
                                                }
                                            }
                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 700
                                                    easing.type: Easing.OutQuint
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                enabled: model.total !== -1
                                                hoverEnabled: true

                                                onClicked: {
                                                    if (model.total !== -1) {
                                                        window.changeToDate(model.dateStr);
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
                    // 3. BOTTOM CARD (App List OR Hourly Chart)
                    // ==========================================
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        border.color: Qt.alpha(window.surface1, 0.3)
                        border.width: 1
                        color: window.base
                        radius: 20

                        // --- VIEW A: App List ---
                        ListView {
                            id: appList

                            anchors.bottomMargin: 12
                            anchors.fill: parent
                            anchors.margins: 8
                            anchors.topMargin: 12
                            clip: true
                            interactive: true
                            model: appListModel
                            spacing: 2
                            visible: window.selectedAppClass === ""

                            ScrollBar.vertical: ScrollBar {
                                active: appList.moving || appList.movingVertically
                                policy: ScrollBar.AsNeeded
                                width: 4

                                contentItem: Rectangle {
                                    color: window.surface2
                                    implicitWidth: 4
                                    radius: 2
                                }
                            }
                            delegate: Rectangle {
                                color: "transparent"
                                height: 58
                                radius: 12
                                width: ListView.view.width

                                Rectangle {
                                    anchors.fill: parent
                                    color: rowMa.containsMouse ? window.surface0 : "transparent"
                                    radius: 12

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }
                                MouseArea {
                                    id: rowMa

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    onClicked: {
                                        window.selectedAppClass = model.appClass;
                                        window.selectedAppName = model.name;
                                        window.selectedAppIcon = model.icon;
                                        window.appDate = new Date(); // Always start app view on today
                                        window.requestDataUpdate();
                                    }
                                }
                                ColumnLayout {
                                    anchors.bottomMargin: 10
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    anchors.topMargin: 10
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Image {
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.preferredHeight: 20
                                            Layout.preferredWidth: 20
                                            Layout.rightMargin: 8
                                            fillMode: Image.PreserveAspectFit
                                            source: model.icon.startsWith("/") ? "file://" + model.icon : "image://icon/" + model.icon
                                            sourceSize: Qt.size(20, 20)
                                            visible: model.icon !== ""
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            color: window.text
                                            elide: Text.ElideRight
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 15
                                            font.weight: Font.DemiBold
                                            text: model.name
                                        }
                                        Text {
                                            color: window.subtext0
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                            text: window.formatTimeList(model.seconds)
                                        }
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                        height: 10

                                        Rectangle {
                                            anchors.fill: parent
                                            color: window.crust
                                            radius: 5
                                        }
                                        Rectangle {
                                            height: parent.height
                                            radius: 5
                                            width: Math.max(10, parent.width * (model.percent / 100.0))

                                            gradient: Gradient {
                                                orientation: Gradient.Horizontal

                                                GradientStop {
                                                    color: window.mauve
                                                    position: 0.0
                                                }
                                                GradientStop {
                                                    color: window.blue
                                                    position: 1.0
                                                }
                                            }
                                            Behavior on width {
                                                NumberAnimation {
                                                    duration: 800
                                                    easing.type: Easing.OutQuint
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            move: Transition {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.OutQuint
                                    properties: "x,y"
                                }
                            }
                        }

                        // --- VIEW B: 24-Hour App Activity Chart (Now 48 chunks / 30 mins) ---
                        ColumnLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12
                            visible: window.selectedAppClass !== ""

                            Text {
                                Layout.alignment: Qt.AlignHCenter
                                color: window.text
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                text: "Daily usage"
                            }
                            RowLayout {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                spacing: 4

                                Repeater {
                                    model: 48 // 2 bars per hour (30 min intervals)

                                    delegate: Item {
                                        Layout.fillHeight: true
                                        Layout.fillWidth: true

                                        Rectangle {
                                            anchors.bottom: parent.bottom
                                            color: window.hourlyData[index] > 0 ? window.blue : window.surface0
                                            height: Math.max(4, parent.height * (window.hourlyData[index] / Math.max(window.maxHourlyTotal, 1)))
                                            radius: 2
                                            width: parent.width

                                            Behavior on color {
                                                ColorAnimation {
                                                    duration: 400
                                                }
                                            }
                                            Behavior on height {
                                                NumberAnimation {
                                                    duration: 600
                                                    easing.type: Easing.OutQuint
                                                }
                                            }

                                            MouseArea {
                                                anchors.fill: parent
                                                hoverEnabled: true

                                                onEntered: {
                                                    parent.opacity = 0.7;
                                                }
                                                onExited: {
                                                    parent.opacity = 1.0;
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // X-Axis Labels 24h
                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    color: window.overlay0
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    text: "00:00"
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                                Text {
                                    color: window.overlay0
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    text: "06:00"
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                                Text {
                                    color: window.overlay0
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    text: "12:00"
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                                Text {
                                    color: window.overlay0
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    text: "18:00"
                                }
                                Item {
                                    Layout.fillWidth: true
                                }
                                Text {
                                    color: window.overlay0
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 11
                                    font.weight: Font.Medium
                                    text: "23:00"
                                }
                            }
                        }
                    }
                } // End of Daily View Wrapper

                // ==========================================
                // WEEK VIEW WRAPPER
                // ==========================================
                ColumnLayout {
                    id: weekViewWrapper

                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    spacing: 16
                    visible: window.isWeekView

                    // Week Heatmap Card
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 260 // Adjusted to fit 7 rows + spacing cleanly
                        border.color: Qt.alpha(window.surface1, 0.3)
                        border.width: 1
                        color: window.base
                        radius: 20

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 16

                            // LEFT: 4/5 Heatmap layout
                            ColumnLayout {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                Layout.preferredWidth: 400
                                spacing: 4

                                Repeater {
                                    model: 7

                                    delegate: RowLayout {
                                        property int dayIndex: index

                                        Layout.fillHeight: true
                                        Layout.fillWidth: true
                                        spacing: 8

                                        Text {
                                            Layout.preferredWidth: 75
                                            color: window.subtext0
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 12
                                            font.weight: Font.Normal
                                            text: ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday"][dayIndex]
                                            verticalAlignment: Text.AlignVCenter
                                        }

                                        // Wrapper rectangle to clip the unified bar edges
                                        Rectangle {
                                            Layout.fillHeight: true
                                            Layout.fillWidth: true
                                            clip: true
                                            color: "transparent"
                                            radius: 10

                                            RowLayout {
                                                anchors.fill: parent
                                                spacing: 0

                                                Repeater {
                                                    model: 24

                                                    delegate: Rectangle {
                                                        property real val: (window.weekHeatmapData[dayIndex] && window.weekHeatmapData[dayIndex][index]) ? window.weekHeatmapData[dayIndex][index] : 0

                                                        Layout.fillHeight: true
                                                        Layout.fillWidth: true
                                                        color: val === 0 ? window.surface0 : Qt.rgba(window.mauve.r, window.mauve.g, window.mauve.b, Math.min(1.0, 0.2 + 0.8 * (val / Math.max(window.maxWeekHour, 1))))
                                                        radius: 0

                                                        Behavior on color {
                                                            ColorAnimation {
                                                                duration: 600
                                                                easing.type: Easing.OutQuint
                                                            }
                                                        }

                                                        MouseArea {
                                                            anchors.fill: parent
                                                            hoverEnabled: true

                                                            onEntered: parent.opacity = 0.7
                                                            onExited: parent.opacity = 1.0
                                                        }
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }

                                // X axis for heatmap hours 24h
                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.topMargin: 4

                                    Item {
                                        Layout.preferredWidth: 75
                                    } // Label Spacer
                                    Text {
                                        Layout.alignment: Qt.AlignLeft
                                        color: window.overlay0
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        text: "00:00"
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        color: window.overlay0
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        text: "06:00"
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        color: window.overlay0
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        text: "12:00"
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignHCenter
                                        color: window.overlay0
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        text: "18:00"
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                    }
                                    Text {
                                        Layout.alignment: Qt.AlignRight
                                        color: window.overlay0
                                        font.family: "FiraCode Nerd Font Mono"
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                        text: "23:00"
                                    }
                                }
                            }

                            // RIGHT: 1/5 Stats side by side layout
                            ColumnLayout {
                                Layout.fillHeight: true
                                Layout.fillWidth: true
                                Layout.preferredWidth: 100
                                spacing: 12

                                // Top Half: Daily Avg
                                Rectangle {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    color: window.surface0
                                    radius: 12

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            color: window.subtext0
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 12
                                            font.weight: Font.Medium
                                            text: "Daily average"
                                        }
                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            color: window.text
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 18
                                            font.weight: Font.Bold
                                            text: window.formatTimeList(window.averageSeconds)
                                        }
                                    }
                                }

                                // Bottom Half: Peak Hours
                                Rectangle {
                                    Layout.fillHeight: true
                                    Layout.fillWidth: true
                                    color: window.surface0
                                    radius: 12

                                    ColumnLayout {
                                        anchors.centerIn: parent
                                        spacing: 4

                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            color: window.subtext0
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 12
                                            font.weight: Font.Medium
                                            text: "Peak hours"
                                        }
                                        Text {
                                            Layout.alignment: Qt.AlignHCenter
                                            color: window.text
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 14
                                            font.weight: Font.Bold
                                            text: window.peakUsageHours
                                        }
                                    }
                                }
                            }
                        }
                    }

                    // Week Top Apps Card
                    Rectangle {
                        Layout.fillHeight: true
                        Layout.fillWidth: true
                        border.color: Qt.alpha(window.surface1, 0.3)
                        border.width: 1
                        color: window.base
                        radius: 20

                        ListView {
                            id: weekAppList

                            anchors.bottomMargin: 12
                            anchors.fill: parent
                            anchors.margins: 8
                            anchors.topMargin: 12
                            clip: true
                            interactive: true
                            model: weekAppListModel
                            spacing: 2

                            ScrollBar.vertical: ScrollBar {
                                active: weekAppList.moving || weekAppList.movingVertically
                                policy: ScrollBar.AsNeeded
                                width: 4

                                contentItem: Rectangle {
                                    color: window.surface2
                                    implicitWidth: 4
                                    radius: 2
                                }
                            }
                            delegate: Rectangle {
                                color: "transparent"
                                height: 58
                                radius: 12
                                width: ListView.view.width

                                Rectangle {
                                    anchors.fill: parent
                                    color: weekRowMa.containsMouse ? window.surface0 : "transparent"
                                    radius: 12

                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }
                                }
                                MouseArea {
                                    id: weekRowMa

                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true

                                    onClicked: {
                                        window.selectedAppClass = model.appClass;
                                        window.selectedAppName = model.name;
                                        window.selectedAppIcon = model.icon;
                                        window.appDate = new Date();
                                        window.isWeekView = false; // Bypasses the week view when clicking back later
                                        window.requestDataUpdate();
                                    }
                                }
                                ColumnLayout {
                                    anchors.bottomMargin: 10
                                    anchors.fill: parent
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 16
                                    anchors.topMargin: 10
                                    spacing: 6

                                    RowLayout {
                                        Layout.fillWidth: true

                                        Image {
                                            Layout.alignment: Qt.AlignVCenter
                                            Layout.preferredHeight: 20
                                            Layout.preferredWidth: 20
                                            Layout.rightMargin: 8
                                            fillMode: Image.PreserveAspectFit
                                            source: model.icon.startsWith("/") ? "file://" + model.icon : "image://icon/" + model.icon
                                            sourceSize: Qt.size(20, 20)
                                            visible: model.icon !== ""
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            color: window.text
                                            elide: Text.ElideRight
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 15
                                            font.weight: Font.DemiBold
                                            text: model.name
                                        }
                                        Text {
                                            color: window.subtext0
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 14
                                            font.weight: Font.Medium
                                            text: window.formatTimeList(model.seconds)
                                        }
                                    }
                                    Item {
                                        Layout.fillWidth: true
                                        height: 10

                                        Rectangle {
                                            anchors.fill: parent
                                            color: window.crust
                                            radius: 5
                                        }
                                        Rectangle {
                                            height: parent.height
                                            radius: 5
                                            width: Math.max(10, parent.width * (model.percent / 100.0))

                                            gradient: Gradient {
                                                orientation: Gradient.Horizontal

                                                GradientStop {
                                                    color: window.mauve
                                                    position: 0.0
                                                }
                                                GradientStop {
                                                    color: window.blue
                                                    position: 1.0
                                                }
                                            }
                                            Behavior on width {
                                                NumberAnimation {
                                                    duration: 800
                                                    easing.type: Easing.OutQuint
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                            move: Transition {
                                NumberAnimation {
                                    duration: 400
                                    easing.type: Easing.OutQuint
                                    properties: "x,y"
                                }
                            }
                        }
                    }
                } // End Week View Wrapper
            }
        }
    }
}
