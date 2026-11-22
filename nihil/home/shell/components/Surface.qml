import QtQuick
import qs.theme

Item {
    id: root

    property color color: "transparent"
    property real radius: 0
    property alias border: plain.border
    property bool pane: false

    readonly property Item backdrop: {
        for (let item = root.parent; item; item = item.parent) {
            if (item.glassBackdrop !== undefined)
                return item.glassBackdrop;
        }
        return null;
    }
    readonly property bool glassy: backdrop !== null && backdrop.texture !== null

    Rectangle {
        id: plain

        anchors.fill: parent
        visible: !root.glassy
        color: root.color
        radius: root.radius
    }

    ShaderEffect {
        anchors.fill: parent
        visible: root.glassy && (root.color.a > 0.01 || plain.border.width > 0)

        property var backdrop: root.glassy ? root.backdrop.texture : null
        readonly property real ySign: GraphicsInfo.api === GraphicsInfo.Vulkan ? 1 : -1
        readonly property real radius: Math.min(root.radius, width / 2, height / 2)
        readonly property real transmission: root.pane ? 0.3 : 0.38
        readonly property real refraction: root.pane ? 14 : Math.min(6, 2 + radius / 3)
        readonly property real bevel: root.pane ? 26 : Math.min(14, 4 + radius)
        readonly property real rim: root.pane ? 0.45 : 0.32
        readonly property real outline: root.color.a <= 0.01 && plain.border.width > 0 ? 1 : 0
        readonly property real dim: root.glassy ? root.backdrop.dim : 1
        readonly property real frost: root.pane ? 5 : 6
        readonly property real scatter: root.pane ? 0.4 : 0.25
        readonly property real halo: root.pane ? 2.2 : 0.9
        readonly property real wobble: root.pane ? 3 : 1.5
        readonly property vector2d box: Qt.vector2d(width, height)
        readonly property vector2d win: Qt.vector2d(Window.width, Window.height)
        readonly property vector2d org: root.glassy ? root.backdrop.origin : Qt.vector2d(0, 0)
        readonly property vector2d scr: root.glassy ? root.backdrop.screenSize : Qt.vector2d(1, 1)
        readonly property vector4d tint: Qt.vector4d(root.color.r, root.color.g, root.color.b, root.color.a)

        vertexShader: Qt.resolvedUrl("../shaders/surface.vert.qsb")
        fragmentShader: Qt.resolvedUrl("../shaders/surface.frag.qsb")
    }

    Rectangle {
        anchors.fill: parent
        visible: root.glassy && plain.border.width > 0 && !Qt.colorEqual(plain.border.color, Tokens.line)
        color: "transparent"
        radius: root.radius
        border.width: plain.border.width
        border.color: plain.border.color
    }
}
