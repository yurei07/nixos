import QtQuick
import qs.theme

ShaderEffect {
    id: root

    property Item source: null
    property int inset: Tokens.frameThickness
    property int edge: Tokens.frameThickness
    property var bumps: []

    function slot(index) {
        const bump = root.bumps[index];
        return bump ? Qt.vector4d(bump.a, bump.b, bump.d, bump.edge) : Qt.vector4d(0, 0, 0, 0);
    }

    property var backdrop: source ? source.texture : null
    readonly property real transmission: 0.3
    readonly property real refraction: 14
    readonly property real bevel: 26
    readonly property real rim: 0.45
    readonly property real dim: source ? source.dim : 1
    readonly property real frost: 5
    readonly property real scatter: 0.4
    readonly property real halo: 2.2
    readonly property real wobble: 3
    readonly property vector2d scr: Qt.vector2d(width, height)
    readonly property vector4d ltrb: Qt.vector4d(inset, edge, edge, edge)
    readonly property vector4d shape: Qt.vector4d(Tokens.frameRadius, Tokens.fillet, Tokens.drawerRadius, 0)
    readonly property vector4d bump0: slot(0)
    readonly property vector4d bump1: slot(1)
    readonly property vector4d bump2: slot(2)
    readonly property vector4d bump3: slot(3)
    readonly property vector4d bump4: slot(4)
    readonly property vector4d bump5: slot(5)
    readonly property vector4d bump6: slot(6)
    readonly property vector4d bump7: slot(7)

    visible: source !== null && source.texture !== null
    fragmentShader: Qt.resolvedUrl("../shaders/frame.frag.qsb")
}
