import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import qs.config

Item {
    id: root

    property bool running: false
    property int bars: 24
    property int rows: 6
    property var levels: []

    implicitHeight: rows * 7

    Process {
        running: root.running
        command: [Config.cmd.cava, "-p", Config.cavaConfig]
        stdout: SplitParser {
            onRead: data => root.levels = data.split(";").filter(s => s !== "").map(Number)
        }
        onRunningChanged: if (!running) root.levels = []
    }

    Row {
        anchors.centerIn: parent
        spacing: (root.width - root.bars * 5) / Math.max(1, root.bars - 1)

        Repeater {
            model: root.bars

            Column {
                id: bar

                required property int index

                readonly property int level: root.levels[index] ?? 0

                spacing: 2

                Repeater {
                    model: root.rows

                    Rectangle {
                        required property int index

                        width: 5
                        height: 5
                        radius: 2.5
                        color: root.rows - index <= bar.level ? Tokens.ink : Tokens.off
                    }
                }
            }
        }
    }
}
