import QtQuick
import QtQuick.Window
import QtQuick.Controls
import Quickshell
import Quickshell.Io

FloatingWindow {
    id: masterWindow

    property string activeArg: ""
    property real animH: 1
    property real animW: 1
    property string currentActive: "hidden"

    // Safe park coordinates to avoid cursor traps
    property int currentX: -5000
    property int currentY: -5000
    property bool disableMorph: false
    property bool isVisible: false
    property bool isWallpaperTransition: false
    property var layouts: {
        "battery": {
            w: 480,
            h: 760,
            x: screenW - 500,
            y: 70,
            comp: "battery/BatteryPopup.qml"
        },
        "calendar": {
            w: 1450,
            h: 750,
            x: 235,
            y: 70,
            comp: "calendar/CalendarPopup.qml"
        },
        "music": {
            w: 700,
            h: 620,
            x: 12,
            y: 70,
            comp: "music/MusicPopup.qml"
        },
        "network": {
            w: 900,
            h: 700,
            x: screenW - 920,
            y: 70,
            comp: "network/NetworkPopup.qml"
        },
        "stewart": {
            w: 800,
            h: 600,
            x: Math.floor((screenW / 2) - (800 / 2)),
            y: Math.floor((screenH / 2) - (600 / 2)),
            comp: "stewart/stewart.qml"
        },
        "wallpaper": {
            w: 1920,
            h: 500,
            x: 0,
            y: Math.floor((screenH / 2) - (500 / 2)),
            comp: "wallpaper/WallpaperPicker.qml"
        },
        "monitors": {
            w: 850,
            h: 580,
            x: Math.floor((screenW / 2) - (850 / 2)),
            y: Math.floor((screenH / 2) - (580 / 2)),
            comp: "monitors/MonitorPopup.qml"
        },
        "focustime": {
            w: 900,
            h: 720,
            x: Math.floor((screenW / 2) - (900 / 2)),
            y: Math.floor((screenH / 2) - (720 / 2)),
            comp: "focustime/FocusTimePopup.qml"
        },
        "hidden": {
            w: 1,
            h: 1,
            x: -5000,
            y: -5000,
            comp: ""
        }
    }

    // NEW: Dynamic duration to allow fast opening but keep morphing smooth
    property int morphDuration: 500
    property int screenH: 1080
    property int screenW: 1920

    function executeSwitch(newWidget, arg, immediate) {
        masterWindow.currentActive = newWidget;
        masterWindow.activeArg = arg;

        let t = layouts[newWidget];
        masterWindow.animW = t.w;
        masterWindow.animH = t.h;
        masterWindow.width = t.w;
        masterWindow.height = t.h;
        masterWindow.currentX = t.x;
        masterWindow.currentY = t.y;

        Quickshell.execDetached(["zsh", "-c", `hyprctl dispatch resizewindowpixel "exact ${t.w} ${t.h},title:^(qs-master)$" && hyprctl dispatch movewindowpixel "exact ${t.x} ${t.y},title:^(qs-master)$"`]);

        masterWindow.isVisible = true;

        let props = newWidget === "wallpaper" ? {
            "widgetArg": arg
        } : {};

        if (immediate) {
            widgetStack.replace(t.comp, props, StackView.Immediate);
        } else {
            widgetStack.replace(t.comp, props);
        }
    }
    function switchWidget(newWidget, arg) {
        let involvesWallpaper = (newWidget === "wallpaper" || currentActive === "wallpaper");
        masterWindow.isWallpaperTransition = involvesWallpaper;

        if (newWidget === "hidden") {
            if (currentActive !== "hidden" && layouts[currentActive]) {
                masterWindow.morphDuration = 250; // FAST CLOSE
                masterWindow.disableMorph = false;
                let t = layouts[currentActive];
                let cx = Math.floor(t.x + (t.w / 2));
                let cy = Math.floor(t.y + (t.h / 2));

                masterWindow.animW = 1;
                masterWindow.animH = 1;
                masterWindow.isVisible = false;

                Quickshell.execDetached(["zsh", "-c", `hyprctl dispatch resizewindowpixel "exact 1 1,title:^(qs-master)$" && hyprctl dispatch movewindowpixel "exact ${cx} ${cy},title:^(qs-master)$"`]);
                delayedClear.start();
            }
        } else {
            if (currentActive === "hidden") {
                masterWindow.morphDuration = 250; // FAST INITIAL OPEN
                masterWindow.disableMorph = false;
                let t = layouts[newWidget];
                let cx = Math.floor(t.x + (t.w / 2));
                let cy = Math.floor(t.y + (t.h / 2));

                masterWindow.animW = 1;
                masterWindow.animH = 1;
                masterWindow.width = 1;
                masterWindow.height = 1;

                Quickshell.execDetached(["zsh", "-c", `hyprctl dispatch movewindowpixel "exact ${cx} ${cy},title:^(qs-master)$"`]);

                prepTimer.newWidget = newWidget;
                prepTimer.newArg = arg;
                prepTimer.start();
            } else {
                masterWindow.morphDuration = 500; // SMOOTH MORPH BETWEEN WIDGETS
                if (involvesWallpaper) {
                    masterWindow.disableMorph = true;
                    masterWindow.isVisible = false;
                    teleportFadeOutTimer.newWidget = newWidget;
                    teleportFadeOutTimer.newArg = arg;
                    teleportFadeOutTimer.start();
                } else {
                    masterWindow.disableMorph = false;
                    executeSwitch(newWidget, arg, false);
                }
            }
        }
    }

    color: "transparent"
    height: 1
    implicitHeight: height
    implicitWidth: width
    title: "qs-master"

    // Always mapped to prevent Wayland from destroying the surface and Hyprland from auto-centering!
    visible: true
    width: 1

    // Push it off-screen the moment the component loads using Hyprland's dispatcher
    Component.onCompleted: {
        Quickshell.execDetached(["zsh", "-c", `hyprctl dispatch resizewindowpixel "exact 1 1,title:^(qs-master)$" && hyprctl dispatch movewindowpixel "exact -5000 -5000,title:^(qs-master)$"`]);
    }
    onCurrentActiveChanged: {
        Quickshell.execDetached(["bash", "-c", "echo '" + currentActive + "' > /tmp/qs_active_widget"]);
    }
    onIsVisibleChanged: {
        if (isVisible)
            masterWindow.requestActivate();
    }

    Item {
        anchors.centerIn: parent
        clip: true
        height: masterWindow.animH
        opacity: masterWindow.isVisible ? 1.0 : 0.0
        width: masterWindow.animW

        Behavior on height {
            enabled: !masterWindow.disableMorph

            NumberAnimation {
                duration: masterWindow.morphDuration
                easing.type: Easing.InOutCubic
            }
        }
        // MODIFIED: Speed up opacity fade-in to match the fast opening (200ms when fast, 300ms when morphing)
        Behavior on opacity {
            NumberAnimation {
                duration: masterWindow.isWallpaperTransition ? 150 : (masterWindow.morphDuration === 500 ? 300 : 200)
                easing.type: Easing.InOutSine
            }
        }

        // MODIFIED: Use dynamic morphDuration instead of hardcoded 500
        Behavior on width {
            enabled: !masterWindow.disableMorph

            NumberAnimation {
                duration: masterWindow.morphDuration
                easing.type: Easing.InOutCubic
            }
        }

        // INNER FIXED CONTAINER
        Item {
            anchors.centerIn: parent
            height: masterWindow.currentActive !== "hidden" && layouts[masterWindow.currentActive] ? layouts[masterWindow.currentActive].h : 1
            width: masterWindow.currentActive !== "hidden" && layouts[masterWindow.currentActive] ? layouts[masterWindow.currentActive].w : 1

            StackView {
                id: widgetStack

                anchors.fill: parent
                focus: true

                // Perfectly synchronized crossfade!
                // Both take exactly 350ms so they blend seamlessly without a gap.
                replaceEnter: Transition {
                    ParallelAnimation {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.InOutQuad
                            from: 0.0
                            property: "opacity"
                            to: 1.0
                        }
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.OutBack
                            from: 0.95
                            property: "scale"
                            to: 1.0
                        }
                    }
                }
                replaceExit: Transition {
                    ParallelAnimation {
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.InOutQuad
                            from: 1.0
                            property: "opacity"
                            to: 0.0
                        }
                        NumberAnimation {
                            duration: 350
                            easing.type: Easing.InCubic
                            from: 1.0
                            property: "scale"
                            to: 1.05
                        }
                    }
                }

                // NEW: Key bubbling catch-all. This triggers ONLY if the child widget doesn't accept the escape event.
                Keys.onEscapePressed: {
                    Quickshell.execDetached(["zsh", Quickshell.env("HOME") + "/.config/hypr/scripts/qs_manager.sh", "close"]);
                    event.accepted = true;
                }
                onCurrentItemChanged: {
                    if (currentItem)
                        currentItem.forceActiveFocus();
                }
            }
        }
    }
    Timer {
        id: prepTimer

        property string newArg: ""
        property string newWidget: ""

        interval: 50

        onTriggered: executeSwitch(newWidget, newArg, false)
    }
    Timer {
        id: teleportFadeOutTimer

        property string newArg: ""
        property string newWidget: ""

        interval: 150

        onTriggered: {
            let t = layouts[newWidget];

            masterWindow.currentActive = newWidget;
            masterWindow.activeArg = newArg;

            masterWindow.animW = t.w;
            masterWindow.animH = t.h;
            masterWindow.width = t.w;
            masterWindow.height = t.h;
            masterWindow.currentX = t.x;
            masterWindow.currentY = t.y;

            Quickshell.execDetached(["zsh", "-c", `hyprctl dispatch resizewindowpixel "exact ${t.w} ${t.h},title:^(qs-master)$" && hyprctl dispatch movewindowpixel "exact ${t.x} ${t.y},title:^(qs-master)$"`]);

            let props = newWidget === "wallpaper" ? {
                "widgetArg": newArg
            } : {};
            widgetStack.replace(t.comp, props, StackView.Immediate);

            teleportFadeInTimer.newWidget = newWidget;
            teleportFadeInTimer.newArg = newArg;
            teleportFadeInTimer.start();
        }
    }
    Timer {
        id: teleportFadeInTimer

        property string newArg: ""
        property string newWidget: ""

        interval: 50

        onTriggered: {
            masterWindow.isVisible = true;
            if (newWidget !== "wallpaper")
                resetMorphTimer.start();
        }
    }
    Timer {
        id: resetMorphTimer

        interval: masterWindow.morphDuration // MODIFIED: Synced with the dynamic animation duration

        onTriggered: masterWindow.disableMorph = false
    }
    Timer {
        interval: 50
        repeat: true
        running: true

        onTriggered: {
            if (!ipcPoller.running)
                ipcPoller.running = true;
        }
    }
    Process {
        id: ipcPoller

        command: ["zsh", "-c", "if [ -f /tmp/qs_widget_state ]; then cat /tmp/qs_widget_state; rm /tmp/qs_widget_state; fi"]

        stdout: StdioCollector {
            onStreamFinished: {
                let rawCmd = this.text.trim();
                if (rawCmd === "")
                    return;

                let parts = rawCmd.split(":");
                let cmd = parts[0];
                let arg = parts.length > 1 ? parts[1] : "";

                if (cmd === "close") {
                    switchWidget("hidden", "");
                } else if (layouts[cmd]) {
                    delayedClear.stop();
                    if (masterWindow.isVisible && masterWindow.currentActive === cmd) {
                        switchWidget("hidden", "");
                    } else {
                        switchWidget(cmd, arg);
                    }
                }
            }
        }
    }
    Timer {
        id: delayedClear

        interval: masterWindow.isWallpaperTransition ? 150 : masterWindow.morphDuration // MODIFIED: Synced dynamically

        onTriggered: {
            masterWindow.currentActive = "hidden";
            widgetStack.clear();
            masterWindow.disableMorph = false;

            // Banished safely back to the shadow realm off-screen
            let cmd = `hyprctl dispatch resizewindowpixel "exact 1 1,title:^(qs-master)$" && hyprctl dispatch movewindowpixel "exact -5000 -5000,title:^(qs-master)$"`;
            Quickshell.execDetached(["zsh", "-c", cmd]);
        }
    }
}
