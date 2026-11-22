pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    property bool on: false
    property date since: new Date()
    // Through a restart of the shell (applying settings restarts it), the screen stays on until
    // it's turned off here; the next session starts without it.
    readonly property string file: Machine.runtimeDir !== "" ? Machine.runtimeDir + "/nihil-caffeine" : ""

    function toggle(): void { set(!on); }

    function set(value: bool): void {
        if (value === on) return;
        if (value) since = new Date();
        on = value;
        if (root.file !== "")
            Quickshell.execDetached(value ? [Config.cmd.sh, "-c", "printf '%s\\n' \"$2\" > \"$1\"", "sh", root.file, String(root.since.getTime())]
                                          : [Config.cmd.sh, "-c", "rm -f \"$1\"", "sh", root.file]);
    }

    FileView {
        path: root.file
        printErrors: false
        onLoaded: {
            const at = Number(text().trim());
            root.since = at > 0 ? new Date(at) : new Date();
            root.on = true;
        }
    }

    IpcHandler {
        target: "caffeine"

        function toggle(): void { root.toggle(); }
        function on(): void { root.set(true); }
        function off(): void { root.set(false); }
        function status(): string { return root.on ? "on" : "off"; }
    }
}
