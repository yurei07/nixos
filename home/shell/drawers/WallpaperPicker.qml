import QtQuick
import Quickshell.Widgets
import qs.theme
import qs.config
import qs.services
import qs.components

Item {
    id: root

    property bool active: false
    property string before: ""
    property int index: 0
    // Chosen with Enter or a click: closed any other way (Esc, a click outside, another drawer),
    // the wallpaper goes back to the one it was.
    property bool kept: false
    readonly property var names: Config.wallpapers

    // Shown once the arrows rest a moment: a key held down doesn't start a set for every step.
    function show(i: int): void {
        if (names.length === 0)
            return;
        index = (i + names.length) % names.length;
        apply.restart();
    }

    function choose(i: int): void {
        show(i);
        apply.stop();
        if (names.length > 0 && Machine.wallpaper !== names[index])
            Machine.liveWallpaper(names[index]);
        kept = true;
        Drawers.close();
    }

    onActiveChanged: {
        if (active) {
            kept = false;
            before = Machine.wallpaper;
            index = Math.max(0, names.indexOf(before));
            list.positionViewAtIndex(index, ListView.Center);
            Qt.callLater(() => { if (root.active) keys.forceActiveFocus(); });
        } else {
            apply.stop();
            if (!kept && before !== "" && Machine.wallpaper !== before)
                Machine.liveWallpaper(before);
        }
    }

    // Its key held: each press the next, with Shift the one before; let go, the one reached stays.
    Connections {
        target: Switcher.wallpapers
        function onStepped(delta: int): void {
            if (root.active)
                root.show(root.index + delta);
        }
        function onCommit(): void {
            if (root.active)
                root.choose(root.index);
        }
    }

    Timer {
        id: apply
        interval: 150
        onTriggered: if (root.names.length > 0 && Machine.wallpaper !== root.names[root.index]) Machine.liveWallpaper(root.names[root.index])
    }

    Item {
        id: keys
        anchors.fill: parent
        focus: root.active
        Keys.onLeftPressed: root.show(root.index - 1)
        Keys.onRightPressed: root.show(root.index + 1)
        Keys.onReturnPressed: root.choose(root.index)
        Keys.onEnterPressed: root.choose(root.index)
        Keys.onEscapePressed: Drawers.close()
        Keys.onTabPressed: root.show(root.index + 1)
        Keys.onBacktabPressed: root.show(root.index - 1)
        Keys.onPressed: event => {
            if (Switcher.wallpapers.keyCode > 0 && event.key === Switcher.wallpapers.keyCode) {
                root.show(root.index + (event.modifiers & Qt.ShiftModifier ? -1 : 1));
                event.accepted = true;
            }
        }
    }

    KeyHints {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 16
        text: Lang.wpHint.arg(Case.key(Switcher.wallpapers.keyName !== "" ? Switcher.wallpapers.keyName : "Tab"))
    }

    ListView {
        id: list
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        anchors.topMargin: 22
        anchors.bottomMargin: 48
        orientation: ListView.Horizontal
        spacing: 14
        clip: true
        model: root.names
        currentIndex: root.index
        highlightMoveDuration: Tokens.animFast
        boundsBehavior: Flickable.StopAtBounds
        // However many there are, the chosen one in the middle, where it can be.
        highlightRangeMode: ListView.ApplyRange
        preferredHighlightBegin: (width - 208) / 2
        preferredHighlightEnd: (width + 208) / 2

        delegate: Surface {
            id: card

            required property string modelData
            required property int index

            readonly property bool chosen: card.index === root.index

            width: 208
            height: ListView.view.height
            // The chosen one as it is, the rest smaller.
            scale: chosen ? 1 : 0.86
            radius: 14
            color: Tokens.surface
            border.width: chosen ? 2 : 1
            border.color: chosen ? Tokens.ink : Tokens.line

            Behavior on scale { NumberAnimation { duration: Tokens.animFast; easing.type: Easing.OutCubic } }

            // Rounded with the card, inside its line.
            ClippingRectangle {
                anchors.fill: parent
                anchors.margins: 3
                radius: card.radius - 3
                color: "transparent"

                Image {
                    anchors.fill: parent
                    source: "file://" + Config.wallpaperDir + "/" + card.modelData + "/" + Config.primaryOutput + ".png"
                    sourceSize.width: 416
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                }
            }

            Label {
                anchors.left: parent.left
                anchors.bottom: parent.bottom
                anchors.margins: 10
                text: Case.sentence(card.modelData.replace(/[-_]/g, " "))
                color: card.chosen ? Tokens.ink : Tokens.dim
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: root.choose(card.index)
            }
        }
    }
}
