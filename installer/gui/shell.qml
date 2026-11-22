//@ pragma Env QT_QPA_PLATFORM=wayland
//@ pragma Env QSG_DISTANCEFIELD_ANTIALIASING=gray

import QtQuick
import Quickshell
import Quickshell.Io
import qs.theme
import qs.config
import qs.components

ShellRoot {
    id: root

    readonly property string stateFile: Quickshell.env("NIHIL_INSTALLER_STATE") || "/tmp/nihil-installer.json"

    // Every screen is on and the window spans them (cage -m extend): the installer goes on one, the
    // computer's own panel or the first connected (NIHIL_INSTALLER_SCREEN), whose scale it has, and
    // never across a bezel. With one screen, or a layout that doesn't add up, the whole window.
    readonly property var main: Quickshell.screens.find(s => s.name === Quickshell.env("NIHIL_INSTALLER_SCREEN"))
        ?? Quickshell.screens[0] ?? null
    readonly property rect area: {
        const full = Qt.rect(0, 0, window.width, window.height);
        const screens = Quickshell.screens;
        if (!main || screens.length < 2)
            return full;
        const left = Math.min(...screens.map(s => s.x));
        const top = Math.min(...screens.map(s => s.y));
        const r = Qt.rect(main.x - left, main.y - top, main.width, main.height);
        const fits = r.width > 0 && r.height > 0 && r.x >= 0 && r.y >= 0
            && r.x + r.width <= window.width + 1 && r.y + r.height <= window.height + 1;
        return fits ? r : full;
    }
    readonly property var pages: ["welcome", "network", "zone", "you", "disk", "lock", "summary", "install", "done"]
    readonly property string pageName: pages[page]
    readonly property var keyboards: [
        { value: "us", en: "English (US)", es: "Inglés (EE. UU.)" },
        { value: "es", en: "Spanish", es: "Español" },
        { value: "gb", en: "English (UK)", es: "Inglés (Reino Unido)" },
        { value: "de", en: "German", es: "Alemán" },
        { value: "fr", en: "French", es: "Francés" },
        { value: "it", en: "Italian", es: "Italiano" },
        { value: "pt", en: "Portuguese", es: "Portugués" },
        { value: "latam", en: "Latin American", es: "Latinoamericano" }
    ]
    readonly property var reservedNames: ["root", "nobody", "messagebus", "polkituser", "sshd", "nscd", "dhcpcd", "uuidd", "tss",
        "greeter", "avahi", "rtkit", "ollama", "geoclue", "colord", "fwupd-refresh", "nm-openvpn", "nm-iodine"]

    property int page: 0
    property string lang: "en"
    property string layout: "us"
    property string startLayout: "us"
    property bool layoutTouched: false
    property bool otherLayout: false
    property string layoutFilter: ""

    property string media: "checking"
    property bool online: false
    property bool checking: false
    property bool scanning: false
    property bool wifi: true
    property var networks: []
    property string ssid: ""
    property bool secure: false
    property string wifiPassword: ""
    property bool joining: false
    property string joinError: ""

    property string zone: ""
    property var zones: []
    property string zoneFilter: ""

    property string fullName: ""
    property string user: ""
    property bool userTyped: false
    property string password: ""
    property string password2: ""
    property string host: "nihil"

    property var machine: null
    property bool probing: false
    property string probedLang: ""
    property string wanted: ""
    property int diskIndex: -1
    property string mode: ""
    property int roomIndex: -1
    property real roomBytes: 0
    property string rootPart: ""
    property string bootPart: ""

    property bool encrypt: false
    property string passphrase: ""
    property string passphrase2: ""

    property var steps: []
    property string logLine: ""
    property string lastError: ""
    property string failure: ""
    property bool installing: false

    readonly property var disk: machine && diskIndex >= 0 && diskIndex < machine.disks.length ? machine.disks[diskIndex] : null
    readonly property var roomOptions: {
        const out = [];
        if (!disk)
            return out;
        for (const free of disk.room.free)
            out.push({ kind: "free", first: free.first, max: free.bytes, fstype: "",
                       title: s("insFreeSpace"), detail: size(free.bytes) });
        for (const giver of disk.room.shrink)
            out.push({ kind: "shrink", part: giver.part, max: giver.give, fstype: giver.fstype,
                       title: s("insRoomIn").arg(giver.part),
                       detail: [giver.label, giver.fstype.toUpperCase()].filter(word => word !== "").join(", ") + ", " + s("insUpTo").arg(size(giver.give)) });
        return out;
    }
    readonly property var room: roomIndex >= 0 && roomIndex < roomOptions.length ? roomOptions[roomIndex] : null
    readonly property var amounts: {
        const out = [];
        if (!room || !disk)
            return out;
        for (const gb of [30, 50, 100, 200, 500])
            if (gb * 1e9 >= disk.need && gb * 1e9 < room.max)
                out.push(gb * 1e9);
        out.push(room.max);
        return out;
    }
    readonly property var boots: disk ? disk.part.boots.filter(part => part.path !== rootPart) : []
    readonly property bool userValid: /^[a-z_][a-z0-9_-]{0,31}$/.test(user) && reservedNames.indexOf(user) < 0
        && !/^(nixbld|systemd-)/.test(user)
    readonly property bool hostValid: /^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$/.test(host)
    readonly property var layoutMatches: {
        const find = plain(layoutFilter.trim());
        const out = [];
        for (const entry of Config.layouts) {
            if (find === "" ? entry.id === layout : entry.id.indexOf(find) === 0 || plain(entry.name).indexOf(find) >= 0)
                out.push(entry);
            if (out.length === 6)
                break;
        }
        return out;
    }
    readonly property var zoneMatches: {
        const find = plain(zoneFilter.trim()).replace(/ /g, "_");
        if (find === "")
            return zone !== "" ? [zone] : [];
        const out = [];
        for (const entry of zones) {
            if (entry.toLowerCase().indexOf(find) >= 0)
                out.push(entry);
            if (out.length === 8)
                break;
        }
        return out;
    }

    // The words are theme/i18n.nix's, as the text mode's and the shell's.
    property var strings: ({})

    function s(key: string): string {
        return (strings[lang] ?? {})[key] ?? (strings.en ?? {})[key] ?? key;
    }

    // With the language's decimal mark, as the shell writes sizes.
    function size(bytes: real): string {
        if (bytes >= 1e12)
            return (Math.round(bytes / 1e11) / 10).toLocaleString(Qt.locale(lang === "es" ? "es_ES" : "en_GB"), "f", 1) + " TB";
        if (bytes >= 1e9)
            return Math.round(bytes / 1e9) + " GB";
        return Math.round(bytes / 1e6) + " MB";
    }

    function plain(text: string): string {
        return text.toLowerCase().replace(/[áàâäã]/g, "a").replace(/[éèêë]/g, "e").replace(/[íìîï]/g, "i")
            .replace(/[óòôöõ]/g, "o").replace(/[úùûü]/g, "u").replace(/ñ/g, "n").replace(/ç/g, "c");
    }

    function fields(line: string): var {
        const out = [];
        let current = "";
        for (let i = 0; i < line.length; i++) {
            if (line[i] === "\\" && i + 1 < line.length) {
                current += line[++i];
            } else if (line[i] === ":") {
                out.push(current);
                current = "";
            } else {
                current += line[i];
            }
        }
        out.push(current);
        return out;
    }

    function keyboardName(id: string): string {
        const known = keyboards.find(entry => entry.value === id);
        if (known)
            return lang === "es" ? known.es : known.en;
        const listed = Config.layouts.find(entry => entry.id === id);
        return listed ? listed.name : id;
    }

    function describe(part: var): string {
        return [size(part.size), part.fstype.toUpperCase(), part.label].filter(word => word !== "").join(", ");
    }

    function consequence(): string {
        if (!disk)
            return "";
        if (mode === "whole")
            return s("insErased").arg(disk.path);
        if (mode === "room" && room && room.kind === "shrink")
            return s("insShrinkGives").arg(room.part).arg(size(roomBytes)).arg(disk.path) + " " + s("insShrinkSafe");
        if (mode === "room")
            return s("insFreeGoes").arg(size(roomBytes)).arg(disk.path);
        const formatted = rootPart + (bootPart !== "" ? ", " + bootPart : "");
        return s("insFormatted").arg(formatted).arg(disk.path);
    }

    function ready(name: string): bool {
        switch (name) {
        case "network":
            return online;
        case "zone":
            return zone !== "" && (zones.length === 0 || zones.indexOf(zone) >= 0);
        case "you":
            return userValid && password !== "" && password === password2 && hostValid;
        case "disk":
            if (probing || !machine || !machine.uefi || !disk)
                return false;
            if (mode === "whole")
                return true;
            if (mode === "room")
                return room !== null && roomBytes >= disk.need && roomBytes <= room.max;
            if (mode === "part")
                return rootPart !== "" && (!disk.part.bootNeeded || bootPart !== "");
            return false;
        case "lock":
            return !encrypt || (passphrase !== "" && passphrase === passphrase2);
        case "summary":
            return media === "ok" && root.ready("disk");
        default:
            return true;
        }
    }

    function go(next: int): void {
        page = Math.max(0, Math.min(pages.length - 1, next));
        scroller.contentY = 0;
        appear.restart();
        panel.forceActiveFocus();
        if (pageName === "network")
            check();
        if (page > 0 && page < pages.indexOf("install") && !probing && (machine === null || probedLang !== lang))
            probe();
        if (pageName === "zone")
            Qt.callLater(() => zoneField.grab());
        if (pageName === "you")
            Qt.callLater(() => nameEntry.grab());
    }

    // Scrolls just enough for an item of the page to be seen whole.
    function reveal(item: Item): void {
        const top = item.mapToItem(body, 0, 0).y;
        const bottom = top + item.height;
        if (bottom > scroller.contentY + scroller.height)
            scroller.contentY = Math.min(bottom - scroller.height + 16, Math.max(0, scroller.contentHeight - scroller.height));
        else if (top < scroller.contentY)
            scroller.contentY = Math.max(0, top - 16);
    }

    function forward(): void {
        if (pageName === "install" || !root.ready(pageName))
            return;
        if (pageName === "welcome" && layout !== startLayout) {
            leave({ next: "layout", page: 1, lang: lang, layout: layout, otherLayout: otherLayout, zone: zone,
                    fullName: fullName, user: user, userTyped: userTyped, host: host, encrypt: encrypt });
        } else if (pageName === "summary") {
            install();
        } else if (pageName === "done") {
            restarter.running = true;
        } else {
            go(page + 1);
        }
    }

    function leave(state: var): void {
        leaver.command = [Config.bash, "-c", "printf '%s' \"$1\" > \"$2\" && kill \"$PPID\"", "nihil-installer",
                          JSON.stringify(state), stateFile];
        leaver.running = true;
    }

    function restore(): void {
        let state = null;
        try {
            state = JSON.parse(saved.text());
        } catch (e) {
            return;
        }
        if (!state)
            return;
        layoutTouched = true;
        lang = state.lang === "es" ? "es" : "en";
        otherLayout = state.otherLayout === true;
        zone = state.zone ?? "";
        fullName = state.fullName ?? "";
        user = state.user ?? "";
        userTyped = state.userTyped === true;
        host = state.host ?? "nihil";
        encrypt = state.encrypt === true;
        if (state.page)
            go(state.page);
    }

    function pickLayout(value: string): void {
        layoutTouched = true;
        otherLayout = value === "other";
        if (!otherLayout)
            layout = value;
    }

    function check(): void {
        if (checking)
            return;
        checking = true;
        connectivity.running = true;
    }

    function scan(again: bool): void {
        if (scanning)
            return;
        scanning = true;
        wifiList.command = [Config.bash, "-c",
            "\"$1\" \"$2\" -t -f TYPE device; echo ---; \"$1\" \"$2\" -t -f IN-USE,SIGNAL,SECURITY,SSID device wifi list --rescan \"$3\"",
            "nihil-installer", Config.sudo, Config.nmcli, again ? "yes" : "auto"];
        wifiList.running = true;
    }

    function pickNetwork(net: var): void {
        // Chosen anew, even the same: its password row shows again, with the focus.
        ssid = "";
        secure = net.secure;
        wifiPassword = "";
        joinError = "";
        ssid = net.ssid;
        if (!secure)
            join();
    }

    function join(): void {
        if (ssid === "" || joining || (secure && wifiPassword === ""))
            return;
        joining = true;
        joinError = "";
        // The key goes through stdin, as nmcli asks for it: never in a command line, where ps and
        // sudo's journal would show it.
        joiner.input = secure ? wifiPassword + "\n" : "";
        joiner.command = secure
            ? [Config.bash, "-c", 'IFS= read -r key; printf "%s\\n" "$key" | "$1" "$2" --ask device wifi connect "$3"',
                "nihil-installer", Config.sudo, Config.nmcli, ssid]
            : [Config.sudo, Config.nmcli, "device", "wifi", "connect", ssid];
        joiner.running = true;
    }

    function probe(): void {
        if (disk)
            wanted = disk.path;
        probing = true;
        probedLang = lang;
        prober.command = [Config.sudo, Config.install, "probe", lang];
        prober.running = true;
    }

    function probed(text: string): void {
        probing = false;
        let result = null;
        try {
            result = JSON.parse(text);
        } catch (e) {}
        if (!result || !Array.isArray(result.disks)) {
            machine = { uefi: true, disks: [], failed: true };
            chooseDisk(-1);
            return;
        }
        machine = result;
        let index = result.disks.findIndex(entry => entry.path === wanted);
        if (index < 0 && result.disks.length === 1)
            index = 0;
        chooseDisk(index);
    }

    function chooseDisk(index: int): void {
        diskIndex = index;
        pickMode("");
    }

    function pickMode(name: string): void {
        mode = name;
        roomIndex = -1;
        roomBytes = 0;
        rootPart = "";
        bootPart = "";
        if (name === "room" && roomOptions.length === 1)
            pickRoom(0);
    }

    function pickRoom(index: int): void {
        roomIndex = index;
        if (amounts.length === 0) {
            roomBytes = 0;
        } else if (room.kind === "free") {
            roomBytes = amounts[amounts.length - 1];
        } else {
            const presets = amounts.slice(0, -1).filter(amount => amount <= 100e9);
            roomBytes = presets.length > 0 ? presets[presets.length - 1] : amounts[amounts.length - 1];
        }
    }

    function checkFilesystem(part: string): void {
        if (probing)
            return;
        if (disk)
            wanted = disk.path;
        probing = true;
        checker.command = [Config.sudo, Config.install, "check-filesystem", part];
        checker.running = true;
    }

    function nameEdited(text: string): void {
        // Without «:» or line breaks: the system refuses them in a name, after the disk is formatted.
        fullName = text.replace(/[:\r\n]/g, "");
        if (!userTyped)
            user = plain(text.trim().split(/\s+/)[0]).replace(/[^a-z0-9_-]/g, "");
    }

    function answers(): var {
        const out = {
            language: lang, layout: layout, zone: zone, fullName: fullName, user: user, password: password, host: host,
            disk: disk.path, mode: mode, encrypt: encrypt, passphrase: encrypt ? passphrase : ""
        };
        if (mode === "room")
            out.room = room.kind === "free" ? { kind: "free", first: room.first, bytes: roomBytes }
                                            : { kind: "shrink", part: room.part, bytes: roomBytes };
        if (mode === "part") {
            out.root = rootPart;
            if (disk.part.bootNeeded)
                out.boot = bootPart;
        }
        return out;
    }

    function install(): void {
        steps = [];
        logLine = "";
        lastError = "";
        failure = "";
        installing = true;
        go(pages.indexOf("install"));
        installer.running = true;
    }

    function retry(): void {
        failure = "";
        machine = null;
        go(pages.indexOf("disk"));
    }

    function handle(line: string): void {
        let event = null;
        try {
            event = JSON.parse(line);
        } catch (e) {
            return;
        }
        if (event.kind === "step")
            steps = steps.concat([event.text]);
        else if (event.kind === "log")
            logLine = event.text;
        else if (event.kind === "error")
            lastError = event.text;
    }

    onLangChanged: {
        if (!layoutTouched)
            layout = lang === "es" ? "es" : "us";
    }

    Component.onCompleted: {
        try {
            strings = JSON.parse(words.text());
        } catch (e) {}
        startLayout = Quickshell.env("XKB_DEFAULT_LAYOUT") || "us";
        layout = startLayout;
        restore();
        mediaCheck.running = true;
        zoneList.running = true;
    }

    component Option: Item {
        id: option

        property string title: ""
        property string detail: ""
        property bool chosen: false
        property bool active: true

        signal picked()

        function press(event: var): void {
            if (option.active && !event.isAutoRepeat)
                option.picked();
        }

        width: parent ? parent.width : 0
        implicitHeight: 44
        opacity: active ? 1 : 0.4
        activeFocusOnTab: active

        Accessible.role: Accessible.RadioButton
        Accessible.name: option.detail !== "" ? option.title + ", " + option.detail : option.title
        Accessible.checkable: true
        Accessible.checked: option.chosen
        Accessible.onPressAction: {
            if (option.active)
                option.picked();
        }
        Keys.onReturnPressed: event => option.press(event)
        Keys.onEnterPressed: event => option.press(event)
        Keys.onSpacePressed: event => option.press(event)

        Surface {
            anchors.fill: parent
            radius: 10
            color: option.chosen || (area.containsMouse && option.active) ? Tokens.surface : "transparent"
            border.width: 1
            border.color: option.chosen ? Tokens.line : "transparent"
        }

        Txt {
            anchors.left: parent.left
            anchors.leftMargin: 16
            anchors.right: info.left
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            text: option.title
            color: option.chosen ? Tokens.ink : Tokens.dim
        }

        Label {
            id: info
            anchors.right: parent.right
            anchors.rightMargin: 16
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, option.width * 0.55)
            horizontalAlignment: Text.AlignRight
            text: option.detail
        }

        FocusRing {
            round: 10
        }

        MouseArea {
            id: area
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: option.active ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (option.active)
                    option.picked();
            }
        }
    }

    // Only what went wrong has a dot before it, red, as in the shell.
    component Note: Item {
        id: note

        property string text: ""
        property bool alarm: false
        property color tint: alarm ? Tokens.ink : Tokens.dim

        width: parent ? parent.width : 0
        implicitHeight: words.implicitHeight

        Rectangle {
            visible: note.alarm
            y: 6
            width: 6
            height: 6
            radius: 3
            color: Tokens.interrupt
        }

        Txt {
            id: words
            x: note.alarm ? 18 : 0
            width: note.width - x
            text: note.text
            color: note.tint
            wrapMode: Text.WordWrap
            elide: Text.ElideNone
            verticalAlignment: Text.AlignTop
        }
    }

    component Entry: Column {
        id: entry

        property string label: ""
        property alias value: input.value
        property alias placeholder: input.placeholder
        property alias password: input.password
        property alias invalid: input.invalid

        signal edited(string text)
        signal accepted()

        function grab(): void { input.grab(); }

        width: parent ? parent.width : 0
        spacing: 8

        Label {
            text: entry.label
        }

        Field {
            id: input
            width: parent.width
            onEdited: text => entry.edited(text)
            onAccepted: entry.accepted()
        }
    }

    FileView {
        id: words
        path: "/etc/nihil/strings.json"
        blockLoading: true
    }

    FileView {
        id: saved
        path: root.stateFile
        blockLoading: true
        printErrors: false
    }

    Process {
        id: leaver
    }

    Process {
        id: announce
        command: [Config.touch, Quickshell.env("NIHIL_INSTALLER_READY") || "/dev/null"]
    }

    Process {
        id: mediaCheck
        command: [Config.sudo, Config.install, "check-media"]
        onExited: code => root.media = code === 0 ? "ok" : "bad"
    }

    Process {
        id: connectivity
        command: [Config.curl, "-fsI", "--max-time", "6", "https://cache.nixos.org"]
        onExited: code => {
            root.checking = false;
            root.online = code === 0;
            if (root.online && root.zone === "")
                zoneGuess.running = true;
            if (!root.online && root.networks.length === 0)
                root.scan(false);
        }
    }

    Process {
        id: zoneGuess
        command: [Config.curl, "-fs", "--max-time", "6", "https://ipapi.co/timezone"]
        stdout: StdioCollector {
            onStreamFinished: {
                const guess = text.trim();
                if (root.zone === "" && /^[A-Za-z]+(\/[A-Za-z0-9_+-]+)+$/.test(guess))
                    root.zone = guess;
            }
        }
    }

    Process {
        id: zoneList
        command: [Config.timedatectl, "list-timezones"]
        stdout: StdioCollector {
            onStreamFinished: root.zones = text.split("\n").filter(entry => entry !== "")
        }
    }

    Process {
        id: wifiList
        stdout: StdioCollector {
            onStreamFinished: {
                root.scanning = false;
                // At the first line that says only ---: the networks come after it, and an SSID can
                // hold anything, --- too.
                const lines = text.split("\n");
                const at = lines.indexOf("---");
                root.wifi = (at >= 0 ? lines.slice(0, at) : lines).indexOf("wifi") >= 0;
                const best = Object.create(null);
                for (const line of (at >= 0 ? lines.slice(at + 1) : [])) {
                    const f = root.fields(line);
                    if (f.length < 4 || f[3] === "")
                        continue;
                    const net = { ssid: f[3], signal: parseInt(f[1]) || 0, secure: f[2] !== "" && f[2] !== "--" };
                    if (!best[net.ssid] || best[net.ssid].signal < net.signal)
                        best[net.ssid] = net;
                }
                root.networks = Object.keys(best).map(name => best[name]).sort((a, b) => b.signal - a.signal).slice(0, 8);
            }
        }
    }

    Process {
        id: joiner

        property string input: ""

        stdinEnabled: true
        onStarted: {
            write(input);
            input = "";
            stdinEnabled = false;
        }
        // nmcli's words in the user's: the usual ones said plainly, any other after what happened.
        stderr: StdioCollector {
            onStreamFinished: {
                const lines = text.trim().split("\n").filter(line => line !== "");
                const said = lines.length > 0 ? lines[lines.length - 1].replace(/^Error: */, "") : "";
                root.joinError = said === "" ? ""
                    : /Secrets were required|wrong password|password.*incorrect/i.test(said) ? root.s("insWrongKey")
                    : /psk: property is invalid/i.test(said) ? root.s("insShortKey")
                    : /No network with SSID/i.test(said) ? root.s("insOutOfRange")
                    : root.s("insNotConnected") + " (" + said + ")";
            }
        }
        onExited: code => {
            stdinEnabled = true;
            root.joining = false;
            if (code === 0) {
                root.joinError = "";
                root.wifiPassword = "";
                root.check();
            } else if (root.joinError === "") {
                root.joinError = root.s("insNotConnected");
            }
        }
    }

    Process {
        id: prober
        stdout: StdioCollector {
            onStreamFinished: root.probed(text)
        }
    }

    Process {
        id: checker
        onExited: {
            root.probing = false;
            root.probe();
        }
    }

    Process {
        id: installer
        command: [Config.sudo, Config.install, "apply"]
        stdinEnabled: true
        stdout: SplitParser {
            onRead: data => root.handle(data)
        }
        onStarted: installer.write(JSON.stringify(root.answers()) + "\n")
        onExited: code => {
            root.installing = false;
            if (code === 0)
                root.go(root.pages.indexOf("done"));
            else
                root.failure = root.lastError !== "" ? root.lastError : root.s("insStoppedHere");
        }
    }

    Process {
        id: restarter
        command: [Config.sudo, Config.install, "finish"]
    }

    Timer {
        interval: 4000
        repeat: true
        running: root.pageName === "network" && !root.online && !root.joining
        onTriggered: root.check()
    }

    FloatingWindow {
        id: window

        title: "NIHIL"
        color: Tokens.black
        fullscreen: true
        visible: true

        Component.onCompleted: announce.running = true

        Canvas {
            anchors.fill: parent
            onWidthChanged: requestPaint()
            onHeightChanged: requestPaint()
            onPaint: {
                const ctx = getContext("2d");
                ctx.reset();
                ctx.fillStyle = String(Tokens.raised);
                for (let y = 4.5; y < height; y += 9) {
                    ctx.beginPath();
                    for (let x = 4.5; x < width; x += 9) {
                        ctx.moveTo(x + 1.15, y);
                        ctx.arc(x, y, 1.15, 0, 2 * Math.PI);
                    }
                    ctx.fill();
                }
            }
        }

        Item {
            id: panel

            // Enter goes on and Escape back, as the buttons below; a control with the focus
            // answers for itself, and a field keeps its Enter.
            focus: true
            Keys.onReturnPressed: event => {
                if (panel.activeFocus && !event.isAutoRepeat)
                    root.forward();
                else
                    event.accepted = false;
            }
            Keys.onEnterPressed: event => {
                if (panel.activeFocus && !event.isAutoRepeat)
                    root.forward();
                else
                    event.accepted = false;
            }
            Keys.onEscapePressed: {
                if (root.page > 0 && root.page < root.pages.indexOf("install"))
                    root.go(root.page - 1);
            }

            x: root.area.x + (root.area.width - width) / 2
            y: root.area.y + (root.area.height - height) / 2
            width: Math.min(720, root.area.width - 48)
            height: Math.min(660, root.area.height - 48)

            Rectangle {
                anchors.fill: parent
                radius: Tokens.drawerRadius
                color: Tokens.black
            }

            Logo {
                id: mark
                x: 40
                y: 30
                size: 24
            }

            Row {
                anchors.right: parent.right
                anchors.rightMargin: 40
                anchors.verticalCenter: mark.verticalCenter
                spacing: 7

                Repeater {
                    model: 7

                    Rectangle {
                        required property int index

                        width: 6
                        height: 6
                        radius: 3
                        color: index <= root.page ? Tokens.ink : Tokens.off

                        Behavior on color { ColorAnimation { duration: Tokens.animNormal } }
                    }
                }
            }

            Flickable {
                id: scroller

                anchors.fill: parent
                anchors.topMargin: 96
                anchors.bottomMargin: 100
                anchors.leftMargin: 40
                anchors.rightMargin: 40
                contentHeight: body.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                Column {
                    id: body

                    width: scroller.width
                    spacing: 16

                    Column {
                        width: parent.width
                        spacing: 28
                        visible: root.pageName === "welcome"

                        DotText {
                            text: root.s("insHello")
                            font.pixelSize: 34
                        }

                        Column {
                            width: parent.width
                            spacing: 8

                            Label {
                                text: root.s("insLanguage")
                            }

                            Choice {
                                width: parent.width
                                label: root.s("insLanguage")
                                options: [{ label: "English", value: "en" }, { label: "Español", value: "es" }]
                                value: root.lang
                                onPicked: value => root.lang = value
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 8

                            Label {
                                text: root.s("insKeyboard")
                            }

                            Choice {
                                width: parent.width
                                label: root.s("insKeyboard")
                                options: root.keyboards.map(entry => ({ label: root.lang === "es" ? entry.es : entry.en, value: entry.value }))
                                    .concat(Config.layouts.length > 0 ? [{ label: root.s("insOther"), value: "other" }] : [])
                                value: root.otherLayout ? "other" : root.layout
                                onPicked: value => root.pickLayout(value)
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 6
                            visible: root.otherLayout

                            Field {
                                width: parent.width
                                placeholder: root.s("insSearch")
                                onEdited: text => root.layoutFilter = text
                            }

                            Repeater {
                                model: root.layoutMatches

                                Option {
                                    required property var modelData

                                    title: modelData.name
                                    detail: modelData.id.toUpperCase()
                                    chosen: root.layout === modelData.id
                                    onPicked: root.layout = modelData.id
                                }
                            }
                        }

                        Note {
                            visible: root.media === "bad"
                            alarm: true
                            text: root.s("insUsbBad")
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 16
                        visible: root.pageName === "network"

                        DotText {
                            text: root.s("insNetwork")
                            font.pixelSize: 34
                        }

                        Txt {
                            visible: root.online
                            text: root.s("insConnected")
                            color: Tokens.ink
                        }

                        Note {
                            visible: !root.online && !root.wifi
                            text: root.s("insNoWifi")
                        }

                        // The password goes right under its network, where it was chosen, and in sight.
                        Column {
                            width: parent.width
                            spacing: 4
                            visible: !root.online && root.wifi

                            Repeater {
                                model: root.networks

                                Column {
                                    id: net

                                    required property var modelData
                                    readonly property bool chosen: root.ssid === modelData.ssid

                                    width: parent.width
                                    spacing: 8
                                    bottomPadding: net.chosen && (key.visible || failed.visible) ? 8 : 0

                                    Option {
                                        title: net.modelData.ssid
                                        detail: net.chosen && root.joining ? root.s("insConnecting") : root.s("percent").arg(net.modelData.signal)
                                        chosen: net.chosen
                                        onPicked: root.pickNetwork(net.modelData)
                                    }

                                    Row {
                                        id: key

                                        visible: net.chosen && root.secure
                                        x: 16
                                        spacing: 10

                                        onVisibleChanged: {
                                            if (visible)
                                                Qt.callLater(() => {
                                                    keyField.grab();
                                                    root.reveal(net);
                                                });
                                        }

                                        Field {
                                            id: keyField
                                            width: net.width - 16 - 10 - connect.width
                                            password: true
                                            placeholder: root.s("insPassword")
                                            value: root.wifiPassword
                                            onEdited: text => root.wifiPassword = text
                                            onAccepted: root.join()
                                        }

                                        KeyButton {
                                            id: connect
                                            height: 36
                                            accent: true
                                            enabled: !root.joining && root.wifiPassword !== ""
                                            opacity: enabled ? 1 : 0.35
                                            text: root.joining ? root.s("insConnecting") : root.s("insConnect")
                                            onClicked: root.join()
                                        }
                                    }

                                    Note {
                                        id: failed
                                        visible: net.chosen && root.joinError !== ""
                                        alarm: true
                                        text: root.joinError
                                    }
                                }
                            }
                        }

                        KeyButton {
                            visible: !root.online
                            height: 36
                            enabled: !root.scanning
                            opacity: enabled ? 1 : 0.35
                            text: root.scanning ? root.s("insLooking") : root.s("insLookAgain")
                            onClicked: {
                                root.scan(true);
                                root.check();
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 16
                        visible: root.pageName === "zone"

                        DotText {
                            text: root.s("insZone")
                            font.pixelSize: 34
                        }

                        Field {
                            id: zoneField
                            width: parent.width
                            placeholder: root.s("cfgTimeZoneSub")
                            onEdited: text => root.zoneFilter = text
                            onAccepted: {
                                if (root.zoneMatches.length > 0 && root.zone !== root.zoneMatches[0])
                                    root.zone = root.zoneMatches[0];
                                else
                                    root.forward();
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 4

                            Repeater {
                                model: root.zoneMatches

                                Option {
                                    required property var modelData

                                    title: modelData.split("/").pop().replace(/_/g, " ")
                                    detail: modelData.replace(/_/g, " ")
                                    chosen: root.zone === modelData
                                    onPicked: root.zone = modelData
                                }
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 14
                        visible: root.pageName === "you"

                        DotText {
                            text: root.s("insYou")
                            font.pixelSize: 34
                        }

                        Entry {
                            id: nameEntry
                            label: root.s("insYourName")
                            placeholder: "Ada Lovelace"
                            value: root.fullName
                            onEdited: text => root.nameEdited(text)
                        }

                        Entry {
                            label: root.s("insUserName")
                            value: root.user
                            invalid: root.user !== "" && !root.userValid
                            onEdited: text => {
                                root.user = text;
                                root.userTyped = true;
                            }
                        }

                        Note {
                            visible: root.user !== "" && !root.userValid
                            alarm: true
                            text: root.s("insUserRule")
                        }

                        Entry {
                            label: root.s("insPassword")
                            password: true
                            value: root.password
                            onEdited: text => root.password = text
                        }

                        Entry {
                            label: root.s("insPasswordAgain")
                            password: true
                            value: root.password2
                            invalid: root.password2 !== "" && root.password2 !== root.password
                            onEdited: text => root.password2 = text
                        }

                        Entry {
                            label: root.s("cfgHost")
                            value: root.host
                            invalid: !root.hostValid
                            onEdited: text => root.host = text
                            onAccepted: root.forward()
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 14
                        visible: root.pageName === "disk"

                        DotText {
                            text: root.s("insWhere")
                            font.pixelSize: 34
                        }

                        Txt {
                            visible: root.probing
                            text: root.s("insLookingDisks")
                            color: Tokens.dim
                        }

                        Note {
                            visible: !root.probing && root.machine !== null && !root.machine.uefi
                            alarm: true
                            text: root.s("insNeedsUefi")
                        }

                        Note {
                            visible: !root.probing && root.machine !== null && root.machine.disks.length === 0
                            alarm: true
                            text: root.machine && root.machine.failed ? root.s("insDisksUnread")
                                : root.s("insNoDisk")
                        }

                        Column {
                            width: parent.width
                            spacing: 4
                            visible: !root.probing

                            Repeater {
                                model: root.machine ? root.machine.disks : []

                                Option {
                                    required property var modelData
                                    required property int index

                                    title: modelData.model !== "" ? modelData.model : modelData.path
                                    detail: [modelData.path, root.size(modelData.size)].concat(modelData.windows ? ["Windows"] : []).join(", ")
                                    chosen: root.diskIndex === index
                                    onPicked: {
                                        if (root.diskIndex !== index)
                                            root.chooseDisk(index);
                                    }
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 4
                            visible: !root.probing && root.disk !== null

                            Label {
                                text: root.disk ? root.disk.path : ""
                                topPadding: 8
                                bottomPadding: 6
                            }

                            Option {
                                title: root.s("insNextTo")
                                active: root.roomOptions.length > 0
                                chosen: root.mode === "room"
                                onPicked: {
                                    if (root.mode !== "room")
                                        root.pickMode("room");
                                }
                            }

                            Option {
                                title: root.s("insWhole")
                                chosen: root.mode === "whole"
                                onPicked: {
                                    if (root.mode !== "whole")
                                        root.pickMode("whole");
                                }
                            }

                            Option {
                                title: root.s("insOnPartition")
                                active: root.disk !== null && root.disk.part.roots.length > 0
                                chosen: root.mode === "part"
                                onPicked: {
                                    if (root.mode !== "part")
                                        root.pickMode("part");
                                }
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 4
                            visible: !root.probing && root.mode === "room"

                            Repeater {
                                model: root.roomOptions

                                Option {
                                    required property var modelData
                                    required property int index

                                    title: modelData.title
                                    detail: modelData.detail
                                    chosen: root.roomIndex === index
                                    onPicked: {
                                        if (root.roomIndex !== index)
                                            root.pickRoom(index);
                                    }
                                }
                            }

                            Label {
                                visible: root.room !== null
                                text: root.s("insRoomFor")
                                topPadding: 10
                                bottomPadding: 6
                            }

                            Choice {
                                visible: root.room !== null
                                width: parent.width
                                label: root.s("insRoomFor")
                                options: root.room ? root.amounts.map(amount => ({
                                    label: amount === root.room.max ? root.s("insAllOfIt").arg(root.size(amount)) : root.size(amount),
                                    value: amount
                                })) : []
                                value: root.roomBytes
                                onPicked: value => root.roomBytes = value
                            }
                        }

                        Column {
                            width: parent.width
                            spacing: 4
                            visible: !root.probing && root.mode === "part"

                            Label {
                                text: root.s("insGoesOn")
                                topPadding: 8
                                bottomPadding: 6
                            }

                            Repeater {
                                model: root.disk ? root.disk.part.roots : []

                                Option {
                                    required property var modelData

                                    title: modelData.path
                                    detail: root.describe(modelData)
                                    chosen: root.rootPart === modelData.path
                                    onPicked: {
                                        root.rootPart = modelData.path;
                                        if (root.bootPart === modelData.path)
                                            root.bootPart = "";
                                    }
                                }
                            }

                            Label {
                                visible: root.disk !== null && root.disk.part.bootNeeded
                                text: root.s("insBootPartition")
                                topPadding: 10
                                bottomPadding: 6
                            }

                            Repeater {
                                model: root.disk && root.disk.part.bootNeeded ? root.boots : []

                                Option {
                                    required property var modelData

                                    title: modelData.path
                                    detail: root.describe(modelData)
                                    chosen: root.bootPart === modelData.path
                                    onPicked: root.bootPart = modelData.path
                                }
                            }

                            Note {
                                visible: root.disk !== null && root.disk.part.bootNeeded && root.boots.length === 0
                                alarm: true
                                text: root.s("insNeedsBoot")
                            }

                        }

                        Repeater {
                            model: !root.probing && root.disk ? root.disk.notes : []

                            Note {
                                required property var modelData

                                text: modelData
                            }
                        }

                        Flow {
                            width: parent.width
                            spacing: 10

                            Repeater {
                                model: !root.probing && root.disk ? root.disk.room.unchecked : []

                                KeyButton {
                                    required property var modelData

                                    height: 36
                                    text: root.s("insCheckPart").arg(modelData)
                                    onClicked: Qt.callLater(root.checkFilesystem, modelData)
                                }
                            }

                            KeyButton {
                                visible: !root.probing
                                height: 36
                                text: root.s("insLookAgain")
                                onClicked: root.probe()
                            }
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 14
                        visible: root.pageName === "lock"

                        DotText {
                            text: root.s("insEncryption")
                            font.pixelSize: 34
                        }

                        Column {
                            width: parent.width
                            spacing: 4

                            Option {
                                title: root.s("insNoEncrypt")
                                chosen: !root.encrypt
                                onPicked: root.encrypt = false
                            }

                            Option {
                                title: root.s("insEncryptDisk")
                                chosen: root.encrypt
                                onPicked: root.encrypt = true
                            }
                        }

                        Entry {
                            visible: root.encrypt
                            label: root.s("insPassphrase")
                            password: true
                            value: root.passphrase
                            onEdited: text => root.passphrase = text
                        }

                        Entry {
                            visible: root.encrypt
                            label: root.s("insPassphraseAgain")
                            password: true
                            value: root.passphrase2
                            invalid: root.passphrase2 !== "" && root.passphrase2 !== root.passphrase
                            onEdited: text => root.passphrase2 = text
                            onAccepted: root.forward()
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 14
                        visible: root.pageName === "summary"

                        DotText {
                            text: root.s("insReady")
                            font.pixelSize: 34
                        }

                        Column {
                            width: parent.width
                            spacing: 10

                            Repeater {
                                model: [
                                    [root.s("insLanguage"), root.lang === "es" ? "Español" : "English"],
                                    [root.s("insKeyboard"), root.keyboardName(root.layout)],
                                    [root.s("insZone"), root.zone],
                                    [root.s("insUser"), root.fullName !== "" ? root.user + ", " + root.fullName : root.user],
                                    [root.s("cfgHost"), root.host],
                                    [root.s("insDisk"), root.disk ? root.disk.path : ""],
                                    [root.s("insEncryption"), root.encrypt ? root.s("insYes") : root.s("insNo")]
                                ]

                                Item {
                                    required property var modelData

                                    width: body.width
                                    height: 22

                                    Label {
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: 160
                                        text: modelData[0]
                                    }

                                    Txt {
                                        x: 160
                                        anchors.verticalCenter: parent.verticalCenter
                                        width: parent.width - 160
                                        text: modelData[1]
                                    }
                                }
                            }
                        }

                        Item {
                            width: 1
                            height: 4
                        }

                        Note {
                            alarm: true
                            text: root.consequence()
                        }

                        Note {
                            visible: root.mode === "room" && root.room !== null && root.room.fstype === "ntfs"
                            text: root.s("insWindowsCheck")
                        }

                        Note {
                            visible: root.disk !== null && root.disk.windows && root.mode !== "whole"
                            text: root.s("insBitLocker")
                        }

                        Note {
                            visible: root.disk !== null && (root.disk.elsewhere ?? "") !== "" && !(root.disk.windows && root.mode !== "whole")
                            text: root.disk ? root.s("insWindowsElsewhere").arg(root.disk.elsewhere) : ""
                        }

                        Note {
                            visible: root.media === "checking"
                            text: root.s("insCheckingUsb")
                        }

                        Note {
                            visible: root.media === "bad"
                            alarm: true
                            text: root.s("insUsbBad")
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 12
                        visible: root.pageName === "install"

                        DotText {
                            text: root.failure !== "" ? root.s("insStoppedTitle") : root.s("insInstalling")
                            font.pixelSize: 34
                        }

                        Repeater {
                            model: root.steps

                            Item {
                                id: step

                                required property var modelData
                                required property int index
                                readonly property bool current: index === root.steps.length - 1 && root.installing

                                width: parent.width
                                implicitHeight: line.implicitHeight

                                Txt {
                                    id: line
                                    width: parent.width
                                    opacity: step.current ? glow.value : 1
                                    color: step.current ? Tokens.ink : Tokens.dim
                                    wrapMode: Text.WordWrap
                                    elide: Text.ElideNone
                                    text: step.modelData
                                }
                            }
                        }

                        Label {
                            width: parent.width
                            visible: root.installing && root.logLine !== ""
                            text: root.logLine
                            elide: Text.ElideMiddle
                        }

                        Note {
                            visible: root.failure !== ""
                            alarm: true
                            text: root.failure + " " + root.s("insLog")
                        }
                    }

                    Column {
                        width: parent.width
                        spacing: 16
                        visible: root.pageName === "done"

                        DotText {
                            text: root.s("insInstalled")
                            font.pixelSize: 34
                        }

                        Txt {
                            width: parent.width
                            text: root.s("insTakeUsb")
                            color: Tokens.dim
                            wrapMode: Text.WordWrap
                            elide: Text.ElideNone
                        }
                    }
                }
            }

            Label {
                anchors.left: parent.left
                anchors.leftMargin: 40
                anchors.verticalCenter: keys.verticalCenter
                visible: root.pageName === "welcome"
                text: Tokens.motto
                color: Tokens.off
                font.italic: true
                font.pixelSize: 12
            }

            Row {
                id: keys

                anchors.right: parent.right
                anchors.rightMargin: 40
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 36
                spacing: 10

                KeyButton {
                    visible: root.pageName === "install" && root.failure !== ""
                    height: 36
                    text: root.s("insTextInstaller")
                    onClicked: root.leave({ next: "text" })
                }

                KeyButton {
                    visible: root.pageName === "install" && root.failure !== ""
                    height: 36
                    accent: true
                    text: root.s("insTryAgain")
                    onClicked: root.retry()
                }

                KeyButton {
                    visible: root.page > 0 && root.page < root.pages.indexOf("install")
                    height: 36
                    text: root.s("insBack")
                    onClicked: root.go(root.page - 1)
                }

                KeyButton {
                    visible: root.pageName !== "install"
                    height: 36
                    accent: true
                    enabled: root.ready(root.pageName)
                    opacity: enabled ? 1 : 0.35
                    text: root.pageName === "summary" ? root.s("insInstall")
                        : root.pageName === "done" ? root.s("insRestart")
                        : root.s("insContinue")
                    onClicked: root.forward()
                }
            }

            NumberAnimation {
                id: appear
                target: body
                property: "opacity"
                from: 0
                to: 1
                duration: Tokens.animNormal
                easing.type: Easing.OutCubic
            }
        }

        QtObject {
            id: glow

            property real value: 1
        }

        SequentialAnimation {
            running: root.installing
            loops: Animation.Infinite

            NumberAnimation { target: glow; property: "value"; to: 0.4; duration: 700; easing.type: Easing.InOutSine }
            NumberAnimation { target: glow; property: "value"; to: 1; duration: 700; easing.type: Easing.InOutSine }
        }
    }
}
