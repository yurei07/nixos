pragma Singleton

import QtQuick
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    property string folder: ""
    // A *.part or *.crdownload counts while it grows: one left behind (a download paused, a
    // browser that crashed) would keep the glyph on for good.
    property int growing: 0
    readonly property bool active: root.folder !== "" && partial.count > 0 && root.growing > 0

    onActiveChanged: {
        if (root.active)
            Glyph.track("downloads", -1);
        else
            Glyph.finish("downloads", "quiet");
    }

    FolderListModel {
        id: partial
        folder: root.folder !== "" ? "file://" + root.folder : ""
        nameFilters: ["*.part", "*.crdownload"]
        showDirs: false
        showHidden: true
        onCountChanged: {
            if (count > 0)
                look.restart();
            else
                root.growing = 0;
        }
    }

    // Written to in the last half minute. Looked at every few seconds while one grows, every
    // minute while only old ones lie there, and at once when one comes or goes.
    Process {
        id: fresh
        command: [Config.cmd.sh, "-c", 'find "$1" -maxdepth 1 -type f \\( -name "*.part" -o -name "*.crdownload" \\) -newermt "30 seconds ago" | wc -l',
            "sh", root.folder]
        stdout: StdioCollector {
            onStreamFinished: root.growing = parseInt(text) || 0
        }
    }

    Timer {
        id: look
        interval: root.growing > 0 ? 5000 : 60000
        running: root.folder !== "" && partial.count > 0
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            if (!fresh.running)
                fresh.running = true;
        }
    }

    Process {
        running: true
        command: [Config.cmd.xdgUserDir, "DOWNLOAD"]
        stdout: StdioCollector {
            onStreamFinished: {
                const dir = text.trim();
                const home = Quickshell.env("HOME");
                root.folder = dir !== "" && dir !== home ? dir : home + "/Downloads";
            }
        }
    }
}
