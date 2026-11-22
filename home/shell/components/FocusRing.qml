import QtQuick
import qs.theme

// Where the keyboard is: a line just outside the control that has the focus.
Rectangle {
    property bool shown: parent ? parent.activeFocus : false
    property real round: 8

    anchors.fill: parent
    anchors.margins: -3
    radius: round + 3
    color: "transparent"
    border.width: 1
    border.color: Tokens.ink
    visible: shown
}
