pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import qs.config

Singleton {
    id: root

    readonly property PwNode sink: Pipewire.defaultAudioSink
    readonly property PwNode source: Pipewire.defaultAudioSource

    readonly property real volume: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? true
    readonly property real micVolume: source?.audio?.volume ?? 0
    readonly property bool micMuted: source?.audio?.muted ?? true

    readonly property var sinks: Pipewire.nodes.values.filter(n => n.audio && n.isSink && !n.isStream)

    readonly property bool micInUse: Pipewire.nodes.values.some(n =>
        n.audio && n.isStream && !n.isSink && !/cava|pavucontrol|quickshell/i.test(`${n.name} ${n.description}`))

    PwObjectTracker {
        objects: [root.sink, root.source]
    }

    readonly property bool silent: muted || volume < 0.02
    readonly property string silentFile: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/nihil/silent"

    onSilentChanged: if (sink?.audio) remember.restart()

    Timer {
        id: remember
        interval: 1500
        onTriggered: Quickshell.execDetached([Config.cmd.sh, "-c",
            root.silent ? "mkdir -p \"$(dirname \"$1\")\" && touch \"$1\"" : "rm -f \"$1\"", "sh", root.silentFile])
    }

    function setVolume(v: real): void {
        if (!sink?.audio) return;
        sink.audio.muted = false;
        sink.audio.volume = Math.max(0, Math.min(1, v));
    }

    function toggleMute(): void {
        if (sink?.audio) sink.audio.muted = !sink.audio.muted;
    }

    function setMicVolume(v: real): void {
        if (!source?.audio) return;
        source.audio.muted = false;
        source.audio.volume = Math.max(0, Math.min(1, v));
        led.restart();
    }

    function toggleMic(): void {
        if (!source?.audio) return;
        source.audio.muted = !source.audio.muted;
        led.restart();
    }

    function setDefaultSink(node): void {
        Pipewire.preferredDefaultAudioSink = node;
    }

    Timer {
        id: led
        interval: 200
        onTriggered: Quickshell.execDetached([Config.cmd.micLedSync])
    }
}
