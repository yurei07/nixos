import QtQuick
import qs.theme

Item {
    id: root

    property real value: 0          // 0..1
    property string text: ""
    property string label: ""
    property int dots: 28
    property bool alert: false

    implicitWidth: 92
    implicitHeight: 92

    readonly property real radius: Math.min(width, height) / 2 - 4
    readonly property int lit: Math.round(Math.max(0, Math.min(1, value)) * dots)

    Repeater {
        model: root.dots

        Rectangle {
            required property int index

            readonly property real angle: (135 + index * 270 / (root.dots - 1)) * Math.PI / 180

            width: 4
            height: 4
            radius: 2
            x: root.width / 2 + root.radius * Math.cos(angle) - 2
            y: root.height / 2 + root.radius * Math.sin(angle) - 2
            color: index < root.lit ? (root.alert ? Tokens.interrupt : Tokens.ink) : Tokens.off

            Behavior on color { ColorAnimation { duration: Tokens.animNormal } }
        }
    }

    DotText {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -4
        text: root.text
        font.pixelSize: 22
    }

    Label {
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 2
        text: root.label
    }
}
