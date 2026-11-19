import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Widgets

// System tile: CPU load and memory in use, big numerals and tracked bars, same
// layout language as the screen time tile. Data from the SystemStats singleton.
Rectangle {
    id: root

    readonly property real cpu: SystemStats.cpu
    readonly property real memFrac: SystemStats.memFrac
    readonly property string memText: (SystemStats.memUsed / (1024 * 1024 * 1024)).toFixed(1) + " / " + (SystemStats.memTotal / (1024 * 1024 * 1024)).toFixed(0) + " GB"

    implicitWidth: 400
    implicitHeight: 150
    radius: Theme.radiusWidget
    color: Theme.widget

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 18
        spacing: 0

        RowLayout {
            Layout.fillWidth: true

            Text {
                Layout.fillWidth: true
                text: "SYSTEM"
                color: Theme.textDim
                font.family: Theme.fontLabel
                font.pixelSize: 9
                font.letterSpacing: Theme.labelSpacing
            }
            Text {
                text: "LIVE"
                color: Theme.textFaint
                font.family: Theme.fontLabel
                font.pixelSize: 9
                font.letterSpacing: Theme.labelSpacing
            }
        }

        // CPU row
        RowLayout {
            Layout.topMargin: 2
            Layout.fillWidth: true

            Text {
                text: Icons.cpu
                color: root.cpu > 0.9 ? Theme.accent : Theme.textDim
                font.family: Theme.fontIcon
                font.pixelSize: 16
            }

            Text {
                text: Math.round(root.cpu * 100) + "%"
                color: root.cpu > 0.9 ? Theme.accent : Theme.text
                font.family: Theme.fontSans
                font.pixelSize: 26
                font.variableAxes: ({ "wght": 700, "opsz": 32 })
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: "CPU"
                color: Theme.textFaint
                font.family: Theme.fontLabel
                font.pixelSize: 9
                font.letterSpacing: Theme.labelSpacing
            }
        }

        ClippingRectangle {
            Layout.fillWidth: true
            Layout.topMargin: 4
            implicitHeight: 6
            radius: 3
            color: Theme.track

            Rectangle {
                width: Math.max(4, parent.width * root.cpu)
                height: parent.height
                radius: 3
                color: root.cpu > 0.9 ? Theme.accent : Theme.pill

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.animMed
                        easing.type: Theme.easing
                    }
                }
            }
        }

        // Memory row
        RowLayout {
            Layout.topMargin: 10
            Layout.fillWidth: true

            Text {
                text: Icons.memory
                color: root.memFrac > 0.9 ? Theme.accent : Theme.textDim
                font.family: Theme.fontIcon
                font.pixelSize: 16
            }

            Text {
                text: Math.round(root.memFrac * 100) + "%"
                color: root.memFrac > 0.9 ? Theme.accent : Theme.text
                font.family: Theme.fontSans
                font.pixelSize: 26
                font.variableAxes: ({ "wght": 700, "opsz": 32 })
            }

            Text {
                Layout.fillWidth: true
                horizontalAlignment: Text.AlignRight
                text: root.memText
                color: Theme.textFaint
                font.family: Theme.fontLabel
                font.pixelSize: 9
                font.letterSpacing: Theme.labelSpacing
            }
        }

        ClippingRectangle {
            Layout.fillWidth: true
            Layout.topMargin: 4
            implicitHeight: 6
            radius: 3
            color: Theme.track

            Rectangle {
                width: Math.max(4, parent.width * root.memFrac)
                height: parent.height
                radius: 3
                color: root.memFrac > 0.9 ? Theme.accent : Theme.text

                Behavior on width {
                    NumberAnimation {
                        duration: Theme.animMed
                        easing.type: Theme.easing
                    }
                }
            }
        }
    }
}
