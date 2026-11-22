import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Bluetooth
import qs.theme
import qs.config
import qs.services
import qs.components

Item {
    id: root

    property bool active: false
    property string expanded: ""
    property string armed: ""
    readonly property string armedName: ({ logout: Lang.actLogout, reboot: Lang.actReboot, power: Lang.actPowerOff })[armed] ?? ""

    focus: active
    Keys.onEscapePressed: Drawers.close()

    // A field that hides keeps the focus in Qt, and Escape with it: it goes back to the panel.
    onExpandedChanged: if (active && expanded !== "update") forceActiveFocus()

    Connections {
        target: Network

        function onAskPasswordChanged(): void {
            if (root.active && Network.askPassword === "")
                root.forceActiveFocus();
        }
    }

    Component.onDestruction: Network.watching(root, false)

    onActiveChanged: {
        Network.watching(root, active);
        if (active) {
            Qt.callLater(() => { if (root.active) root.forceActiveFocus(); });
            Brightness.refresh();
        } else {
            expanded = "";
            armed = "";
            Network.askPassword = "";
            Bt.scan(false);
        }
    }

    function toggleSection(name: string): void {
        expanded = expanded === name ? "" : name;
        if (expanded === "wifi") Network.scan();
        if (expanded === "update") {
            Updates.maybeCheck();
            Qt.callLater(() => updatePassword.grab());
        }
        Bt.scan(expanded === "bt");
    }

    function update(): void {
        if (updatePassword.text === "" && !Machine.fingerprint) {
            updatePassword.grab();
            return;
        }
        Machine.update(updatePassword.text);
        updatePassword.clear();
    }

    function session(name: string, command: var): void {
        if (armed === name) {
            armed = "";
            Drawers.close();
            Quickshell.execDetached(command);
        } else {
            armed = name;
            disarm.restart();
        }
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = ""
    }

    component SliderRow: RowLayout {
        id: row

        property string glyph: ""
        property real value: 0
        property bool muted: false
        property string label: ""
        // What the glyph does when clicked; none, and it does nothing.
        property string glyphLabel: ""

        signal moved(real value)
        signal glyphClicked()

        spacing: 12

        Ico {
            Layout.preferredWidth: 22
            glyph: row.glyph
            color: row.muted ? Tokens.interrupt : Tokens.dim

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                enabled: row.glyphLabel !== ""
                cursorShape: Qt.PointingHandCursor
                onClicked: row.glyphClicked()

                Accessible.role: Accessible.Button
                Accessible.name: row.glyphLabel
                Accessible.onPressAction: row.glyphClicked()
            }
        }

        SegSlider {
            Layout.fillWidth: true
            label: row.label
            value: row.value
            muted: row.muted
            onMoved: v => row.moved(v)
        }

        Label {
            Layout.preferredWidth: 30
            horizontalAlignment: Text.AlignRight
            text: String(Math.round(row.value * 100))
        }
    }

    Flickable {
        anchors.fill: parent
        anchors.topMargin: 22
        anchors.bottomMargin: 22
        anchors.leftMargin: 26
        anchors.rightMargin: 22
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: column
            width: parent.width
            spacing: 18

            RowLayout {
                Layout.fillWidth: true

                Label { text: Lang.panel }
                Item { Layout.fillWidth: true }
                Label { text: Network.ssid || Network.ethernet || Lang.offline }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 3
                rowSpacing: 6
                columnSpacing: 0

                Tile {
                    Layout.alignment: Qt.AlignHCenter
                    glyph: Network.wifiEnabled ? Icons.wifiOn : Icons.wifiOff
                    label: Lang.tileWifi
                    active: Network.wifiEnabled
                    expandable: true
                    expanded: root.expanded === "wifi"
                    onToggled: Network.setWifi(!Network.wifiEnabled)
                    onExpand: root.toggleSection("wifi")
                }

                Tile {
                    Layout.alignment: Qt.AlignHCenter
                    glyph: Bt.enabled ? Icons.btOn : Icons.btOff
                    label: Lang.tileBluetooth
                    active: Bt.enabled
                    expandable: true
                    expanded: root.expanded === "bt"
                    onToggled: Bt.setEnabled(!Bt.enabled)
                    onExpand: root.toggleSection("bt")
                }

                Tile {
                    Layout.alignment: Qt.AlignHCenter
                    glyph: Icons.speaker
                    label: Lang.tileOutput
                    active: !Audio.muted
                    expandable: true
                    expanded: root.expanded === "audio"
                    onToggled: Audio.toggleMute()
                    onExpand: root.toggleSection("audio")
                }

                Tile {
                    Layout.alignment: Qt.AlignHCenter
                    glyph: Audio.micMuted ? Icons.micOff : Icons.mic
                    label: Lang.tileMic
                    active: !Audio.micMuted
                    onToggled: Audio.toggleMic()
                }

                Tile {
                    Layout.alignment: Qt.AlignHCenter
                    glyph: Notifs.dnd ? Icons.bellOff : Icons.bell
                    label: Lang.tileDnd
                    active: Notifs.dnd
                    onToggled: Notifs.dnd = !Notifs.dnd
                }

                Tile {
                    Layout.alignment: Qt.AlignHCenter
                    glyph: Icons.night
                    label: Lang.tileNight
                    active: Toggles.night
                    expandable: true
                    expanded: root.expanded === "night"
                    onToggled: Toggles.night = !Toggles.night
                    onExpand: root.toggleSection("night")
                }

                Tile {
                    Layout.alignment: Qt.AlignHCenter
                    glyph: Icons.coffee
                    label: Lang.caffeine
                    active: Caffeine.on
                    onToggled: Caffeine.toggle()
                }

                Tile {
                    Layout.alignment: Qt.AlignHCenter
                    glyph: Icons.shot
                    label: Lang.tileShot
                    onToggled: { Drawers.close(); Recorder.shot(); }
                }

                Tile {
                    Layout.alignment: Qt.AlignHCenter
                    glyph: Recorder.recording ? Icons.stop : Icons.record
                    label: Lang.tileRecord
                    active: Recorder.recording
                    onToggled: { Drawers.close(); Recorder.toggle(); }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 14

                SliderRow {
                    Layout.fillWidth: true
                    glyph: Icons.volume(Audio.volume, Audio.muted)
                    label: Lang.settingVolume
                    glyphLabel: Audio.muted ? Lang.unmute : Lang.mute
                    value: Audio.volume
                    muted: Audio.muted
                    onMoved: v => Audio.setVolume(v)
                    onGlyphClicked: Audio.toggleMute()
                }

                SliderRow {
                    Layout.fillWidth: true
                    glyph: Audio.micMuted ? Icons.micOff : Icons.mic
                    label: Lang.tileMic
                    glyphLabel: Audio.micMuted ? Lang.unmute : Lang.mute
                    value: Audio.micVolume
                    muted: Audio.micMuted
                    onMoved: v => Audio.setMicVolume(v)
                    onGlyphClicked: Audio.toggleMic()
                }

                SliderRow {
                    Layout.fillWidth: true
                    visible: Brightness.available
                    glyph: Icons.brightness
                    label: Lang.settingBrightness
                    value: Brightness.value
                    onMoved: v => Brightness.set(v)
                }
            }

            SliderRow {
                Layout.fillWidth: true
                visible: root.expanded === "night"
                glyph: Icons.night
                label: Lang.actNight
                glyphLabel: Lang.actNight
                value: Toggles.nightLevel
                onMoved: v => Toggles.setNightLevel(v)
                onGlyphClicked: Toggles.night = !Toggles.night
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.expanded === "wifi"
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true

                    Label { text: Network.scanning ? Lang.scanning : Lang.networks }
                    Item { Layout.fillWidth: true }
                    CircleButton { glyph: Icons.refresh; label: Lang.scan; size: 28; onClicked: Network.rescan() }
                    CircleButton { glyph: Icons.cog; label: Lang.moreSettings; size: 28; onClicked: { Drawers.close(); Network.editor(); } }
                }

                WifiList {
                    Layout.fillWidth: true
                    limit: 12
                    active: root.expanded === "wifi"
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.expanded === "bt"
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true

                    Label { text: Bt.discovering ? Lang.scanning : Lang.devices }
                    Item { Layout.fillWidth: true }
                    CircleButton { glyph: Icons.refresh; label: Bt.discovering ? Lang.scanStop : Lang.scan; size: 28; onClicked: Bt.scan(!Bt.discovering) }
                    CircleButton { glyph: Icons.cog; label: Lang.moreSettings; size: 28; onClicked: { Drawers.close(); Apps.run([Config.cmd.blueman]); } }
                }

                Repeater {
                    model: root.expanded === "bt" ? Bt.devices.slice(0, 10) : []

                    ListRow {
                        required property var modelData

                        glyph: modelData.connected ? Icons.btConnected : Icons.btOn
                        title: modelData.name || modelData.address
                        detail: modelData.batteryAvailable ? Lang.percent.arg(Math.round(modelData.battery * 100)) : (modelData.paired ? "" : Lang.newDevice)
                        current: modelData.connected
                        busy: modelData.state === BluetoothDeviceState.Connecting || modelData.state === BluetoothDeviceState.Disconnecting
                        onClicked: Bt.toggleDevice(modelData)
                    }
                }

                Label {
                    visible: Bt.devices.length === 0
                    text: Bt.enabled ? Lang.noDevices : Lang.btOff
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                visible: root.expanded === "audio"
                spacing: 4

                RowLayout {
                    Layout.fillWidth: true

                    Label { text: Lang.audioOutput }
                    Item { Layout.fillWidth: true }
                    CircleButton { glyph: Icons.cog; label: Lang.moreSettings; size: 28; onClicked: { Drawers.close(); Apps.run([Config.cmd.pavucontrol]); } }
                }

                Repeater {
                    model: root.expanded === "audio" ? Audio.sinks : []

                    ListRow {
                        required property var modelData

                        glyph: /headphone|headset|bluez/i.test(modelData.name) ? Icons.headphones : Icons.speaker
                        title: modelData.description || modelData.nickname || modelData.name
                        current: Audio.sink === modelData
                        onClicked: Audio.setDefaultSink(modelData)
                    }
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                RowLayout {
                    Layout.fillWidth: true

                    Label { text: Lang.notifications.arg(Notifs.history.length) }
                    Item { Layout.fillWidth: true }
                    CircleButton { glyph: Icons.broom; label: Lang.clear; size: 28; visible: Notifs.history.length > 0; onClicked: Notifs.clear() }
                }

                Repeater {
                    model: Notifs.history.slice(0, 6)

                    NotifCard {
                        required property var modelData

                        Layout.fillWidth: true
                        notification: modelData
                    }
                }

                Label {
                    visible: Notifs.history.length === 0
                    text: Notifs.dnd ? Lang.dndOn : Lang.nothingNew
                }
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 8

                Rectangle {
                    Layout.fillWidth: true
                    implicitHeight: 1
                    color: Tokens.line
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    CircleButton { glyph: Icons.lock; label: Lang.actLock; onClicked: { Drawers.close(); Quickshell.execDetached([Config.cmd.lock]); } }
                    CircleButton { glyph: Icons.sleep; label: Lang.actSuspend; onClicked: { Drawers.close(); Quickshell.execDetached([Config.cmd.systemctl, "suspend"]); } }
                    CircleButton { glyph: Icons.logout; label: Lang.actLogout; filled: root.armed === "logout"; onClicked: root.session("logout", [Config.cmd.uwsm, "stop"]) }
                    CircleButton { glyph: Icons.restart; label: Lang.actReboot; filled: root.armed === "reboot"; onClicked: root.session("reboot", [Config.cmd.systemctl, "reboot"]) }
                    CircleButton { glyph: Icons.power; label: Lang.actPowerOff; danger: true; filled: root.armed === "power"; onClicked: root.session("power", [Config.cmd.powerOff]) }

                    Item { Layout.fillWidth: true }

                    CircleButton {
                        id: updateButton
                        glyph: Icons.download
                        label: Lang.updUpdate
                        filled: root.expanded === "update"
                        onClicked: root.toggleSection("update")

                        Rectangle {
                            visible: Updates.state === "behind" && !updateButton.filled
                            anchors.top: parent.top
                            anchors.right: parent.right
                            width: 9
                            height: 9
                            radius: 4.5
                            color: Tokens.ink
                            border.width: 2
                            border.color: Tokens.black
                        }
                    }

                    CircleButton {
                        glyph: Icons.cog
                        label: Lang.bindSettings
                        onClicked: {
                            Drawers.close();
                            Machine.show("", false);
                        }
                    }
                }

                Alert {
                    Layout.fillWidth: true
                    text: root.armed !== "" ? Lang.confirmTo.arg(root.armedName.toLowerCase()) : Updates.summary
                    wrong: root.armed !== ""
                    opacity: root.armed !== "" || updateButton.hovered ? 1 : 0
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    visible: root.expanded === "update" || Machine.updating
                    spacing: 6

                    Txt {
                        Layout.fillWidth: true
                        visible: Updates.dev !== ""
                        text: Lang.updDev
                        color: Tokens.muted
                        wrapMode: Text.Wrap
                        elide: Text.ElideNone
                        font.pixelSize: 12
                    }

                    Repeater {
                        model: Updates.state === "behind" ? Updates.commits.slice(0, 6) : []

                        RowLayout {
                            id: commit

                            required property var modelData

                            Layout.fillWidth: true
                            spacing: 10

                            Label { text: commit.modelData.sha }

                            Txt {
                                Layout.fillWidth: true
                                text: commit.modelData.subject
                                color: Tokens.dim
                                font.pixelSize: 12
                            }
                        }
                    }

                    Label {
                        visible: Updates.state === "behind" && Updates.behind > 6
                        text: Lang.updMore.arg(Updates.behind - 6)
                    }

                    Alert {
                        Layout.fillWidth: true
                        visible: Machine.kind === "update" && Machine.phase !== ""
                        text: Machine.statusTitle
                        wrong: Machine.phase === "failed"
                        color: Tokens.ink
                        font.family: Tokens.fontSans
                        font.pixelSize: 13
                    }

                    Label {
                        Layout.fillWidth: true
                        visible: Machine.kind === "update" && Machine.phase !== "" && text !== ""
                        text: Machine.statusSub
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        visible: !Machine.busy || (Machine.kind === "update" && Machine.phase === "auth" && Machine.auth === "finger")
                        spacing: 8

                        Field {
                            id: updatePassword
                            Layout.fillWidth: true
                            password: true
                            catchEscape: true
                            placeholder: Lang.cfgApplyPassword
                            onAccepted: root.update()
                            onEscaped: root.expanded = ""
                        }

                        KeyButton {
                            accent: true
                            text: Lang.updUpdate
                            onClicked: root.update()
                        }
                    }
                }
            }
        }
    }
}
