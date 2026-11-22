pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    readonly property bool enabled: Machine.glass
    property int live: 0
    property string seen: ""
    property double movedAt: 0
    property bool moving: false

    function places(): string {
        return Hyprland.toplevels.values.map(client => {
            const ipc = client.lastIpcObject;
            return ipc && ipc.at && ipc.size ? ipc.at.join(",") + "," + ipc.size.join(",") : "";
        }).join(";");
    }

    function refresh(): void {
        Hyprland.refreshToplevels();
    }

    function place(client: var, monitor: var): var {
        const ipc = client?.lastIpcObject;
        if (!ipc || !ipc.at || !ipc.size || !monitor || ipc.hidden || ipc.mapped === false)
            return Qt.rect(0, 0, 0, 0);
        return Qt.rect(ipc.at[0] - monitor.x, ipc.at[1] - monitor.y, ipc.size[0], ipc.size[1]);
    }

    function specialOf(monitor: var): var {
        const id = monitor?.lastIpcObject?.specialWorkspace?.id ?? 0;
        return id !== 0 ? (Hyprland.workspaces.values.find(w => w.id === id) ?? null) : null;
    }

    function underFrame(monitor: var, inset: real, edge: real, w: real, h: real): bool {
        const clients = [monitor?.activeWorkspace, root.specialOf(monitor)].filter(ws => ws)
            .reduce((all, ws) => all.concat(Array.from(ws.toplevels.values)), []);
        if (clients.some(client => (client.lastIpcObject?.fullscreen ?? 0) >= 2))
            return false;
        return clients.some(client => {
            const r = root.place(client, monitor);
            return r.width > 0 && (r.x < inset - 1 || r.y < edge - 1 || r.x + r.width > w - edge + 1 || r.y + r.height > h - edge + 1);
        });
    }

    // Hyprland tells of no window moving, so the windows are read; most often while a drawer's
    // glass shows them, and once a second at rest, sooner while one is seen moving.
    Timer {
        interval: root.live > 0 ? (root.moving ? 50 : 200) : (root.moving ? 200 : 1000)
        running: root.enabled && Hyprland.toplevels.values.length > 0
        repeat: true
        onTriggered: {
            const now = root.places();
            if (now !== root.seen) {
                root.seen = now;
                root.movedAt = Date.now();
            }
            root.moving = Date.now() - root.movedAt < 1500;
            root.refresh();
        }
    }

    Connections {
        target: Hyprland
        enabled: root.enabled

        function onRawEvent(event: var): void {
            switch (event.name) {
            case "activespecial":
                Hyprland.refreshMonitors();
                root.refresh();
                break;
            case "openwindow":
            case "closewindow":
            case "movewindowv2":
            case "changefloatingmode":
            case "fullscreen":
            case "workspacev2":
                root.refresh();
                break;
            }
        }
    }
}
