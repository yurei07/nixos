import QtQuick
import qs.theme
import qs.services
import qs.components

Column {
    id: root

    property int current: -1

    readonly property string repo: Nilo.settings.repo ?? "~/nixos-config"
    readonly property var paths: {
        const found = Nilo.repos.slice(0, 6);
        return found.some(path => same(path, repo)) ? found : [repo].concat(found.slice(0, 5));
    }
    readonly property int count: paths.length

    spacing: 2

    function same(a: string, b: string): bool {
        return String(a ?? "").replace(/\/+$/, "") === String(b ?? "").replace(/\/+$/, "");
    }

    function choose(index: int): void {
        const path = paths[index];
        if (path && !same(path, repo)) Nilo.set("repo", path);
    }

    Repeater {
        model: root.paths

        Surface {
            id: row

            required property string modelData
            required property int index

            readonly property bool selected: root.same(modelData, root.repo)

            width: root.width
            height: 44
            radius: 14
            color: root.current === index || area.containsMouse ? Tokens.raised : "transparent"

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    root.current = row.index;
                    root.choose(row.index);
                }
            }

            Led {
                id: led
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                on: row.selected
            }

            Txt {
                id: name
                anchors.left: led.right
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                width: Math.min(implicitWidth, parent.width * 0.4)
                text: row.modelData.replace(/\/+$/, "").split("/").pop()
                color: row.selected ? Tokens.ink : Tokens.dim
                font.pixelSize: 14
            }

            Txt {
                anchors.left: name.right
                anchors.leftMargin: 16
                anchors.right: parent.right
                anchors.rightMargin: 18
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideLeft
                text: row.modelData
                color: Tokens.muted
                font.family: Tokens.fontMono
                font.pixelSize: 11
            }
        }
    }
}
