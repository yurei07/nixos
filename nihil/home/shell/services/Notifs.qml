pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import qs.config

Singleton {
    id: root

    property bool dnd: false
    // Kept as it was through a restart of the shell (applying settings) and into the next session.
    readonly property string dndFile: Machine.stateDir + "/dnd"
    property var popups: []
    readonly property var history: server.trackedNotifications.values.slice().reverse()

    // Kept for the panel, newest first; the oldest go beyond this many.
    readonly property int kept: 50
    readonly property int defaultTimeout: 5000
    readonly property int longestTimeout: 30000
    readonly property int criticalTimeout: 15000

    property var deadlines: ({})    // notification id -> epoch ms
    property int held: -1

    function show(n): void {
        deadlines[n.id] = Date.now() + timeoutFor(n);
        popups = [n].concat(popups.filter(p => p !== n)).slice(0, 4);
    }

    function hidePopup(n): void {
        delete deadlines[n.id];
        popups = popups.filter(p => p !== n);
    }

    // A transient notice isn't kept: it goes with its popup, as the specification asks.
    function leave(gone: var): void {
        for (const n of gone)
            if (n.transient) n.expire();
    }

    function hold(n, on: bool): void {
        if (!n) return;
        if (on) {
            held = n.id;
        } else {
            if (held === n.id) held = -1;
            deadlines[n.id] = Math.max(deadlines[n.id] ?? 0, Date.now() + 2000);
        }
    }

    function expire(): void {
        const now = Date.now();
        const keep = popups.filter(p => p.id === held || (deadlines[p.id] ?? 0) > now);
        if (keep.length === popups.length) return;
        const gone = popups.filter(p => keep.indexOf(p) < 0);
        for (const p of gone)
            delete deadlines[p.id];
        popups = keep;
        leave(gone);
    }

    function hidePopups(): void {
        const gone = popups;
        popups = [];
        deadlines = ({});
        leave(gone);
    }

    function markSeen(): void {
        const gone = popups.filter(p => !isCritical(p));
        popups = popups.filter(p => isCritical(p));
        leave(gone);
    }

    function clear(): void {
        for (const n of server.trackedNotifications.values.slice())
            n.dismiss();
        popups = [];
        deadlines = ({});
    }

    function picture(given: string): string {
        const icon = "image://icon/";
        if (!given.startsWith(icon) || given.indexOf("?") >= 0)
            return given;
        let name = given.slice(icon.length);
        try {
            name = decodeURIComponent(name);
        } catch (error) {}
        if (name.startsWith("file://"))
            return name;
        if (name.startsWith("/"))
            return "file://" + name.split("/").map(encodeURIComponent).join("/");
        return Quickshell.iconPath(name, true);
    }

    function tagOf(n): string {
        return String(n?.hints?.["x-nihil-tag"] ?? "");
    }

    function dismissTag(tag: string, except: var): void {
        for (const n of server.trackedNotifications.values.slice())
            if (n !== except && tagOf(n) === tag) n.dismiss();
    }

    function isCritical(n): bool {
        return n.urgency === NotificationUrgency.Critical;
    }

    function niloKind(n): string {
        return String(n?.hints?.["x-nihil-nilo"] ?? "");
    }

    function timeoutFor(n): int {
        if (isCritical(n)) return criticalTimeout;
        const t = Number(n.expireTimeout) || 0;
        if (t <= 0) return defaultTimeout;
        return Math.max(1500, Math.min(longestTimeout, Math.round(t < 100 ? t * 1000 : t)));
    }

    // A body can bring bold, italics, underline and line breaks; any other < is shown as it is, so
    // a picture or a link can't load from anywhere, closed or not.
    function markup(text: string): string {
        return String(text).replace(/<(?!\/?(?:b|i|u)>|br\s*\/?>)/gi, "&lt;");
    }

    onDndChanged: Quickshell.execDetached([Config.cmd.sh, "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n' \"$2\" > \"$1\"",
                                           "sh", root.dndFile, root.dnd ? "on" : "off"])

    FileView {
        path: root.dndFile
        printErrors: false
        onLoaded: root.dnd = text().trim() === "on"
    }

    NotificationServer {
        id: server

        keepOnReload: false
        actionsSupported: true
        bodyMarkupSupported: true
        imageSupported: true
        persistenceSupported: true

        onNotification: n => {
            n.tracked = true;
            n.closed.connect(() => root.hidePopup(n));
            if (root.tagOf(n) !== "") root.dismissTag(root.tagOf(n), n);
            const all = server.trackedNotifications.values;
            for (let i = 0; i < all.length - root.kept; i++)
                if (all[i] !== n) all[i].dismiss();

            const critical = root.isCritical(n);
            if (root.dnd && !critical) {
                if (n.transient) n.expire();
                return;
            }

            if (root.niloKind(n) !== "") {
                Glyph.nilo();
                Sounds.play(Config.sounds.notify, 0.4);
                Nilo.peek(root.niloKind(n));
                return;
            }

            root.show(n);
            Glyph.notify(critical);
            Sounds.play(critical ? Config.sounds.critical : Config.sounds.notify, critical ? 0.5 : 0.4);
        }
    }

    Timer {
        interval: 250
        repeat: true
        running: root.popups.length > 0
        onTriggered: root.expire()
    }

    IpcHandler {
        target: "notifs"

        function clear(): void { root.clear(); }
        function hide(): void { root.hidePopups(); }
        function toggleDnd(): void { root.dnd = !root.dnd; }
    }
}
