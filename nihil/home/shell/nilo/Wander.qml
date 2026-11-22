import QtQuick
import Quickshell.Hyprland
import qs.theme
import qs.services

Item {
    id: root

    required property string output
    required property real homeX
    required property real homeY
    property real inset: Tokens.barWidth
    property real edge: Tokens.frameThickness

    readonly property bool here: Nilo.roaming && (Hyprland.focusedMonitor?.name ?? "") === output
    readonly property bool hiding: Nilo.tool === "look_at_screen" || Nilo.tool === "click"
    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === root.output) ?? null
    readonly property real size: 46

    property bool out: false
    property bool moving: false
    property real goalX: homeX
    property real goalY: homeY
    property int travel: 900
    readonly property alias hit: hitArea

    width: size
    height: size
    x: goalX - size / 2
    y: goalY - size / 2
    visible: (out || fade.running) && !hiding
    scale: out ? 1 : 0.3
    opacity: out ? 1 : 0

    Behavior on x { enabled: root.out; NumberAnimation { duration: root.travel; easing.type: Easing.InOutCubic } }
    Behavior on y { enabled: root.out; NumberAnimation { duration: root.travel; easing.type: Easing.InOutCubic } }
    Behavior on scale { NumberAnimation { duration: Tokens.animDrawer; easing.type: Easing.OutBack } }
    Behavior on opacity { NumberAnimation { id: fade; duration: Tokens.animDrawer } }

    function random(a: real, b: real): real { return a + Math.random() * (b - a); }

    function go(px: real, py: real, free: bool): void {
        const w = parent ? parent.width : 0;
        const h = parent ? parent.height : 0;
        const nx = free ? px : Math.max(inset + size, Math.min(w - edge - size, px));
        const ny = free ? py : Math.max(edge + size, Math.min(h - edge - size, py));
        const far = Math.hypot(nx - goalX, ny - goalY);
        if (far < 4) return;
        travel = Math.max(500, Math.min(1400, far * 1.1));
        eyes.lookX = Math.max(-1, Math.min(1, (nx - goalX) / 240));
        eyes.lookY = Math.max(-1, Math.min(1, (ny - goalY) / 240));
        moving = true;
        arrive.interval = travel;
        arrive.restart();
        goalX = nx;
        goalY = ny;
    }

    function roam(): void {
        if (!here) return;
        if (Nilo.confirm !== null) {
            go(homeX + 56, homeY, false);
            return;
        }
        const tool = Nilo.tool;
        if (tool === "use_window" || tool === "type_text" || tool === "press_keys") {
            Hyprland.refreshToplevels();
            const active = Hyprland.toplevels.values.find(c => (c.lastIpcObject?.focusHistoryID ?? -1) === 0);
            const ipc = active?.lastIpcObject;
            if (ipc && ipc.at && ipc.size && monitor) {
                go(ipc.at[0] - monitor.x + ipc.size[0] / 2, ipc.at[1] - monitor.y + Math.min(96, ipc.size[1] / 3), false);
                return;
            }
        }
        const w = parent ? parent.width : 0;
        const h = parent ? parent.height : 0;
        go(random(inset + 120, w - edge - 120), random(edge + 120, h * 0.62), false);
    }

    onHereChanged: {
        if (here) {
            goalX = homeX;
            goalY = homeY;
            out = true;
            emerge.restart();
        } else if (out) {
            go(homeX, homeY, true);
            leave.interval = travel;
            leave.restart();
        }
    }

    Connections {
        target: Nilo
        function onToolChanged(): void { root.roam(); }
        function onConfirmChanged(): void { root.roam(); }
    }

    Timer {
        id: emerge
        interval: Tokens.animDrawer
        onTriggered: root.roam()
    }

    Timer {
        id: leave
        onTriggered: if (!root.here) root.out = false
    }

    Timer {
        id: arrive
        onTriggered: root.moving = false
    }

    Timer {
        interval: 3400
        repeat: true
        running: root.here && root.out
        onTriggered: root.roam()
    }

    Item {
        id: hitArea
        anchors.centerIn: parent
        width: root.out && !root.hiding ? root.size : 0
        height: width
    }

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: Tokens.black
    }

    Eyes {
        id: eyes
        anchors.centerIn: parent
        eyeWidth: 7
        eyeHeight: 17
        gap: 8
        looking: root.moving
        mood: root.moving ? "idle"
            : Nilo.confirm !== null ? "alert"
            : Nilo.tool === "type_text" || Nilo.tool === "press_keys" || Nilo.phase === "writing" ? "writing"
            : "thinking"
        pulse: Nilo.pulse
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: Nilo.open()
    }
}
