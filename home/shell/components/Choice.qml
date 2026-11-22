import QtQuick
import qs.theme

Flow {
    id: root

    property var options: []
    property var value
    property bool mono: false
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
    readonly property int chosen: options.findIndex(option => JSON.stringify(option.value) === JSON.stringify(value))

    signal picked(var value)

    // The arrows pick the one beside, as in any group of options.
    function step(by: int): void {
        if (options.length === 0)
            return;
        const next = Math.max(0, Math.min(options.length - 1, (chosen < 0 ? (by > 0 ? -1 : options.length) : chosen) + by));
        if (next !== chosen)
            root.picked(options[next].value);
    }

    spacing: 20
    activeFocusOnTab: options.length > 0

    Accessible.role: Accessible.Grouping
    Accessible.name: root.named
    Keys.onLeftPressed: root.step(-1)
    Keys.onUpPressed: root.step(-1)
    Keys.onRightPressed: root.step(1)
    Keys.onDownPressed: root.step(1)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Home)
            root.step(-root.options.length);
        else if (event.key === Qt.Key_End)
            root.step(root.options.length);
        else
            return;
        event.accepted = true;
    }

    Repeater {
        model: root.options

        Item {
            id: option

            required property var modelData
            required property int index
            readonly property bool chosen: root.chosen === index

            implicitWidth: name.implicitWidth
            implicitHeight: 30

            Accessible.role: Accessible.RadioButton
            Accessible.name: option.modelData.label
            Accessible.checkable: true
            Accessible.checked: option.chosen
            Accessible.onPressAction: root.picked(option.modelData.value)

            Txt {
                id: name
                anchors.verticalCenter: parent.verticalCenter
                anchors.verticalCenterOffset: -1
                text: option.modelData.label
                color: option.chosen ? Tokens.ink : area.containsMouse ? Tokens.dim : Tokens.muted
                font.family: root.mono ? Tokens.fontMono : Tokens.fontSans
                font.pixelSize: 13

                Behavior on color { ColorAnimation { duration: Tokens.animFast } }
            }

            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 2
                color: option.chosen ? Tokens.ink : Tokens.off
                opacity: option.chosen || area.containsMouse ? 1 : 0

                Behavior on opacity { NumberAnimation { duration: Tokens.animFast } }
            }

            FocusRing {
                anchors.margins: -5
                shown: root.activeFocus && (option.chosen || (root.chosen < 0 && option.index === 0))
                round: 4
            }

            MouseArea {
                id: area
                anchors.fill: parent
                anchors.margins: -6
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.picked(option.modelData.value)
            }
        }
    }
}
