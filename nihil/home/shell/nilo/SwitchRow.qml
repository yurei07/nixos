import QtQuick
import qs.theme
import qs.config
import qs.components

Item {
    id: root

    property string title: ""
    property string sub: ""
    property bool on: false
    property bool current: false
    property string guard: ""
    property bool choice: false

    readonly property bool asking: guard !== ""

    signal toggled()
    signal cancelled()

    implicitHeight: 56 + (asking ? authorization.height : 0)
    height: implicitHeight
    clip: true

    Behavior on height { NumberAnimation { duration: Tokens.animNormal; easing.type: Easing.OutCubic } }

    Surface {
        anchors.fill: parent
        radius: 14
        color: root.asking || root.current || hover.hovered ? Tokens.raised : "transparent"
        border.width: root.asking ? 1 : 0
        border.color: Tokens.interrupt
    }

    HoverHandler {
        id: hover
    }

    MouseArea {
        width: parent.width
        height: 56
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }

    Column {
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.right: toggle.left
        anchors.rightMargin: 16
        y: (56 - height) / 2
        spacing: 3

        Txt {
            width: parent.width
            text: root.title
            color: root.on || root.asking ? Tokens.ink : Tokens.dim
            font.pixelSize: 15
        }

        Txt {
            width: parent.width
            visible: text !== ""
            text: root.sub
            color: Tokens.muted
            font.pixelSize: 12
        }
    }

    Toggle {
        id: toggle
        anchors.right: parent.right
        anchors.rightMargin: 16
        y: (56 - height) / 2
        visible: !root.choice
        on: root.on
        onToggled: root.toggled()
    }

    Rectangle {
        anchors.horizontalCenter: toggle.horizontalCenter
        y: (56 - height) / 2
        width: 8
        height: 8
        radius: 4
        visible: root.choice
        color: root.on ? Tokens.ink : Tokens.off

        Behavior on color { ColorAnimation { duration: Tokens.animFast } }
    }

    Column {
        id: authorization
        x: 16
        y: 52
        width: parent.width - 32
        spacing: 12
        bottomPadding: 16
        visible: root.asking

        Txt {
            width: parent.width
            text: root.guard
            color: Tokens.dim
            wrapMode: Text.Wrap
            elide: Text.ElideNone
            font.pixelSize: 13
            lineHeight: 1.2
        }

        Row {
            anchors.right: parent.right
            spacing: 8

            KeyButton {
                text: Lang.confirmCancel
                onClicked: root.cancelled()
            }

            KeyButton {
                danger: true
                text: Lang.accessAuthorize
                onClicked: root.toggled()
            }
        }
    }
}
