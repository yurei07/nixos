import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.config

// A drawer opened with its key and, while that key's modifier is held, gone through with the
// same key, Shift going back: let go, the one reached is chosen. Hyprland's submap
// nihil-<name> sends the keys while it's held, as global shortcuts.
Scope {
    id: root

    // The drawer's name, as Drawers and the shortcuts know it, and its key in Config.binds.
    required property string name
    // What it's for, in the shortcuts' descriptions.
    required property string what

    property bool held: false
    property bool moved: false
    property bool entered: false

    readonly property var keyParts: String(Config.binds[root.name] ?? "").split("+").map(part => part.trim()).filter(part => part !== "")
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
    readonly property bool modifierDown: root.modifier !== "" && (Clipboard.down[root.modifier] ?? false)
    readonly property bool open: Drawers.current === root.name

    signal stepped(int delta)
    signal commit()

    function dispatch(lua: string, classic: string): void {
        Hyprland.dispatch(Hyprland.usingLua ? lua : classic);
    }

    function enter(): void {
        if (root.entered || !root.modifierDown)
            return;
        root.entered = true;
        root.dispatch(`hl.dsp.submap("nihil-${root.name}")`, `submap nihil-${root.name}`);
    }

    function leave(gone: bool): void {
        if (!root.entered)
            return;
        root.entered = false;
        if (!gone)
            root.dispatch('hl.dsp.submap("reset")', "submap reset");
    }

    function press(delta: int): void {
        if (!root.open) {
            root.held = root.modifierDown;
            root.moved = false;
            Drawers.open(root.name, "", false);
            root.enter();
            return;
        }
        if (root.modifierDown) {
            root.held = true;
            root.enter();
        }
        root.moved = true;
        root.stepped(delta);
    }

    function go(): void {
        root.leave(true);
        root.held = false;
        if (root.open)
            root.commit();
    }

    function cancel(): void {
        root.leave(true);
        root.held = false;
        if (root.open)
            Drawers.close();
    }

    onModifierDownChanged: {
        if (root.modifierDown)
            return;
        root.leave(false);
        if (!root.held)
            return;
        root.held = false;
        if (root.open && root.moved)
            root.commit();
    }

    onOpenChanged: {
        if (root.open)
            return;
        root.leave(false);
        root.held = false;
        root.moved = false;
    }

    GlobalShortcut {
        name: "nihil-" + root.name
        description: "NIHIL: " + root.what + "; held, the next one"
        onPressed: root.press(1)
    }

    GlobalShortcut {
        name: "nihil-" + root.name + "-next"
        description: "NIHIL: " + root.what + " held, the next one"
        onPressed: root.press(1)
    }

    GlobalShortcut {
        name: "nihil-" + root.name + "-back"
        description: "NIHIL: " + root.what + " held, the one before"
        onPressed: root.press(-1)
    }

    GlobalShortcut {
        name: "nihil-" + root.name + "-go"
        description: "NIHIL: " + root.what + " held, the one chosen"
        onPressed: root.go()
    }

    GlobalShortcut {
        name: "nihil-" + root.name + "-cancel"
        description: "NIHIL: " + root.what + " held, leave things as they were"
        onPressed: root.cancel()
    }
}
