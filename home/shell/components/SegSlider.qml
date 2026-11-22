import QtQuick
import qs.theme
import qs.config

Item {
    id: root

    property real value: 0
    property int segments: 24
    property color litColor: Tokens.ink
    property bool muted: false
    // Its name for a screen reader.
    property string label: ""

    signal moved(real value)

    // A wheel's notch is 120; a touchpad or a fine wheel sends it in small parts, which add up
    // to the 5 % a notch moves.
    property real wheeled: 0

    function nudge(by: real): void {
        root.moved(Math.max(0, Math.min(1, root.value + by)));
    }

    implicitHeight: 14
    implicitWidth: 240
    activeFocusOnTab: true

    Accessible.role: Accessible.Slider
    Accessible.name: root.label
    Accessible.description: Lang.percent.arg(Math.round(root.value * 100))
    Accessible.onIncreaseAction: root.nudge(0.05)
    Accessible.onDecreaseAction: root.nudge(-0.05)
    Keys.onRightPressed: root.nudge(0.05)
    Keys.onUpPressed: root.nudge(0.05)
    Keys.onLeftPressed: root.nudge(-0.05)
    Keys.onDownPressed: root.nudge(-0.05)
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Home)
            root.moved(0);
        else if (event.key === Qt.Key_End)
            root.moved(1);
        else if (event.key === Qt.Key_PageUp)
            root.nudge(0.25);
        else if (event.key === Qt.Key_PageDown)
            root.nudge(-0.25);
        else
            return;
        event.accepted = true;
    }

    readonly property real segWidth: (width - (segments - 1) * 3) / segments
    readonly property int lit: Math.round(Math.max(0, Math.min(1, value)) * segments)

    // Plain segments, not glass: each its own glass would be a shader of its own, 96 in the panel's
    // four sliders, for marks a few pixels wide.
    Repeater {
        model: root.segments

        Rectangle {
            required property int index

            x: index * (root.segWidth + 3)
            width: root.segWidth
            height: root.height
            radius: 3
            color: index < root.lit ? (root.muted ? Tokens.muted : root.litColor) : Tokens.raised

            Behavior on color { ColorAnimation { duration: Tokens.animFast } }
        }
    }

    function emitAt(x: real): void {
        root.moved(Math.max(0, Math.min(1, x / width)));
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        onPressed: mouse => root.emitAt(mouse.x - 6)
        onPositionChanged: mouse => { if (pressed) root.emitAt(mouse.x - 6); }
        onWheel: wheel => {
            if (wheel.angleDelta.y === 0) {
                wheel.accepted = false;
                return;
            }
            root.wheeled += wheel.angleDelta.y;
            const notches = Math.trunc(root.wheeled / 120);
            if (notches === 0)
                return;
            root.wheeled -= notches * 120;
            root.nudge(notches * 0.05);
        }
    }

    FocusRing {
        round: 4
    }
}
