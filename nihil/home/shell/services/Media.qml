pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import qs.config

Singleton {
    id: root

    readonly property var players: Mpris.players.values
    readonly property var active: players.find(p => p.isPlaying) ?? players[0] ?? null
    readonly property bool playing: active?.isPlaying ?? false
    readonly property string title: active?.trackTitle || Lang.nothingPlaying
    readonly property string artist: active?.trackArtist ?? ""
    readonly property string art: active?.trackArtUrl ?? ""
    readonly property string player: active?.identity ?? ""
    readonly property real length: active?.length ?? 0
    property real position: 0
    readonly property real progress: length > 0 ? Math.min(1, position / length) : 0

    function toggle(): void { active?.togglePlaying(); }
    function next(): void { active?.next(); }
    function previous(): void { active?.previous(); }

    IpcHandler {
        target: "media"

        function toggle(): void { root.toggle(); }
        function next(): void { root.next(); }
        function previous(): void { root.previous(); }
        function now(): string {
            const player = root.active;
            return JSON.stringify(player === null ? null
                : { title: player.trackTitle ?? "", artist: player.trackArtist ?? "", player: player.identity ?? "", playing: player.isPlaying, art: player.trackArtUrl ?? "" });
        }
    }

    // A time of what plays, or dashes with nothing playing.
    function shown(seconds: real): string {
        return active ? clock(seconds) : "--:--";
    }

    function clock(seconds: real): string {
        const s = Math.max(0, Math.floor(seconds));
        return Math.floor(s / 60) + ":" + String(s % 60).padStart(2, "0");
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.active !== null
        triggeredOnStart: true
        onTriggered: {
            root.active?.positionChanged();
            root.position = root.active?.position ?? 0;
        }
    }
}
