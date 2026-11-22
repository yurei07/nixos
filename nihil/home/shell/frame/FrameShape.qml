import QtQuick
import QtQuick.Shapes
import qs.theme
import "Geometry.js" as Geometry

Shape {
    id: root

    property int inset: Tokens.frameThickness
    property int edge: Tokens.frameThickness
    property var bumps: []

    readonly property string inner: Geometry.outline(width, height, inset, edge, edge, edge,
        Tokens.frameRadius, Tokens.fillet, Tokens.drawerRadius, bumps, 0)

    preferredRendererType: Shape.CurveRenderer

    ShapePath {
        fillColor: Tokens.black
        strokeColor: "transparent"
        fillRule: ShapePath.OddEvenFill

        PathSvg {
            path: `M0 0 L${root.width} 0 L${root.width} ${root.height} L0 ${root.height} Z ${root.inner}`
        }
    }

    ShapePath {
        fillColor: "transparent"
        strokeColor: Tokens.line
        strokeWidth: 1

        PathSvg { path: root.inner }
    }
}
