import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import qs.theme
import qs.config
import qs.components

Column {
    id: root

    spacing: 10
    visible: items.count > 0

    function hidden(item): bool {
        const name = `${item.id} ${item.title}`.toLowerCase();
        return Config.trayHidden.some(pattern => name.indexOf(pattern.toLowerCase()) >= 0);
    }

    Repeater {
        id: items

        model: SystemTray.items.values.filter(item => !root.hidden(item))

        Item {
            id: entry

            required property SystemTrayItem modelData

            width: 18
            height: 18

            AppIcon {
                anchors.centerIn: parent
                size: 14
                icon: entry.modelData.icon
                colored: area.containsMouse
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                cursorShape: Qt.PointingHandCursor
                Accessible.role: Accessible.Button
                Accessible.name: entry.modelData.tooltipTitle || entry.modelData.title || entry.modelData.id
                Accessible.onPressAction: entry.modelData.activate()
                onClicked: mouse => {
                    if (mouse.button === Qt.LeftButton && !entry.modelData.onlyMenu) {
                        entry.modelData.activate();
                    } else if (entry.modelData.hasMenu) {
                        const p = entry.mapToItem(null, entry.width + 10, 0);
                        entry.modelData.display(QsWindow.window, p.x, p.y);
                    }
                }
            }
        }
    }
}
