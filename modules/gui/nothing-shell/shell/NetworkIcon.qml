import QtQuick

// Ethernet / wifi strength / offline glyph. Click opens the wifi popover.
Text {
    id: root

    property string screenName: ""

    text: NetworkService.icon
    color: NetworkService.connected ? Theme.text : Theme.textFaint
    font.family: Theme.fontIcon
    font.pixelSize: 14

    MouseArea {
        anchors.fill: parent
        anchors.margins: -4
        cursorShape: Qt.PointingHandCursor
        onClicked: PopupState.toggleWifiPopup(root.screenName)
    }
}
