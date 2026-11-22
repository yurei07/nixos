pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import qs.theme
import qs.config

Singleton {
    id: root

    readonly property bool enabled: Config.nilo.enabled

    property bool wanted: false
    property bool ready: false
    property bool known: false
    property var queued: []
    property int restarts: 0
    property bool failed: false         // the agent kept closing: it waits for retry()
    property int exitCode: 0

    property var settings: ({})
    property var models: []
    property string recommended: ""
    property string fast: ""
    property string inUse: ""             // the model of the latest answer
    property real ramGB: 0
    property bool ollama: true

    property var service: ({})
    readonly property bool startingOllama: service.starting === true

    property var repos: []

    property bool loaded: false
    property bool loading: false
    property real expires: 0
    property real sizeGB: 0
    property int gpu: 0

    readonly property ListModel messages: ListModel {}
    property bool busy: false
    property string phase: "idle"
    property string tool: ""
    property var confirm: null
    // A card shows this much at first; what's beyond it has to be seen before it can be confirmed.
    readonly property int cardLines: 80
    readonly property int cardFiles: 8
    readonly property int cardChars: 800
    property bool confirmAll: false
    readonly property bool confirmHides: confirm !== null && !confirmAll
        && ((confirm.diff ?? []).length > cardLines || (confirm.files ?? []).length > cardFiles
            || String(confirm.text ?? "").length > cardChars)
    property bool stopping: false
    property int pulse: 0
    property string mood: ""

    property var pull: null
    property var asides: []

    property bool shown: false
    property bool summon: false
    property bool gear: false
    signal summoned()

    property bool behind: false
    property bool roaming: false
    property bool peeking: false
    property string peekKind: ""        // done, confirm or error
    property string peekScreen: ""
    property string peekQuestion: ""
    property string peekText: ""
    property var peekFacts: ({})

    onShownChanged: {
        if (shown) {
            behind = false;
            roaming = false;
            unpeek();
            Notifs.dismissTag("nilo");
        } else if (busy) {
            behind = true;
        }
    }

    readonly property bool onboarded: settings.onboarded === true
    readonly property var current: models.find(m => m.tag === settings.model) ?? null
    readonly property bool installed: current?.installed === true
    // The agent's own words are English: shown as they are only to a chat in English.
    readonly property bool english: Lang.locale.startsWith("en")

    function start(): void {
        if (!enabled || wanted) return;
        wanted = true;
        agent.running = true;
    }

    function retry(): void {
        failed = false;
        restarts = 0;
        wanted = false;
        start();
    }

    function send(request: var): void {
        if (!enabled) return;
        start();
        if (agent.running && ready) agent.write(JSON.stringify(request) + "\n");
        else queued = queued.concat([request]);
    }

    function open(): void {
        start();
        summon = true;
        if (Drawers.current === "launcher") summoned();
        else Drawers.open("launcher", "", false);
    }

    function toggle(): void {
        if (shown && Drawers.current === "launcher") Drawers.close();
        else open();
    }

    function openSettings(): void {
        gear = true;
        open();
    }

    function barScreen(): string {
        const focused = Hyprland.focusedMonitor?.name ?? "";
        const bars = Config.barOutputs;
        if (bars.indexOf(focused) >= 0) return focused;
        return bars.indexOf(Config.primaryOutput) >= 0 ? Config.primaryOutput : (bars[0] ?? focused);
    }

    function latest(kind: string): var {
        for (let i = messages.count - 1; i >= 0; i--) {
            const m = messages.get(i);
            if (m.kind === kind) return m;
            if (m.kind === "user") break;
        }
        return null;
    }

    function plain(text: string): string {
        return String(text ?? "")
            .replace(/```[\s\S]*?```/g, " … ")
            .replace(/\[([^\]\n]+)\]\([^)\s]+\)/g, "$1")
            .replace(/[*_`#>]/g, "")
            .replace(/\s+/g, " ")
            .trim();
    }

    function confirmText(c: var): string {
        if (!c) return "";
        if (c.action === "desktop") return desktopText(c);
        if (c.action === "run" || c.action === "terminal") return "$ " + (c.command ?? "");
        if (c.action === "edit" || c.action === "create")
            return (c.action === "create" ? Lang.confirmCreate : Lang.confirmEdit) + " " + (c.path ?? "");
        return c.message ? "git commit: " + c.message : "git " + (c.action === "push" ? Lang.confirmPush : Lang.confirmCommit);
    }

    function desktopText(c: var): string {
        switch (c.what) {
        case "type": return Lang.confirmType.arg(c.app ?? "") + ": " + plain(c.text ?? "");
        case "keys": return Lang.confirmKeys.arg(c.app ?? "") + ": " + (c.keys ?? "");
        case "send": return Lang.confirmSend + ": " + (c.path ?? plain(c.text ?? ""));
        case "search": return Lang.confirmSearch + ": " + plain(c.text ?? "");
        case "fetch": return Lang.confirmFetch + ": " + (c.text ?? "");
        case "open": return Lang.confirmOpenUrl + ": " + (c.text ?? "");
        }
        return "";
    }

    function amount(text: string, now: real): real {
        const t = String(text ?? "").trim().toLowerCase();
        if (t === "up") return now + 0.1;
        if (t === "down") return now - 0.1;
        const m = t.match(/^([+-]?)(\d+(?:[.,]\d+)?)\s*%?$/);
        if (!m) return NaN;
        const n = parseFloat(m[2].replace(",", ".")) / 100;
        return Math.max(0, Math.min(1, m[1] === "+" ? now + n : m[1] === "-" ? now - n : n));
    }

    function flag(text: string, now: bool): var {
        const t = String(text ?? "").trim().toLowerCase();
        if (t === "" || t === "toggle") return !now;
        if (["on", "true", "1", "yes", "sí", "si"].includes(t)) return true;
        if (["off", "false", "0", "no"].includes(t)) return false;
        return null;
    }

    function control(setting: string, value: string, id: string): var {
        const t = String(value ?? "").trim();
        const word = t.toLowerCase();
        if (setting === "night" && /^[+-]?\d/.test(word)) {
            const v = amount(word, Toggles.nightLevel);
            if (isNaN(v)) return { ok: false, error: "night takes on, off or a strength from 0 to 100" };
            Toggles.setNightLevel(v);
            return { ok: true, value: String(Math.round(v * 100)) };
        }
        if (setting === "wifi" && word === "disconnect") {
            if (!Network.ssid) return { ok: false, error: "there is no Wi-Fi network to leave" };
            Network.disconnect();
            return { ok: true, value: Network.ssid };
        }
        if (setting === "wifi" && flag(word, false) === null) {
            Network.join(t, answer => send(Object.assign({ op: "answer", id: id }, answer)));
            return null;
        }
        if (setting === "bluetooth" && flag(word, false) === null) {
            const leave = /^disconnect\b/.test(word);
            Bt.reach(leave ? t.replace(/^disconnect\s*/i, "") : t, !leave,
                     answer => send(Object.assign({ op: "answer", id: id }, answer)));
            return null;
        }
        if (setting === "screenshot") {
            const mode = word === "region" ? "region" : "screen";
            Drawers.close();
            Recorder.capture(mode);
            return { ok: true, value: mode };
        }
        const switches = {
            dnd: [Notifs.dnd, on => Notifs.dnd = on],
            caffeine: [Caffeine.on, on => Caffeine.set(on)],
            night: [Toggles.night, on => Toggles.night = on],
            glass: [Machine.glass, on => Machine.setGlass(on)],
            mute: [Audio.muted, on => { if (on !== Audio.muted) Audio.toggleMute(); }],
            mic: [!Audio.micMuted, on => { if (on === Audio.micMuted) Audio.toggleMic(); }],
            wifi: [Network.wifiEnabled, on => Network.setWifi(on)],
            bluetooth: [Bt.enabled, on => Bt.setEnabled(on)],
            record: [Recorder.recording, on => { if (on !== Recorder.recording) { Drawers.close(); Recorder.toggle(); } }]
        };
        if (switches[setting]) {
            const on = flag(value, switches[setting][0]);
            if (on === null) return { ok: false, error: setting + " takes on, off or toggle" };
            switches[setting][1](on);
            return { ok: true, value: on ? "on" : "off" };
        }
        if (setting === "volume" || setting === "brightness") {
            if (setting === "brightness" && !Brightness.available)
                return { ok: false, error: "this screen's brightness cannot be changed from here" };
            const v = amount(value, setting === "volume" ? Audio.volume : Brightness.value);
            if (isNaN(v)) return { ok: false, error: setting + " takes a number from 0 to 100, +10 or -10" };
            if (setting === "volume") Audio.setVolume(v);
            else Brightness.set(v);
            Osd.show(setting, v, false);
            return { ok: true, value: String(Math.round(v * 100)) };
        }
        if (setting === "wallpaper") {
            const t = String(value ?? "").trim();
            const step = t === "" || t === "next" ? "next" : t === "prev" || t === "previous" ? "prev" : "";
            if (step !== "") {
                Quickshell.execDetached([Config.cmd.wallpaper, step]);
                return { ok: true, value: step };
            }
            const wanted = t.toLowerCase().replace(/[\s_-]+/g, "");
            const name = Config.wallpapers.find(n => n.toLowerCase().replace(/[\s_-]+/g, "") === wanted)
                ?? Config.wallpapers.find(n => n.toLowerCase().includes(t.toLowerCase()));
            if (!name) return { ok: false, error: "no wallpaper called " + t + "; there are " + Config.wallpapers.join(", ") };
            Machine.setWallpaper(name);
            return { ok: true, value: name };
        }
        if (setting === "lock") {
            Quickshell.execDetached([Config.cmd.lock]);
            return { ok: true, value: "on" };
        }
        return { ok: false, error: "NIHIL has no setting called " + setting };
    }

    onBusyChanged: if (!busy) roaming = false

    function aside(id: string): void {
        roaming = true;
        const open = Drawers.current !== "";
        Drawers.close();
        if (!open) {
            send({ op: "answer", id: id, ok: true });
            return;
        }
        asides = asides.concat([id]);
        asideLater.restart();
    }

    // The answer goes back once the deck has said what it did: sent, waiting for a device, or why not.
    function toPhone(e: var): void {
        const done = result => send(Object.assign({ op: "answer", id: e.id }, result.ok
            ? { ok: true, devices: result.devices ?? [] } : { ok: false, error: String(result.error ?? "vector") }));
        if (!Vector.enabled) done({ error: "off" });
        else if (e.path) Vector.send(e.path, done);
        else Vector.sendText(String(e.text ?? ""), done);
    }

    function tell(kind: string): void {
        const question = latest("user");
        const reply = latest("nilo");
        const failure = latest("error");
        peekKind = kind;
        peekQuestion = question ? question.text : "";
        peekText = kind === "confirm" ? confirmText(confirm)
            : kind === "error" ? (failure ? errorText(failure.name, failure.text) : "")
            : (reply ? reply.text : "");
        peekFacts = kind === "confirm" ? (confirm ?? {}) : (() => { try { return JSON.parse(reply?.info || "{}"); } catch (e) { return {}; } })();
        const body = plain(peekText);
        Quickshell.execDetached([Config.cmd.notifySend, "--app-name=Nilo", "--hint=string:x-nihil-tag:nilo",
                                 "--hint=string:x-nihil-nilo:" + kind, "--",
                                 kind === "confirm" ? Lang.niloPeekWaiting : kind === "error" ? Lang.niloPeekFailed : Lang.niloPeekDone,
                                 (body.length > 220 ? body.slice(0, 219) + "…" : body)
                                     .replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")]);
    }

    function peek(kind: string): void {
        if (shown || kind !== peekKind) return;
        peekScreen = barScreen();
        peekUntil = Date.now() + (kind === "confirm" ? 30 : peekSeconds) * 1000;
        peeking = true;
    }

    function unpeek(): void {
        peeking = false;
    }

    readonly property int peekSeconds: Math.min(20, 7 + Math.ceil(plain(peekText).length / 45))
    property real peekUntil: 0

    function peekTouch(): void {
        if (peeking) peekUntil = Math.max(peekUntil, Date.now() + 4000);
    }

    Timer {
        interval: 500
        repeat: true
        running: root.peeking
        onTriggered: if (Date.now() >= root.peekUntil) root.unpeek()
    }

    function ask(text: string): void {
        askAs(text, "");
    }

    // A question another program asked, with nihil-ipc nilo ask, says so in the chat: the cards that follow
    // aren't the answer to anything typed here.
    function askAs(text: string, by: string): void {
        const question = text.trim();
        if (!question || busy || failed) return;
        if (by === "" && quickOpen(question)) return;
        messages.append({ kind: "user", text: question, done: true, name: by, status: "", info: "", cid: "" });
        busy = true;
        phase = "waiting";
        mood = "";
        send({ op: "ask", text: question });
    }

    // Asked with no model to answer: the chat says why, with the button that sees to it, as an empty
    // chat's notice does.
    function unready(): void {
        const code = !ollama ? "ollama-down" : "model-missing";
        const l = last();
        if (messages.count === 0 || (l && l.kind === "error" && l.name === code)) return;
        messages.append({ kind: "error", text: "", done: true, name: code, status: "", info: "", cid: "" });
    }

    function stop(): void {
        if (!busy) return;
        stopping = true;
        send({ op: "stop" });
    }

    function reset(): void {
        if (busy) stop();
        messages.clear();
        confirm = null;
        send({ op: "reset" });
    }

    // For the card it was asked from: a card left from before can't answer a newer one.
    function answer(id: string, ok: bool): void {
        if (!confirm || confirm.id !== id) return;
        send({ op: "confirm", id: id, ok: ok });
    }

    function set(key: string, value: var): void {
        const next = Object.assign({}, settings);
        next[key] = value;
        settings = next;
        send({ op: "set", key: key, value: value });
    }

    function download(tag: string): void {
        pull = { model: tag, status: "starting", progress: 0, error: "", code: "" };
        send({ op: "pull", model: tag });
    }

    function startOllama(): void {
        if (startingOllama) return;
        service = Object.assign({}, service, { starting: true, error: "" });
        send({ op: "startOllama" });
    }

    function findRepos(): void { send({ op: "repos" }); }

    function editNotes(): void { send({ op: "notes" }); }

    readonly property var opener: /^(?:[áa]bre(?:me)?|abrir|lanza|arranca|open|launch|start)\s+(.+?)[.!]*$/i

    function quickOpen(text: string): bool {
        if (settings.apps !== true) return false;
        const m = text.match(opener);
        if (!m) return false;
        const targets = m[1].split(/\s*,\s*|\s+(?:y|e|and)\s+/i)
            .map(t => t.replace(/^(?:el|la|los|las|the|an?)\s+/i, "").trim())
            .filter(t => t !== "");
        if (targets.length === 0 || targets.length > 4) return false;
        const plan = [];
        for (const t of targets) {
            if (/^(?:https?:\/\/|mailto:)\S+$/i.test(t)) {
                plan.push({ url: t, name: t });
                continue;
            }
            const q = t.toLowerCase();
            const hits = Apps.search(q);
            if (hits.length === 0 || Apps.score(hits[0], q) < 400) return false;
            plan.push({ entry: hits[0], name: hits[0].name });
        }
        messages.append({ kind: "user", text: text, done: true, name: "", status: "", info: "", cid: "" });
        for (const p of plan) {
            messages.append({ kind: "tool", text: "", done: true, name: "open_app", status: "done", cid: "",
                              info: JSON.stringify({ ok: true, opened: p.name, args: { target: p.name } }) });
            if (p.entry) Apps.launch(p.entry);
            else Apps.open(p.url);
        }
        Drawers.close();
        return true;
    }

    function launch(target: string, kind: string): var {
        if (kind === "url" || kind === "path") {
            Apps.open(target);
            Drawers.close();
            return { ok: true, name: target };
        }
        const q = String(target ?? "").trim().toLowerCase();
        const found = q ? Apps.search(q) : [];
        const best = found.length > 0 && Apps.score(found[0], q) >= 200 ? found[0] : null;
        if (!best) return { ok: false, similar: found.slice(0, 5).map(e => e.name) };
        Drawers.close();
        Apps.launch(best);
        return { ok: true, name: best.name };
    }

    function cancelDownload(): void { send({ op: "cancelPull" }); }
    function remove(tag: string): void { send({ op: "delete", model: tag }); }
    function sleep(): void { send({ op: "sleep" }); }

    function warm(): void {
        if (known && installed && !loaded && !loading) {
            loading = true;
            send({ op: "warm" });
        }
    }

    function last(): var {
        return messages.count > 0 ? messages.get(messages.count - 1) : null;
    }

    function findTool(id: string): int {
        for (let i = messages.count - 1; i >= 0; i--)
            if (messages.get(i).cid === id) return i;
        return -1;
    }

    function errorText(code: string, detail: string): string {
        const model = settings.model ?? "";
        switch (code) {
        case "ollama-down": return Lang.niloErrOllama;
        case "model-missing": return Lang.niloErrModel.arg(model);
        case "memory": return Lang.niloErrMemory.arg(model);
        case "no-model": return Lang.niloErrNoModel;
        case "bad-repo": return Lang.niloErrRepo.arg(detail);
        }
        return english ? Lang.niloErrOther.arg((detail || code).slice(0, 160)) : Lang.niloErrPlain;
    }

    function catalogue(e: var): void {
        models = e.models ?? [];
        recommended = e.recommended ?? "";
        fast = e.fast ?? "";
        ramGB = e.ramGB ?? 0;
        ollama = e.ollama !== false;
    }

    function handle(line: string): void {
        let e;
        try { e = JSON.parse(line); } catch (err) { console.log("nilo: bad line " + line); return; }

        switch (e.ev) {
        case "hello":
            settings = e.settings;
            catalogue(e);
            known = true;
            restarts = 0;
            break;
        case "settings":
            settings = e.settings;
            break;
        case "models":
            catalogue(e);
            if (pull && pull.status === "success") pull = null;
            break;
        case "state":
            if (e.model) inUse = e.model;
            loaded = e.loaded;
            loading = e.loading;
            expires = e.expires ?? 0;
            sizeGB = e.sizeGB ?? 0;
            gpu = e.gpu ?? 0;
            if (e.ollama !== null && e.ollama !== undefined) {
                if (ollama && e.ollama === false) service = ({});
                ollama = e.ollama;
            }
            break;
        case "ollama":
            service = e;
            if (e.up === true) {
                ollama = true;
                if (pull && pull.code === "ollama-down") pull = null;
            } else if (e.up === false) {
                ollama = false;
            }
            break;
        case "repos":
            repos = e.repos ?? [];
            break;
        case "notes":
            Drawers.close();
            Apps.run([Config.cmd.terminal, "-e", Config.cmd.editor, e.path]);
            break;
        case "reset":
            break;
        case "start":
            busy = true;
            phase = "waiting";
            inUse = e.model ?? "";
            break;
        case "thinking":
            if (phase === "waiting") phase = "thinking";
            break;
        case "token": {
            const l = last();
            if (l && l.kind === "nilo" && !l.done)
                messages.setProperty(messages.count - 1, "text", l.text + e.text);
            else
                messages.append({ kind: "nilo", text: e.text.replace(/^\s+/, ""), done: false, name: "", status: "", info: "", cid: "" });
            phase = "writing";
            pulse++;
            break;
        }
        case "tool":
            if (e.status === "running") {
                closeReply();
                messages.append({ kind: "tool", text: "", done: false, name: e.name, status: "running",
                                  info: JSON.stringify(e.args ?? {}), cid: e.id });
                phase = "tool";
                tool = e.name;
            } else {
                const i = findTool(e.id);
                if (i >= 0) {
                    const args = JSON.parse(messages.get(i).info || "{}");
                    messages.set(i, { done: true, status: e.ok || e.declined ? "done" : "failed",
                                      info: JSON.stringify(Object.assign({}, e, { args: args })),
                                      text: e.tail ? e.tail.join("\n") : messages.get(i).text });
                }
                if (e.name === "git_commit" && e.ok && !e.declined) mood = "happy";
                phase = "waiting";
                tool = "";
            }
            break;
        case "output": {
            const i = findTool(e.id);
            if (i >= 0) messages.setProperty(i, "text", (e.lines ?? []).join("\n"));
            break;
        }
        case "launch":
            send(Object.assign({ op: "launched", id: e.id }, launch(e.target, e.kind)));
            break;
        case "aside":
            aside(e.id);
            break;
        case "control": {
            const answer = control(String(e.setting ?? ""), String(e.value ?? ""), e.id);
            if (answer) send(Object.assign({ op: "answer", id: e.id }, answer));
            break;
        }
        case "vector":
            toPhone(e);
            break;
        case "confirm":
            confirmAll = false;
            confirm = e;
            messages.append({ kind: "confirm", text: "", done: false, name: e.action, status: "asking",
                              info: JSON.stringify(e), cid: e.id });
            phase = "confirm";
            if (!shown) tell("confirm");
            break;
        case "confirmed": {
            const i = findTool(e.id);
            if (i >= 0) messages.set(i, { done: true, status: e.ok ? "ok" : "declined" });
            confirm = null;
            phase = "tool";
            if (peeking && peekKind === "confirm") unpeek();
            break;
        }
        case "done": {
            closeReply();
            const l = last();
            if (e.cancelled)
                messages.append({ kind: "note", text: "", done: true, name: "stopped", status: "", info: "", cid: "" });
            else if (l && l.kind === "nilo" && e.stats && e.stats.tokens)
                messages.setProperty(messages.count - 1, "info", JSON.stringify(e.stats));
            if (behind && !shown && !e.cancelled) tell(e.failed ? "error" : "done");
            behind = false;
            busy = false;
            stopping = false;
            phase = "idle";
            tool = "";
            confirm = null;
            break;
        }
        case "error":
            if (e.code === "busy") {
                const l = last();
                if (l && l.kind === "user") messages.remove(messages.count - 1);
                busy = false;
                phase = "idle";
                break;
            }
            messages.append({ kind: "error", text: e.detail ?? "", done: true, name: e.code, status: "", info: "", cid: "" });
            mood = "error";
            moodReset.restart();
            break;
        case "pull":
            if (e.status === "error" || e.status === "cancelled" || e.status === "busy") {
                pull = e.status === "error" ? { model: e.model, status: "error", progress: 0, error: e.detail ?? "", code: e.code ?? "" } : null;
            } else {
                pull = { model: e.model, status: e.status, error: "", code: "",
                         attempt: e.attempt ?? 0, attempts: e.attempts ?? 0,
                         progress: e.total > 0 ? e.completed / e.total : (pull?.progress ?? 0) };
            }
            break;
        }
    }

    function closeReply(): void {
        const l = last();
        if (l && l.kind === "nilo" && !l.done) {
            messages.setProperty(messages.count - 1, "done", true);
            messages.setProperty(messages.count - 1, "text", l.text.replace(/\s+$/, ""));
        }
    }

    Timer {
        id: moodReset
        interval: 3200
        onTriggered: root.mood = ""
    }

    onMoodChanged: if (mood === "happy") moodReset.restart()

    Process {
        id: agent
        command: [Config.nilo.agent]
        stdinEnabled: true

        stdout: SplitParser {
            onRead: data => root.handle(data)
        }
        stderr: SplitParser {
            onRead: data => console.log("nilo: " + data)
        }

        onStarted: {
            root.ready = true;
            agent.write(JSON.stringify({ op: "hello" }) + "\n");
            const pending = root.queued;
            root.queued = [];
            for (const request of pending) agent.write(JSON.stringify(request) + "\n");
        }

        onExited: (code, status) => {
            root.ready = false;
            root.known = false;
            root.loading = false;
            root.service = ({});
            root.exitCode = code;
            // What the agent had going ends with it: its tools failed, its cards can't be answered.
            root.confirm = null;
            for (let i = 0; i < root.messages.count; i++) {
                const m = root.messages.get(i);
                if (m.kind === "tool" && m.status === "running")
                    root.messages.set(i, { done: true, status: "failed" });
                else if (m.kind === "confirm" && m.status === "asking")
                    root.messages.set(i, { done: true, status: "declined" });
            }
            if (root.busy) {
                root.closeReply();
                root.busy = false;
                root.stopping = false;
                root.phase = "idle";
                root.tool = "";
            }
            if (root.wanted && root.restarts < 5) {
                root.restarts++;
                restart.restart();
            } else if (root.wanted) {
                root.failed = true;
            }
        }
    }

    Timer {
        id: restart
        interval: 1500 * root.restarts
        onTriggered: if (root.wanted && !agent.running) agent.running = true
    }

    Timer {
        id: asideLater
        interval: Tokens.animDrawer + 80
        onTriggered: {
            for (const id of root.asides)
                root.send({ op: "answer", id: id, ok: true });
            root.asides = [];
        }
    }

    IpcHandler {
        target: "nilo"

        function toggle(): void { root.toggle(); }
        function open(): void { root.open(); }
        function sleep(): void { root.sleep(); }
        function ask(text: string): void {
            root.open();
            root.askAs(text, "ipc");
        }
        function state(): string { return root.busy ? root.phase : "idle"; }
        function reset(): void { root.reset(); }
    }
}
