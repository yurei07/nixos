pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "Agenda.js" as Agenda

// The calendars subscribed to in Preferences, read by nihil-calendar (home/calendar) for the
// calendar widget: what it kept at the last read first, then, while the widget is on and there's
// any, every quarter of an hour, again when the network comes back after a read that didn't, and
// at once after one is added or taken away.
Singleton {
    id: root

    // [{ id, name, ok }], and their events: [{ cal, title, where, allDay, start, end }] by start.
    property var calendars: []
    property var events: []
    property real updated: 0
    readonly property bool any: root.calendars.length > 0
    readonly property bool failed: root.calendars.some(calendar => !calendar.ok)
    readonly property bool shown: Machine.widgets.indexOf("calendar") >= 0
    // Adding one: the address goes in on stdin, which no one else can read. Done once its answer is
    // read, so what went wrong is known by then.
    property bool adding: false
    property string addError: ""
    property bool loaded: false
    readonly property real minute: 60 * 1000
    readonly property string keptFile: (Quickshell.env("XDG_CACHE_HOME") || Quickshell.env("HOME") + "/.cache") + "/nihil/calendar.json"
    readonly property string listFile: (Quickshell.env("XDG_CONFIG_HOME") || Quickshell.env("HOME") + "/.config") + "/nihil/calendars.json"

    function take(text: string): void {
        try {
            const kept = JSON.parse(text);
            if (!Array.isArray(kept?.calendars) || !Array.isArray(kept?.events))
                return;
            root.calendars = kept.calendars.filter(c => typeof c?.id === "string").map(c => ({ id: c.id, name: String(c.name ?? ""), ok: c.ok === true }));
            root.events = kept.events.filter(e => Number.isFinite(e?.start) && Number.isFinite(e?.end));
            root.updated = Number(kept.updated) || 0;
        } catch (error) {
        }
    }

    function sync(): void {
        if (!root.loaded)
            return;
        if (syncer.running) {
            syncer.again = true;
            return;
        }
        syncer.running = true;
    }

    function add(address: string): void {
        if (root.adding || address.trim() === "")
            return;
        root.addError = "";
        root.adding = true;
        adder.input = address.trim() + "\n";
        adder.running = true;
    }

    function remove(id: string): void {
        if (remover.running)
            return;
        remover.command = [Config.cmd.calendar, "remove", id];
        remover.running = true;
    }

    // As the widget asks: the next ones, the busy days of a month.
    function upcoming(now: real, count: int): var {
        return Agenda.upcoming(root.events, now, count);
    }

    // The days of a month with something on them: { 19: true }.
    function busy(y: int, m: int): var {
        const days = {};
        for (const day of Object.keys(Agenda.busy(root.events, y, m)))
            days[Number(day.slice(8))] = true;
        return days;
    }

    function month(y: int, m: int, first: int): var {
        return Agenda.month(y, m, first);
    }

    // A day by its short name and number, «Jue 19», without the dot some languages put after it.
    function dayName(date: var): string {
        return Case.sentence(date.toLocaleString(Qt.locale(Lang.locale), Lang.calDay).replace(/\./g, ""));
    }

    function title(event: var): string {
        return event.title !== "" ? event.title : Lang.calUntitled;
    }

    // When one is, in a few words: «Ahora», «Hoy, 10:00», «Mañana», «Jue 19, 18:30».
    function when(event: var, now: real): string {
        if (!event.allDay && event.start <= now && now < event.end)
            return Lang.calNow;
        const away = Agenda.daysAway(event.start, now);
        const start = new Date(event.start * 1000);
        const time = Qt.formatTime(start, "HH:mm");
        if (away <= 0)
            return event.allDay ? Lang.calToday : Lang.genToday.arg(time);
        if (away === 1)
            return event.allDay ? Lang.calTomorrow : Lang.calTomorrowAt.arg(time);
        const day = root.dayName(start);
        return event.allDay ? day : day + ", " + time;
    }

    Timer {
        interval: 15 * root.minute
        running: root.any && root.shown
        repeat: true
        onTriggered: root.sync()
    }

    onShownChanged: {
        if (root.shown && root.any)
            root.sync();
    }

    Connections {
        target: Network
        function onConnectedChanged(): void {
            if (Network.connected && root.failed && root.shown)
                root.sync();
        }
    }

    Process {
        id: syncer

        property bool again: false

        command: [Config.cmd.calendar, "sync"]
        stdout: StdioCollector {
            onStreamFinished: root.take(text)
        }
        onExited: {
            if (syncer.again) {
                syncer.again = false;
                syncAgain.restart();
            }
        }
    }

    Timer {
        id: syncAgain
        interval: 50
        onTriggered: syncer.running ? syncAgain.restart() : root.sync()
    }

    Process {
        id: adder

        property string input: ""

        command: [Config.cmd.calendar, "add"]
        stdinEnabled: true
        onStarted: {
            write(adder.input);
            adder.input = "";
            stdinEnabled = false;
        }
        stdout: StdioCollector {
            onStreamFinished: {
                let answer = null;
                try {
                    answer = JSON.parse(text);
                } catch (error) {
                }
                root.addError = typeof answer?.id === "string" ? "" : String(answer?.error ?? "fetch");
                root.adding = false;
                if (root.addError === "")
                    syncAgain.restart();
            }
        }
        onExited: stdinEnabled = true
    }

    Process {
        id: remover
        stdout: StdioCollector {
            onStreamFinished: syncAgain.restart()
        }
    }

    // What was kept, at once, and whether any calendar is subscribed to: then a read, which also
    // finds one added or taken away by hand. With none, nothing runs.
    Process {
        command: [Config.cmd.sh, "-c", "if [ -s \"$2\" ]; then echo some; else echo none; fi; cat \"$1\" 2>/dev/null", "sh",
                  root.keptFile, root.listFile]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const cut = text.indexOf("\n");
                root.take(text.slice(cut + 1));
                root.loaded = true;
                if ((text.slice(0, cut) === "some" || root.any) && root.shown)
                    root.sync();
            }
        }
    }
}
