pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    readonly property bool active: Drawers.current === "dashboard"
    // The processor, memory and temperature, for the Dashboard and the desktop's system card.
    readonly property bool measuring: active || Machine.widgets.indexOf("system") >= 0
    // Read only while shown, by those or the desktop's network card.
    readonly property bool shown: measuring || Machine.widgets.indexOf("network") >= 0
    property real cpu: 0            // 0..1
    property real mem: 0            // 0..1
    property real temp: 0           // degrees C
    property real disk: 0           // 0..1, of the system's filesystem, for the system card
    property string iface: ""
    property real rx: 0             // bytes/s
    property real tx: 0
    property var rxHistory: []
    property var txHistory: []

    property var lastCpu: null
    property real lastRx: -1
    property real lastTx: -1
    property string tempPath: ""
    property string tempSkip: ""
    property int tempMisses: 0

    // As every size in NIHIL is written: powers of 1000, and the language's decimal mark.
    function human(bytes: real): string {
        return Dates.bytes(bytes) + "/s";
    }

    function push(list: var, value: real): var {
        const next = list.concat([value]);
        return next.length > 60 ? next.slice(next.length - 60) : next;
    }

    FileView { id: stat; path: "/proc/stat"; blockLoading: true }
    FileView { id: meminfo; path: "/proc/meminfo"; blockLoading: true }
    FileView { id: tempFile; path: root.tempPath; blockLoading: true }
    FileView { id: rxFile; path: root.iface ? `/sys/class/net/${root.iface}/statistics/rx_bytes` : ""; blockLoading: true }
    FileView { id: txFile; path: root.iface ? `/sys/class/net/${root.iface}/statistics/tx_bytes` : ""; blockLoading: true }

    Process {
        id: route
        command: [Config.cmd.ip, "route", "show", "default"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = text.match(/dev (\S+)/);
                const iface = m ? m[1] : "";
                if (iface !== root.iface) { root.lastRx = -1; root.lastTx = -1; }
                root.iface = iface;
            }
        }
    }

    Process {
        id: findTemp
        command: [Config.cmd.sh, "-c",
            "skip=$1; sane() { [ \"$1\" != \"$skip\" ] && v=$(cat \"$1\" 2>/dev/null) && [ \"${v:-0}\" -gt 0 ] 2>/dev/null && [ \"$v\" -lt 150000 ]; }; " +
            "for want in k10temp zenpower coretemp cpu_thermal thinkpad acpitz; do " +
            "for d in /sys/class/hwmon/hwmon*; do [ \"$(cat \"$d/name\" 2>/dev/null)\" = \"$want\" ] || continue; " +
            "for f in \"$d\"/temp*_input; do sane \"$f\" && { echo \"$f\"; exit; }; done; done; done; " +
            "for f in /sys/class/thermal/thermal_zone*/temp /sys/class/hwmon/hwmon*/temp*_input; do sane \"$f\" && { echo \"$f\"; exit; }; done",
            "sh", root.tempSkip]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                root.tempPath = text.trim();
                console.info("nihil: temperature from", root.tempPath || "nowhere");
            }
        }
    }

    onMeasuringChanged: {
        if (measuring && !tempPath && !findTemp.running)
            findTemp.running = true;
        // Counted afresh on opening: from the last time, it would be the use over all the time between.
        if (!measuring)
            lastCpu = null;
    }

    // Hidden, nothing is read; shown again, the rates start over rather than spread what came in
    // meanwhile over one second.
    onShownChanged: {
        if (shown)
            return;
        lastRx = -1;
        lastTx = -1;
        rx = 0;
        tx = 0;
        rxHistory = [];
        txHistory = [];
    }

    // The way out can change with the network: read again then, rather than every few seconds.
    Connections {
        target: Network
        enabled: root.shown

        function onSsidChanged(): void { route.running = true; }
        function onEthernetChanged(): void { route.running = true; }
    }

    function tick(): void {
        if (root.iface) {
            rxFile.reload();
            txFile.reload();
            const r = parseFloat(rxFile.text()), t = parseFloat(txFile.text());
            if (!isNaN(r) && !isNaN(t)) {
                if (root.lastRx >= 0) {
                    root.rx = Math.max(0, r - root.lastRx);
                    root.tx = Math.max(0, t - root.lastTx);
                }
                root.lastRx = r;
                root.lastTx = t;
            }
        } else {
            root.rx = 0;
            root.tx = 0;
        }
        root.rxHistory = root.push(root.rxHistory, root.rx);
        root.txHistory = root.push(root.txHistory, root.tx);

        if (!root.measuring) return;

        stat.reload();
        const cpuLine = stat.text().split("\n")[0].trim().split(/\s+/).slice(1).map(Number);
        const idle = cpuLine[3] + (cpuLine[4] || 0);
        const total = cpuLine.reduce((a, b) => a + b, 0);
        if (root.lastCpu && total > root.lastCpu.total)
            root.cpu = 1 - (idle - root.lastCpu.idle) / (total - root.lastCpu.total);
        root.lastCpu = { idle: idle, total: total };

        meminfo.reload();
        const mem = {};
        for (const line of meminfo.text().split("\n")) {
            const m = line.match(/^(\w+):\s+(\d+)/);
            if (m) mem[m[1]] = parseInt(m[2]);
        }
        if (mem.MemTotal) root.mem = 1 - (mem.MemAvailable ?? mem.MemFree) / mem.MemTotal;

        if (root.tempPath) {
            tempFile.reload();
            const v = parseInt(tempFile.text());
            if (!isNaN(v) && v > 0 && v < 150000) {
                root.temp = v / 1000;
                root.tempMisses = 0;
            } else if (++root.tempMisses >= 5) {
                console.warn("nihil: temperature: no reading from", root.tempPath + ", looking for another sensor");
                root.tempSkip = root.tempPath;
                root.tempMisses = 0;
                root.tempPath = "";
                findTemp.running = true;
            }
        }
    }

    Timer {
        interval: 1000
        running: root.shown
        repeat: true
        triggeredOnStart: true
        onTriggered: root.tick()
    }

    Timer {
        interval: 30000
        running: root.shown
        repeat: true
        triggeredOnStart: true
        onTriggered: route.running = true
    }

    // A disk fills slowly: once a minute.
    Process {
        id: diskUse
        command: [Config.cmd.df, "-kP", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const fields = text.trim().split("\n").pop().trim().split(/\s+/);
                const used = Number(fields[2]), free = Number(fields[3]);
                if (used >= 0 && free >= 0 && used + free > 0)
                    root.disk = used / (used + free);
            }
        }
    }

    Timer {
        interval: 60000
        running: Machine.widgets.indexOf("system") >= 0
        repeat: true
        triggeredOnStart: true
        onTriggered: diskUse.running = true
    }
}
