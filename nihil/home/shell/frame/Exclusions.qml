import QtQuick
import Quickshell
import Quickshell.Wayland

Scope {
    id: root

    required property ShellScreen screen
    required property int inset
    required property int edge

    component Zone: PanelWindow {
        color: "transparent"
        exclusionMode: ExclusionMode.Normal
        WlrLayershell.namespace: "nihil-exclusion"
        WlrLayershell.layer: WlrLayer.Bottom
        mask: Region {}
        implicitWidth: 1
        implicitHeight: 1
    }

    Zone {
        screen: root.screen
        anchors { left: true; top: true; bottom: true }
        implicitWidth: root.inset
        exclusiveZone: root.inset
    }

    Zone {
        screen: root.screen
        anchors { top: true; left: true; right: true }
        implicitHeight: root.edge
        exclusiveZone: root.edge
    }

    Zone {
        screen: root.screen
        anchors { right: true; top: true; bottom: true }
        implicitWidth: root.edge
        exclusiveZone: root.edge
    }

    Zone {
        screen: root.screen
        anchors { bottom: true; left: true; right: true }
        implicitHeight: root.edge
        exclusiveZone: root.edge
    }
}
