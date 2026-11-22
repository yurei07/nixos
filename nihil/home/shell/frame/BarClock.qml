import QtQuick
import Quickshell
import qs.theme
import qs.config
import qs.services
import qs.components

Item {
    id: root

    required property string output

    implicitWidth: 36
    implicitHeight: column.implicitHeight

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    Column {
        id: column
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: -6

        DotText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "HH")
            font.pixelSize: 20
        }

        DotText {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Qt.formatDateTime(clock.date, "mm")
            font.pixelSize: 20
            color: Tokens.dim
        }
    }

    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: Lang.bindDashboard
        Accessible.onPressAction: Drawers.toggle("dashboard", root.output)
        onClicked: Drawers.toggle("dashboard", root.output)
    }
}
