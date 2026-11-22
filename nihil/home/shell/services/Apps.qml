pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    // Every app, and those the launcher shows: one hidden in Preferences is hidden from the deck,
    // and from Nilo, too. Kept as ids in apps.json, with no rebuild.
    readonly property var every: DesktopEntries.applications.values
        .filter(e => !e.noDisplay)
        .sort((a, b) => a.name.toLowerCase().localeCompare(b.name.toLowerCase()))
    property var hidden: []
    readonly property var all: root.every.filter(e => root.hidden.indexOf(e.id) < 0)
    readonly property string keptFile: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/nihil/apps.json"

    function setHidden(id: string, hide: bool): void {
        const next = root.hidden.filter(other => other !== id);
        if (hide)
            next.push(id);
        root.hidden = next;
        Quickshell.execDetached([Config.cmd.sh, "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "sh", root.keptFile,
                                 JSON.stringify({ hidden: root.hidden })]);
    }

    function score(e, q: string): int {
        const name = e.name.toLowerCase();
        if (name === q) return 1000;
        if (name.startsWith(q)) return 800 - name.length;
        if (name.split(/[\s\-_.]+/).some(w => w.startsWith(q))) return 600 - name.length;
        if (name.indexOf(q) >= 0) return 400 - name.indexOf(q);
        const extra = [e.genericName ?? "", e.comment ?? "", ...(e.keywords ?? [])].join(" ").toLowerCase();
        if (extra.indexOf(q) >= 0) return 200;
        let i = 0;
        for (const c of name) if (c === q[i]) i++;
        return i === q.length ? 100 - name.length : -1;
    }

    function search(query: string): var {
        const q = query.trim().toLowerCase();
        if (!q) return root.all;
        return root.all
            .map(e => ({ e: e, s: root.score(e, q) }))
            .filter(x => x.s >= 0)
            .sort((a, b) => b.s - a.s)
            .map(x => x.e);
    }

    // Apps start in a scope of their own (uwsm app), not inside the shell's service: they live on
    // when the shell restarts, and the session closes them properly when it ends.
    function run(command: var): void {
        Quickshell.execDetached([Config.cmd.uwsm, "app", "--"].concat(command));
    }

    function open(target: string): void {
        root.run([Config.cmd.xdgOpen, target]);
    }

    function launch(e): void {
        if (e.runInTerminal) {
            // In the folder the entry names (Path=), as uwsm does for any other from its .desktop.
            const command = e.command && e.command.length ? e.command : [Config.cmd.sh, "-c", e.execString];
            const line = [Config.cmd.uwsm, "app", "--", Config.cmd.terminal, "-e"].concat(command);
            Quickshell.execDetached(e.workingDirectory ? { command: line, workingDirectory: e.workingDirectory } : line);
        } else {
            root.run([e.id + ".desktop"]);
        }
    }

    Process {
        command: [Config.cmd.sh, "-c", "cat \"$1\" 2>/dev/null", "sh", root.keptFile]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kept = JSON.parse(text)?.hidden;
                    if (Array.isArray(kept))
                        root.hidden = kept.filter(id => typeof id === "string");
                } catch (error) {
                }
            }
        }
    }

    IpcHandler {
        target: "apps"

        function list(): string {
            return JSON.stringify(root.all.map(e => ({ id: e.id, name: e.name, icon: e.icon ?? "" })));
        }
        function launch(id: string): string {
            const entry = root.all.find(e => e.id === id);
            if (!entry)
                return "unknown";
            root.launch(entry);
            return "ok";
        }
        function url(address: string): string {
            if (!/^https?:\/\/[^\s\/?#]+[^\s]*$/i.test(address))
                return "invalid";
            root.open(address);
            return "ok";
        }
    }

    IpcHandler {
        target: "session"

        function lock(): void { Quickshell.execDetached([Config.cmd.lock]); }
    }

    function iconFor(appClass: string): string {
        if (!appClass) return "";
        const entry = (typeof DesktopEntries.heuristicLookup === "function")
            ? DesktopEntries.heuristicLookup(appClass)
            : DesktopEntries.byId(appClass);
        return entry?.icon ?? appClass;
    }
}
