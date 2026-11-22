import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.config
import qs.services
import qs.components
import qs.nilo

Item {
    id: root

    required property string output

    readonly property real eyesY: tail.y + eyes.y + eyes.height / 2

    Column {
        anchors.top: parent.top
        anchors.topMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 22

        Ico {
            anchors.horizontalCenter: parent.horizontalCenter
            glyph: Icons.nix
            font.pixelSize: 20
            color: logo.containsMouse || Drawers.isOpen("launcher", root.output) ? Tokens.ink : Tokens.dim

            MouseArea {
                id: logo
                anchors.fill: parent
                anchors.margins: -8
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: Lang.bindLauncher
                Accessible.onPressAction: Drawers.toggle("launcher", root.output)
                onClicked: Drawers.toggle("launcher", root.output)
            }
        }

        Workspaces {
            anchors.horizontalCenter: parent.horizontalCenter
            output: root.output
        }
    }

    AppIcon {
        anchors.centerIn: parent
        size: 22
        icon: Apps.iconFor(ToplevelManager.activeToplevel?.appId ?? "")
        visible: (ToplevelManager.activeToplevel?.appId ?? "") !== ""
    }

    Column {
        id: tail
        anchors.bottom: parent.bottom
        anchors.bottomMargin: 16
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 18

        Item {
            id: eyes
            anchors.horizontalCenter: parent.horizontalCenter
            width: 24
            height: 14
            visible: Nilo.enabled && (Nilo.loaded || Nilo.loading || Nilo.busy || Nilo.peeking
                || (Nilo.pull !== null && Nilo.pull.status !== "error"))
            opacity: Nilo.roaming && (Hyprland.focusedMonitor?.name ?? "") === root.output ? 0 : 1

            Behavior on opacity { NumberAnimation { duration: Tokens.animDrawer } }

            Eyes {
                anchors.centerIn: parent
                eyeWidth: 4
                eyeHeight: 11
                gap: 5
                mood: Nilo.confirm !== null && !Nilo.shown ? "alert"
                    : Nilo.peeking && Nilo.peekScreen === root.output
                    ? (Nilo.peekKind === "error" ? "error" : "happy")
                    : Nilo.busy ? (Nilo.phase === "writing" ? "writing" : "thinking") : Nilo.loading ? "waking"
                    : Nilo.loaded ? "idle" : "asleep"
                pulse: Nilo.pulse
            }

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: Lang.bindNilo
                Accessible.onPressAction: Nilo.toggle()
                onClicked: Nilo.toggle()
            }
        }

        Tray {
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Ico {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Caffeine.on
            glyph: Icons.coffee
            color: Tokens.ink

            MouseArea {
                anchors.fill: parent
                anchors.margins: -6
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: Lang.caffeine
                Accessible.onPressAction: Caffeine.set(false)
                onClicked: Caffeine.set(false)
            }
        }

        Status {
            anchors.horizontalCenter: parent.horizontalCenter
            output: root.output
        }

        BatteryGauge {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Battery.present
        }

        BarClock {
            anchors.horizontalCenter: parent.horizontalCenter
            output: root.output
        }

        Rectangle {
            id: privacy
            anchors.horizontalCenter: parent.horizontalCenter
            width: 6
            height: 6
            radius: 3
            color: Tokens.interrupt
            visible: Audio.micInUse || Recorder.recording
            opacity: dimmed ? 0.3 : 1

            property bool dimmed: false

            // A blink, not a fade: each frame of the frame's window redraws the whole screen, and a
            // call with the microphone open lasts an hour. Two frames a second instead of sixty.
            Timer {
                interval: 900
                repeat: true
                running: privacy.visible
                onTriggered: privacy.dimmed = !privacy.dimmed
                onRunningChanged: if (!running) privacy.dimmed = false
            }
        }
    }
}
