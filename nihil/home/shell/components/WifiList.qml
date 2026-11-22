import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.config
import qs.services

// The Wi-Fi networks around, to join one: the panel's list and the welcome's.
ColumnLayout {
    id: root

    property int limit: 10
    property bool active: true

    readonly property var live: active ? Network.networks.slice(0, limit) : []
    // While a password is asked for, the rows hold still: a scan would make every one anew, and
    // the field with them, losing what was typed and the focus.
    property var rows: []

    function follow(): void {
        if (Network.askPassword === "" || !active)
            rows = live;
    }

    spacing: 4
    onLiveChanged: follow()
    Component.onCompleted: follow()

    Connections {
        target: Network

        function onAskPasswordChanged(): void {
            root.follow();
        }
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.leftMargin: 12
        visible: !Network.wifiEnabled

        Txt {
            Layout.fillWidth: true
            text: Lang.wifiOff
            color: Tokens.dim
        }

        KeyButton {
            text: Lang.wifiTurnOn
            onClicked: Network.setWifi(true)
        }
    }

    Repeater {
        model: root.rows

        ColumnLayout {
            id: net

            required property var modelData
            readonly property bool asking: Network.askPassword === modelData.ssid

            Layout.fillWidth: true
            spacing: 4

            ListRow {
                glyph: Icons.wifi(net.modelData.signal)
                title: net.modelData.ssid
                detailGlyph: net.modelData.active ? Icons.check : (net.modelData.secure ? Icons.lock : "")
                detailName: net.modelData.active ? Lang.wifiConnected : (net.modelData.secure ? Lang.wifiLocked : "")
                current: net.modelData.active === true
                busy: Network.pending === net.modelData.ssid
                onClicked: net.modelData.active ? Network.disconnect() : Network.connect(net.modelData, "")
            }

            Field {
                Layout.fillWidth: true
                visible: net.asking
                password: true
                catchEscape: true
                placeholder: Lang.password
                onVisibleChanged: {
                    if (visible) {
                        clear();
                        grab();
                    }
                }
                Component.onCompleted: {
                    if (visible)
                        grab();
                }
                onAccepted: Network.connect(net.modelData, text)
                onEscaped: Network.askPassword = ""
            }
        }
    }

    Alert {
        Layout.fillWidth: true
        visible: Network.error !== ""
        text: Network.error
    }
}
