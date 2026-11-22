import QtQuick
import qs.theme

Item {
    id: root

    property string glyph: ""
    property string label: ""
    property bool active: false
    property bool expandable: false
    property bool expanded: false

    signal toggled()
    signal expand()

    // Enter or Space switches it; Shift+Enter or the menu key opens what it holds, as the right
    // button does.
    function press(event: var): void {
        if (event.isAutoRepeat)
            return;
        if (root.expandable && (event.modifiers & Qt.ShiftModifier))
            root.expand();
        else
            root.toggled();
    }

    implicitWidth: 96
    implicitHeight: 92
    activeFocusOnTab: true

    Accessible.role: Accessible.CheckBox
    Accessible.name: root.label
    Accessible.checkable: true
    Accessible.checked: root.active
    Accessible.onPressAction: root.toggled()
    Accessible.onToggleAction: root.toggled()
    Keys.onReturnPressed: event => root.press(event)
    Keys.onEnterPressed: event => root.press(event)
    Keys.onSpacePressed: event => root.press(event)
    Keys.onMenuPressed: {
        if (root.expandable)
            root.expand();
    }

    Surface {
        id: disc
        anchors.horizontalCenter: parent.horizontalCenter
        width: 56
        height: 56
        radius: 28
        color: root.active ? Tokens.ink : (area.containsMouse ? Tokens.raised : Tokens.surface)
        border.width: root.active ? 0 : 1
        border.color: Tokens.line

        Behavior on color { ColorAnimation { duration: Tokens.animNormal } }

        Ico {
            anchors.centerIn: parent
            glyph: root.glyph
            font.pixelSize: 22
            color: root.active ? Tokens.black : Tokens.dim
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            cursorShape: Qt.PointingHandCursor
            onClicked: mouse => mouse.button === Qt.RightButton && root.expandable ? root.expand() : root.toggled()
        }

        FocusRing {
            shown: root.activeFocus
            round: disc.radius
        }
    }

    Row {
        id: caption
        anchors.top: disc.bottom
        anchors.topMargin: 8
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 3

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.label
            color: more.containsMouse ? Tokens.ink : root.active ? Tokens.dim : Tokens.muted
        }

        Ico {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.expandable
            glyph: Icons.chevron
            font.pixelSize: 11
            color: root.expanded || more.containsMouse ? Tokens.ink : Tokens.muted
            rotation: root.expanded ? 90 : 0

            Behavior on rotation { NumberAnimation { duration: Tokens.animNormal } }
        }
    }

    MouseArea {
        id: more
        visible: root.expandable
        anchors.fill: caption
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.expand()
    }
}
