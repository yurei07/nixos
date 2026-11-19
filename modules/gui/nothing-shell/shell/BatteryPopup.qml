import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.UPower
import Quickshell.Wayland

// Battery popover under the bar: the big Ndot percentage, charge state, time
// remaining and power draw. Same open/close pattern as the wifi popover.
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
    WlrLayershell.namespace: "nothing-batterypopup"
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

    readonly property bool visibleCard: PopupState.batteryPopupOpen && PopupState.batteryPopupScreen === root.screen.name

    readonly property var device: UPower.displayDevice
    readonly property real level: {
        const p = device?.percentage ?? 0;
        return p > 1 ? p / 100 : p;
    }
    readonly property bool charging: device?.state === UPowerDeviceState.Charging
    readonly property bool discharging: device?.state === UPowerDeviceState.Discharging
    readonly property string stateText: !device?.ready ? "NO BATTERY" : charging ? "CHARGING" : discharging ? "DISCHARGING" : device?.state === UPowerDeviceState.FullyCharged ? "FULL" : "IDLE"
    readonly property string timeText: {
        if (!device?.ready)
            return "";
        const s = charging ? (device.timeToFull ?? 0) : (device.timeToEmpty ?? 0);
        if (!s || s <= 0)
            return "--:--";
        const h = Math.floor(s / 3600);
        const m = Math.floor((s % 3600) / 60);
        return (h > 0 ? h + ":" : "") + String(m).padStart(h > 0 ? 2 : 1, "0") + (h > 0 ? "" : " MIN");
    }
    readonly property real watts: device?.energyRate ?? 0

    mask: Region {
        item: root.visibleCard ? card : null
    }

    Timer {
        id: exitTimer

        interval: 250
        onTriggered: if (!card.hover.containsMouse)
            PopupState.closeBatteryPopup()
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
            spacing: Theme.gapM

            // big Ndot percentage + state
            Item {
                width: parent.width
                height: 92

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    text: Math.round(root.level * 100) + "%"
                    color: root.level <= 0.2 && !root.charging ? Theme.accent : Theme.text
                    font.family: Theme.fontDot
                    font.pixelSize: 64
                }

                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    spacing: Theme.gapXs

                    Text {
                        anchors.right: parent.right
                        text: root.stateText
                        color: root.charging ? Theme.text : Theme.textDim
                        font.family: Theme.fontLabel
                        font.pixelSize: 10
                        font.letterSpacing: Theme.labelSpacing
                    }

                    Text {
                        anchors.right: parent.right
                        visible: root.timeText !== ""
                        text: root.timeText
                        color: Theme.text
                        font.family: Theme.fontLabel
                        font.pixelSize: 14
                    }

                    Text {
                        anchors.right: parent.right
                        visible: root.watts > 0
                        text: root.watts.toFixed(1) + " W"
                        color: Theme.textDim
                        font.family: Theme.fontLabel
                        font.pixelSize: 12
                    }
                }
            }

            // charge bar
            Rectangle {
                width: parent.width
                height: 10
                radius: 5
                color: Theme.track

                Rectangle {
                    width: Math.max(6, parent.width * root.level)
                    height: parent.height
                    radius: 5
                    color: root.level <= 0.2 && !root.charging ? Theme.accent : Theme.pill

                    Behavior on width {
                        NumberAnimation {
                            duration: Theme.animMed
                            easing.type: Theme.easing
                        }
                    }
                }
            }

            Text {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                visible: root.charging
                text: Icons.glyphLights + " PLUGGED IN"
                color: Theme.textDim
                font.family: Theme.fontIcon
                font.pixelSize: 12
                topPadding: Theme.gapXs
            }
        }
    }
}
