import QtQuick
import Quickshell
import Quickshell.Hyprland
import qs.theme
import qs.services

Item {
    id: root

    required property string output
    property bool suppressed: false

    readonly property bool shown: !suppressed && Notifs.popups.length > 0
                                  && (Hyprland.focusedMonitor?.name ?? output) === output

    width: shown ? 380 : 0
    height: shown ? column.implicitHeight : 0

    Column {
        id: column
        width: 380
        spacing: 10

        Repeater {
            model: root.shown ? Notifs.popups : []

            NotifCard {
                required property var modelData

                width: 380
                notification: modelData
                popup: true
            }
        }
    }
}
