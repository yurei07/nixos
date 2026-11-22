pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    property var list: []
    property bool bootMenu: false
    property real free: 0
    property real size: 0
    property bool loaded: false
    property bool failed: false

    property var changes: ({})
    property var queue: []

    readonly property int shown: 10

    function refresh(cleaned: bool): void {
        if (cleaned)
            root.changes = {};
        if (!lister.running)
            lister.running = true;
    }

    function compare(number: int): void {
        if (String(number) in root.changes || root.queue.indexOf(number) >= 0 || (differ.reading && differ.number === number))
            return;
        root.queue = root.queue.concat([number]);
        root.next();
    }

    function next(): void {
        if (differ.running || differ.reading || root.queue.length === 0)
            return;
        differ.number = root.queue[0];
        root.queue = root.queue.slice(1);
        differ.reading = true;
        differ.running = true;
    }

    function line(text: string): var {
        const found = /^(.+?): (.*)$/.exec(text);
        if (!found)
            return null;
        // The size it grew or shrank by, as Nix writes it: «12.6 KiB», «-3.2 MiB», «+1.0 GiB».
        const rest = found[2].replace(/(^|, )[+-]?[0-9.]+ [KMGTPE]iB$/, "");
        const sides = rest.split(" → ");
        if (sides.length !== 2)
            return { name: found[1], from: "", to: "", versions: false };
        const plain = side => side === "∅" || side === "ε" ? "" : side;
        return { name: found[1], from: sides[0] === "∅" ? null : plain(sides[0]), to: sides[1] === "∅" ? null : plain(sides[1]), versions: true };
    }

    function store(number: int, value: var): void {
        const next = Object.assign({}, root.changes);
        next[String(number)] = value;
        root.changes = next;
    }

    Process {
        id: lister
        command: [Config.cmd.nihil, "generations", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const found = JSON.parse(text);
                    root.list = found.generations ?? [];
                    root.bootMenu = found.bootMenu === true;
                    root.free = found.free ?? 0;
                    root.size = found.size ?? 0;
                    root.failed = false;
                } catch (error) {
                    root.failed = true;
                }
                root.loaded = true;
            }
        }
    }

    Process {
        id: differ

        property int number: 0
        property bool reading: false

        command: [Config.cmd.nihil, "generations", "changes", String(number)]
        onRunningChanged: {
            if (!running)
                Qt.callLater(root.next);
        }
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const found = JSON.parse(text);
                    const lines = (found.lines ?? []).map(text => root.line(text)).filter(entry => entry !== null && entry.versions);
                    root.store(differ.number, {
                        before: found.before ?? null,
                        changed: lines.slice(0, root.shown),
                        more: Math.max(0, lines.length - root.shown),
                        same: lines.length === 0,
                        failed: false
                    });
                } catch (error) {
                    root.store(differ.number, { before: null, changed: [], more: 0, same: false, failed: true });
                }
                differ.reading = false;
                Qt.callLater(root.next);
            }
        }
    }
}
