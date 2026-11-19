import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Networking
import Quickshell.Wayland

// Wi-Fi popover under the bar: the radio switch and the network list, Nothing style.
// Closes when the pointer leaves the card and the popover, or on the chip again.
PanelWindow {
    id: root

    screen: modelData
    anchors.top: true
    anchors.right: true
    exclusionMode: ExclusionMode.Ignore
    margins.top: Config.barMarginTop + Config.barHeight + 8
    margins.right: Theme.gapL
    implicitWidth: 420
    implicitHeight: card.height + 2 * Theme.gapM
    color: "transparent"
    WlrLayershell.namespace: "nothing-wifipopup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    readonly property bool visibleCard: PopupState.wifiPopupOpen && PopupState.wifiPopupScreen === root.screen.name

    // click-through entirely when closed; card closes when the pointer leaves it
    mask: Region {
        item: root.visibleCard ? card : null
    }

    Timer {
        id: exitTimer

        interval: 250
        onTriggered: if (!card.hover.containsMouse)
            PopupState.closeWifiPopup()
    }

    Rectangle {
        id: card

        x: parent.width - width - Theme.gapL
        width: parent.width - 2 * Theme.gapL
        height: column.implicitHeight + 2 * Theme.gapM
        radius: Theme.radiusCard
        color: Theme.glass
        border.width: Theme.hairline
        border.color: Theme.outline
        opacity: root.visibleCard ? 1 : 0
        visible: opacity > 0

        property alias hover: cardHover

        HoverHandler {
            id: cardHover

            onHoveredChanged: {
                if (hovered)
                    exitTimer.stop();
                else
                    exitTimer.restart();
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.animFast
            }
        }

        Column {
            id: column

            anchors.centerIn: parent
            width: parent.width - 2 * Theme.gapM
            spacing: Theme.gapS

            // header: WI-FI + radio switch
            Rectangle {
                width: parent.width
                height: 42
                radius: Theme.radiusSmall
                color: Networking.wifiEnabled ? Theme.pill : Theme.surface
                border.width: Theme.hairline
                border.color: Theme.outline

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.animFast
                    }
                }

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: Theme.gapM
                    spacing: Theme.gapS

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Icons.wifi(1)
                        color: Networking.wifiEnabled ? Theme.pillText : Theme.text
                        font.family: Theme.fontIcon
                        font.pixelSize: 15
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: "Wi-Fi"
                        color: Networking.wifiEnabled ? Theme.pillText : Theme.text
                        font.family: Theme.fontLabel
                        font.pixelSize: 13
                        font.weight: Font.Medium
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Networking.wifiEnabled ? "ON" : "OFF"
                        color: Networking.wifiEnabled ? Theme.pillText : Theme.textFaint
                        font.family: Theme.fontLabel
                        font.pixelSize: 9
                        font.letterSpacing: Theme.labelSpacing
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: NetworkService.toggleWifi()
                }
            }

            Repeater {
                model: ScriptModel {
                    values: {
                        const wifi = NetworkService.wifi;
                        if (!wifi)
                            return [];
                        return wifi.networks.values
                            .slice()
                            .sort((a, b) => (b.connected - a.connected) || (b.signalStrength - a.signalStrength))
                            .slice(0, 8);
                    }
                }

                delegate: Rectangle {
                    id: row

                    required property var modelData

                    width: parent.width
                    height: 38
                    radius: Theme.radiusSmall
                    color: rowArea.containsMouse ? Theme.surfaceHi : Theme.surface

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.animFast
                        }
                    }

                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: Theme.gapM
                        spacing: Theme.gapS

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: Icons.wifi(modelData.signalStrength > 1 ? modelData.signalStrength / 100 : modelData.signalStrength)
                            color: Theme.textDim
                            font.family: Theme.fontIcon
                            font.pixelSize: 13
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            width: row.width - 90
                            elide: Text.ElideRight
                            text: modelData.name || "(hidden network)"
                            color: Theme.text
                            font.family: Theme.fontLabel
                            font.pixelSize: 12
                        }
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: Theme.gapM
                        text: modelData.connected ? Icons.check : ""
                        color: Theme.text
                        font.family: Theme.fontIcon
                        font.pixelSize: 13
                    }

                    MouseArea {
                        id: rowArea

                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            if (!modelData.connected) {
                                try {
                                    modelData.connect();
                                } catch (e) {}
                            }
                        }
                    }
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                visible: NetworkService.wifi === null
                text: "NO ADAPTER"
                color: Theme.textFaint
                font.family: Theme.fontLabel
                font.pixelSize: 10
                font.letterSpacing: Theme.labelSpacing
                topPadding: Theme.gapS
                bottomPadding: Theme.gapS
            }
        }
    }
}
