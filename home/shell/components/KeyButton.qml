import QtQuick
import qs.theme

Surface {
    id: root

    property string text: ""
    property bool accent: false
    property bool danger: false

    signal clicked()

    function press(event: var): void {
        if (!event.isAutoRepeat)
            root.clicked();
    }

    implicitWidth: label.implicitWidth + 28
    implicitHeight: 30
    radius: 8
    activeFocusOnTab: true
    color: danger ? Tokens.interrupt : accent ? Tokens.ink : area.containsMouse ? Tokens.raised : Tokens.surface
    border.width: 1
    border.color: danger ? Tokens.interrupt : accent ? Tokens.ink : area.containsMouse ? Tokens.muted : Tokens.line

    Accessible.role: Accessible.Button
    Accessible.name: root.text
    Accessible.onPressAction: root.clicked()
    Keys.onReturnPressed: event => root.press(event)
    Keys.onEnterPressed: event => root.press(event)
    Keys.onSpacePressed: event => root.press(event)

    Behavior on color { ColorAnimation { duration: Tokens.animFast } }

    Label {
        id: label
        anchors.centerIn: parent
        text: root.text
        color: root.danger ? Tokens.ink : root.accent ? Tokens.black : area.containsMouse ? Tokens.ink : Tokens.dim
    }

    FocusRing {
        round: root.radius
    }

    MouseArea {
        id: area
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.clicked()
    }
}
