import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config
import qs.services

Item {
    id: root

    required property string output
    property vector2d origin: Qt.vector2d(0, 0)
    property vector2d screenSize: Qt.vector2d(1, 1)
    property real dim: 1
    property bool windows: false

    // Once there's a wallpaper, the glass keeps it while the next one loads: on a change it doesn't
    // fall back to flat for a moment, everywhere, with the picker open.
    readonly property Item texture: !wall.shown ? null : root.windows ? shot : wall
    readonly property string name: Machine.wallpaper !== "" ? Machine.wallpaper : Machine.get("wallpaper", "night")
    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === root.output) ?? null
    readonly property var special: Glass.specialOf(root.monitor)

    width: 1
    height: 1
    clip: true

    property bool counted: false
    function count(showing: bool): void {
        if (showing === root.counted)
            return;
        root.counted = showing;
        Glass.live += showing ? 1 : -1;
    }
    onWindowsChanged: root.count(root.windows)
    Component.onCompleted: root.count(root.windows)
    Component.onDestruction: root.count(false)

    onNameChanged: wall.primary = false

    component Shown: ScreencopyView {
        id: shown

        required property var modelData
        property var monitor: null
        property bool capture: false
        // Not "layer": every Item has one.
        property int above: 0

        readonly property var ipc: shown.modelData?.lastIpcObject ?? ({})
        readonly property rect place: Glass.place(shown.modelData, shown.monitor)

        x: shown.place.x
        y: shown.place.y
        width: shown.place.width
        height: shown.place.height
        visible: shown.place.width > 0 && shown.place.height > 0
        z: shown.above + ((shown.ipc.fullscreen ?? 0) > 0 ? 1500
            : shown.ipc.floating ? 1000 - Math.min(shown.ipc.focusHistoryID ?? 0, 999) : 0)
        captureSource: (shown.capture && shown.visible) ? (shown.modelData?.wayland ?? null) : null
        live: true
    }

    Item {
        id: scene

        width: root.screenSize.x
        height: root.screenSize.y

        Image {
            id: wall

            property bool primary: false
            property bool shown: false

            anchors.fill: parent
            asynchronous: true
            retainWhileLoading: true
            // Cut to fill, as awww draws it, not stretched: what the glass bends is what's behind it.
            fillMode: Image.PreserveAspectCrop
            smooth: true
            mipmap: true
            source: "file://" + Config.wallpaperDir + "/" + root.name + "/" + (primary ? Config.primaryOutput : root.output) + ".png"
            onStatusChanged: {
                if (status === Image.Ready)
                    shown = true;
                if (status === Image.Error && !primary)
                    primary = true;
            }
        }

        Repeater {
            model: root.windows && root.monitor?.activeWorkspace ? root.monitor.activeWorkspace.toplevels : null
            delegate: Shown {
                monitor: root.monitor
                capture: root.windows
            }
        }

        Repeater {
            model: root.windows && root.special ? root.special.toplevels : null
            delegate: Shown {
                monitor: root.monitor
                capture: root.windows
                above: 2000
            }
        }
    }

    ShaderEffectSource {
        id: shot

        width: 1
        height: 1
        sourceItem: root.windows ? scene : null
        hideSource: true
        live: true
        mipmap: true
        smooth: true
    }
}
