import QtQuick
import qs.theme

Item {
    id: root

    property int size: 30
    readonly property real pitch: size / 7
    readonly property var face: ({
        N: ["#...#", "##..#", "##..#", "#.#.#", "#..##", "#..##", "#...#"],
        I: ["#", "#", "#", "#", "#", "#", "#"],
        H: ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
        L: ["#....", "#....", "#....", "#....", "#....", "#....", "#####"]
    })
    readonly property var columns: {
        const columns = [];
        const word = "NIHIL";
        for (let k = 0; k < word.length; k++) {
            const glyph = root.face[word[k]];
            if (k > 0)
                columns.push([false, false, false, false, false, false, false]);
            for (let x = 0; x < glyph[0].length; x++) {
                const column = [];
                for (let y = 0; y < 7; y++)
                    column.push(glyph[y][x] === "#");
                columns.push(column);
            }
        }
        return columns;
    }

    implicitWidth: columns.length * pitch
    implicitHeight: size

    Repeater {
        model: root.columns.length * 7

        Rectangle {
            required property int index
            readonly property int column: Math.floor(index / 7)
            readonly property int row: index % 7
            readonly property bool lit: root.columns[column][row]

            width: (lit ? 0.72 : 0.24) * root.pitch
            height: width
            radius: width / 2
            x: (column + 0.5) * root.pitch - width / 2
            y: (row + 0.5) * root.pitch - height / 2
            color: lit ? Tokens.ink : Tokens.off
        }
    }
}
