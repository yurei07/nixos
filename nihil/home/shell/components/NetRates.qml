import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.config
import qs.services

// The interface in use, and what comes in and goes out: the Dashboard's and the desktop's.
RowLayout {
    Layout.fillWidth: true

    Label { text: SysStats.iface || Lang.offline }
    Item { Layout.fillWidth: true }
    Label { text: "↓ " + SysStats.human(SysStats.rx); color: Tokens.dim }
    Label { text: "↑ " + SysStats.human(SysStats.tx) }
}
