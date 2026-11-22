import QtQuick
import qs.theme
import qs.config
import qs.services
import qs.components

Item {
    id: root

    property int cursor: -1

    readonly property int modelCount: models.count
    readonly property int autoIndex: modelCount
    readonly property int thinkIndex: modelCount + 1
    readonly property int accessStart: modelCount + 2
    readonly property int repoStart: accessStart + access.count
    readonly property int total: repoStart + repos.count
    readonly property var sleepChoices: [1, 5, 15, 30]
    readonly property bool asking: access.asking !== ""

    signal done()

    onVisibleChanged: if (visible) Nilo.findRepos()

    function back(): bool {
        if (!asking) return false;
        access.asking = "";
        return true;
    }

    function gb(value: real): string {
        return Number(value).toLocaleString(Qt.locale(Lang.locale), "f", 1);
    }

    function memory(): string {
        if (!Nilo.loaded) return Lang.setAsleep;
        const until = Nilo.expires > 0 ? Qt.formatTime(new Date(Nilo.expires * 1000), "HH:mm") : "—";
        const awake = Lang.setAwakeUntil.arg(gb(Nilo.sizeGB)).arg(until);
        return Nilo.gpu > 0 ? awake + " " + Lang.setOnGpu.arg(Nilo.gpu) : awake;
    }

    function sync(): void {
        models.current = cursor >= 0 && cursor < modelCount ? cursor : -1;
        access.current = cursor >= accessStart && cursor < repoStart ? cursor - accessStart : -1;
        repos.current = cursor >= repoStart && cursor < total ? cursor - repoStart : -1;
        if (asking && (access.current < 0 || access.items[access.current].key !== access.asking)) access.asking = "";
        keep(models.current >= 0 ? models : cursor === autoIndex ? autoRow : cursor === thinkIndex ? thinkRow
            : access.current >= 0 ? access.rowAt(access.current) : repos);
    }

    function keep(item: Item): void {
        if (!item) return;
        const y = item.mapToItem(content, 0, 0).y;
        if (y < flick.contentY) flick.contentY = Math.max(0, y - 40);
        else if (y + item.height > flick.contentY + flick.height)
            flick.contentY = Math.max(0, Math.min(flick.contentHeight - flick.height, y + item.height - flick.height + 20));
    }

    function move(step: int): void {
        cursor = Math.max(0, Math.min(total - 1, cursor < 0 ? 0 : cursor + step));
        sync();
    }

    function flip(key: string): void {
        Nilo.set(key, !(Nilo.settings[key] === true));
    }

    function activate(): void {
        if (cursor < 0) return;
        if (cursor < modelCount) models.choose(cursor);
        else if (cursor === autoIndex) flip("auto");
        else if (cursor === thinkIndex) flip("think");
        else if (cursor < repoStart) access.toggle(cursor - accessStart);
        else if (cursor < total) repos.choose(cursor - repoStart);
    }

    function sleepStep(step: int): void {
        const i = sleepChoices.indexOf(Nilo.settings.keepAlive ?? 5);
        Nilo.set("keepAlive", sleepChoices[Math.max(0, Math.min(sleepChoices.length - 1, (i < 0 ? 1 : i) + step))]);
    }

    function choosePath(path: string): void {
        const typed = path.trim();
        if (typed !== "" && typed !== (Nilo.settings.repo ?? "")) Nilo.set("repo", typed);
    }

    component Section: Column {
        property alias title: heading.text

        width: parent ? parent.width : 0
        spacing: 8
        topPadding: 18

        Rectangle { width: parent.width; height: 1; color: Tokens.line }
        Label { id: heading; topPadding: 8 }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentHeight: content.implicitHeight + 24
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: content
            x: Math.max(0, (parent.width - width) / 2)
            width: Math.min(640, flick.width)
            spacing: 4

            Section { title: Lang.setModel; topPadding: 0 }

            ModelList {
                id: models
                width: content.width
                manage: true
            }

            SwitchRow {
                id: autoRow
                width: content.width
                title: Lang.setAuto
                sub: Nilo.settings.auto && Nilo.fast === "" ? Lang.setAutoNeedsTwo : ""
                on: Nilo.settings.auto === true
                current: root.cursor === root.autoIndex
                onToggled: root.flip("auto")
            }

            SwitchRow {
                id: thinkRow
                width: content.width
                title: Lang.setThink
                on: Nilo.settings.think === true
                current: root.cursor === root.thinkIndex
                onToggled: root.flip("think")
            }

            Section { title: Lang.setAccess }

            AccessList {
                id: access
                width: content.width
                onGrew: row => root.keep(row)
            }

            Section { title: Lang.setRepo }

            RepoList {
                id: repos
                width: content.width
            }

            GearRow {
                width: content.width
                title: Lang.setRepoPath

                Field {
                    width: Math.min(320, content.width - 200)
                    value: Nilo.settings.repo ?? ""
                    catchEscape: true
                    onFinished: root.choosePath(text)
                    onAccepted: root.done()
                    onEscaped: root.done()
                }
            }

            Section { title: Lang.setContext }

            GearRow {
                width: content.width
                title: Lang.setNotes

                KeyButton {
                    text: Lang.setContextEdit
                    onClicked: Nilo.editNotes()
                }
            }

            Section { title: Lang.setMemory }

            GearRow {
                width: content.width
                title: Lang.setSleepAfter
                sub: root.memory()

                Row {
                    spacing: 16

                    Choice {
                        anchors.verticalCenter: parent.verticalCenter
                        mono: true
                        options: root.sleepChoices.map(minutes => ({ value: minutes, label: Lang.setMinutes.arg(minutes) }))
                        value: Nilo.settings.keepAlive ?? 5
                        onPicked: value => Nilo.set("keepAlive", value)
                    }

                    KeyButton {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: Nilo.loaded
                        text: Lang.setSleepNow
                        onClicked: Nilo.sleep()
                    }
                }
            }

            Item { width: 1; height: 18 }

            Rectangle { width: content.width; height: 1; color: Tokens.line }

            Item { width: 1; height: 10 }

            Row {
                x: 16
                spacing: 8

                KeyButton {
                    text: Lang.setIntro
                    onClicked: {
                        Nilo.set("onboarded", false);
                        root.done();
                    }
                }

                KeyButton {
                    text: Lang.setOpenPreferences
                    onClicked: {
                        Drawers.close();
                        Machine.show("system", false);
                    }
                }
            }

        }
    }
}
