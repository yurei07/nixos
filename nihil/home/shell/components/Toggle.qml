import QtQuick
import qs.theme

Item {
    id: root

    property bool on: false
    // Its name for a screen reader; without one, the title of the row it sits in.
    property string label: ""
    readonly property string named: {
        if (label !== "")
            return label;
        const key = "title";
        for (let item = parent; item; item = item.parent) {
            if (typeof item[key] === "string" && item[key] !== "")
                return item[key];
        }
        return "";
    }

    signal toggled()

    function press(event: var): void {
        if (!event.isAutoRepeat)
            root.toggled();
    }

    implicitWidth: 34
    implicitHeight: 30
    activeFocusOnTab: true

    Accessible.role: Accessible.CheckBox
    Accessible.name: root.named
    Accessible.checkable: true
    Accessible.checked: root.on
    Accessible.onPressAction: root.toggled()
    Accessible.onToggleAction: root.toggled()
    Keys.onSpacePressed: event => root.press(event)
    Keys.onReturnPressed: event => root.press(event)
    Keys.onEnterPressed: event => root.press(event)

    Surface {
        id: track
        anchors.verticalCenter: parent.verticalCenter
        width: 34
        height: 20
        radius: 10
        color: root.on ? Tokens.ink : "transparent"
        border.width: 1
        property color borderTint: root.on ? Tokens.ink : area.containsMouse ? Tokens.muted : Tokens.off
        border.color: borderTint

        Behavior on color { ColorAnimation { duration: Tokens.animFast } }
        Behavior on borderTint { ColorAnimation { duration: Tokens.animFast } }

        Surface {
            anchors.verticalCenter: parent.verticalCenter
            x: root.on ? parent.width - width - 4 : 4
            width: 12
            height: 12
            radius: 6
            color: root.on ? Tokens.black : area.containsMouse ? Tokens.dim : Tokens.muted

            Behavior on x { NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic } }
            Behavior on color { ColorAnimation { duration: Tokens.animFast } }
        }

        FocusRing {
            shown: root.activeFocus
            round: track.radius
        }
    }

    MouseArea {
        id: area
        anchors.fill: parent
        anchors.margins: -6
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: root.toggled()
    }
}
