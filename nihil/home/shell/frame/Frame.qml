import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland
import qs.theme
import qs.config
import qs.services
import qs.components
import qs.drawers
import qs.nilo

Scope {
    id: root

    required property ShellScreen modelData

    readonly property string output: modelData.name
    // The screens named for it; with none of them connected (a closed laptop on a dock that names
    // its ports another way), the first one, rather than no bar anywhere.
    readonly property bool anyBar: Quickshell.screens.some(s => Config.barOutputs.indexOf(s.name) >= 0)
    readonly property bool hasBar: Config.barOutputs.indexOf(output) >= 0
        || (!anyBar && Quickshell.screens.indexOf(modelData) === 0)
    readonly property int inset: hasBar ? Tokens.barWidth : Tokens.frameThickness
    readonly property int edge: Tokens.frameThickness

    // A screen unplugged with a drawer open takes it along: left as it was, the other screens'
    // hot edges, which wait for no drawer to be open, and Nilo's peek would stay shut.
    Component.onDestruction: if (Drawers.screen === root.output) Drawers.close()

    Exclusions {
        screen: root.modelData
        inset: root.inset
        edge: root.edge
    }

    PanelWindow {
        id: win

        screen: root.modelData
        color: "transparent"
        anchors { top: true; bottom: true; left: true; right: true }
        exclusionMode: ExclusionMode.Ignore

        WlrLayershell.layer: WlrLayer.Top
        WlrLayershell.namespace: "nihil-frame"
        // OnDemand, not Exclusive: Hyprland drops every focus grab when a layer turns exclusive.
        // A drawer the pointer opened, launcher included, takes no keys: with the pointer left at
        // an edge, what's typed into a window would go to it. A click on it, or its keys, do.
        WlrLayershell.keyboardFocus: clipKeys ? WlrKeyboardFocus.Exclusive
            : ((launcherOpen || panelOpen || dashOpen) && !Drawers.byHover) || wallOpen || ovOpen
            ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

        Loader {
            active: win.clipKeys
            source: "ClipboardKeys.qml"
            onLoaded: item.window = win
        }

        IdleInhibitor {
            window: win
            enabled: Caffeine.on
        }

        readonly property bool dashOpen: Drawers.isOpen("dashboard", root.output)
        readonly property bool panelOpen: Drawers.isOpen("panel", root.output)
        readonly property bool launcherOpen: Drawers.isOpen("launcher", root.output)
        readonly property bool wallOpen: Drawers.isOpen("wallpapers", root.output)
        readonly property bool clipOpen: Drawers.isOpen("clipboard", root.output)
        readonly property bool ovOpen: Drawers.isOpen("overview", root.output)
        readonly property bool clipKeys: clipOpen && Clipboard.keyboard
        readonly property bool osdOpen: Osd.shown && Osd.screen === root.output && !panelOpen

        property real dashP: dashOpen ? 1 : 0
        property real panelP: panelOpen ? 1 : 0
        property real launcherP: launcherOpen ? 1 : 0
        property real wallP: wallOpen ? 1 : 0
        property real clipP: clipOpen ? 1 : 0
        property real ovP: ovOpen ? 1 : 0
        property real osdP: osdOpen ? 1 : 0

        Behavior on dashP { NumberAnimation { duration: Tokens.animDrawer; easing.type: Easing.OutCubic } }
        Behavior on panelP { NumberAnimation { duration: Tokens.animDrawer; easing.type: Easing.OutCubic } }
        Behavior on launcherP { NumberAnimation { duration: Tokens.animDrawer; easing.type: Easing.OutCubic } }
        Behavior on wallP { NumberAnimation { duration: Tokens.animDrawer; easing.type: Easing.OutCubic } }
        Behavior on clipP { NumberAnimation { duration: Tokens.animDrawer; easing.type: Easing.OutCubic } }
        Behavior on ovP { NumberAnimation { duration: Tokens.animDrawer; easing.type: Easing.OutCubic } }
        Behavior on osdP { NumberAnimation { duration: Tokens.animNormal; easing.type: Easing.OutCubic } }

        function reveal(p: real): real { return Math.max(0, (p - 0.55) / 0.45); }

        readonly property real innerW: width - root.inset - root.edge
        readonly property real centerX: root.inset + innerW / 2

        readonly property real dashW: Math.min(980, innerW - 120)
        property real dashD: Math.min(dashboard.implicitHeight, height - 2 * root.edge - 96)
        Behavior on dashD { NumberAnimation { duration: Tokens.animNormal; easing.type: Easing.OutCubic } }
        readonly property real panelL: Math.min(height - 2 * root.edge - 96, 860)
        readonly property real panelD: 400
        readonly property real launcherW: Math.min(860, innerW - 120)
        property real launcherD: launcher.niloMode ? Math.min(680, height - 2 * root.edge - 140) : 470
        Behavior on launcherD { NumberAnimation { duration: Tokens.animDrawer; easing.type: Easing.OutCubic } }
        readonly property real wallW: Math.min(innerW - 120, Math.max(460, Config.wallpapers.length * 222 + 34))
        readonly property real wallD: 214
        readonly property real clipW: Math.min(680, innerW - 120)
        property real clipD: Math.min(clipboard.implicitHeight, height - 2 * root.edge - 96)
        Behavior on clipD { NumberAnimation { duration: Tokens.animNormal; easing.type: Easing.OutCubic } }
        readonly property real ovW: Math.min(innerW - 120, overview.implicitWidth)
        readonly property real ovD: overview.implicitHeight
        readonly property real osdL: 300
        readonly property real osdD: 64

        readonly property bool peekOpen: root.hasBar && Nilo.peeking && Nilo.peekScreen === root.output
            && Drawers.current === ""
        property real peekP: peekOpen ? 1 : 0
        Behavior on peekP { NumberAnimation { duration: Tokens.animDrawer; easing.type: Easing.OutCubic } }
        readonly property real peekD: 400
        readonly property real peekL: Math.min(peek.implicitHeight, height - 2 * root.edge - 2 * (Tokens.frameRadius + Tokens.fillet))
        readonly property real peekA: Math.max(root.edge + Tokens.frameRadius + Tokens.fillet,
            Math.min(barHit.eyesY - peekL / 2, height - root.edge - Tokens.frameRadius - Tokens.fillet - peekL))

        readonly property var bumps: [
            { edge: 0, a: centerX - dashW / 2, b: centerX + dashW / 2, d: dashD * dashP },
            { edge: 0, a: centerX - clipW / 2, b: centerX + clipW / 2, d: clipD * clipP },
            { edge: 0, a: centerX - ovW / 2, b: centerX + ovW / 2, d: ovD * ovP },
            { edge: 1, a: root.edge, b: root.edge + panelL, d: panelD * panelP },
            { edge: 1, a: height / 2 - osdL / 2, b: height / 2 + osdL / 2, d: panelP > 0 ? 0 : osdD * osdP },
            { edge: 2, a: centerX - launcherW / 2, b: centerX + launcherW / 2, d: launcherD * launcherP },
            { edge: 2, a: centerX - wallW / 2, b: centerX + wallW / 2, d: wallD * wallP },
            { edge: 3, a: peekA, b: peekA + peekL, d: peekD * peekP }
        ]

        mask: Region {
            regions: [
                Region { item: barHit },
                Region { item: hotZone },
                Region { item: cornerZone },
                Region { item: bottomZone },
                Region { item: dashHit },
                Region { item: panelHit },
                Region { item: launcherHit },
                Region { item: wallHit },
                Region { item: clipHit },
                Region { item: ovHit },
                Region { item: peekHit },
                Region { item: wander.hit },
                Region { item: popups }
            ]
        }

        HyprlandFocusGrab {
            windows: [win]
            active: ((win.launcherOpen || win.panelOpen || win.dashOpen) && !Drawers.byHover) || win.wallOpen || win.ovOpen
            onCleared: {
                if (Drawers.current !== "clipboard")
                    Drawers.close();
            }
        }

        Item {
            id: scene
            anchors.fill: parent

            property Item glassBackdrop: Machine.glass ? backdrop.item : null

            Loader {
                id: backdrop
                active: Machine.glass
                sourceComponent: Backdrop {
                    id: behind
                    output: root.output
                    screenSize: Qt.vector2d(win.width, win.height)
                    dim: 1 - 0.5 * win.launcherP
                    windows: win.bumps.some(bump => bump.d > 0.5) || popups.shown
                        || Glass.underFrame(behind.monitor, root.inset, root.edge, win.width, win.height)
                }
            }

            Rectangle {
                anchors.fill: parent
                color: Tokens.black
                opacity: 0.5 * win.launcherP
                visible: opacity > 0
            }

            MouseArea {
                id: launcherHit
                width: win.launcherOpen ? parent.width : 0
                height: win.launcherOpen ? parent.height : 0
                onClicked: Drawers.close()
            }

            FrameShape {
                anchors.fill: parent
                visible: !glassFrame.visible
                inset: root.inset
                edge: root.edge
                bumps: win.bumps
            }

            FrameGlass {
                id: glassFrame
                anchors.fill: parent
                source: scene.glassBackdrop
                inset: root.inset
                edge: root.edge
                bumps: win.bumps
            }

            GlyphLight {
                anchors.fill: parent
                inset: root.inset
                edge: root.edge
            }

            Bar {
                id: barHit
                visible: root.hasBar
                x: 0
                y: 0
                width: root.hasBar ? root.inset : 0
                height: parent.height
                output: root.output
            }

            MouseArea {
                id: hotZone
                x: win.centerX - win.dashW / 2
                y: 0
                width: win.dashW
                height: Drawers.current === "" || (win.dashOpen && Drawers.byHover) ? root.edge + 3 : 0
                hoverEnabled: true
                onContainsMouseChanged: containsMouse ? hoverOpen.restart() : hoverClose.restart()
            }

            DropArea {
                id: hotDrop
                anchors.fill: hotZone
                enabled: Vector.enabled
                onEntered: if (Drawers.current === "") Drawers.open("dashboard", root.output, true)
                onExited: dragClose.restart()
            }

            Item {
                id: dashHit
                x: win.centerX - win.dashW / 2
                y: 0
                width: win.dashP > 0 ? win.dashW : 0
                height: root.edge + win.dashD * win.dashP

                HoverHandler {
                    id: dashHover
                    onHoveredChanged: if (!hovered) hoverClose.restart()
                }

                DropArea {
                    id: dashDrop
                    anchors.fill: parent
                    enabled: Vector.enabled && win.dashOpen
                    onExited: dragClose.restart()
                }

                Item {
                    y: root.edge
                    width: parent.width
                    height: win.dashD * win.dashP
                    clip: true

                    Dashboard {
                        id: dashboard
                        width: win.dashW
                        height: win.dashD
                        anchors.bottom: parent.bottom
                        active: win.dashOpen
                        opacity: win.reveal(win.dashP)
                        // Closed, a drawer is out of Tab's way: what's typed can't land in a field nobody sees.
                        visible: win.dashOpen || win.dashP > 0
                        enabled: win.dashOpen
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: win.dashOpen && Drawers.byHover
                    onPressed: mouse => {
                        Drawers.byHover = false;
                        mouse.accepted = false;
                    }
                }
            }

            Item {
                id: clipHit
                x: win.centerX - win.clipW / 2
                y: 0
                width: win.clipP > 0 ? win.clipW : 0
                height: root.edge + win.clipD * win.clipP

                Item {
                    y: root.edge
                    width: parent.width
                    height: win.clipD * win.clipP
                    clip: true

                    ClipboardView {
                        id: clipboard
                        width: win.clipW
                        height: win.clipD
                        anchors.bottom: parent.bottom
                        active: win.clipKeys
                        opacity: win.reveal(win.clipP)
                    }
                }
            }

            Item {
                id: ovHit
                x: win.centerX - win.ovW / 2
                y: 0
                width: win.ovP > 0 ? win.ovW : 0
                height: root.edge + win.ovD * win.ovP

                Item {
                    y: root.edge
                    width: parent.width
                    height: win.ovD * win.ovP
                    clip: true

                    Overview {
                        id: overview
                        output: root.output
                        width: win.ovW
                        height: win.ovD
                        anchors.bottom: parent.bottom
                        active: win.ovOpen
                        opacity: win.reveal(win.ovP)
                    }
                }
            }

            Timer {
                id: hoverOpen
                interval: 160
                onTriggered: {
                    if (hotZone.containsMouse && Drawers.current === "")
                        Drawers.open("dashboard", root.output, true);
                }
            }

            Timer {
                id: dragClose
                interval: 450
                onTriggered: {
                    if (Drawers.byHover && win.dashOpen && !hotDrop.containsDrag && !dashDrop.containsDrag && !Vector.dropping
                            && !hotZone.containsMouse && !dashHover.hovered)
                        Drawers.close();
                }
            }

            Connections {
                target: Vector

                function onDroppingChanged(): void {
                    if (!Vector.dropping)
                        dragClose.restart();
                }
            }

            Timer {
                id: hoverClose
                interval: 420
                onTriggered: {
                    if (!Drawers.byHover)
                        return;
                    if ((win.dashOpen && !hotZone.containsMouse && !dashHover.hovered)
                            || (win.panelOpen && !cornerZone.containsMouse && !panelHover.hovered)
                            || (win.launcherOpen && !bottomZone.containsMouse && !launcherHover.hovered))
                        Drawers.close();
                }
            }

            MouseArea {
                id: cornerZone
                x: win.width - width
                y: 0
                width: 14
                height: Drawers.current === "" ? 14 : 0
                hoverEnabled: true
                onContainsMouseChanged: containsMouse ? cornerOpen.restart() : hoverClose.restart()
            }

            Timer {
                id: cornerOpen
                interval: 400
                onTriggered: {
                    if (cornerZone.containsMouse && Drawers.current === "")
                        Drawers.open("panel", root.output, true);
                }
            }

            Item {
                id: panelHit
                x: win.width - root.edge - win.panelD * win.panelP
                y: 0
                width: win.panelP > 0 ? win.panelD * win.panelP + root.edge : 0
                height: root.edge + win.panelL
                clip: true

                HoverHandler {
                    id: panelHover
                    onHoveredChanged: if (!hovered) hoverClose.restart()
                }

                Panel {
                    y: root.edge
                    width: win.panelD
                    height: win.panelL
                    active: win.panelOpen
                    opacity: win.reveal(win.panelP)
                    visible: win.panelOpen || win.panelP > 0
                    enabled: win.panelOpen
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: win.panelOpen && Drawers.byHover
                    onPressed: mouse => {
                        Drawers.byHover = false;
                        mouse.accepted = false;
                    }
                }
            }

            Item {
                x: win.width - root.edge - win.osdD * win.osdP
                y: win.height / 2 - win.osdL / 2
                width: win.osdD * win.osdP
                height: win.osdL
                clip: true
                visible: win.osdP > 0 && win.panelP === 0

                OsdView {
                    width: win.osdD
                    height: win.osdL
                    opacity: win.reveal(win.osdP)
                }
            }

            Item {
                x: win.centerX - win.launcherW / 2
                y: win.height - root.edge - win.launcherD * win.launcherP
                width: win.launcherW
                height: win.launcherD * win.launcherP
                clip: true

                HoverHandler {
                    id: launcherHover
                    onHoveredChanged: if (!hovered) hoverClose.restart()
                }

                Launcher {
                    id: launcher
                    width: win.launcherW
                    height: win.launcherD
                    active: win.launcherOpen
                    opacity: win.reveal(win.launcherP)
                    visible: win.launcherOpen || win.launcherP > 0
                    enabled: win.launcherOpen
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: win.launcherOpen && Drawers.byHover
                    onPressed: mouse => {
                        Drawers.byHover = false;
                        mouse.accepted = false;
                    }
                }
            }

            Item {
                id: wallHit
                x: win.centerX - win.wallW / 2
                y: win.height - root.edge - win.wallD * win.wallP
                width: win.wallP > 0 ? win.wallW : 0
                height: win.wallD * win.wallP
                clip: true

                WallpaperPicker {
                    width: win.wallW
                    height: win.wallD
                    active: win.wallOpen
                    opacity: win.reveal(win.wallP)
                    visible: win.wallOpen || win.wallP > 0
                    enabled: win.wallOpen
                }
            }

            MouseArea {
                id: bottomZone
                x: win.centerX - win.launcherW / 2
                y: win.height - height
                width: win.launcherW
                height: Drawers.current === "" || (win.launcherOpen && Drawers.byHover) ? root.edge + 3 : 0
                hoverEnabled: true
                onContainsMouseChanged: containsMouse ? bottomOpen.restart() : hoverClose.restart()
            }

            Timer {
                id: bottomOpen
                interval: 350
                onTriggered: {
                    if (bottomZone.containsMouse && Drawers.current === "")
                        Drawers.open("launcher", root.output, true);
                }
            }

            Item {
                id: peekHit
                x: root.inset
                y: win.peekA
                width: win.peekP > 0 ? win.peekD * win.peekP : 0
                height: win.peekL
                clip: true

                Peek {
                    id: peek
                    shown: win.peekOpen
                    anchors.right: parent.right
                    width: win.peekD
                    height: win.peekL
                    opacity: win.reveal(win.peekP)
                }
            }

            Popups {
                id: popups
                anchors.top: parent.top
                anchors.right: parent.right
                anchors.topMargin: root.edge + 14
                anchors.rightMargin: root.edge + 14
                output: root.output
                suppressed: win.panelP > 0
            }

            Wander {
                id: wander
                output: root.output
                inset: root.inset
                edge: root.edge
                homeX: root.hasBar ? root.inset / 2 : root.edge + 40
                homeY: root.hasBar ? barHit.eyesY : root.edge + 40
            }
        }
    }
}
