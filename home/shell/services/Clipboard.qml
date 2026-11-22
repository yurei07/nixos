pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Wayland
import qs.config

Singleton {
    id: root

    property var items: []
    property int index: 0
    readonly property bool shown: Drawers.current === "clipboard" || Drawers.waiting?.name === "clipboard"
    readonly property bool enabled: Config.clipboard > 0
    // Never /tmp, where another user could make the folder first: with no runtime folder, no pictures.
    readonly property string dir: (Quickshell.env("XDG_RUNTIME_DIR") ?? "") !== "" ? Quickshell.env("XDG_RUNTIME_DIR") + "/nihil-clipboard" : ""

    readonly property var keyParts: String(Config.binds.clipboard ?? "").split("+").map(part => part.trim()).filter(part => part !== "")
    readonly property string modifier: {
        if (keyParts.length < 2)
            return "";
        const alias = { WIN: "SUPER", LOGO: "SUPER", MOD4: "SUPER", META: "SUPER", CONTROL: "CTRL", MOD1: "ALT" };
        const up = keyParts[0].toUpperCase();
        const name = alias[up] ?? up;
        return ["SUPER", "CTRL", "ALT", "SHIFT"].indexOf(name) >= 0 ? name.toLowerCase() : "";
    }
    readonly property string keyName: keyParts.length > 0 ? keyParts[keyParts.length - 1] : ""
    readonly property int keyCode: {
        if (keyName.length === 1)
            return keyName.toUpperCase().charCodeAt(0);
        const code = Qt["Key_" + keyName];
        return typeof code === "number" ? code : -1;
    }

    property var down: ({})

    property string phase: ""
    readonly property int wait: 200
    property bool keyboard: false

    property var target: null
    property var pending: null

    function press(): void {
        if (phase !== "") {
            step(1);
            return;
        }
        target = ToplevelManager.activeToplevel;
        index = 0;
        if (enabled)
            refresh();
        if (isDown(modifier)) {
            phase = "held";
            later.restart();
        } else if (enabled) {
            keyboard = true;
            reveal();
        } else {
            finish(null);
        }
    }

    function reveal(): void {
        later.stop();
        if (!enabled || phase === "out")
            return;
        phase = "out";
        Drawers.open("clipboard", "", false);
        idle.restart();
    }

    function step(by: int): void {
        if (phase === "") {
            press();
            return;
        }
        reveal();
        if (phase !== "out")
            return;
        if (items.length > 0)
            index = (index + by + items.length) % items.length;
        idle.restart();
    }

    function isDown(name: string): bool {
        return name !== "" && root.down[name] === true;
    }

    function track(name: string, isPressed: bool): void {
        const next = Object.assign({}, root.down);
        next[name] = isPressed;
        root.down = next;
        if (!isPressed && name === root.modifier)
            released("hyprland");
    }

    function released(from: string): void {
        if (phase === "held") {
            console.info("nihil: clipboard: let go (" + from + "), pasting what is on the clipboard");
            finish(null);
        } else if (phase === "out") {
            console.info("nihil: clipboard: let go (" + from + ")");
            paste();
        }
    }

    function paste(): void {
        if (phase === "held")
            finish(null);
        else if (phase === "out")
            finish(items[index] ?? null);
    }

    function pick(i: int): void {
        index = i;
        paste();
    }

    function cancel(): void {
        end();
    }

    function end(): void {
        phase = "";
        keyboard = false;
        later.stop();
        idle.stop();
        if (shown)
            Drawers.close();
    }

    function finish(item: var): void {
        end();
        pending = { item: item };
        settle.tries = 0;
        settle.restart();
    }

    function isModifier(key: int): bool {
        switch (modifier) {
        case "super":
            return key === Qt.Key_Super_L || key === Qt.Key_Super_R || key === Qt.Key_Meta
                || key === Qt.Key_Hyper_L || key === Qt.Key_Hyper_R;
        case "ctrl":
            return key === Qt.Key_Control;
        case "alt":
            return key === Qt.Key_Alt || key === Qt.Key_AltGr;
        case "shift":
            return key === Qt.Key_Shift;
        }
        return false;
    }

    function forget(id: string): void {
        items = items.filter(item => item.id !== id);
        index = Math.min(index, Math.max(0, items.length - 1));
        Quickshell.execDetached([Config.cmd.clipboard, "delete", id]);
        idle.restart();
    }

    function forgetChosen(): void {
        const item = items[index];
        if (phase === "out" && item !== undefined)
            forget(item.id);
    }

    function wipe(): void {
        items = [];
        Quickshell.execDetached([Config.cmd.clipboard, "wipe"]);
    }

    function refresh(): void {
        if (!lister.running)
            lister.running = true;
    }

    function parse(text: string): var {
        const found = [];
        for (const line of text.split("\n")) {
            const tab = line.indexOf("\t");
            if (tab <= 0)
                continue;
            const id = line.slice(0, tab), preview = line.slice(tab + 1);
            const picture = /^\[\[ binary data .* ([a-z]+)(?: (\d+)x(\d+))? \]\]$/.exec(preview);
            if (picture) {
                found.push({ id: id, kind: "image", text: "", format: picture[1], mime: "image/" + picture[1],
                             width: Number(picture[2] ?? 0), height: Number(picture[3] ?? 0),
                             file: root.dir !== "" ? root.dir + "/" + id + "." + picture[1] : "" });
            } else {
                const plain = preview.trim();
                const kind = /^#[0-9a-fA-F]{6}$/.test(plain) ? "colour" : /^https?:\/\/\S+$/.test(plain) ? "link" : "text";
                found.push({ id: id, kind: kind, text: preview, format: "", mime: "", width: 0, height: 0, file: "" });
            }
        }
        return found.slice(0, Config.clipboard);
    }

    onShownChanged: {
        if (!shown && phase === "out") {
            phase = "";
            keyboard = false;
            idle.stop();
        }
    }

    Timer {
        id: later
        interval: root.wait
        onTriggered: root.reveal()
    }

    Timer {
        id: idle
        interval: 20000
        onTriggered: root.cancel()
    }

    Timer {
        id: settle

        property int tries: 0

        interval: 60
        repeat: true
        onTriggered: {
            tries += 1;
            const active = ToplevelManager.activeToplevel;
            const back = root.target === null || active === root.target;
            if (tries < 2 || (!back && tries < 8))
                return;
            stop();
            const job = root.pending;
            root.pending = null;
            if (job === null)
                return;
            const elsewhere = !back && active !== null;
            const item = job.item;
            if (item === null) {
                if (elsewhere) {
                    console.info("nihil: clipboard: another window has the keyboard, nothing pasted");
                    return;
                }
                console.info("nihil: clipboard: pasting what is on the clipboard with SHIFT + Insert");
                Quickshell.execDetached([Config.cmd.clipboard, "keys", "paste"]);
                return;
            }
            console.info("nihil: clipboard: " + (elsewhere ? "copied " + item.id + ", another window has the keyboard"
                                                           : "pasting " + item.id + " with SHIFT + Insert"));
            Quickshell.execDetached([Config.cmd.clipboard, elsewhere ? "copy" : "paste", item.id, item.mime]);
        }
    }

    Process {
        id: lister
        command: [Config.cmd.clipboard, "list", String(Config.clipboard)]
        stdout: StdioCollector {
            onStreamFinished: {
                root.items = root.parse(text);
                root.index = Math.min(root.index, Math.max(0, root.items.length - 1));
            }
        }
    }

    GlobalShortcut {
        name: "nihil-clipboard"
        description: "NIHIL: paste, or the clipboard history held down"
        onPressed: root.press()
    }

    GlobalShortcut {
        name: "nihil-clipboard-next"
        description: "NIHIL: the next copy in the clipboard history"
        onPressed: root.step(1)
    }

    GlobalShortcut {
        name: "nihil-clipboard-back"
        description: "NIHIL: the copy before in the clipboard history"
        onPressed: root.step(-1)
    }

    GlobalShortcut {
        name: "nihil-clipboard-forget"
        description: "NIHIL: forget the copy chosen in the clipboard history"
        onPressed: root.forgetChosen()
    }

    GlobalShortcut {
        name: "nihil-clipboard-paste"
        description: "NIHIL: paste the copy chosen in the clipboard history"
        onPressed: root.paste()
    }

    GlobalShortcut {
        name: "nihil-clipboard-cancel"
        description: "NIHIL: leave the clipboard history, pasting nothing"
        onPressed: root.cancel()
    }

    GlobalShortcut {
        name: "nihil-super"
        description: "NIHIL: SUPER down and up, for the clipboard history"
        onPressed: root.track("super", true)
        onReleased: root.track("super", false)
    }

    GlobalShortcut {
        name: "nihil-ctrl"
        description: "NIHIL: CTRL down and up, for the clipboard history"
        onPressed: root.track("ctrl", true)
        onReleased: root.track("ctrl", false)
    }

    GlobalShortcut {
        name: "nihil-alt"
        description: "NIHIL: ALT down and up, for the clipboard history"
        onPressed: root.track("alt", true)
        onReleased: root.track("alt", false)
    }

    GlobalShortcut {
        name: "nihil-shift"
        description: "NIHIL: SHIFT down and up, for the clipboard history"
        onPressed: root.track("shift", true)
        onReleased: root.track("shift", false)
    }

    IpcHandler {
        target: "clipboard"

        function open(): void { root.press(); }
        function next(): void { root.step(1); }
        function previous(): void { root.step(-1); }
        function released(): void { root.released("nihil-ipc"); }
        function paste(): void { root.paste(); }
        function cancel(): void { root.cancel(); }
    }
}
