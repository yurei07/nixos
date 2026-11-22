import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme
import qs.config
import qs.services
import qs.components

Item {
    id: root

    property bool active: false

    focus: active
    onActiveChanged: if (active) Qt.callLater(() => { if (root.active) root.forceActiveFocus(); })
    Keys.onEscapePressed: Drawers.close()
    Keys.onPressed: event => {
        const paste = (event.key === Qt.Key_V && event.modifiers & Qt.ControlModifier)
            || (event.key === Qt.Key_Insert && event.modifiers & Qt.ShiftModifier);
        if (paste && Vector.enabled) {
            Vector.send("");
            event.accepted = true;
        }
    }

    implicitHeight: layout.implicitHeight + 22 + 24

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    ColumnLayout {
        id: layout
        anchors.fill: parent
        anchors.leftMargin: 32
        anchors.rightMargin: 32
        anchors.topMargin: 22
        anchors.bottomMargin: 24
        spacing: 16

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: 232
            spacing: 26

            ColumnLayout {
                Layout.preferredWidth: 220
                Layout.fillHeight: true
                spacing: 4

                Label {
                    text: "ex nihilo"
                    font.italic: true
                }

                DotText {
                    text: Qt.formatDateTime(clock.date, "HH:mm")
                    font.pixelSize: 68
                }

                Txt {
                    Layout.fillWidth: true
                    text: Case.sentence(clock.date.toLocaleString(Qt.locale(Lang.locale), Lang.dateLong))
                    color: Tokens.dim
                    font.pixelSize: 15
                }

                Item {
                    Layout.fillHeight: true
                    visible: !Vector.enabled
                }

                VectorBox {
                    Layout.topMargin: 6
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: Vector.enabled
                }
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 1
                color: Tokens.line
            }

            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    DotScreen {
                        Layout.preferredWidth: 104
                        Layout.preferredHeight: 104
                        source: Media.art
                        pitch: 4
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Label { text: Case.sentence(Media.player) || Lang.media }

                        Txt {
                            Layout.fillWidth: true
                            text: Media.title
                            font.pixelSize: 17
                            font.weight: Font.Medium
                        }

                        Txt {
                            Layout.fillWidth: true
                            text: Media.artist
                            color: Tokens.dim
                            visible: text !== ""
                        }

                        MediaKeys {
                            Layout.topMargin: 6
                            size: 32
                        }
                    }
                }

                DotMeter {
                    Layout.fillWidth: true
                    Layout.preferredWidth: 100
                    count: Math.max(8, Math.floor((width + 3) / 7))
                    dot: 4
                    gap: 3
                    value: Media.progress
                }

                RowLayout {
                    Layout.fillWidth: true

                    Label { text: Media.shown(Media.position) }
                    Item { Layout.fillWidth: true }
                    Label { text: Media.shown(Media.length) }
                }

                Visualizer {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    running: root.active && Media.playing
                }
            }

            Rectangle {
                Layout.fillHeight: true
                implicitWidth: 1
                color: Tokens.line
            }

            ColumnLayout {
                Layout.preferredWidth: 262
                Layout.fillHeight: true
                spacing: 10

                Row {
                    spacing: 6

                    Dial { width: 82; height: 82; value: SysStats.cpu; text: String(Math.round(SysStats.cpu * 100)); label: "CPU" }
                    Dial { width: 82; height: 82; value: SysStats.mem; text: String(Math.round(SysStats.mem * 100)); label: "RAM" }
                    Dial {
                        width: 82
                        height: 82
                        value: Math.min(1, SysStats.temp / 100)
                        text: String(Math.round(SysStats.temp))
                        label: "°C"
                        alert: SysStats.temp >= 90
                    }
                }

                NetRates {}

                DotScope {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    live: root.active
                    series: SysStats.rxHistory
                    secondary: SysStats.txHistory
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 1
            color: Tokens.line
        }

        TaskBoard {
            Layout.fillWidth: true
            Layout.fillHeight: true
            active: root.active
        }
    }
}
