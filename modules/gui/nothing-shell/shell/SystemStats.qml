pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Bar system monitor: CPU from /proc/stat deltas, memory from /proc/meminfo.
// Polled every 2 s; both reads are cheap single-file sysfs/procfs reads.
Singleton {
    id: root

    property real cpu: 0 // 0..1 over the polling interval
    property real memUsed: 0 // bytes
    property real memTotal: 0 // bytes
    readonly property real memFrac: memTotal > 0 ? memUsed / memTotal : 0

    property real prevIdle: 0
    property real prevTotal: 0

    Timer {
        interval: 2000
        repeat: true
        running: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload();
            memFile.reload();
        }
    }

    FileView {
        id: statFile
        path: "/proc/stat"
        blockLoading: true
        onLoaded: {
            const line = root.splitFirst(text());
            if (!line)
                return;
            const p = line.split(/\s+/).slice(1).map(Number);
            const total = p.reduce((a, b) => a + b, 0);
            const idle = p[3] + (p[4] ?? 0); // idle + iowait
            const dTotal = total - root.prevTotal;
            const dIdle = idle - root.prevIdle;
            if (root.prevTotal > 0 && dTotal > 0)
                root.cpu = Math.max(0, Math.min(1, 1 - dIdle / dTotal));
            root.prevTotal = total;
            root.prevIdle = idle;
        }
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        blockLoading: true
        onLoaded: {
            const get = k => {
                const l = root.findLine(text(), k + ":");
                return l ? Number(l.split(/\s+/)[1]) * 1024 : 0;
            };
            root.memTotal = get("MemTotal");
            root.memUsed = Math.max(0, root.memTotal - get("MemAvailable"));
        }
    }

    function splitFirst(text) {
        const lines = text.split("\n");
        for (const l of lines)
            if (l.startsWith("cpu "))
                return l;
        return "";
    }

    function findLine(text, prefix) {
        const lines = text.split("\n");
        for (const l of lines)
            if (l.startsWith(prefix))
                return l;
        return "";
    }
}
