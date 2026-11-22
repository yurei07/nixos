import QtQuick
import qs.theme

Item {
    id: root

    property string glyph: ""
    property alias color: label.color
    property alias font: label.font

    implicitWidth: ink.advanceWidth
    implicitHeight: line.height

    TextMetrics {
        id: ink
        font: label.font
        text: root.glyph
    }

    FontMetrics {
        id: line
        font: label.font
    }

    Text {
        id: label

        x: root.width / 2 - (ink.tightBoundingRect.x + ink.tightBoundingRect.width / 2)
        y: root.height / 2 - (line.ascent + ink.tightBoundingRect.y + ink.tightBoundingRect.height / 2)
        text: root.glyph
        color: Tokens.dim
        font.family: Tokens.fontIcons
        font.pixelSize: 16

        Behavior on color { ColorAnimation { duration: Tokens.animFast } }
    }
}
