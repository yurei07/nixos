pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config

Singleton {
    id: root

    property bool recording: false

    function toggle(): void {
        if (root.recording)
            Quickshell.execDetached([Config.cmd.record, "stop"]);
        else
            later.run([Config.cmd.record, "start", "screen"]);
    }

    function shot(): void {
        root.capture("region");
    }

    function capture(mode: string): void {
        later.run([Config.cmd.shot, mode]);
    }

    IpcHandler {
        target: "recorder"

        function started(): void { root.recording = true; }
        function stopped(): void { root.recording = false; }
        function status(): string { return root.recording ? "on" : "off"; }
    }

    Timer {
        id: later

        property var command: []

        function run(command: var): void {
            later.command = command;
            later.restart();
        }

        interval: 350
        onTriggered: Quickshell.execDetached(later.command)
    }

    Process {
        running: true
        command: [Config.cmd.record, "status"]
        stdout: StdioCollector {
            onStreamFinished: root.recording = text.trim() === "on"
        }
    }
}
