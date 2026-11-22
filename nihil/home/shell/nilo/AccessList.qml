import QtQuick
import qs.config
import qs.services

Column {
    id: root

    property int current: -1
    property string asking: ""

    readonly property string repo: Nilo.settings.repo ?? "~/nixos-config"
    readonly property string level: Nilo.settings.access ?? "chat"
    readonly property var levels: ["chat", "terminal", "system"]
    readonly property var items: [
        { key: "web", level: false, title: Lang.accessWeb, guard: "" },
        { key: "chat", level: true, title: Lang.accessChat, guard: "" },
        { key: "terminal", level: true, title: Lang.accessTerminal, guard: Lang.accessTerminalGuard.arg(repo) },
        { key: "system", level: true, title: Lang.accessEverything, guard: Lang.accessEverythingGuard }
    ]
    readonly property int count: items.length

    signal grew(Item row)

    spacing: 2

    onVisibleChanged: if (!visible) asking = ""

    function chosen(item: var): bool {
        return item.level ? root.level === item.key : Nilo.settings[item.key] === true;
    }

    function toggle(index: int): void {
        const item = items[index];
        if (!item) return;
        if (!item.level) {
            Nilo.set(item.key, !chosen(item));
            asking = "";
        } else if (root.level === item.key) {
            asking = "";
        } else if (levels.indexOf(item.key) < levels.indexOf(root.level) || item.guard === "" || asking === item.key) {
            Nilo.set("access", item.key);
            asking = "";
        } else {
            asking = item.key;
        }
    }

    function authorize(): void {
        const index = items.findIndex(item => item.key === asking);
        if (index >= 0) toggle(index);
    }

    function moveBy(step: int): void {
        current = current < 0 ? 0 : Math.max(0, Math.min(count - 1, current + step));
        if (asking !== "" && items[current].key !== asking) asking = "";
    }

    function rowAt(index: int): Item {
        return rows.itemAt(index);
    }

    Repeater {
        id: rows
        model: root.items

        SwitchRow {
            id: row

            required property var modelData
            required property int index

            width: root.width
            title: modelData.title
            guard: root.asking === modelData.key ? modelData.guard : ""
            on: root.chosen(modelData)
            choice: modelData.level
            current: root.current === index

            onHeightChanged: if (asking) root.grew(row)
            onToggled: {
                root.current = row.index;
                root.toggle(row.index);
            }
            onCancelled: root.asking = ""
        }
    }
}
