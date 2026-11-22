import QtQuick
import qs.theme

Rectangle {
    id: root

    property var rows: []
    property real size: 288
    readonly property int count: rows.length
    readonly property int quiet: 4

    readonly property var centres: [[], [], [6, 18], [6, 22], [6, 26], [6, 30], [6, 34], [6, 22, 38], [6, 24, 42],
        [6, 26, 46], [6, 28, 50], [6, 30, 54], [6, 32, 58], [6, 34, 62], [6, 26, 46, 66]]

    implicitWidth: size
    implicitHeight: size
    radius: 14
    color: Tokens.ink

    onRowsChanged: dots.requestPaint()

    Canvas {
        id: dots
        anchors.fill: parent

        onPaint: {
            const ctx = getContext("2d");
            ctx.reset();
            const n = root.count;
            if (n === 0)
                return;
            const module = width / (n + 2 * root.quiet);
            const origin = root.quiet * module;
            const version = (n - 17) / 4;

            const whole = [[0, 0, 7], [n - 7, 0, 7], [0, n - 7, 7]];
            const places = version < root.centres.length ? root.centres[version] : [];
            for (const cx of places) {
                for (const cy of places) {
                    const onCorner = (cx < 9 && cy < 9) || (cx > n - 9 && cy < 9) || (cx < 9 && cy > n - 9);
                    if (!onCorner)
                        whole.push([cx - 2, cy - 2, 5]);
                }
            }
            const inWhole = (x, y) => whole.some(([wx, wy, side]) => x >= wx && x < wx + side && y >= wy && y < wy + side);

            ctx.fillStyle = Tokens.black;
            for (let y = 0; y < n; y++) {
                const row = root.rows[y];
                for (let x = 0; x < n; x++) {
                    if (row.charAt(x) !== "1" || inWhole(x, y))
                        continue;
                    ctx.beginPath();
                    ctx.arc(origin + (x + 0.5) * module, origin + (y + 0.5) * module, module * 0.43, 0, 2 * Math.PI);
                    ctx.fill();
                }
            }

            const square = (x, y, side, colour) => {
                ctx.fillStyle = colour;
                ctx.beginPath();
                const corner = Math.min(side / 2, 1.2) * module;
                ctx.roundedRect(origin + x * module, origin + y * module, side * module, side * module, corner, corner);
                ctx.fill();
            };
            for (const [x, y, side] of whole) {
                square(x, y, side, Tokens.black);
                square(x + 1, y + 1, side - 2, Tokens.ink);
                square(x + 2, y + 2, side - 4, Tokens.black);
            }
        }
    }
}
