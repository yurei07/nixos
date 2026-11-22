import QtQuick
import qs.theme

Item {
    id: root

    property int count: 10
    property real value: 0
    property bool vertical: false
    property int dot: 6
    property int gap: 3
    property color litColor: Tokens.ink
    property color unlitColor: Tokens.off
    property int head: -1

    readonly property int lit: Math.round(Math.max(0, Math.min(1, value)) * count)

    implicitWidth: vertical ? dot : count * dot + (count - 1) * gap
    implicitHeight: vertical ? count * dot + (count - 1) * gap : dot

    Repeater {
        model: root.count

        Rectangle {
            required property int index

            width: root.dot
            height: root.dot
            radius: root.dot / 2
            x: root.vertical ? 0 : index * (root.dot + root.gap)
            y: root.vertical ? (root.count - 1 - index) * (root.dot + root.gap) : 0
            color: index < root.lit || index === root.head ? root.litColor : root.unlitColor

            // While a head sweeps, it steps: no animation between steps keeping the window drawing.
            Behavior on color {
                enabled: root.head < 0
                ColorAnimation { duration: Tokens.animFast }
            }
        }
    }
}
