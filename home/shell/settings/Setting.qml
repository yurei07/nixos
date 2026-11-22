import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.components

Item {
    id: root

    property string title: ""
    property string sub: ""
    default property alias control: holder.data

    readonly property real nameWidth: 200

    Layout.fillWidth: true
    implicitHeight: Math.max(name.y + name.implicitHeight, values.y + values.implicitHeight) + 14

    FontMetrics {
        id: line
        font: name.font
    }

    Txt {
        id: name
        width: root.nameWidth
        y: values.y + Math.max(0, (holder.height - line.height) / 2)
        text: root.title
        wrapMode: Text.WordWrap
        elide: Text.ElideNone
        font.pixelSize: 14
    }

    Column {
        id: values
        x: root.nameWidth + 24
        y: 14
        width: root.width - x
        spacing: 6

        Item {
            id: holder
            width: childrenRect.width
            height: childrenRect.height
        }

        Txt {
            visible: root.sub !== ""
            width: parent.width
            text: root.sub
            color: Tokens.muted
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: Tokens.line
        opacity: 0.6
    }
}
