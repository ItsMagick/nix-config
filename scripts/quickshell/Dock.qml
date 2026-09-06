import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: dockWindow

    property var appsData: []
    property var filteredApps: {
        let dummy = appsData;
        let result = dummy.slice();

        if (searchText !== "") {
            let lowerSearch = searchText.toLowerCase();
            result = result.filter(app => app.name.toLowerCase().includes(lowerSearch));
        }

        return result.sort(function (a, b) {
            if (a.pinned === b.pinned) {
                return a.name.localeCompare(b.name);
            }
            return a.pinned ? -1 : 1;
        });
    }
    property bool isSettingsOpen: false

    // --- State Variables ---
    property bool isStartupReady: false
    property var pinnedApps: {
        let pinned = [];
        for (let i = 0; i < appsData.length; i++) {
            if (appsData[i].pinned)
                pinned.push(appsData[i]);
        }
        return pinned;
    }
    property string searchText: ""

    function toggleApp(appName) {
        let newArray = [];
        for (let i = 0; i < dockWindow.appsData.length; i++) {
            let item = Object.assign({}, dockWindow.appsData[i]);
            if (item.name === appName) {
                item.pinned = !item.pinned;
            }
            newArray.push(item);
        }
        dockWindow.appsData = newArray;

        let safeName = appName.replace(/'/g, "'\\''");
        Quickshell.execDetached(["zsh", "-c", "~/.config/hypr/scripts/quickshell/dock_backend.sh toggle '" + safeName + "'"]);
    }

    WlrLayershell.namespace: "qsdock"
    color: "transparent"
    exclusiveZone: 0
    focusable: true

    // FIX 2: Added a + 50 buffer to the height.
    // This expands the invisible window boundary upwards so tooltips and popups don't get clipped.
    height: dockContainer.height + settingsPanel.height + 70

    anchors {
        bottom: true
        left: true
        right: true
    }
    margins {
        bottom: 8
    }
    MatugenColors {
        id: mocha
    }
    Timer {
        interval: 10
        running: true

        onTriggered: dockWindow.isStartupReady = true
    }

    // ==========================================
    // DATA FETCHING
    // ==========================================
    Process {
        id: appPoller

        command: ["zsh", "-c", "~/.config/hypr/scripts/quickshell/dock_backend.sh get"]

        stdout: StdioCollector {
            onStreamFinished: {
                let txt = this.text.trim();
                if (txt !== "") {
                    try {
                        dockWindow.appsData = JSON.parse(txt);
                    } catch (e) {}
                }
            }
        }
    }
    Timer {
        interval: 100
        repeat: false
        running: true

        onTriggered: appPoller.running = true
    }

    // ==========================================
    // UI LAYOUT
    // ==========================================
    Item {
        anchors.fill: parent
        focus: true

        Keys.onPressed: event => {
            if (event.key === Qt.Key_Escape) {
                dockWindow.isSettingsOpen = false;
                event.accepted = true;
                return;
            }

            if (event.key === Qt.Key_Meta || event.key === Qt.Key_Super_L || event.key === Qt.Key_Super_R || event.key === Qt.Key_Alt || event.key === Qt.Key_Control) {
                return;
            }

            // FIX 1: Only catch typing IF the settings window is already manually opened.
            if (dockWindow.isSettingsOpen && !searchInput.activeFocus && event.text.length > 0) {
                searchInput.forceActiveFocus();
                searchInput.text += event.text;
                event.accepted = true;
            }
        }

        // ---------------- SETTINGS SLIDE OUT ----------------
        Rectangle {
            id: settingsPanel

            anchors.bottom: dockContainer.top
            anchors.bottomMargin: 10
            anchors.horizontalCenter: parent.horizontalCenter
            border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.15)
            border.width: 1
            clip: true
            color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.95)
            height: isSettingsOpen ? 400 : 0
            opacity: isSettingsOpen ? 1 : 0
            radius: 14
            visible: height > 0
            width: 400

            Behavior on opacity {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    border.color: searchInput.activeFocus ? mocha.mauve : Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.1)
                    border.width: 1
                    color: Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.8)
                    radius: 8

                    Behavior on border.color {
                        ColorAnimation {
                            duration: 200
                        }
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            color: searchInput.activeFocus ? mocha.mauve : mocha.text
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 16
                            text: "󰍉"
                        }
                        TextField {
                            id: searchInput

                            Layout.fillWidth: true
                            color: mocha.text
                            font.family: "FiraCode Nerd Font Mono"
                            font.pixelSize: 13
                            placeholderText: "Search..."
                            placeholderTextColor: mocha.subtext0

                            background: Item {
                            }

                            Keys.onEscapePressed: {
                                dockWindow.isSettingsOpen = false;
                                dockWindow.forceActiveFocus();
                            }
                            onTextChanged: dockWindow.searchText = text

                            Connections {
                                function onIsSettingsOpenChanged() {
                                    if (!dockWindow.isSettingsOpen)
                                        searchInput.text = "";
                                }

                                target: dockWindow
                            }
                        }
                    }
                }
                Rectangle {
                    Layout.fillWidth: true
                    color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.1)
                    height: 1
                }
                ListView {
                    Layout.fillHeight: true
                    Layout.fillWidth: true
                    boundsBehavior: Flickable.StopAtBounds
                    clip: true
                    model: dockWindow.filteredApps
                    spacing: 4

                    ScrollBar.vertical: ScrollBar {
                        policy: ScrollBar.AlwaysOff
                    }
                    delegate: Rectangle {
                        color: settingsItemMouse.containsMouse ? Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.5) : "transparent"
                        height: 42
                        radius: 8
                        width: ListView.view.width

                        Behavior on color {
                            ColorAnimation {
                                duration: 150
                            }
                        }
                        transform: Translate {
                            x: settingsItemMouse.containsMouse ? 6 : 0
                        }
                        Behavior on transform {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutExpo
                            }
                        }

                        Item {
                            anchors.fill: parent

                            Image {
                                id: appIcon

                                anchors.left: parent.left
                                anchors.leftMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                fillMode: Image.PreserveAspectFit
                                height: 24
                                source: "image://icon/" + modelData.icon
                                sourceSize: Qt.size(24, 24)
                                width: 24
                            }
                            Text {
                                anchors.left: appIcon.right
                                anchors.leftMargin: 12
                                anchors.right: checkIndicator.left
                                anchors.rightMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                color: mocha.text
                                elide: Text.ElideRight
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 13
                                font.weight: Font.Medium
                                text: modelData.name
                            }
                            Rectangle {
                                id: checkIndicator

                                anchors.right: parent.right
                                anchors.rightMargin: 10
                                anchors.verticalCenter: parent.verticalCenter
                                border.color: modelData.pinned ? mocha.mauve : mocha.surface2
                                border.width: 2
                                color: modelData.pinned ? mocha.mauve : "transparent"
                                height: 20
                                radius: 10
                                width: 20

                                Behavior on color {
                                    ColorAnimation {
                                        duration: 200
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    color: mocha.base
                                    font.family: "FiraCode Nerd Font Mono"
                                    font.pixelSize: 12
                                    opacity: modelData.pinned ? 1 : 0
                                    text: ""

                                    Behavior on opacity {
                                        NumberAnimation {
                                            duration: 200
                                        }
                                    }
                                }
                            }
                        }
                        MouseArea {
                            id: settingsItemMouse

                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: {
                                dockWindow.toggleApp(modelData.name);
                                searchInput.forceActiveFocus();
                            }
                        }
                    }
                }
            }
        }

        // ---------------- MAIN DOCK ----------------
        Rectangle {
            id: dockContainer

            property bool isHovered: dockMouse.containsMouse
            property bool showLayout: false

            anchors.bottom: parent.bottom
            anchors.horizontalCenter: parent.horizontalCenter
            border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, isHovered ? 0.15 : 0.05)
            border.width: 1
            color: isHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.95) : Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.75)
            height: 56
            opacity: showLayout ? 1 : 0
            radius: 24
            width: dockLayout.implicitWidth + 32

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
            transform: Translate {
                y: dockContainer.showLayout ? 0 : 20

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
                running: dockWindow.isStartupReady

                onTriggered: dockContainer.showLayout = true
            }
            MouseArea {
                id: dockMouse

                anchors.fill: parent
                hoverEnabled: true
            }
            RowLayout {
                id: dockLayout

                anchors.centerIn: parent
                spacing: 12

                Repeater {
                    model: dockWindow.pinnedApps

                    delegate: Item {
                        id: dockAppDelegate

                        property bool itemHovered: appMouseArea.containsMouse

                        Layout.preferredHeight: 42
                        Layout.preferredWidth: 42

                        Item {
                            anchors.fill: parent
                            scale: appMouseArea.pressed ? 0.85 : (itemHovered ? 1.15 : 1.0)

                            Behavior on scale {
                                NumberAnimation {
                                    duration: appMouseArea.pressed ? 50 : 250
                                    easing.type: appMouseArea.pressed ? Easing.OutQuad : Easing.OutBack
                                }
                            }

                            Rectangle {
                                anchors.fill: parent
                                border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, itemHovered ? 0.15 : 0.05)
                                border.width: 1
                                color: itemHovered ? Qt.rgba(mocha.surface1.r, mocha.surface1.g, mocha.surface1.b, 0.9) : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.4)
                                radius: 12

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
                            }
                            Image {
                                anchors.centerIn: parent
                                fillMode: Image.PreserveAspectFit
                                height: 28
                                source: "image://icon/" + modelData.icon
                                sourceSize: Qt.size(28, 28)
                                width: 28
                            }
                        }
                        Rectangle {
                            anchors.bottom: parent.top
                            anchors.bottomMargin: 10
                            anchors.horizontalCenter: parent.horizontalCenter
                            border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.1)
                            border.width: 1
                            color: mocha.surface0
                            height: 28

                            // Hide tooltip if the context menu is open
                            opacity: (parent.itemHovered && !contextMenu.visible) ? 1 : 0
                            radius: 6
                            width: tooltipText.implicitWidth + 16

                            Behavior on opacity {
                                NumberAnimation {
                                    duration: 200
                                }
                            }
                            transform: Translate {
                                y: parent.itemHovered ? 0 : 5
                            }
                            Behavior on transform {
                                NumberAnimation {
                                    duration: 200
                                    easing.type: Easing.OutExpo
                                }
                            }

                            Text {
                                id: tooltipText

                                anchors.centerIn: parent
                                color: mocha.text
                                font.family: "FiraCode Nerd Font Mono"
                                font.pixelSize: 11
                                font.weight: Font.Bold
                                text: modelData.name
                            }
                        }

                        // FIX 4: Custom Right-Click Context Menu
                        Popup {
                            id: contextMenu

                            height: menuColumn.implicitHeight + 16
                            padding: 8
                            width: 160

                            // Center horizontally above the icon
                            x: (parent.width - width) / 2
                            y: -height - 15

                            background: Rectangle {
                                border.color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.15)
                                border.width: 1
                                color: Qt.rgba(mocha.base.r, mocha.base.g, mocha.base.b, 0.95)
                                radius: 12
                            }
                            enter: Transition {
                                NumberAnimation {
                                    duration: 150
                                    from: 0
                                    property: "opacity"
                                    to: 1
                                }
                            }
                            exit: Transition {
                                NumberAnimation {
                                    duration: 150
                                    from: 1
                                    property: "opacity"
                                    to: 0
                                }
                            }

                            ColumnLayout {
                                id: menuColumn

                                anchors.fill: parent
                                spacing: 4

                                // Open Button
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    color: openCtxMouse.containsMouse ? Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.8) : "transparent"
                                    radius: 6

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 10

                                        Text {
                                            color: mocha.text
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 14
                                            text: "󰝰"
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            color: mocha.text
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 12
                                            text: "Open"
                                        }
                                    }
                                    MouseArea {
                                        id: openCtxMouse

                                        anchors.fill: parent
                                        hoverEnabled: true

                                        onClicked: {
                                            contextMenu.close();
                                            if (dockWindow.isSettingsOpen)
                                                dockWindow.isSettingsOpen = false;
                                            Quickshell.execDetached(["zsh", "-c", modelData.exec]);
                                        }
                                    }
                                }

                                // Unpin Button
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 32
                                    color: unpinCtxMouse.containsMouse ? Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.8) : "transparent"
                                    radius: 6

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 10

                                        Text {
                                            color: mocha.red
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 14
                                            text: "󰅖"
                                        }
                                        Text {
                                            Layout.fillWidth: true
                                            color: mocha.red
                                            font.family: "FiraCode Nerd Font Mono"
                                            font.pixelSize: 12
                                            text: "Unpin"
                                        }
                                    }
                                    MouseArea {
                                        id: unpinCtxMouse

                                        anchors.fill: parent
                                        hoverEnabled: true

                                        onClicked: {
                                            contextMenu.close();
                                            dockWindow.toggleApp(modelData.name);
                                        }
                                    }
                                }
                            }
                        }
                        MouseArea {
                            id: appMouseArea

                            // Accept both buttons so right click doesn't fall through
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            anchors.fill: parent
                            hoverEnabled: true

                            onClicked: mouse => {
                                if (mouse.button === Qt.LeftButton) {
                                    if (dockWindow.isSettingsOpen)
                                        dockWindow.isSettingsOpen = false;
                                    Quickshell.execDetached(["zsh", "-c", modelData.exec]);
                                } else if (mouse.button === Qt.RightButton) {
                                    contextMenu.open();
                                }
                            }
                        }
                    }
                }
                Rectangle {
                    Layout.preferredHeight: 24
                    Layout.preferredWidth: 1
                    color: Qt.rgba(mocha.text.r, mocha.text.g, mocha.text.b, 0.15)
                    visible: dockWindow.pinnedApps.length > 0
                }
                Item {
                    id: gearContainer

                    property bool btnHovered: settingsMouse.containsMouse

                    Layout.preferredHeight: 42
                    Layout.preferredWidth: 42

                    Rectangle {
                        anchors.fill: parent
                        color: dockWindow.isSettingsOpen ? mocha.surface2 : Qt.rgba(mocha.surface0.r, mocha.surface0.g, mocha.surface0.b, 0.6)
                        opacity: gearContainer.btnHovered || dockWindow.isSettingsOpen ? 1 : 0
                        radius: 12
                        scale: gearContainer.btnHovered ? 1.15 : 1.0

                        Behavior on color {
                            ColorAnimation {
                                duration: 200
                            }
                        }
                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                        Behavior on scale {
                            NumberAnimation {
                                duration: 250
                                easing.type: Easing.OutBack
                            }
                        }
                    }
                    Text {
                        anchors.centerIn: parent
                        color: mocha.text
                        font.family: "FiraCode Nerd Font Mono"
                        font.pixelSize: 22
                        opacity: gearContainer.btnHovered || dockWindow.isSettingsOpen ? 1.0 : 0.6
                        text: ""

                        Behavior on opacity {
                            NumberAnimation {
                                duration: 200
                            }
                        }
                    }
                    MouseArea {
                        id: settingsMouse

                        anchors.fill: parent
                        hoverEnabled: true

                        onClicked: dockWindow.isSettingsOpen = !dockWindow.isSettingsOpen
                    }
                }
            }
        }
    }
}
