pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    property bool night: false
    property real nightLevel: 0.5

    readonly property int kelvin: Math.round(6000 - nightLevel * 3400)
    // Its level, and whether it's on: applying settings restarts the shell, and the night light
    // stays as it was through that, and into the next session.
    readonly property string nightFile: Machine.stateDir + "/night"

    function setNightLevel(level: real): void {
        root.nightLevel = Math.max(0, Math.min(1, level));
        keep.restart();
        if (!root.night) root.night = true;
        else retune.restart();
    }

    onNightChanged: {
        sunset.running = night;
        keep.restart();
    }

    IpcHandler {
        target: "night"

        function toggle(): void { root.night = !root.night; }
        function on(): void { root.night = true; }
        function off(): void { root.night = false; }
        function status(): string { return root.night ? "on" : "off"; }
        function level(percent: int): void { root.setNightLevel(percent / 100); }
    }

    IpcHandler {
        target: "toggles"

        function state(): string { return JSON.stringify({ caffeine: Caffeine.on, night: root.night }); }
    }

    // The level, and «on» on a line of its own; a file from before has only the level.
    FileView {
        path: root.nightFile
        printErrors: false
        onLoaded: {
            const lines = text().split("\n");
            const level = parseFloat(lines[0]);
            if (!isNaN(level)) root.nightLevel = Math.max(0, Math.min(1, level));
            if ((lines[1] ?? "").trim() === "on") root.night = true;
        }
    }

    Timer {
        id: keep
        interval: 400
        onTriggered: Quickshell.execDetached([Config.cmd.sh, "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s\\n%s\\n' \"$2\" \"$3\" > \"$1\"",
                                              "sh", root.nightFile, root.nightLevel.toFixed(2), root.night ? "on" : "off"])
    }

    Process {
        id: sunset
        command: [Config.cmd.hyprsunset, "-t", String(root.kelvin)]
    }

    Timer {
        id: retune
        interval: 120
        onTriggered: {
            if (tune.running) {
                restart();
                return;
            }
            tune.applied = root.kelvin;
            tune.said = "";
            tune.running = true;
        }
    }

    Process {
        id: tune
        property int applied: 0
        property string said: ""
        command: [Config.cmd.hyprctl, "hyprsunset", "temperature", String(applied)]
        stdout: SplitParser { onRead: line => tune.said += line + "\n" }
        onExited: code => {
            if (code !== 0 || /error|couldn|fail|invalid|unknown/i.test(tune.said)) {
                sunset.running = false;
                relaunch.restart();
            } else if (root.night && tune.applied !== root.kelvin) {
                retune.restart();
            }
        }
    }

    Timer {
        id: relaunch
        interval: 400
        onTriggered: sunset.running = root.night
    }
}
