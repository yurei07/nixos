import QtQuick
import QtQuick.Layouts
import Quickshell
import qs.theme
import qs.config
import qs.services
import qs.components

Flickable {
    id: page

    readonly property bool wanted: Machine.get("deck.enable", false)

    contentHeight: column.implicitHeight + 24
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    Component.onCompleted: Deck.refresh()
    Component.onDestruction: Deck.cancel()

    ColumnLayout {
        id: column
        width: page.width
        spacing: 14

        Heading {
            title: Lang.cfgDevices
        }

        Setting {
            title: Lang.deckUse

            Toggle {
                on: page.wanted
                onToggled: Machine.set("deck.enable", !on, false)
            }
        }

        // Away from any network: the computer announces itself over Bluetooth LE while the deck runs.
        Setting {
            visible: page.wanted
            title: Lang.deckBluetooth

            Toggle {
                on: Machine.get("deck.bluetooth", true)
                onToggled: Machine.set("deck.bluetooth", !on, false)
            }
        }

        Alert {
            Layout.fillWidth: true
            visible: Deck.enabled && Deck.loaded && !Deck.running
            text: Lang.deckDown
        }

        Setting {
            visible: Deck.enabled && Deck.running
            title: Lang.deckWatchTitle

            KeyButton {
                text: Lang.deckWatchInstall
                onClicked: Apps.run([Config.cmd.terminal, "--hold", "--title", Lang.deckWatchTitle, Config.cmd.watch])
            }
        }

        Setting {
            visible: Deck.enabled && Deck.running
            title: Lang.deckPairTitle

            Column {
                spacing: 14

                KeyButton {
                    visible: !Deck.pairing
                    accent: true
                    text: Lang.deckPair
                    onClicked: Deck.pair()
                }

                Alert {
                    visible: Deck.pairFailed && !Deck.pairing
                    text: Lang.deckPairFailed
                }

                Repeater {
                    model: Deck.asking

                    Column {
                        required property var modelData

                        spacing: 8

                        Label {
                            text: Lang.deckAsking.arg(modelData.name)
                        }

                        Row {
                            spacing: 8

                            KeyButton {
                                accent: true
                                text: Lang.deckAllow
                                onClicked: Deck.allow(modelData.id, true)
                            }

                            KeyButton {
                                text: Lang.deckDeny
                                onClicked: Deck.allow(modelData.id, false)
                            }
                        }
                    }
                }

                QrCode {
                    visible: Deck.pairing && Deck.asking.length === 0
                    rows: Deck.rows
                }

                KeyButton {
                    visible: Deck.pairing
                    text: Lang.cfgCancel
                    onClicked: Deck.cancel()
                }
            }
        }

        Label {
            visible: Deck.enabled && Deck.running
            Layout.topMargin: 8
            text: Deck.devices.length > 0 ? Lang.deckDevices : Lang.deckNone
        }

        Repeater {
            model: Deck.enabled && Deck.running ? Deck.devices : []

            Item {
                id: device

                required property var modelData

                Layout.fillWidth: true
                implicitHeight: 44

                Surface {
                    anchors.fill: parent
                    radius: 10
                    color: area.hovered ? Tokens.surface : "transparent"
                }

                HoverHandler {
                    id: area
                }

                Txt {
                    x: 14
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - x - seen.width - forget.width - (air.visible ? air.width + 8 : 0) - 48
                    text: device.modelData.name
                }

                // It came last over Bluetooth, with no network in common.
                Ico {
                    id: air
                    visible: device.modelData.bluetooth === true
                    anchors.right: seen.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    glyph: Icons.btConnected
                    font.pixelSize: 13
                    color: Tokens.muted
                }

                // When it was last seen; in its last month unused, the day the deck forgets it.
                Label {
                    id: seen
                    readonly property real expires: device.modelData.expires ?? 0
                    anchors.right: forget.left
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    text: expires > 0 && expires - Date.now() / 1000 < 30 * 86400 ? Lang.deckForgetsOn.arg(Dates.day(expires))
                                                                                  : Dates.moment(device.modelData.seen ?? 0)
                    font.pixelSize: 12
                }

                KeyButton {
                    id: forget
                    anchors.right: parent.right
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    text: Lang.deckForget
                    onClicked: Deck.forget(device.modelData.id)
                }
            }
        }
    }
}
