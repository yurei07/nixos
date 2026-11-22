import QtQuick
import QtQuick.Effects
import Quickshell
import Quickshell.Widgets
import qs.theme

Item {
    id: root

    property string icon: ""
    property bool colored: false
    property int size: 32

    implicitWidth: size
    implicitHeight: size

    function resolve(name: string): string {
        if (!name) return Quickshell.iconPath("application-x-executable", true);
        if (name.startsWith("/")) return "file://" + name;
        if (name.indexOf("://") > 0) return name;
        return Quickshell.iconPath(name, true) || Quickshell.iconPath("application-x-executable", true);
    }

    // In grey through an effect; in colour as it is, with no layer, but while it turns.
    property real saturation: root.colored ? 0 : -1

    Behavior on saturation { NumberAnimation { id: fade; duration: Tokens.animNormal } }

    IconImage {
        anchors.fill: parent
        source: root.resolve(root.icon)
        asynchronous: true

        layer.enabled: !root.colored || fade.running
        layer.effect: MultiEffect {
            saturation: root.saturation
            brightness: root.colored ? 0 : -0.05
        }
    }
}
