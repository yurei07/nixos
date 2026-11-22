pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    readonly property bool enabled: Config.deck.enabled
    readonly property string folder: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/nihil/vector/in"
    property var received: ({ id: "" })
    readonly property bool has: (root.received.id ?? "") !== ""
    property string text: ""
    readonly property bool busy: sender.running || actor.running
    property bool dropping: false

    signal lit(string what)
    signal sent(var item)

    // Each takes an optional done(result), called with what the deck answered ({ ok, … } or { error }).
    function send(source: string, done: var): void {
        root.run(["send"].concat(source !== "" ? [source] : []), done);
    }

    // Through stdin: an argument can't pass 128 KiB, and anyone could read it in /proc.
    function sendText(value: string, done: var): void {
        if (value !== "")
            root.run(["text", "-"], done, value);
        else if (done)
            done({ error: "empty" });
    }

    function run(words: var, done: var, input: string): void {
        if (!root.enabled || sender.running) {
            if (done)
                done({ error: root.enabled ? "busy" : "off" });
            return;
        }
        sender.done = done ?? null;
        sender.input = input ?? "";
        sender.command = [Config.deck.command, "vector"].concat(words);
        sender.running = true;
    }

    function act(action: string): void {
        if (!root.enabled || !root.has || actor.running)
            return;
        actor.action = action;
        actor.command = [Config.deck.command, "vector", action];
        actor.running = true;
    }

    function fileUrl(path: string): string {
        return "file://" + path.split("/").map(encodeURIComponent).join("/");
    }

    function home(path: string): string {
        const mine = Quickshell.env("HOME") ?? "";
        return mine !== "" && path.startsWith(mine + "/") ? "~" + path.slice(mine.length) : path;
    }

    // A body is markup, as the notification spec has it: a name a device chose is shown as written.
    function notify(title: string, body: string, picture: string): void {
        const shown = body.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;");
        Quickshell.execDetached([Config.cmd.notifySend, "-a", "NIHIL"].concat(
            picture !== "" ? ["-h", "string:image-path:" + root.fileUrl(picture)] : [], ["--", title, shown]));
    }

    function answer(text: string): var {
        try {
            return JSON.parse(text);
        } catch (error) {
            return { error: "vector" };
        }
    }

    function refuse(error: string): void {
        root.notify(root.failure(error), "", "");
        root.lit("failed");
    }

    function failure(error: string): string {
        return {
            many: Lang.vectorMany,
            big: Lang.vectorBig,
            folder: Lang.vectorFolder,
            empty: Lang.vectorEmpty,
            secret: Lang.vectorSecret
        }[error] ?? Lang.vectorFailed;
    }

    function read(): void {
        try {
            const item = JSON.parse(meta.text());
            item.path = root.folder + "/" + item.name;
            root.received = item;
        } catch (error) {
            root.received = ({ id: "" });
        }
    }

    FileView {
        id: meta
        path: root.enabled ? root.folder + "/.item.json" : ""
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: root.read()
        onLoadFailed: root.received = ({ id: "" })
    }

    FileView {
        id: preview
        path: root.received.kind === "text" ? root.received.path : ""
        blockLoading: true
        printErrors: false
        onLoaded: root.text = preview.text().slice(0, 600)
        onLoadFailed: root.text = ""
        onPathChanged: if (path === "") root.text = ""
    }

    Process {
        id: sender

        property var done: null
        property string input: ""

        stdinEnabled: true
        onStarted: {
            write(input);
            input = "";
            stdinEnabled = false;
        }
        onExited: stdinEnabled = true

        stdout: StdioCollector {
            onStreamFinished: {
                const result = root.answer(text);
                const done = sender.done;
                sender.done = null;
                if (done)
                    done(result);
                if (result.ok) {
                    const devices = result.devices ?? [];
                    root.notify(devices.length > 0 ? Lang.vectorSent.arg(devices.join(", ")) : Lang.vectorWaiting,
                        result.kind === "text" ? "" : result.name, result.kind === "image" ? result.path : "");
                    root.sent(result);
                    root.lit("sent");
                } else {
                    root.notify(root.failure(result.error), "", "");
                    root.lit("failed");
                }
            }
        }
    }

    Process {
        id: actor

        property string action: ""

        stdout: StdioCollector {
            onStreamFinished: {
                const result = root.answer(text);
                meta.reload();
                root.read();
                if (result.ok) {
                    if (actor.action === "save")
                        root.notify(Lang.vectorSaved, root.home(result.path), result.kind === "image" ? result.path : "");
                    root.lit(actor.action);
                } else {
                    root.notify({ copy: Lang.vectorNoCopy, save: Lang.vectorNoSave, open: Lang.vectorNoOpen }[actor.action]
                        ?? Lang.vectorFailed, "", "");
                    root.lit("failed");
                }
            }
        }
    }

    IpcHandler {
        target: "vector"

        function reload(): void {
            meta.reload();
            root.read();
        }

        function received(): void {
            meta.reload();
            root.read();
            const item = root.received;
            if (!root.has)
                return;
            if (item.kind === "text") {
                preview.reload();
                root.text = preview.text().slice(0, 600);
            }
            root.lit("received");
            root.notify(Lang.vectorFrom.arg(item.from || Lang.vectorDevice),
                item.kind === "text" ? root.text.split("\n")[0].slice(0, 120) : item.name,
                item.kind === "image" ? item.path : "");
        }
    }
}
