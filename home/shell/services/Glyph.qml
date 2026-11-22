pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme

Singleton {
    id: root

    signal sweep(color tint, int laps, int startEdge)
    signal rise(color tint)

    property var jobs: ({})
    readonly property bool working: Object.keys(jobs).length > 0
    readonly property real level: {
        const known = Object.values(root.jobs).filter(value => value >= 0);
        return known.length > 0 ? Math.min(...known) : -1;
    }

    function track(id: string, fraction: real): void {
        const next = Object.assign({}, root.jobs);
        next[id] = fraction < 0 ? -1 : Math.min(1, fraction);
        root.jobs = next;
    }

    function finish(id: string, outcome: string): void {
        if (!(id in root.jobs))
            return;
        const next = Object.assign({}, root.jobs);
        delete next[id];
        root.jobs = next;
        if (outcome === "done" && !root.working)
            root.rise(Tokens.ink);
    }

    function notify(critical: bool): void {
        root.sweep(critical ? Tokens.interrupt : Tokens.ink, critical ? 2 : 1, 1);
    }

    function charge(): void {
        root.rise(Tokens.ink);
    }

    function nilo(): void {
        root.sweep(Tokens.ink, 1, 3);
    }

    IpcHandler {
        target: "glyph"

        function test(critical: bool): void { root.notify(critical); }
        function charge(): void { root.charge(); }
        function progress(id: string, fraction: real): void { root.track(id, fraction); }
        function done(id: string): void { root.finish(id, "done"); }
        function failed(id: string): void { root.finish(id, "failed"); }
        function clear(id: string): void { root.finish(id, "quiet"); }
    }
}
