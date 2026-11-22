import QtQuick
import qs.theme
import qs.config
import qs.services

// Previous, play or pause, next: the Dashboard's and the desktop's, the same, and off with nothing
// to play.
Row {
    property int size: 32

    spacing: size >= 32 ? 8 : 6
    enabled: Media.active !== null
    opacity: enabled ? 1 : 0.35

    CircleButton { glyph: Icons.prev; label: Lang.mediaPrevious; size: parent.size; onClicked: Media.previous() }
    CircleButton {
        glyph: Media.playing ? Icons.pause : Icons.play
        label: Media.playing ? Lang.mediaPause : Lang.mediaPlay
        size: parent.size
        filled: true
        onClicked: Media.toggle()
    }
    CircleButton { glyph: Icons.next; label: Lang.mediaNext; size: parent.size; onClicked: Media.next() }
}
