import QtQuick
import qs.theme

Item {
    id: root

    property var series: []         // newest last
    property var secondary: []      // optional second trace (dimmer)
    property int samples: 60
    property real floor: 512        // bytes/s mapped to the baseline
    // Whether it follows the data: each repaint is a frame of its whole window, so one nobody sees
    // (a closed drawer) waits, and catches up when it's seen again.
    property bool live: visible

    implicitHeight: 48

    readonly property real step: width / samples
    readonly property int rows: step >= 1 ? Math.min(64, Math.max(3, Math.floor(height / step))) : 0

    onSeriesChanged: if (live) trace.requestPaint()
    onSecondaryChanged: if (live) trace.requestPaint()
    onLiveChanged: if (live) trace.requestPaint()

    function level(v: real, peak: real): real {
        if (v <= root.floor) return 0;
        return Math.min(1, Math.log(v / root.floor) / Math.log(Math.max(peak, root.floor * 4) / root.floor));
    }

    // The empty grid: painted again only when the size changes.
    Canvas {
        id: grid
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const step = root.step;
            const r = Math.max(1, step * 0.28);
            ctx.fillStyle = Tokens.off;
            for (let i = 0; i < root.samples; i++)
                for (let j = 0; j < root.rows; j++) {
                    ctx.beginPath();
                    ctx.arc(i * step + step / 2, height - j * step - step / 2, r * 0.6, 0, 2 * Math.PI);
                    ctx.fill();
                }
        }
    }

    Canvas {
        id: trace
        anchors.fill: parent
        onWidthChanged: requestPaint()
        onHeightChanged: requestPaint()
        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const step = root.step;
            const rows = root.rows;
            if (rows === 0)
                return;
            const r = Math.max(1, step * 0.28);
            const peak = Math.max(root.floor * 4, ...root.series, ...root.secondary);

            const draw = (data, colour) => {
                ctx.fillStyle = colour;
                const offset = root.samples - data.length;
                for (let k = 0; k < data.length; k++) {
                    const h = Math.round(root.level(data[k], peak) * (rows - 1));
                    if (h <= 0 && data[k] <= root.floor) continue;
                    ctx.beginPath();
                    ctx.arc((offset + k) * step + step / 2, height - h * step - step / 2, r, 0, 2 * Math.PI);
                    ctx.fill();
                }
            };

            draw(root.secondary, Tokens.muted);
            draw(root.series, Tokens.ink);
        }
    }
}
