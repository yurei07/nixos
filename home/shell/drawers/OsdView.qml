import QtQuick
import qs.theme
import qs.services
import qs.components

Item {
    id: root

    readonly property string glyph: Osd.kind === "brightness" ? Icons.brightness
                                  : Osd.kind === "mic" ? (Osd.muted ? Icons.micOff : Icons.mic)
                                  : Icons.volume(Osd.value, Osd.muted)

    Column {
        anchors.centerIn: parent
        spacing: 14

        Ico {
            anchors.horizontalCenter: parent.horizontalCenter
            glyph: root.glyph
            font.pixelSize: 18
            color: Osd.muted ? Tokens.interrupt : Tokens.ink
        }

        DotMeter {
            anchors.horizontalCenter: parent.horizontalCenter
            vertical: true
            count: 16
            dot: 6
            gap: 5
            value: Osd.muted ? 0 : Osd.value
        }

        DotText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Osd.muted ? "--" : String(Math.round(Osd.value * 100))
            font.pixelSize: 20
            color: Osd.muted ? Tokens.muted : Tokens.ink
        }
    }
}
