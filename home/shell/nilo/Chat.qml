import QtQuick
import Quickshell
import qs.theme
import qs.config
import qs.services
import qs.components
import "Markdown.js" as Markdown

Item {
    id: root

    property string armed: ""
    property bool follow: true
    property real faceRoom: 0

    signal suggest(string text)

    readonly property real emptyTop: Math.max(faceRoom,
        (height - faceRoom - (empty.visible ? empty.implicitHeight : down.implicitHeight)) / 2 + faceRoom)

    readonly property var voices: ({ ink: String(Tokens.ink), dim: String(Tokens.dim), code: "#E6E6E6",
                                     surface: String(Tokens.surface), mono: Tokens.fontMono, icons: Tokens.fontIcons })

    function scroll(step: real): void {
        follow = false;
        list.contentY = Math.max(list.originY, Math.min(list.contentY + step, list.originY + list.contentHeight - list.height));
        if (list.atYEnd) follow = true;
    }

    function toEnd(): void {
        follow = true;
        list.positionViewAtEnd();
    }

    function host(url: string): string {
        const m = String(url ?? "").match(/^[a-z]+:\/\/([^\/?#]+)/i);
        return m ? m[1].replace(/^www\./, "") : String(url ?? "");
    }

    function toolText(name: string, status: string, info: string): string {
        let data = {};
        try { data = JSON.parse(info || "{}"); } catch (e) {}
        const args = data.args ?? data;
        if (status === "failed") {
            // Why, in the chat's language: what the agent says is for the model, in English.
            if (data.reason === "timeout") return Lang.toolTookTooLong;
            return Nilo.english && data.error ? Lang.toolFailed.arg(String(data.error).slice(0, 80)) : Lang.toolFailedPlain;
        }
        if (status !== "running" && data.declined) return Lang.toolDeclined;
        const running = status === "running";
        switch (name) {
        case "web_search":
            return running ? Lang.toolSearching.arg(args.query ?? "") : Case.count(data.count ?? 0, Lang.toolSearchedOne, Lang.toolSearched).arg(args.query ?? "");
        case "open_url":
            return running ? Lang.toolReading.arg(host(args.url)) : Lang.toolRead.arg(data.title || data.host || host(args.url));
        case "system_info":
            return running ? Lang.toolSystem : Lang.toolSystemDone;
        case "git_status":
            return running ? Lang.toolGitStatus : Case.count(data.changes ?? 0, Lang.toolGitStatusDoneOne, Lang.toolGitStatusDone).arg(data.branch ?? "");
        case "git_commit":
            if (running) return Lang.toolGitCommit;
            if (data.declined) return Lang.toolDeclined;
            if (data.pushed) return data.commit ? Lang.toolGitPushed.arg(data.commit) : Lang.toolGitPushedOnly;
            return Lang.toolGitCommitted.arg(data.commit ?? "");
        case "list_files":
            return running ? Lang.toolListing : Case.count(data.count ?? 0, Lang.toolListedOne, Lang.toolListed);
        case "read_file":
            return running ? Lang.toolOpening.arg(args.path ?? "") : ((data.lines ?? 0) === 1 ? Lang.toolOpenedOne.arg(data.path ?? args.path ?? "")
                : Lang.toolOpened.arg(data.path ?? args.path ?? "").arg(data.lines ?? 0));
        case "edit_file":
        case "write_file":
            if (running) return Lang.toolChanging.arg(args.path ?? "");
            if (data.declined) return Lang.toolDeclined;
            return data.created ? ((data.added ?? 0) === 1 ? Lang.toolCreatedOne.arg(data.path ?? "") : Lang.toolCreated.arg(data.path ?? "").arg(data.added ?? 0))
                : Lang.toolChanged.arg(data.path ?? "").arg(data.added ?? 0).arg(data.removed ?? 0);
        case "run_command": {
            const line = String(args.command ?? "").split("\n")[0];
            const command = line.length > 48 ? line.slice(0, 47) + "…" : line;
            if (running) return Lang.toolRunning.arg(command);
            if (data.declined) return Lang.toolDeclined;
            if (data.terminal) return Lang.toolInTerminal.arg(command);
            return data.exit === 0 ? Lang.toolRanOk.arg(command) : Lang.toolRanFail.arg(command).arg(data.exit ?? "?");
        }
        case "open_app":
            if (running) return Lang.toolLaunching.arg(args.target ?? "");
            return data.searched ? Lang.toolInBrowser.arg(data.opened || args.target || "")
                : Lang.toolLaunched.arg(data.opened || args.target || "");
        case "list_windows":
            return running ? Lang.toolWindows : Case.count(data.count ?? 0, Lang.toolWindowsDoneOne, Lang.toolWindowsDone);
        case "look_at_screen":
            if (running) return Lang.toolLooking;
            return data.what === "screen" || !data.app ? Lang.toolLookedScreen : Lang.toolLookedWindow.arg(data.app);
        case "click":
            if (running) return Lang.toolClicking;
            return data.app ? Lang.toolClicked.arg(data.app) : Lang.toolClickedScreen;
        case "use_window": {
            const app = data.app || args.window || "";
            if (running) return Lang.toolWindow.arg(app);
            if (data.declined) return Lang.toolDeclined;
            const done = { close: Lang.toolClose, fullscreen: Lang.toolFullscreen, maximize: Lang.toolMaximize,
                           float: Lang.toolFloat }[data.action ?? args.action];
            if ((data.action ?? args.action) === "move") return Lang.toolMove.arg(app).arg(data.workspace ?? args.workspace ?? "");
            return (done ?? Lang.toolFocus).arg(app);
        }
        case "type_text":
            if (running) return Lang.toolTyping.arg(args.window || "…");
            return data.declined ? Lang.toolDeclined : Lang.toolTyped.arg(data.app || args.window || "");
        case "press_keys":
            if (running) return Lang.toolPressing.arg(args.keys ?? "");
            return data.declined ? Lang.toolDeclined : Lang.toolPressed.arg(data.keys || args.keys || "").arg(data.app || "");
        case "media": {
            if (running) return args.query ? Lang.toolFinding.arg(args.query) : Lang.toolMedia;
            if (data.playing) return Lang.toolPlaying.arg(data.playing);
            if (data.state === "paused" || (data.action ?? args.action) === "pause") return Lang.toolPaused;
            if (data.title) return Lang.toolPlaying.arg(data.title + (data.artist ? ", " + data.artist : ""));
            return (data.action ?? args.action) === "previous" ? Lang.toolPrevious : Lang.toolNext;
        }
        case "control": {
            const setting = data.setting ?? args.setting ?? "";
            const label = root.settingName(setting);
            // Within a sentence in lower case, but for the names of things: Wi-Fi, Bluetooth.
            const named = setting === "wifi" || setting === "bluetooth" ? label : label.toLocaleLowerCase();
            if (running) return setting === "screenshot" ? Lang.toolShooting : Lang.toolControl.arg(named);
            if (setting === "lock") return Lang.actLock;
            if (setting === "wallpaper" && (data.value === "next" || data.value === "prev"))
                return data.value === "next" ? Lang.actNextWallpaper : Lang.actPrevWallpaper;
            if (setting === "screenshot") return Lang.toolShot;
            const value = data.value === "on" ? Lang.toolOn : data.value === "off" ? Lang.toolOff
                : (setting === "volume" || setting === "brightness" || setting === "night") ? Lang.percent.arg(data.value) : String(data.value ?? "");
            return Lang.toolControlled.arg(label).arg(value);
        }
        case "send_to_phone":
            if (running) return Lang.toolSending;
            return data.declined ? Lang.toolDeclined : Lang.toolSent;
        }
        return name;
    }

    function settingName(setting: string): string {
        return ({ volume: Lang.settingVolume, mute: Lang.settingMute, mic: Lang.tileMic,
                  brightness: Lang.settingBrightness, dnd: Lang.settingDnd, caffeine: Lang.settingCaffeine,
                  night: Lang.settingNight, wifi: Lang.tileWifi, bluetooth: Lang.tileBluetooth,
                  wallpaper: Lang.settingWallpaper, glass: Lang.settingGlass,
                  workspace: Lang.settingWorkspace, screenshot: Lang.tileShot, record: Lang.settingRecord,
                  lock: Lang.settingLock })[setting] ?? setting;
    }

    function desktopTitle(facts: var): string {
        switch (facts.what) {
        case "type": return Lang.confirmType.arg(facts.app ?? "");
        case "keys": return Lang.confirmKeys.arg(facts.app ?? "");
        case "send": return Lang.confirmSend;
        case "search": return Lang.confirmSearch;
        case "fetch": return Lang.confirmFetch;
        case "open": return Lang.confirmOpenUrl;
        case "read": return Lang.confirmRead;
        case "click": return Lang.confirmClick.arg(facts.app ?? "");
        case "launch": return Lang.confirmLaunch;
        }
        return "";
    }

    function dangerText(code: string): string {
        switch (code) {
        case "root": return Lang.dangerRoot;
        case "delete": return Lang.dangerDelete;
        case "disk": return Lang.dangerDisk;
        case "git": return Lang.dangerGit;
        case "power": return Lang.dangerPower;
        case "system": return Lang.dangerSystem;
        case "permissions": return Lang.dangerPermissions;
        case "internet": return Lang.dangerInternet;
        case "script": return Lang.dangerScript;
        }
        return code;
    }

    function unitLine(): string {
        const s = Nilo.service;
        if (!s.activeState) return "";
        const why = s.result && s.result !== "success" ? s.result : s.subState;
        return (s.unit ? s.unit + ": " : "") + (s.activeState ?? "") + (why ? " (" + why + ")" : "");
    }

    function errorText(code: string, detail: string): string {
        return Nilo.errorText(code, detail);
    }

    Column {
        id: empty
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.emptyTop
        width: Math.min(620, parent.width - 48)
        spacing: 10
        visible: Nilo.messages.count === 0 && (Nilo.ollama || !Nilo.known)
        opacity: visible ? 1 : 0

        Behavior on opacity { NumberAnimation { duration: Tokens.animNormal } }

        readonly property bool downloading: Nilo.pull !== null && Nilo.pull.status !== "error"
            && Nilo.pull.model === (Nilo.settings.model ?? "")

        property string greeting: ""

        function greet(): void {
            const hour = new Date().getHours();
            const options = (hour < 6 ? Lang.niloGreetNight : hour < 13 ? Lang.niloGreetMorning
                : hour < 20 ? Lang.niloGreetAfternoon : Lang.niloGreetEvening).split("|");
            const pick = options[Math.floor(Math.random() * options.length)];
            greeting = Config.greeting !== "" ? pick.arg(Config.greeting) : pick.replace(/[,\s]*%1/, "");
        }

        onVisibleChanged: if (visible) greet()
        Component.onCompleted: greet()

        DotText {
            id: hello
            anchors.horizontalCenter: parent.horizontalCenter
            width: Math.min(implicitWidth, parent.width)
            horizontalAlignment: Text.AlignHCenter
            elide: Text.ElideRight
            text: empty.greeting
            font.pixelSize: 30
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Nilo.installed ? (Nilo.settings.web ? Lang.niloEmpty : Lang.niloEmptyOffline)
                : parent.downloading ? Lang.niloDownloadingModel.arg(Nilo.settings.model).arg(Math.floor(Nilo.pull.progress * 100))
                : Lang.niloErrModel.arg(Nilo.settings.model ?? "")
            color: Tokens.dim
            font.pixelSize: 15
        }

        Item {
            width: 1
            height: 16
        }

        DotMeter {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !Nilo.installed && parent.downloading
            count: 24
            dot: 6
            gap: 4
            value: Nilo.pull?.progress ?? 0
        }

        Item {
            width: 1
            height: 12
            visible: !Nilo.installed && parent.downloading
        }

        KeyButton {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !Nilo.installed && parent.downloading
            text: Lang.confirmCancel
            onClicked: Nilo.cancelDownload()
        }

        KeyButton {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !Nilo.installed && !parent.downloading && Nilo.known
            text: Lang.niloDownload
            accent: true
            onClicked: Nilo.download(Nilo.settings.model)
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: Nilo.installed

            Repeater {
                model: [
                    { text: Lang.niloTryFlake, on: true },
                    { text: Lang.niloTryNews, on: Nilo.settings.web === true },
                    { text: Lang.niloTryDisk, on: Nilo.settings.system === true },
                    { text: Lang.niloTryShell, on: Nilo.settings.shell === true },
                    { text: Lang.niloTryApps, on: Nilo.settings.apps === true },
                    { text: Lang.niloTryMusic, on: Nilo.settings.desktop === true && Nilo.settings.web === true },
                    { text: Lang.niloTryWrite, on: Nilo.settings.desktop === true },
                    { text: Lang.niloTryFiles, on: Nilo.settings.write === true && Nilo.settings.desktop !== true },
                    { text: Lang.niloTryPush, on: Nilo.settings.git === true }
                ].filter(s => s.on).slice(0, 5)

                Txt {
                    required property var modelData

                    anchors.horizontalCenter: parent.horizontalCenter
                    height: 28
                    text: modelData.text
                    color: tryArea.containsMouse ? Tokens.ink : Tokens.dim
                    font.pixelSize: 13

                    Behavior on color { ColorAnimation { duration: Tokens.animFast } }

                    MouseArea {
                        id: tryArea
                        anchors.fill: parent
                        anchors.leftMargin: -10
                        anchors.rightMargin: -10
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.suggest(parent.modelData.text)
                    }
                }
            }
        }
    }

    Column {
        id: down
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        anchors.topMargin: root.emptyTop
        width: Math.min(620, parent.width - 48)
        spacing: 12
        visible: Nilo.messages.count === 0 && !Nilo.ollama && Nilo.known

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Nilo.startingOllama ? Lang.niloOllamaStarting : Lang.niloOllamaDown
            color: Tokens.dim
            font.pixelSize: 15
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: text !== "" && !Nilo.startingOllama
            text: root.unitLine()
            color: Tokens.muted
            font.family: Tokens.fontMono
            font.pixelSize: 12
        }

        Column {
            width: parent.width
            spacing: 3
            visible: !Nilo.startingOllama && (Nilo.service.log ?? []).length > 0
            topPadding: 2

            Repeater {
                model: (Nilo.service.log ?? []).slice(-4)

                Txt {
                    required property string modelData
                    width: parent.width
                    text: modelData
                    horizontalAlignment: Text.AlignHCenter
                    color: Tokens.muted
                    font.family: Tokens.fontMono
                    font.pixelSize: 11
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 2
                }
            }
        }

        Txt {
            width: parent.width
            visible: !Nilo.startingOllama && (Nilo.service.error ?? "") !== ""
            text: Nilo.service.error ?? ""
            horizontalAlignment: Text.AlignHCenter
            color: Tokens.dim
            wrapMode: Text.Wrap
            elide: Text.ElideNone
            font.pixelSize: 13
        }

        Item { width: 1; height: 2 }

        KeyButton {
            anchors.horizontalCenter: parent.horizontalCenter
            visible: !Nilo.startingOllama
            text: Lang.niloStartOllama
            accent: true
            onClicked: Nilo.startOllama()
        }

        Txt {
            anchors.horizontalCenter: parent.horizontalCenter
            text: Lang.niloOllamaHelp
            color: Tokens.muted
            font.family: Tokens.fontMono
            font.pixelSize: 11
        }
    }

    ListView {
        id: list
        anchors.fill: parent
        clip: true
        model: Nilo.messages
        boundsBehavior: Flickable.StopAtBounds
        visible: Nilo.messages.count > 0
        bottomMargin: 8

        onCountChanged: if (root.follow) Qt.callLater(positionViewAtEnd)
        onContentHeightChanged: if (root.follow) Qt.callLater(positionViewAtEnd)
        onMovementStarted: root.follow = false
        onMovementEnded: root.follow = atYEnd

        delegate: Item {
            id: entry

            required property int index
            required property string kind
            required property string text
            required property bool done
            required property string name
            required property string status
            required property string info
            required property string cid

            readonly property real gapAbove: index === 0 ? 0 : kind === "user" ? 26 : kind === "nilo" ? 12 : 8

            width: ListView.view.width
            height: gapAbove + body.height

            Loader {
                id: body
                y: entry.gapAbove
                width: parent.width
                sourceComponent: entry.kind === "user" ? userView
                    : entry.kind === "nilo" ? niloView
                    : entry.kind === "tool" ? toolView
                    : entry.kind === "confirm" ? confirmView
                    : entry.kind === "error" ? errorView : noteView
            }

            Component {
                id: userView

                Column {
                    spacing: 4

                    Row {
                        spacing: 10

                        Txt {
                            text: "›"
                            color: Tokens.muted
                            font.family: Tokens.fontMono
                            font.pixelSize: 15
                        }

                        Txt {
                            width: entry.width - 24
                            text: entry.text
                            color: Tokens.dim
                            wrapMode: Text.Wrap
                            elide: Text.ElideNone
                            font.pixelSize: 14
                        }
                    }

                    Txt {
                        x: 22
                        visible: entry.name === "ipc"
                        text: Lang.niloAskedBy
                        color: Tokens.muted
                        font.pixelSize: 12
                    }
                }
            }

            Component {
                id: niloView

                Column {
                    spacing: 8

                    Column {
                        id: reply
                        width: entry.width
                        spacing: 6

                        readonly property var parts: Markdown.segments(entry.text)

                        Repeater {
                            model: reply.parts.length

                            Item {
                                id: part

                                required property int index
                                readonly property var segment: reply.parts[index] ?? ({ kind: "text", text: "" })
                                readonly property bool isCode: segment.kind === "code"

                                width: reply.width
                                height: isCode ? block.height + 4 : prose.height

                                Text {
                                    id: prose
                                    visible: !part.isCode
                                    width: parent.width
                                    text: part.isCode ? "" : Markdown.html(part.segment.text, root.voices)
                                    textFormat: Text.RichText
                                    wrapMode: Text.Wrap
                                    color: Tokens.ink
                                    font.family: Tokens.fontSans
                                    font.pixelSize: 15
                                    lineHeight: 1.3
                                    // Only the web: a reply's link can't open a file or another program.
                                    onLinkActivated: link => {
                                        if (!/^https?:\/\//i.test(link))
                                            return;
                                        Drawers.close();
                                        Apps.open(link);
                                    }

                                    HoverHandler {
                                        id: pointer
                                        cursorShape: prose.hoveredLink ? Qt.PointingHandCursor : Qt.ArrowCursor
                                    }

                                    // Where a link goes, whatever its words say.
                                    Surface {
                                        visible: Markdown.host(prose.hoveredLink) !== ""
                                        z: 2
                                        x: Math.max(0, Math.min(pointer.point.position.x + 12, prose.width - width))
                                        y: pointer.point.position.y + 18
                                        width: destination.implicitWidth + 16
                                        height: destination.implicitHeight + 8
                                        radius: 8
                                        color: Tokens.surface
                                        border.width: 1
                                        border.color: Tokens.line

                                        Label {
                                            id: destination
                                            anchors.centerIn: parent
                                            text: Markdown.host(prose.hoveredLink)
                                        }
                                    }
                                }

                                CodeBlock {
                                    id: block
                                    visible: part.isCode
                                    width: parent.width
                                    code: part.isCode ? part.segment.text : ""
                                    language: part.isCode ? part.segment.language : ""
                                }
                            }
                        }
                    }

                    Row {
                        id: meta
                        visible: entry.done && entry.text !== ""
                        spacing: 14

                        readonly property var stats: { try { return JSON.parse(entry.info || "{}"); } catch (e) { return {}; } }

                        Label {
                            visible: Nilo.settings.auto === true && (meta.stats.model ?? "") !== ""
                            text: meta.stats.model ?? ""
                            color: Tokens.muted
                        }

                        Label {
                            visible: (meta.stats.tokens ?? 0) > 0 && (meta.stats.seconds ?? 0) > 0
                            text: Lang.niloRate.arg(Math.round(meta.stats.tokens / meta.stats.seconds))
                            color: Tokens.muted
                        }

                        CopyButton {
                            text: entry.text
                        }
                    }
                }
            }

            Component {
                id: toolView

                Column {
                    spacing: 6

                    Row {
                        spacing: 10
                        height: 18

                        Rectangle {
                            id: dot
                            anchors.verticalCenter: parent.verticalCenter
                            width: 6
                            height: 6
                            radius: 3
                            color: entry.status === "failed" ? Tokens.interrupt : entry.status === "running" ? Tokens.ink : Tokens.muted

                            SequentialAnimation on opacity {
                                running: entry.status === "running"
                                loops: Animation.Infinite
                                onRunningChanged: if (!running) dot.opacity = 1
                                NumberAnimation { to: 0.2; duration: 420 }
                                NumberAnimation { to: 1; duration: 420 }
                            }
                        }

                        Txt {
                            anchors.verticalCenter: parent.verticalCenter
                            width: entry.width - 16
                            text: root.toolText(entry.name, entry.status, entry.info)
                            color: entry.status === "running" ? Tokens.dim : Tokens.muted
                            font.family: Tokens.fontMono
                            font.pixelSize: 11
                        }
                    }

                    Surface {
                        x: 16
                        visible: entry.name === "run_command" && entry.text !== ""
                        width: Math.min(entry.width - 16, 620)
                        height: visible ? output.implicitHeight + 16 : 0
                        radius: 10
                        color: Tokens.black
                        border.width: 1
                        border.color: Tokens.line

                        Txt {
                            id: output
                            x: 12
                            y: 8
                            width: parent.width - 24
                            text: entry.text
                            textFormat: Text.PlainText
                            color: entry.status === "running" ? Tokens.dim : Tokens.muted
                            font.family: Tokens.fontMono
                            font.pixelSize: 11
                            wrapMode: Text.WrapAnywhere
                            elide: Text.ElideNone
                            maximumLineCount: 8
                        }
                    }
                }
            }

            Component {
                id: confirmView

                Surface {
                    id: card

                    readonly property var facts: { try { return JSON.parse(entry.info || "{}"); } catch (e) { return {}; } }
                    readonly property bool file: facts.action === "edit" || facts.action === "create"
                    readonly property bool command: facts.action === "run" || facts.action === "terminal"
                    readonly property bool desktop: facts.action === "desktop"
                    readonly property var why: desktop ? (facts.why ?? []) : []
                    readonly property bool risky: command && (facts.danger ?? []).length > 0
                        || why.some(code => code !== "private" && code !== "web")
                    readonly property bool open: entry.status === "asking"
                    // While it's being asked, the card can show all there is; afterwards, what it showed at first.
                    readonly property bool all: open && Nilo.confirmAll
                    readonly property bool hiding: open && Nilo.confirmHides
                    readonly property var diff: facts.diff ?? []
                    readonly property var files: facts.files ?? []
                    readonly property bool isArmed: open && root.armed === entry.cid

                    width: Math.min(entry.width, 620)
                    height: content.implicitHeight + 32
                    radius: 18
                    color: Tokens.surface
                    border.width: 1
                    border.color: isArmed || (open && risky) ? Tokens.interrupt : Tokens.line
                    opacity: open ? 1 : 0.55

                    Behavior on opacity { NumberAnimation { duration: Tokens.animNormal } }

                    Column {
                        id: content
                        x: 18
                        y: 16
                        width: card.width - 36
                        spacing: 8

                        Label {
                            text: card.desktop ? root.desktopTitle(card.facts)
                                : card.file ? (card.facts.action === "create" ? Lang.confirmCreate : Lang.confirmEdit) + " " + Lang.confirmFile
                                : card.command ? Lang.confirmRun + (card.facts.action === "terminal" ? " " + Lang.confirmTerminal : "")
                                : card.facts.action === "commit-push" ? Lang.confirmCommitPush
                                : card.facts.action === "push" ? Lang.confirmPush : Lang.confirmCommit
                            color: Tokens.ink
                        }

                        Txt {
                            width: parent.width
                            visible: text !== ""
                            text: card.desktop ? (card.facts.path ?? card.facts.title ?? "")
                                : card.file
                                ? (card.facts.repo ? card.facts.repo + "/" : "") + (card.facts.path ?? "") + "   +" + (card.facts.added ?? 0)
                                    + ((card.facts.removed ?? 0) > 0 ? " −" + card.facts.removed : "")
                                : card.command ? (card.facts.cwd ?? "")
                                : (card.facts.repo ?? "") + " (" + (card.facts.branch ?? "") + ")" + (card.facts.remote ? "  →  " + card.facts.remote : "")
                            color: Tokens.dim
                            font.family: Tokens.fontMono
                            font.pixelSize: 12
                        }

                        Surface {
                            visible: card.command || card.desktop && (card.facts.text ?? card.facts.keys ?? "") !== ""
                            width: parent.width
                            height: visible ? commandText.implicitHeight + 20 : 0
                            radius: 12
                            color: Tokens.black
                            border.width: 1
                            border.color: Tokens.line

                            Txt {
                                id: commandText
                                x: 12
                                y: 10
                                width: parent.width - 24
                                readonly property string whole: card.desktop ? (card.facts.text ?? card.facts.keys ?? "") : "$ " + (card.facts.command ?? "")
                                text: !card.desktop || card.all || whole.length <= Nilo.cardChars ? whole : whole.slice(0, Nilo.cardChars) + " …"
                                textFormat: Text.PlainText
                                color: Tokens.ink
                                font.family: Tokens.fontMono
                                font.pixelSize: 12
                                wrapMode: Text.WrapAnywhere
                                elide: Text.ElideNone
                            }
                        }

                        Label {
                            visible: text !== ""
                            text: [["enter", Lang.whyEnter], ["sensitive", Lang.whySensitive], ["web", Lang.whyWeb],
                                   ["private", Lang.whyPrivate]]
                                .filter(pair => card.why.includes(pair[0])).map(pair => pair[1]).join(". ")
                            color: Tokens.dim
                        }

                        Txt {
                            width: parent.width
                            visible: card.command && (card.facts.reason ?? "") !== ""
                            text: card.facts.reason ?? ""
                            textFormat: Text.PlainText
                            color: Tokens.dim
                            wrapMode: Text.Wrap
                            elide: Text.ElideNone
                            font.pixelSize: 13
                        }

                        Row {
                            visible: card.command && card.risky
                            spacing: 8

                            Rectangle {
                                anchors.verticalCenter: parent.verticalCenter
                                width: 6
                                height: 6
                                radius: 3
                                color: Tokens.interrupt
                            }

                            Label {
                                text: Case.sentence((card.facts.danger ?? []).map(code => root.dangerText(code)).join(", "))
                                color: Tokens.dim
                            }
                        }

                        Surface {
                            visible: card.file
                            width: parent.width
                            height: visible ? lines.implicitHeight + 20 : 0
                            radius: 12
                            color: Tokens.black
                            border.width: 1
                            border.color: Tokens.line

                            Column {
                                id: lines
                                x: 12
                                y: 10
                                width: parent.width - 24
                                spacing: 1

                                Repeater {
                                    model: card.file ? (card.all ? card.diff : card.diff.slice(0, Nilo.cardLines)) : []

                                    Txt {
                                        required property var modelData
                                        width: parent.width
                                        text: modelData.t === "@" ? Lang.confirmAtLine.arg(modelData.s)
                                            : (modelData.t === "+" ? "+ " : modelData.t === "-" ? "− " : "  ") + modelData.s.replace(/\t/g, "    ")
                                        color: modelData.t === "+" ? Tokens.ink : modelData.t === "-" ? Tokens.dim : Tokens.muted
                                        font.family: Tokens.fontMono
                                        font.pixelSize: 12
                                        font.strikeout: modelData.t === "-"
                                        wrapMode: Text.WrapAnywhere
                                        elide: Text.ElideNone
                                    }
                                }

                                Txt {
                                    visible: !card.all && card.diff.length > Nilo.cardLines
                                    text: Case.count(card.diff.length - Nilo.cardLines, Lang.confirmMoreLinesOne, Lang.confirmMoreLines)
                                    color: Tokens.muted
                                    font.family: Tokens.fontMono
                                    font.pixelSize: 12
                                    topPadding: 4
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 2
                            visible: !card.file && !card.command && !card.desktop

                            Repeater {
                                model: card.all ? card.files : card.files.slice(0, Nilo.cardFiles)

                                Txt {
                                    required property string modelData
                                    width: parent.width
                                    text: modelData
                                    color: Tokens.muted
                                    font.family: Tokens.fontMono
                                    font.pixelSize: 12
                                }
                            }

                            Txt {
                                readonly property int rest: (card.all ? 0 : Math.max(0, card.files.length - Nilo.cardFiles))
                                    + (card.facts.more ?? 0)
                                visible: rest > 0
                                text: Lang.confirmMore.arg(rest)
                                color: Tokens.muted
                                font.family: Tokens.fontMono
                                font.pixelSize: 12
                            }

                            Txt {
                                visible: card.facts.action === "push" && (card.facts.ahead ?? 0) > 0
                                text: Case.count(card.facts.ahead ?? 0, Lang.confirmAheadOne, Lang.confirmAhead)
                                color: Tokens.muted
                                font.family: Tokens.fontMono
                                font.pixelSize: 12
                            }
                        }

                        Txt {
                            width: parent.width
                            visible: (card.facts.message ?? "") !== ""
                            text: Lang.quoted.arg(card.facts.message ?? "")
                            color: Tokens.ink
                            wrapMode: Text.Wrap
                            elide: Text.ElideNone
                            font.pixelSize: 14
                            topPadding: 4
                        }

                        Txt {
                            width: parent.width
                            visible: (card.facts.trailer ?? "") !== ""
                            text: card.facts.trailer ?? ""
                            textFormat: Text.PlainText
                            color: Tokens.muted
                            font.family: Tokens.fontMono
                            font.pixelSize: 11
                        }

                        Item { width: 1; height: 4 }

                        Row {
                            anchors.right: parent.right
                            spacing: 8
                            visible: card.open

                            KeyButton {
                                text: Lang.confirmCancel
                                onClicked: Nilo.answer(entry.cid, false)
                            }

                            // With part of it still out of sight, the card first shows the rest.
                            KeyButton {
                                accent: !card.isArmed
                                danger: card.isArmed
                                text: card.hiding ? Lang.confirmShowAll : card.isArmed ? Lang.enterAgain : Lang.confirmOk
                                onClicked: {
                                    if (card.hiding) Nilo.confirmAll = true;
                                    else Nilo.answer(entry.cid, true);
                                }
                            }
                        }

                        Label {
                            anchors.right: parent.right
                            visible: !card.open
                            text: entry.status === "ok" ? Lang.confirmDone : Lang.confirmDeclined
                        }
                    }
                }
            }

            Component {
                id: errorView

                Row {
                    spacing: 10

                    Rectangle {
                        y: 6
                        width: 6
                        height: 6
                        radius: 3
                        color: Tokens.interrupt
                    }

                    Txt {
                        width: entry.width - (download.visible ? download.width + 30 : start.visible ? start.width + 30 : 16)
                        text: root.errorText(entry.name, entry.text)
                        color: Tokens.dim
                        wrapMode: Text.Wrap
                        elide: Text.ElideNone
                        font.pixelSize: 13
                    }

                    KeyButton {
                        id: download
                        visible: entry.name === "model-missing" && !Nilo.installed && Nilo.pull === null
                        text: Lang.niloDownload
                        accent: true
                        onClicked: Nilo.download(Nilo.settings.model)
                    }

                    KeyButton {
                        id: start
                        visible: entry.name === "ollama-down" && !Nilo.ollama && !Nilo.startingOllama
                        text: Lang.niloStartOllama
                        accent: true
                        onClicked: Nilo.startOllama()
                    }
                }
            }

            Component {
                id: noteView

                Label {
                    text: Lang.niloStopped
                }
            }
        }

        footer: Item {
            width: ListView.view.width
            height: typing.visible ? 34 : 0

            Row {
                id: typing
                y: 18
                spacing: 6
                visible: Nilo.busy && Nilo.phase !== "writing" && Nilo.phase !== "confirm"

                property int lit: 0

                Repeater {
                    model: 3
                    Rectangle {
                        required property int index
                        width: 6
                        height: 6
                        radius: 3
                        color: typing.lit === index ? Tokens.ink : Tokens.off
                    }
                }

                Timer {
                    running: typing.visible
                    interval: 260
                    repeat: true
                    onTriggered: typing.lit = (typing.lit + 1) % 3
                }
            }
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 22
        visible: list.visible && !list.atYBeginning
        gradient: Gradient {
            GradientStop { position: 0; color: Tokens.black }
            GradientStop { position: 1; color: "transparent" }
        }
    }
}
