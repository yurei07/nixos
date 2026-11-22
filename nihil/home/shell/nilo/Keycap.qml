import QtQuick
import qs.theme
import qs.components

Surface {
    id: root

    property string text: ""

    implicitWidth: Math.max(34, label.implicitWidth + 20)
    implicitHeight: 30
    radius: 8
    color: Tokens.surface
    border.width: 1
    border.color: Tokens.line

    Label {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: Tokens.ink
        font.pixelSize: 11
    }
}
