import QtQuick
import qs.theme

Item {
    id: root

    property string text: ""
    property bool wrong: true
    property color color: Tokens.muted
    property alias font: words.font
    property alias horizontalAlignment: words.horizontalAlignment

    readonly property real indent: wrong ? 14 : 0

    implicitWidth: words.implicitWidth + indent
    implicitHeight: words.implicitHeight

    FontMetrics {
        id: line
        font: words.font
    }

    Rectangle {
        visible: root.wrong
        y: Math.round((line.height - height) / 2)
        width: 6
        height: 6
        radius: 3
        color: Tokens.interrupt
    }

    Label {
        id: words
        x: root.indent
        width: root.width - root.indent
        text: root.text
        color: root.wrong ? Tokens.ink : root.color
    }
}
