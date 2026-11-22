pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    property string state: ""
    property int behind: 0
    property var commits: []
    property string pinned: ""
    property string dev: ""
    property real checkedAt: 0

    readonly property string summary: state === "behind" ? (behind === 1 ? Lang.updBehindOne : Lang.updBehind.arg(behind))
        : state === "current" ? Lang.updCurrent.arg(pinned)
        : state === "offline" ? Lang.updOffline
        : state === "unknown" ? Lang.updUnknown
        : Lang.updChecking

    function check(): void {
        if (checker.running)
            return;
        if (state === "")
            state = "checking";
        checker.running = true;
    }

    // The checkout nihil dev builds, read here on its own: Preferences says so where the
    // password that builds it as root is asked, and nihil dev may have changed meanwhile.
    function readDev(): void {
        if (!devReader.running)
            devReader.running = true;
    }

    function maybeCheck(): void {
        if (Date.now() - checkedAt > 30 * 60 * 1000)
            check();
    }

    Timer {
        interval: 60 * 1000
        running: true
        onTriggered: root.check()
    }

    Timer {
        interval: 6 * 3600 * 1000
        running: true
        repeat: true
        onTriggered: root.check()
    }

    Process {
        id: devReader
        command: [Config.cmd.sh, "-c", "d=$(head -n 1 /var/lib/nihil/dev 2>/dev/null) && [ -f \"$d/flake.nix\" ] && printf '%s' \"$d\""]
        stdout: StdioCollector {
            onStreamFinished: root.dev = text.trim()
        }
    }

    Process {
        id: checker
        command: [Config.cmd.nihil, "check", "--json"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const found = JSON.parse(text);
                    root.state = found.state ?? "unknown";
                    root.behind = found.behind ?? 0;
                    root.commits = found.commits ?? [];
                    root.pinned = found.pinned ?? "";
                    root.dev = found.dev ?? "";
                } catch (error) {
                    root.state = "offline";
                }
                root.checkedAt = Date.now();
            }
        }
    }
}
