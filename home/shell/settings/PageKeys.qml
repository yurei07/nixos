import QtQuick
import QtQuick.Layouts
import qs.theme
import qs.config
import qs.services
import qs.components

Flickable {
    id: page

    readonly property var order: ["launcher", "dashboard", "panel", "settings", "wallpapers", "copy", "clipboard", "nilo", "colourPicker", "lock",
        "close", "float", "maximize", "fullscreen", "special", "toSpecial", "nextWorkspace", "overview", "screenshot", "snip"]
    readonly property var actions: order.filter(name => name in Config.bindDefaults && (name !== "nilo" || Config.nilo.enabled))
    readonly property var programs: Machine.get("programs", Config.programs)
    readonly property var modifiers: ["SUPER", "SHIFT", "CTRL", "ALT"]
    // The keys a bind takes, a laptop's own among them: XF86SelectiveScreenshot, the snipping key, is
    // the snip's by default.
    readonly property var keyName: /^([A-Za-z0-9]|F([1-9]|1[0-9]|2[0-4])|Return|Space|Tab|Escape|BackSpace|Delete|Insert|Home|End|Prior|Next|Page_Up|Page_Down|Left|Right|Up|Down|Menu|Pause|PRINT|Print|comma|period|slash|minus|equal|semicolon|apostrophe|grave|backslash|bracketleft|bracketright|Super_L|Super_R|XF86[A-Za-z0-9]+|KP_[A-Za-z0-9]+)$/

    property string editing: ""
    property var mods: []
    property string key: ""
    property string name: ""
    property string command: ""
    property string error: ""

    contentHeight: column.implicitHeight + 24
    clip: true
    boundsBehavior: Flickable.StopAtBounds

    function keyOf(name: string): var {
        const binds = Machine.get("binds", {});
        return name in binds ? binds[name] : Config.bindDefaults[name];
    }

    function label(name: string): string {
        return Lang["bind" + name.charAt(0).toUpperCase() + name.slice(1)] ?? name;
    }

    function normal(combo: string): string {
        return combo.split("+").map(part => part.trim().toUpperCase()).filter(part => part !== "")
            .map(part => part === "CONTROL" ? "CTRL" : part).sort().join("+");
    }

    function reserved(combo: string): bool {
        const wanted = normal(combo);
        for (let digit = 0; digit <= 9; digit++) {
            if (wanted === normal("SUPER + " + digit) || wanted === normal("SUPER + SHIFT + " + digit))
                return true;
        }
        return false;
    }

    function owner(combo: string): string {
        const wanted = normal(combo);
        // Shift with the screenshot's key, or the snip's, records: Hyprland has those already.
        for (const name of ["screenshot", "snip"]) {
            const taken = keyOf(name);
            if ("action:" + name !== page.editing && taken && normal(taken).split("+").indexOf("SHIFT") < 0
                && normal("SHIFT + " + taken) === wanted)
                return label(name);
        }
        for (let i = 0; i < page.actions.length; i++) {
            const taken = keyOf(page.actions[i]);
            if ("action:" + page.actions[i] !== page.editing && taken && normal(taken) === wanted)
                return label(page.actions[i]);
        }
        for (let i = 0; i < page.programs.length; i++) {
            const taken = page.programs[i].keys;
            if ("program:" + i !== page.editing && taken && normal(taken) === wanted)
                return page.programs[i].name;
        }
        return "";
    }

    function open(id: string, combo: var, name: string, command: string): void {
        if (page.editing === id) {
            page.editing = "";
            return;
        }
        const parts = combo ? combo.split("+").map(part => part.trim()) : [];
        const upper = part => part.toUpperCase() === "CONTROL" ? "CTRL" : part.toUpperCase();
        page.mods = parts.map(upper).filter(part => page.modifiers.indexOf(part) >= 0);
        page.key = parts.filter(part => page.modifiers.indexOf(upper(part)) < 0).join(" + ");
        page.name = name;
        page.command = command;
        page.error = "";
        page.editing = id;
    }

    function toggleMod(mod: string): void {
        page.mods = page.mods.indexOf(mod) >= 0 ? page.mods.filter(other => other !== mod) : page.mods.concat([mod]);
    }

    function combo(): var {
        const key = page.key.trim();
        if (key === "" && page.mods.length === 0)
            return null;
        if (!page.keyName.test(key)) {
            page.error = Lang.cfgKeyInvalid;
            return undefined;
        }
        if (page.mods.length === 0 && !/^(PRINT|Print|F[0-9]+|XF86[A-Za-z0-9]+)$/.test(key)) {
            page.error = Lang.cfgKeyNeedsMod;
            return undefined;
        }
        const combo = page.modifiers.filter(mod => page.mods.indexOf(mod) >= 0).concat([key]).join(" + ");
        if (reserved(combo)) {
            page.error = Lang.cfgKeyReserved;
            return undefined;
        }
        const other = owner(combo);
        if (other !== "") {
            page.error = Lang.cfgKeyTaken.arg(other);
            return undefined;
        }
        // The screenshot's key, and the snip's, record with Shift: that one has to be free too.
        if ((page.editing === "action:screenshot" || page.editing === "action:snip") && page.mods.indexOf("SHIFT") < 0) {
            const shifted = owner("SHIFT + " + combo);
            if (shifted !== "") {
                page.error = Lang.cfgKeyShiftTaken.arg(shifted);
                return undefined;
            }
        }
        return combo;
    }

    function saveAction(name: string): void {
        const chosen = combo();
        if (chosen === undefined)
            return;
        const fallback = Config.bindDefaults[name];
        const same = chosen === null ? !fallback : (fallback && normal(fallback) === normal(chosen));
        Machine.set("binds." + name, same ? undefined : chosen);
        page.editing = "";
    }

    function resetAction(name: string): void {
        Machine.set("binds." + name, undefined);
        page.editing = "";
    }

    function list(): var {
        return page.programs.map(program => ({ name: program.name, exec: program.exec, keys: program.keys ?? null }));
    }

    function saveProgram(index: int): void {
        if (page.name.trim() === "" || page.command.trim() === "") {
            page.error = Lang.cfgProgramMissing;
            return;
        }
        const chosen = combo();
        if (chosen === undefined)
            return;
        const next = list();
        next[index] = { name: page.name.trim(), exec: page.command.trim(), keys: chosen };
        Machine.set("programs", next);
        page.editing = "";
    }

    function removeProgram(index: int): void {
        Machine.set("programs", list().filter((program, i) => i !== index));
        page.editing = "";
    }

    component Combo: Column {
        spacing: 10

        Flow {
            width: parent.width
            spacing: 6

            Repeater {
                model: page.modifiers

                KeyButton {
                    required property string modelData

                    text: Case.key(modelData)
                    accent: page.mods.indexOf(modelData) >= 0
                    onClicked: page.toggleMod(modelData)
                }
            }

            Txt {
                height: 32
                text: "+"
                color: Tokens.muted
            }

            // Wide enough for its examples: comma and Space are what's written, not , or a space.
            Field {
                width: 310
                height: 32
                placeholder: Lang.cfgKeyName
                value: page.key
                invalid: page.error !== ""
                onEdited: text => {
                    page.key = text;
                    page.error = "";
                }
            }
        }

        Alert {
            visible: page.error !== ""
            text: page.error
        }
    }

    component Entry: Item {
        id: row

        property string entry: ""
        property string title: ""
        property var combo: null
        // Made only while open: the page has a row for every action and program, and each editor
        // is fields and keys, with glass of their own.
        property Component editor: null
        readonly property bool open: page.editing === entry

        signal clicked()

        Layout.fillWidth: true
        implicitHeight: 44 + (open ? holder.childrenRect.height + 14 : 0)

        Surface {
            anchors.fill: parent
            radius: 10
            color: row.open || area.containsMouse ? Tokens.surface : "transparent"
        }

        Txt {
            x: 14
            y: 12
            text: row.title
            color: row.open ? Tokens.ink : Tokens.dim
        }

        Txt {
            anchors.right: parent.right
            anchors.rightMargin: 14
            y: 12
            text: row.combo ? Case.keys(row.combo) : Lang.cfgKeyNone
            color: row.combo ? Tokens.ink : Tokens.muted
            font.family: Tokens.fontMono
            font.pixelSize: 13
        }

        MouseArea {
            id: area
            anchors.left: parent.left
            anchors.right: parent.right
            height: 44
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: row.clicked()
        }

        Item {
            id: holder
            visible: row.open
            x: 14
            y: 44
            width: parent.width - 28
            height: childrenRect.height

            Loader {
                width: parent.width
                active: row.open
                sourceComponent: row.editor
            }
        }
    }

    ColumnLayout {
        id: column
        width: page.width
        spacing: 0

        Heading {
            Layout.bottomMargin: 12
            title: Lang.cfgKeys
        }

        Label {
            Layout.bottomMargin: 6
            text: Lang.cfgSystemKeys
        }

        Repeater {
            model: page.actions

            Entry {
                required property string modelData

                entry: "action:" + modelData
                title: page.label(modelData)
                combo: page.keyOf(modelData)
                onClicked: page.open("action:" + modelData, page.keyOf(modelData), "", "")

                editor: Component {
                    Column {
                        width: parent.width
                        spacing: 10

                        Combo {
                            width: parent.width
                        }

                        Flow {
                            width: parent.width
                            spacing: 6

                            KeyButton {
                                text: Lang.cfgKeySave
                                accent: true
                                onClicked: page.saveAction(modelData)
                            }

                            KeyButton {
                                text: Lang.cfgKeyDefault
                                onClicked: page.resetAction(modelData)
                            }
                        }
                    }
                }
            }
        }

        Label {
            Layout.topMargin: 22
            Layout.bottomMargin: 6
            text: Lang.cfgPrograms
        }

        Repeater {
            model: page.programs.length + (page.editing === "program:" + page.programs.length ? 1 : 0)

            Entry {
                required property int index
                readonly property var program: index < page.programs.length ? page.programs[index] : ({ name: "", exec: "", keys: null })

                entry: "program:" + index
                title: program.name !== "" ? program.name : Lang.cfgProgramAdd
                combo: program.keys ?? null
                onClicked: page.open("program:" + index, program.keys ?? null, program.name, program.exec)

                editor: Component {
                    Column {
                        width: parent.width
                        spacing: 10

                        Flow {
                            width: parent.width
                            spacing: 8

                            Field {
                                width: 180
                                height: 32
                                placeholder: Lang.cfgProgramName
                                value: page.name
                                onEdited: text => page.name = text
                            }

                            Field {
                                width: 280
                                height: 32
                                placeholder: Lang.cfgProgramExec
                                value: page.command
                                onEdited: text => page.command = text
                            }
                        }

                        Combo {
                            width: parent.width
                        }

                        Flow {
                            width: parent.width
                            spacing: 6

                            KeyButton {
                                text: Lang.cfgKeySave
                                accent: true
                                onClicked: page.saveProgram(index)
                            }

                            KeyButton {
                                visible: index < page.programs.length
                                text: Lang.cfgKeyRemove
                                onClicked: page.removeProgram(index)
                            }
                        }
                    }
                }
            }
        }

        KeyButton {
            Layout.topMargin: 10
            visible: page.editing !== "program:" + page.programs.length
            text: "+ " + Lang.cfgProgramAdd
            onClicked: page.open("program:" + page.programs.length, null, "", "")
        }
    }
}
