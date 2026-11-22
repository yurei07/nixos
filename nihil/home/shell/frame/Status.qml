import QtQuick
import qs.theme
import qs.config
import qs.services
import qs.components

Item {
    id: root

    required property string output

    implicitWidth: Math.max(24, batteryRow.implicitWidth)
    implicitHeight: column.implicitHeight

    Column {
        id: column
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 12

        Ico {
            anchors.horizontalCenter: parent.horizontalCenter
            glyph: Network.ethernet ? Icons.ethernet
                 : !Network.wifiEnabled ? Icons.wifiOff
                 : Network.ssid ? Icons.wifi(Network.strength)
                 : Icons.wifiLevels[0]
            color: Network.connected ? Tokens.ink : Tokens.muted
        }

        Ico {
            anchors.horizontalCenter: parent.horizontalCenter
            glyph: !Bt.enabled ? Icons.btOff : Bt.connected.length > 0 ? Icons.btConnected : Icons.btOn
            color: Bt.connected.length > 0 ? Tokens.ink : Tokens.muted
        }

        // The battery: glyph and percent, in the alert colour when it runs low. Clicking it
        // opens the panel, where NIHIL's power actions live.
        Row {
            id: batteryRow
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Battery.present
            spacing: 4

            Ico {
                anchors.verticalCenter: parent.verticalCenter
                glyph: Battery.charging ? Icons.batteryCharging : Icons.battery
                color: Battery.low ? Tokens.interrupt : Tokens.ink
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: Math.round(Battery.level * 100) + "%"
                color: Battery.low ? Tokens.interrupt : Tokens.muted
            }
        }

        Ico {
            id: speaker
            anchors.horizontalCenter: parent.horizontalCenter
            glyph: Icons.volume(Audio.volume, Audio.muted)
            color: Audio.muted ? Tokens.muted : Tokens.ink
        }
    }

    MouseArea {
        anchors.fill: parent
        anchors.margins: -6
        cursorShape: Qt.PointingHandCursor
        Accessible.role: Accessible.Button
        Accessible.name: Lang.bindPanel
        Accessible.onPressAction: Drawers.toggle("panel", root.output)
        onClicked: Drawers.toggle("panel", root.output)
        // A notch is 120: a fine wheel or a touchpad sends less, and adds up to one; a sideways
        // scroll, or a touchpad's last event, sends none, and changes nothing.
        property real wheeled: 0
        onWheel: wheel => {
            if (wheel.angleDelta.y === 0)
                return;
            wheeled += wheel.angleDelta.y;
            const notches = Math.trunc(wheeled / 120);
            if (notches === 0)
                return;
            wheeled -= notches * 120;
            const v = Math.max(0, Math.min(1, Audio.volume + notches * 0.05));
            Audio.setVolume(v);
            Osd.show("volume", v, false);
        }
    }
}
