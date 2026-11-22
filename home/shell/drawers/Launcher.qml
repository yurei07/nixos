import QtQuick
import QtQuick.Controls as QQC
import Quickshell
import Quickshell.Io
import qs.theme
import qs.config
import qs.services
import qs.components
import qs.nilo

Item {
    id: root

    property bool active: false
    property string query: ""
    property string armed: ""
    property string result: ""

    readonly property string mode: query.startsWith("?") ? "nilo" : query.startsWith(">") ? "actions"
        : query.startsWith("=") ? "calc" : "apps"
    readonly property string term: mode === "apps" ? query : query.slice(1).trim()
    readonly property bool niloMode: mode === "nilo"

    property real niloP: niloMode ? 1 : 0
    Behavior on niloP { NumberAnimation { duration: Tokens.animDrawer; easing.type: Easing.OutCubic } }

    readonly property var apps: mode === "apps" ? Apps.search(term) : []

    readonly property var allActions: [
        { id: "lock", name: Lang.actLock, hint: Lang.hintSession, keys: "lock", glyph: Icons.lock, command: [Config.cmd.lock] },
        { id: "suspend", name: Lang.actSuspend, hint: Lang.hintSystem, keys: "sleep suspend", glyph: Icons.sleep, command: [Config.cmd.systemctl, "suspend"] },
        { id: "reboot", name: Lang.actReboot, hint: Lang.hintSystem, keys: "reboot restart", glyph: Icons.restart, command: [Config.cmd.systemctl, "reboot"], confirm: true },
        { id: "power", name: Lang.actPowerOff, hint: Lang.hintSystem, keys: "power off shutdown", glyph: Icons.power, command: [Config.cmd.powerOff], confirm: true, danger: true },
        { id: "logout", name: Lang.actLogout, hint: Lang.hintSession, keys: "logout exit", glyph: Icons.logout, command: [Config.cmd.uwsm, "stop"], confirm: true },
        { id: "next", name: Lang.actNextWallpaper, hint: Lang.hintWallpaper, keys: "wallpaper next", glyph: Icons.image, command: [Config.cmd.wallpaper, "next"] },
        { id: "prev", name: Lang.actPrevWallpaper, hint: Lang.hintWallpaper, keys: "wallpaper previous", glyph: Icons.image, command: [Config.cmd.wallpaper, "prev"] },
        { id: "wallpapers", name: Lang.bindWallpapers, hint: Lang.hintWallpaper, keys: "wallpaper choose pick", glyph: Icons.image },
        { id: "dnd", name: Lang.actDnd, hint: Notifs.dnd ? Lang.hintOn : Lang.hintOff, keys: "dnd silent", glyph: Notifs.dnd ? Icons.bellOff : Icons.bell },
        { id: "night", name: Lang.actNight, hint: Toggles.night ? Lang.hintOn : Lang.hintOff, keys: "night light", glyph: Icons.night },
        { id: "caffeine", name: Lang.actCaffeine, hint: Caffeine.on ? Lang.hintOn : Lang.hintOff, keys: "caffeine cafeina coffee awake screen", glyph: Icons.coffee },
        { id: "settings", name: Lang.bindSettings, hint: Lang.hintSystem, keys: "settings preferences ajustes preferencias configuracion", glyph: Icons.cog },
        { id: "terminal", name: Lang.actTerminal, hint: Case.sentence(Config.cmd.terminal.split("/").pop()), glyph: Icons.terminal, command: [Config.cmd.terminal] }
    ]

    readonly property var actions: mode !== "actions" ? [] : allActions.filter(a =>
        !term || `${a.name} ${a.hint} ${a.keys ?? ""}`.toLowerCase().indexOf(term.toLowerCase()) >= 0)

    onActiveChanged: {
        if (active) {
            input.text = Nilo.summon ? "?" : "";
            Nilo.summon = false;
            armed = "";
            result = "";
            grid.currentIndex = 0;
            list.currentIndex = 0;
            Qt.callLater(() => { if (root.active) input.forceActiveFocus(); });
        } else {
            // Nothing armed or typed waits in a closed launcher.
            armed = "";
            input.text = "";
        }
        syncNilo();
    }

    function modifierOnly(key: int): bool {
        return [Qt.Key_Shift, Qt.Key_Control, Qt.Key_Meta, Qt.Key_Alt, Qt.Key_AltGr, Qt.Key_Super_L, Qt.Key_Super_R,
                Qt.Key_Hyper_L, Qt.Key_Hyper_R, Qt.Key_CapsLock, Qt.Key_NumLock].indexOf(key) >= 0;
    }

    function syncNilo(): void {
        if (active || Nilo.shown) Nilo.shown = active && niloMode;
        if (active && niloMode) Nilo.start();
    }

    onNiloModeChanged: syncNilo()

    Connections {
        target: Nilo
        function onSummoned() {
            if (!root.active) return;
            root.syncNilo();
            if (!root.niloMode) input.text = "?";
            input.forceActiveFocus();
        }
    }

    onQueryChanged: {
        armed = "";
        grid.currentIndex = 0;
        list.currentIndex = 0;
        // A result belongs to its sum: none until the new one is worked out.
        result = "";
        if (query.startsWith("=")) calcDelay.restart();
        if (query.startsWith("?") && query.slice(1).trim() !== "") Nilo.warm();
    }

    function launch(entry): void {
        Drawers.close();
        Apps.launch(entry);
    }

    function runAction(action): void {
        if (!action) return;
        if (action.confirm && armed !== action.id) {
            armed = action.id;
            disarm.restart();
            return;
        }
        if (action.id === "wallpapers") {
            Drawers.open("wallpapers", "", false);
            return;
        }
        Drawers.close();
        if (action.id === "dnd") Notifs.dnd = !Notifs.dnd;
        else if (action.id === "night") Toggles.night = !Toggles.night;
        else if (action.id === "caffeine") Caffeine.toggle();
        else if (action.id === "settings") Machine.show("", false);
        else if (action.id === "terminal") Apps.run(action.command);
        else Quickshell.execDetached(action.command);
    }

    function accept(): void {
        if (mode === "nilo") niloView.accept(term);
        else if (mode === "apps" && apps.length > 0) launch(apps[Math.max(0, grid.currentIndex)]);
        else if (mode === "actions") runAction(actions[list.currentIndex]);
        else if (mode === "calc" && result) {
            // Other programs read a minus as ASCII's, not qalc's U+2212.
            Quickshell.execDetached([Config.cmd.wlCopy, "--", result.replace(/\u2212/g, "-")]);
            Drawers.close();
        }
    }

    function move(key): bool {
        if (mode === "apps") {
            if (key === Qt.Key_Right || key === Qt.Key_Tab) grid.moveCurrentIndexRight();
            else if (key === Qt.Key_Left || key === Qt.Key_Backtab) grid.moveCurrentIndexLeft();
            else if (key === Qt.Key_Down) grid.moveCurrentIndexDown();
            else if (key === Qt.Key_Up) grid.moveCurrentIndexUp();
            else return false;
            return true;
        }
        if (mode === "actions") {
            if (key === Qt.Key_Down || key === Qt.Key_Tab) list.incrementCurrentIndex();
            else if (key === Qt.Key_Up || key === Qt.Key_Backtab) list.decrementCurrentIndex();
            else return false;
            armed = "";
            return true;
        }
        return false;
    }

    Timer {
        id: calcDelay
        interval: 140
        onTriggered: {
            if (root.term === "")
                return;
            if (calc.running) {
                calc.again = true;
                return;
            }
            calc.asked = root.term;
            calc.command = [Config.cmd.qalc, "-t", "--", root.term];
            calc.running = true;
        }
    }

    Process {
        id: calc

        property string asked: ""
        property bool again: false

        stdout: StdioCollector {
            onStreamFinished: {
                if (calc.asked === root.term && root.mode === "calc")
                    root.result = text.trim().split("\n").pop();
            }
        }
        onExited: {
            if (again) {
                again = false;
                calcDelay.restart();
            }
        }
    }

    NiloView {
        id: niloView
        x: 24
        y: 14
        width: parent.width - 48
        height: Math.max(0, search.y - y - 16)
        visible: root.niloP > 0 && root.opacity > 0
        opacity: root.niloP
        active: root.active && root.niloMode
        question: root.niloMode ? root.term : ""
        caret: input.cursorRectangle.x / Math.max(1, input.width)
        onCleared: input.text = "?"
        onRefocus: input.forceActiveFocus()
    }

    Surface {
        id: search
        x: 24
        y: 24 + root.niloP * (root.height - height - 74)
        width: parent.width - 48
        height: 48
        radius: 12
        color: Tokens.surface
        border.width: 1
        border.color: input.activeFocus ? Tokens.muted : Tokens.line

        Ico {
            id: searchIcon
            anchors.left: parent.left
            anchors.leftMargin: 18
            anchors.verticalCenter: parent.verticalCenter
            glyph: root.mode === "calc" ? Icons.calculator : root.mode === "actions" ? Icons.chevron : Icons.search
            color: Tokens.muted
            opacity: 1 - root.niloP
        }

        Eyes {
            anchors.centerIn: searchIcon
            eyeWidth: 4
            eyeHeight: 11
            gap: 5
            mood: niloView.mood
            pulse: Nilo.pulse
            opacity: root.niloP
            visible: opacity > 0 && root.opacity > 0
        }

        QQC.TextField {
            id: input
            QQC.ContextMenu.menu: TextMenu {
                target: input
            }
            anchors.left: searchIcon.right
            anchors.right: modeLabel.left
            anchors.leftMargin: 12
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            background: null
            color: Tokens.ink
            selectionColor: Tokens.ink
            selectedTextColor: Tokens.black
            objectName: "launcherSearch"
            placeholderText: Lang.search
            placeholderTextColor: Tokens.muted
            font.family: Tokens.fontMono
            font.pixelSize: 14
            onTextChanged: root.query = text
            onAccepted: root.accept()
            Keys.onEscapePressed: if (!(root.niloMode && niloView.back())) Drawers.close()
            Keys.onPressed: event => {
                if (Drawers.byHover && !root.modifierOnly(event.key)) Drawers.byHover = false;
                if (root.niloMode ? niloView.key(event) : root.move(event.key)) event.accepted = true;
            }

            Txt {
                x: input.leftPadding + mark.advanceWidth + 10
                anchors.verticalCenter: parent.verticalCenter
                visible: input.text === "?" && niloView.view === "chat"
                text: Lang.niloAsk
                color: Tokens.muted
                font.family: Tokens.fontMono
                font.pixelSize: 14
            }

            TextMetrics {
                id: mark
                font: input.font
                text: "?"
            }
        }

        Label {
            id: modeLabel
            anchors.right: parent.right
            anchors.rightMargin: 20
            anchors.verticalCenter: parent.verticalCenter
            text: root.mode === "apps" ? Case.count(root.apps.length, Lang.appsCountOne, Lang.appsCount) : root.mode === "actions" ? Lang.actions
                : root.mode === "nilo" ? Lang.nilo : Lang.calculator
        }
    }

    GridView {
        id: grid
        anchors.top: search.bottom
        anchors.bottom: hints.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        anchors.topMargin: 14
        anchors.bottomMargin: 10
        visible: root.mode === "apps"
        clip: true
        cellWidth: width / 7
        cellHeight: 112
        model: root.apps
        keyNavigationWraps: true
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 0

        delegate: Item {
            id: cell

            required property var modelData
            required property int index

            readonly property bool selected: GridView.isCurrentItem

            width: grid.cellWidth
            height: grid.cellHeight

            Surface {
                anchors.fill: parent
                anchors.margins: 4
                radius: 18
                color: cell.selected ? Tokens.raised : "transparent"
                border.width: cell.selected ? 1 : 0
                border.color: Tokens.line
            }

            AppIcon {
                id: icon
                anchors.horizontalCenter: parent.horizontalCenter
                y: 18
                size: 46
                icon: cell.modelData.icon
                colored: cell.selected || area.containsMouse
            }

            Label {
                anchors.top: icon.bottom
                anchors.topMargin: 10
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 16
                horizontalAlignment: Text.AlignHCenter
                text: cell.modelData.name
                color: cell.selected ? Tokens.ink : Tokens.muted
            }

            MouseArea {
                id: area
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: grid.currentIndex = cell.index
                onClicked: root.launch(cell.modelData)
            }
        }
    }

    ListView {
        id: list
        anchors.top: search.bottom
        anchors.bottom: hints.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: 24
        anchors.topMargin: 14
        anchors.bottomMargin: 10
        visible: root.mode === "actions"
        clip: true
        spacing: 2
        model: root.actions
        keyNavigationWraps: true
        boundsBehavior: Flickable.StopAtBounds
        highlightMoveDuration: 0

        delegate: Surface {
            id: row

            required property var modelData
            required property int index

            readonly property bool selected: ListView.isCurrentItem
            readonly property bool isArmed: root.armed === modelData.id

            width: list.width
            height: 44
            radius: 14
            color: isArmed ? Tokens.interrupt : (selected ? Tokens.raised : "transparent")

            Ico {
                id: glyph
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                glyph: row.modelData.glyph
                color: row.isArmed ? Tokens.ink : (row.modelData.danger ? Tokens.interrupt : (row.selected ? Tokens.ink : Tokens.dim))
            }

            Txt {
                anchors.left: glyph.right
                anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                text: row.modelData.name
                color: row.selected || row.isArmed ? Tokens.ink : Tokens.dim
            }

            Label {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: row.isArmed ? Lang.confirmAgain : row.modelData.hint
                color: row.isArmed ? Tokens.ink : Tokens.muted
            }

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onEntered: list.currentIndex = row.index
                onClicked: root.runAction(row.modelData)
            }
        }
    }

    // Armed, an action waits a few seconds for its second Enter or click, as the panel's do.
    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = ""
    }

    Label {
        anchors.centerIn: grid
        visible: (root.mode === "apps" && root.apps.length === 0) || (root.mode === "actions" && root.actions.length === 0)
        text: Lang.noResults
    }

    Column {
        anchors.centerIn: grid
        visible: root.mode === "calc"
        spacing: 12

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: root.term || Lang.typeExpression
        }

        DotText {
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(implicitWidth, root.width - 80)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: root.result || "0"
            font.pixelSize: 56
            color: root.result ? Tokens.ink : Tokens.off
        }
    }

    KeyHints {
        id: hints
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 16
        text: root.mode === "nilo" ? niloView.hint : root.mode === "calc" ? Lang.hintCalc
            : Config.nilo.enabled ? Lang.hintAppsNilo : Lang.hintApps
    }
}
