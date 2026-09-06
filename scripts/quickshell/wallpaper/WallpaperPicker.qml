import QtQuick
import QtQuick.Layouts
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io

Item {
    id: window

    readonly property string awwwCommand: "awww img '%1'"
    readonly property int borderWidth: 3
    readonly property string homeDir: "file://" + Quickshell.env("HOME")
    property bool initialFocusSet: false
    readonly property int itemHeight: 420
    readonly property int itemWidth: 300
    readonly property string mpvCommand: "pkill mpvpaper; mpvpaper -o 'loop --no-audio --hwdec=auto --profile=high-quality --video-sync=display-resample --interpolation --tscale=oversample' '*' '%1'"
    readonly property real skewFactor: -0.35
    readonly property int spacing: 0
    readonly property string srcDir: Quickshell.env("QS_WALLPAPER_DIR") || (Quickshell.env("HOME") + "/Pictures/wallpapers")
    property string targetWallName: ""
    readonly property string thumbDir: homeDir + "/.cache/wallpaper_picker/thumbs"

    // -------------------------------------------------------------------------
    // PROPERTIES & IPC RECEIVER
    // -------------------------------------------------------------------------
    property string widgetArg: ""

    function tryFocus() {
        if (initialFocusSet)
            return;

        if (view.count > 0) {
            let foundIndex = -1;

            // Search for the specific filename
            if (targetWallName !== "") {
                for (let i = 0; i < view.count; i++) {
                    if (folderModel.get(i, "fileName") === targetWallName) {
                        foundIndex = i;
                        break;
                    }
                }
            }

            if (foundIndex !== -1) {
                // Found the target wallpaper! Focus it.
                view.currentIndex = foundIndex;
                view.positionViewAtIndex(foundIndex, ListView.Center);
                initialFocusSet = true;
            } else if (folderModel.status === FolderListModel.Ready) {
                // Folder finished loading but target is missing (e.g., deleted).
                // Fallback to the first item safely to avoid getting stuck.
                let safeIndex = 0;
                view.currentIndex = safeIndex;
                view.positionViewAtIndex(safeIndex, ListView.Center);
                initialFocusSet = true;
            }
        }
    }

    Component.onCompleted: {
        view.forceActiveFocus();
    }
    onWidgetArgChanged: {
        if (widgetArg !== "") {
            targetWallName = widgetArg;
            tryFocus();
        }
    }

    Shortcut {
        sequence: "Left"

        onActivated: view.decrementCurrentIndex()
    }
    Shortcut {
        sequence: "Right"

        onActivated: view.incrementCurrentIndex()
    }
    Shortcut {
        sequence: "Return"

        onActivated: {
            if (view.currentItem)
                view.currentItem.pickWallpaper();
        }
    }

    // -------------------------------------------------------------------------
    // CONTENT
    // -------------------------------------------------------------------------
    ListView {
        id: view

        anchors.fill: parent
        anchors.margins: 0

        // Pre-load items off-screen so they don't block the thread as they enter the view
        cacheBuffer: 2000
        clip: false
        focus: true

        // Reset back to standard speed for snappy manual keyboard navigation
        highlightMoveDuration: window.initialFocusSet ? 300 : 0
        highlightRangeMode: ListView.StrictlyEnforceRange
        orientation: ListView.Horizontal
        preferredHighlightBegin: (width / 2) - (window.itemWidth / 2)
        preferredHighlightEnd: (width / 2) + (window.itemWidth / 2)
        spacing: window.spacing

        delegate: Item {
            id: delegateRoot

            readonly property bool isCurrent: ListView.isCurrentItem
            readonly property bool isVideo: fileName.startsWith("000_")

            function pickWallpaper() {
                let cleanName = fileName;
                if (cleanName.startsWith("000_")) {
                    cleanName = cleanName.substring(4);
                }

                const originalFile = window.srcDir + "/" + cleanName;
                const thumbFile = Quickshell.env("HOME") + "/.cache/wallpaper_picker/thumbs/" + fileName;

                if (isVideo) {
                    const finalCmd = window.mpvCommand.arg(originalFile);
                    Quickshell.execDetached(["bash", "-c", finalCmd + " & matugen image " + thumbFile + "--source-color-index 0" + " &"]);
                } else {
                    const finalCmd = window.awwwCommand.arg(originalFile);
                    Quickshell.execDetached(["bash", "-c", "pkill mpvpaper"]);
                    Quickshell.execDetached(["bash", "-c", finalCmd]);
                    Quickshell.execDetached(["bash", "-c", "matugen image " + thumbFile + " --source-color-index 0"]);
                }

                Quickshell.execDetached(["bash", "-c", "hyprctl dispatch killactive"]);
            }

            anchors.verticalCenter: parent.verticalCenter
            height: window.itemHeight
            width: window.itemWidth
            z: isCurrent ? 10 : 1

            MouseArea {
                anchors.fill: parent

                onClicked: {
                    view.currentIndex = index;
                    delegateRoot.pickWallpaper();
                }
            }
            Item {
                anchors.centerIn: parent
                height: parent.height
                opacity: delegateRoot.isCurrent ? 1.0 : 0.6
                scale: delegateRoot.isCurrent ? 1.15 : 0.95
                width: parent.width

                Behavior on opacity {
                    NumberAnimation {
                        duration: 500
                    }
                }
                Behavior on scale {
                    NumberAnimation {
                        duration: 500
                        easing.type: Easing.OutBack
                    }
                }
                transform: Matrix4x4 {
                    property real s: window.skewFactor

                    matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                }

                Image {
                    anchors.fill: parent

                    // Load from disk on a background thread to prevent UI freezing
                    asynchronous: true
                    fillMode: Image.Stretch
                    source: fileUrl
                    sourceSize: Qt.size(1, 1)
                    visible: true
                }
                Item {
                    anchors.fill: parent
                    anchors.margins: window.borderWidth
                    clip: true

                    Rectangle {
                        anchors.fill: parent
                        color: "black"
                    }
                    Image {
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -50

                        // Load from disk on a background thread to prevent UI freezing
                        asynchronous: true
                        fillMode: Image.PreserveAspectCrop
                        height: parent.height
                        source: fileUrl
                        width: parent.width + (parent.height * Math.abs(window.skewFactor)) + 50

                        transform: Matrix4x4 {
                            property real s: -window.skewFactor

                            matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }
                    }
                    Rectangle {
                        anchors.margins: 10
                        anchors.right: parent.right
                        anchors.top: parent.top
                        color: "#60000000"
                        height: 32
                        radius: 6
                        visible: delegateRoot.isVideo
                        width: 32

                        transform: Matrix4x4 {
                            property real s: -window.skewFactor

                            matrix: Qt.matrix4x4(1, s, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1)
                        }

                        Canvas {
                            anchors.fill: parent
                            anchors.margins: 8

                            onPaint: {
                                var ctx = getContext("2d");
                                ctx.fillStyle = "#EEFFFFFF";
                                ctx.beginPath();
                                ctx.moveTo(4, 0);
                                ctx.lineTo(14, 8);
                                ctx.lineTo(4, 16);
                                ctx.closePath();
                                ctx.fill();
                            }
                        }
                    }
                }
            }
        }
        model: FolderListModel {
            id: folderModel

            folder: window.thumbDir
            nameFilters: ["*.jpg", "*.jpeg", "*.png", "*.webp", "*.gif", "*.mp4", "*.mkv", "*.mov", "*.webm"]
            showDirs: false
            sortField: FolderListModel.Name

            // Re-check focus when the model's loading status updates
            onStatusChanged: window.tryFocus()
        }

        onCountChanged: window.tryFocus()
    }
}
