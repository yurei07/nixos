pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "GithubPage.js" as GithubPage

// A year of contributions on a GitHub profile, for the desktop widget: read from the page GitHub
// draws its own calendar from, while the widget is on, every hour, and kept between sessions; a
// try that didn't read is tried again when the network comes back, or in ten minutes.
Singleton {
    id: root

    readonly property string user: String(Machine.widgetOptions.github?.user ?? "")
    readonly property bool wanted: Machine.widgets.indexOf("github") >= 0 && GithubPage.valid(root.user)
    // What was last read and whose: each day from the oldest as { date, level }, level 0 to 4, and
    // the year's total, -1 when the page didn't say.
    property var days: []
    property int total: -1
    property string of: ""
    property real readAt: 0
    // The last try didn't read: what shows, if anything, is from before.
    property bool failed: false
    readonly property bool current: root.of !== "" && root.of.toLowerCase() === root.user.toLowerCase()
    // What was kept is read first: no page asked for at login when the one kept is new enough.
    property bool loaded: false
    readonly property string keptFile: Machine.stateDir + "/github.json"
    readonly property real hour: 60 * 60 * 1000

    function valid(user: string): bool {
        return GithubPage.valid(user);
    }

    // weeks × 7 levels to today (YYYY-MM-DD), a column a week from `first`: 0 not read, -1 to come.
    function cells(weeks: int, first: int, today: string): var {
        return GithubPage.grid(root.current ? root.days : [], weeks, first, today);
    }

    function read(now: bool): void {
        if (!root.loaded || !root.wanted || page.running)
            return;
        if (!now && root.current && Date.now() - root.readAt < root.hour / 2)
            return;
        page.asked = root.user;
        page.command = [Config.cmd.curl, "-fsSL", "--max-time", "20", "--proto", "=https",
                        "https://github.com/users/" + root.user + "/contributions"];
        page.running = true;
    }

    function keep(): void {
        Quickshell.execDetached([Config.cmd.sh, "-c", "mkdir -p \"$(dirname \"$1\")\" && printf '%s' \"$2\" > \"$1\"", "sh", root.keptFile,
                                 JSON.stringify({ user: root.of, at: root.readAt, total: root.total, days: root.days })]);
    }

    onWantedChanged: root.read(false)
    onUserChanged: {
        root.failed = false;
        root.read(false);
    }

    Timer {
        interval: root.hour
        running: root.wanted
        repeat: true
        onTriggered: root.read(true)
    }

    // Offline at login, say: sooner than the hour.
    Timer {
        id: retry
        interval: 10 * 60 * 1000
        onTriggered: root.read(true)
    }

    // Once the one before has gone: a name changed while it read is read next.
    Timer {
        id: again
        interval: 50
        onTriggered: page.running ? again.restart() : root.read(true)
    }

    Connections {
        target: Network
        function onConnectedChanged(): void {
            if (Network.connected && root.failed)
                root.read(true);
        }
    }

    Process {
        id: page

        property string asked: ""

        stdout: StdioCollector {
            onStreamFinished: {
                const read = GithubPage.parse(text);
                if (read === null) {
                    root.failed = true;
                    retry.restart();
                } else {
                    root.days = read.days;
                    root.total = read.total;
                    root.of = page.asked;
                    root.readAt = Date.now();
                    root.failed = false;
                    root.keep();
                }
                if (page.asked !== root.user)
                    again.restart();
            }
        }
    }

    Process {
        command: [Config.cmd.sh, "-c", "cat \"$1\" 2>/dev/null", "sh", root.keptFile]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const kept = JSON.parse(text);
                    const days = GithubPage.clean(kept?.days);
                    if (GithubPage.valid(kept?.user) && days.length > 0 && Number.isFinite(kept?.at) && root.readAt === 0) {
                        root.days = days;
                        root.total = Number.isInteger(kept?.total) ? kept.total : -1;
                        root.of = kept.user;
                        root.readAt = kept.at;
                    }
                } catch (error) {
                }
                root.loaded = true;
                root.read(false);
            }
        }
    }
}
