import QtQuick
import qs.theme
import qs.components

Item {
    id: root

    property string title: ""
    property string sub: ""
    default property alias control: holder.data

    implicitHeight: Math.max(56, words.implicitHeight + 24, holder.height + 24)

    Column {
        id: words
        anchors.left: parent.left
        anchors.leftMargin: 16
        anchors.right: holder.left
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Txt {
            width: parent.width
            text: root.title
            color: Tokens.dim
            font.pixelSize: 15
        }

        Txt {
            width: parent.width
            visible: text !== ""
            text: root.sub
            color: Tokens.muted
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            font.pixelSize: 12
        }
    }

    Item {
        id: holder
        anchors.right: parent.right
        anchors.rightMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        width: childrenRect.width
        height: childrenRect.height
    }
}
