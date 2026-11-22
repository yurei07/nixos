import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Widgets
import qs.theme
import qs.config
import qs.services
import qs.components

Item {
    id: root

    required property string output
    property bool active: false
    property int index: 0

    readonly property var monitor: Hyprland.monitors.values.find(m => m.name === root.output) ?? null
    readonly property var size: root.logical(root.monitor)
    readonly property real ratio: root.size.w > 0 && root.size.h > 0 ? root.size.w / root.size.h : 16 / 9
    readonly property real cardH: 150
    readonly property real cardW: Math.round(root.cardH * root.ratio)
    readonly property var ids: {
        const used = Hyprland.workspaces.values.filter(w => w.id > 0).map(w => w.id);
        const count = Math.max(Config.persistentWorkspaces, ...used);
        return Array.from({ length: count }, (_, i) => i + 1);
    }

    implicitWidth: root.ids.length * (root.cardW + 14) - 14 + 48
    implicitHeight: 22 + root.cardH + 30 + 48

    readonly property string wallpaper: Machine.wallpaper !== "" ? Machine.wallpaper : Machine.get("wallpaper", "night")
    function wallpaperFor(output: string): string {
        return "file://" + Config.wallpaperDir + "/" + root.wallpaper + "/" + output + ".png";
    }

    // A screen's size as windows see it: Hyprland gives its mode's, before scale and turn.
    function logical(m: var): var {
        const scale = m?.scale || 1;
        const turned = ((m?.lastIpcObject?.transform ?? 0) % 2) === 1;
        const w = (m?.width ?? 0) / scale, h = (m?.height ?? 0) / scale;
        return turned ? { w: h, h: w } : { w: w, h: h };
    }

    function step(delta: int): void {
        if (root.ids.length > 0)
            root.index = (root.index + delta + root.ids.length) % root.ids.length;
    }

    Connections {
        target: Switcher.overview
        function onStepped(delta: int): void {
            if (root.active)
                root.step(delta);
        }
        function onCommit(): void {
            if (root.active)
                root.go(root.ids[root.index]);
        }
    }

    function go(id: int): void {
        Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ workspace = ${id} })` : `workspace ${id}`);
        Drawers.close();
    }

    function reach(client: var): void {
        const raw = String(client.lastIpcObject?.address ?? client.address ?? "");
        if (raw === "")
            return;
        const address = raw.startsWith("0x") ? raw : "0x" + raw;
        Hyprland.dispatch(Hyprland.usingLua ? `hl.dsp.focus({ window = "address:${address}" })` : `focuswindow address:${address}`);
        Drawers.close();
    }

    onActiveChanged: {
        if (!root.active)
            return;
        Hyprland.refreshMonitors();
        Hyprland.refreshWorkspaces();
        Hyprland.refreshToplevels();
        root.index = Math.max(0, root.ids.indexOf(Hyprland.focusedWorkspace?.id ?? 1));
        keys.forceActiveFocus();
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: root.active
        Keys.onLeftPressed: root.index = Math.max(0, root.index - 1)
        Keys.onRightPressed: root.index = Math.min(root.ids.length - 1, root.index + 1)
        Keys.onReturnPressed: root.go(root.ids[root.index])
        Keys.onEnterPressed: root.go(root.ids[root.index])
        Keys.onEscapePressed: Drawers.close()
        Keys.onTabPressed: root.step(1)
        Keys.onBacktabPressed: root.step(-1)
        Keys.onPressed: event => {
            if (Switcher.overview.keyCode > 0 && event.key === Switcher.overview.keyCode) {
                root.step(event.modifiers & Qt.ShiftModifier ? -1 : 1);
                event.accepted = true;
            }
        }
    }

    KeyHints {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 16
        text: Lang.ovHint.arg(Case.key(Switcher.overview.keyName !== "" ? Switcher.overview.keyName : "Tab"))
    }

    ListView {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 22
        anchors.bottomMargin: 48
        orientation: ListView.Horizontal
        spacing: 14
        clip: true
        model: root.ids
        currentIndex: root.index
        highlightMoveDuration: Tokens.animFast
        boundsBehavior: Flickable.StopAtBounds
        // However many there are, the chosen one in the middle, where it can be.
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: (width - root.cardW) / 2
        preferredHighlightEnd: (width + root.cardW) / 2

        delegate: Item {
            id: card

            required property int modelData
            required property int index

            readonly property var ws: Hyprland.workspaces.values.find(w => w.id === card.modelData) ?? null
            readonly property var mon: card.ws?.monitor ?? root.monitor
            readonly property var area: root.logical(card.mon)
            readonly property real across: card.area.w > 0 ? card.area.w / root.cardW : 1
            readonly property real down: card.area.h > 0 ? card.area.h / root.cardH : 1
            readonly property bool chosen: card.index === root.index || pointer.containsMouse
            readonly property bool current: (Hyprland.focusedWorkspace?.id ?? 0) === card.modelData

            width: root.cardW
            height: ListView.view.height

            // The chosen one as it is, the rest smaller.
            Item {
                id: face
                width: root.cardW
                height: root.cardH
                scale: card.index === root.index ? 1 : 0.86

                Behavior on scale { NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic } }

                MouseArea {
                    id: pointer
                    width: root.cardW
                    height: root.cardH
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.go(card.modelData)
                }

                ClippingRectangle {
                    id: screen
                    width: root.cardW
                    height: root.cardH
                    radius: 14
                    color: Tokens.black
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        saturation: card.chosen ? 0 : -1
                    }

                    Image {
                        property bool primary: false
                        anchors.fill: parent
                        source: root.wallpaperFor(primary ? Config.primaryOutput : (card.mon?.name ?? root.output))
                        sourceSize.width: root.cardW * 2
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        onStatusChanged: {
                            if (status === Image.Error && !primary)
                                primary = true;
                        }
                    }

                    Repeater {
                        model: card.ws ? card.ws.toplevels : null

                        delegate: Item {
                            id: client

                            required property var modelData

                            readonly property var ipc: client.modelData.lastIpcObject ?? ({})

                            z: (client.ipc.fullscreen ?? 0) > 0 ? 2000
                                : client.ipc.floating ? 1000 - (client.ipc.focusHistoryID ?? 0) : 0
                            x: client.ipc.at && card.mon ? (client.ipc.at[0] - card.mon.x) / card.across : 0
                            y: client.ipc.at && card.mon ? (client.ipc.at[1] - card.mon.y) / card.down : 0
                            width: client.ipc.size ? client.ipc.size[0] / card.across : 0
                            height: client.ipc.size ? client.ipc.size[1] / card.down : 0

                            ScreencopyView {
                                anchors.fill: parent
                                captureSource: root.active ? client.modelData.wayland : null
                                live: false
                            }

                            MouseArea {
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.reach(client.modelData)
                            }
                        }
                    }
                }

                Rectangle {
                    width: root.cardW
                    height: root.cardH
                    radius: 14
                    color: "transparent"
                    border.width: card.chosen ? 2 : 1
                    border.color: card.chosen ? Tokens.ink : Tokens.line
                }
            }

            Label {
                y: root.cardH * (1 + face.scale) / 2 + 8
                anchors.horizontalCenter: parent.horizontalCenter
                text: card.modelData
                color: card.current ? Tokens.ink : Tokens.dim
            }
        }
    }
}
