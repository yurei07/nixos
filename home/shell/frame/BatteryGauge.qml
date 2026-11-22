import QtQuick
import qs.theme
import qs.services
import qs.components

Item {
    id: root

    property int scan: -1

    implicitWidth: 18
    implicitHeight: meter.implicitHeight + 6 + percent.implicitHeight

    DotMeter {
        id: meter
        anchors.horizontalCenter: parent.horizontalCenter
        vertical: true
        count: 10
        dot: 5
        gap: 3
        value: Battery.level
        litColor: Battery.low ? Tokens.interrupt : Tokens.ink
        head: root.scan
    }

    Label {
        id: percent
        anchors.top: meter.bottom
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        text: String(Math.round(Battery.level * 100))
        color: Battery.low ? Tokens.ink : Tokens.muted
    }

    // The charging sweep, a step every half second, and only where the bar is shown: each step is a
    // frame of the whole screen.
    Timer {
        running: root.visible && Battery.charging && !Battery.full
        interval: 500
        repeat: true
        onTriggered: root.scan = root.scan >= 9 ? meter.lit : root.scan + 1
        onRunningChanged: if (!running) root.scan = -1
    }
}
