import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.services
import qs.components

Scope {
    PanelWindow {
        id: win

        readonly property var target: {
            const screens = Quickshell.screens;
            for (let i = 0; i < screens.length; i++) {
                if (screens[i].name === Machine.screen)
                    return screens[i];
            }
            return screens.length > 0 ? screens[0] : null;
        }

        visible: Machine.shown && target !== null
        screen: target
        color: "transparent"
        anchors {
            top: true
            bottom: true
            left: true
            right: true
        }
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "nihil-settings"
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand

        HyprlandFocusGrab {
            windows: [win]
            active: win.visible
            onCleared: Machine.hide()
        }

        // The welcome has its own way back (WelcomeView), and can't be hidden.
        Shortcut {
            sequence: "Escape"
            enabled: !Machine.welcoming
            onActivated: Machine.hide()
        }

        Rectangle {
            anchors.fill: parent
            color: Tokens.black
            opacity: 0.7

            MouseArea {
                anchors.fill: parent
                onClicked: Machine.hide()
            }
        }

        Item {
            anchors.fill: parent

            property Item glassBackdrop: Machine.glass ? backdrop.item : null

            Loader {
                id: backdrop
                // Only while it's shown: with windows: true it captures every window, and speeds up
                // Glass's timer for all, as long as it exists.
                active: Machine.glass && win.visible && win.target !== null
                sourceComponent: Backdrop {
                    output: win.target.name
                    screenSize: Qt.vector2d(win.width, win.height)
                    dim: 0.3
                    windows: true
                }
            }

            Surface {
                anchors.centerIn: parent
                width: Math.min(1060, parent.width - 120)
                height: Math.min(720, parent.height - 120)
                pane: true
                radius: Tokens.drawerRadius
                color: Tokens.black
                border.width: 1
                border.color: Tokens.line

                MouseArea {
                    anchors.fill: parent
                }

                // Hidden, Preferences keeps nothing: a password typed and left, or a pairing still
                // open, goes with it.
                Loader {
                    anchors.fill: parent
                    active: win.visible
                    focus: true
                    sourceComponent: Machine.welcoming ? welcome : preferences
                }
            }
        }

        Component {
            id: preferences

            SettingsView {}
        }

        Component {
            id: welcome

            WelcomeView {}
        }
    }
}
