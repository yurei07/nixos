pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.config
import qs.theme

Singleton {
    id: root

    property string current: ""
    property string screen: ""
    property bool byHover: false

    readonly property var edges: ({ dashboard: "top", clipboard: "top", overview: "top", launcher: "bottom", wallpapers: "bottom", panel: "right" })
    property var waiting: null

    function focusedScreen(): string {
        return Hyprland.focusedMonitor?.name ?? (Quickshell.screens.length > 0 ? Quickshell.screens[0].name : "");
    }

    function isOpen(name: string, screenName: string): bool {
        return current === name && screen === screenName;
    }

    function open(name: string, screenName: string, hover: bool): void {
        const target = screenName || focusedScreen();
        if (current !== "" && current !== name && screen === target && edges[current] === edges[name]) {
            close();
            waiting = { name: name, screen: target, hover: hover };
            later.restart();
            return;
        }
        waiting = null;
        screen = target;
        byHover = hover;
        if (name === "launcher" && current !== "launcher" && !hover)
            Sounds.play(Config.sounds.menu, 0.4);
        if (name === "panel")
            Notifs.markSeen();
        current = name;
    }

    function toggle(name: string, screenName: string): void {
        const target = screenName || focusedScreen();
        if (current === name && screen === target && !byHover)
            close();
        else
            open(name, target, false);
    }

    function close(): void {
        current = "";
        byHover = false;
        waiting = null;
    }

    Timer {
        id: later
        interval: Tokens.animDrawer
        onTriggered: {
            const next = root.waiting;
            root.waiting = null;
            if (next !== null && root.current === "")
                root.open(next.name, next.screen, next.hover);
        }
    }

    IpcHandler {
        target: "drawers"

        function toggle(name: string): void { root.toggle(name, ""); }
        function open(name: string): void { root.open(name, "", false); }
        function close(): void { root.close(); }
    }
}
