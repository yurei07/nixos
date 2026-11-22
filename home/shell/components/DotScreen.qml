import QtQuick
import QtQuick.Effects
import qs.theme

Item {
    id: root

    property string source: ""
    property int pitch: 5
    property int radius: 14
    readonly property alias status: art.status

    clip: true

    Surface {
        anchors.fill: parent
        radius: root.radius
        color: Tokens.surface
    }

    Image {
        id: art
        anchors.fill: parent
        source: root.source
        fillMode: Image.PreserveAspectCrop
        autoTransform: true
        asynchronous: true
        visible: false
        sourceSize.width: root.width * 2
        sourceSize.height: root.height * 2
    }

    MultiEffect {
        anchors.fill: parent
        source: art
        visible: art.status === Image.Ready
        saturation: -1
        contrast: 0.25
        brightness: 0.05
        maskEnabled: true
        maskSource: mask
    }

    Canvas {
        id: mask
        anchors.fill: parent
        visible: false
        layer.enabled: true

        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            ctx.fillStyle = "white";
            const p = root.pitch;
            for (let y = p / 2; y < height; y += p)
                for (let x = p / 2; x < width; x += p) {
                    ctx.beginPath();
                    ctx.arc(x, y, p * 0.42, 0, 2 * Math.PI);
                    ctx.fill();
                }
        }
    }
}
