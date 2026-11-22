pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import qs.config
import "Widgets.js" as Widgets

Singleton {
    id: root

    property var saved: ({})
    property var draft: ({})
    property bool loaded: false
    readonly property int changes: loaded ? differences(saved, draft) : 0

    property bool shown: false
    property string page: "you"
    property bool welcoming: false
    property string screen: ""

    property string phase: ""
    property string failure: ""
    property string auth: ""
    readonly property bool fingerprint: saved.fingerprint === true
    property var instead: null
    property string detail: ""
    property string log: ""
    property real since: 0
    readonly property bool busy: phase === "auth" || phase === "applying"
    property string kind: "settings"
    readonly property bool updating: kind === "update" && busy
    property int target: 0
    property real freed: 0

    property string passwordState: ""

    property string wallpaper: ""
    property bool glass: false

    property var widgets: Config.widgetDefaults
    // Where each widget was put on the desktop, by name: [x, y] from the desktop's top left,
    // inside the frame. One with none goes where there's room.
    property var widgetPlaces: ({})
    // How big each is, by name: how many times its own size, or its width and height for one made
    // to any shape. One not there is as it comes.
    property var widgetSizes: ({})
    // What a widget is told, by name and then by key: whose GitHub contributions, a note's text.
    property var widgetOptions: ({})
    // Moving them about: a long press on one, Arrange in Preferences, nihil-ipc widgets arrange.
    // Nothing is kept until it ends with Enter; Esc puts back what was there when it began.
    property bool arranging: false
    property var arrangedFrom: null
    // While arranging: photos thrown away, whose pictures go once it's kept, and pictures put in,
    // beside the ones they'd take the place of until then.
    property var doomed: []
    property var staged: []
    // Those being moved into place once it's kept, shown from where they were until they're there.
    property var moving: []
    property bool keptLast: false
    property bool widgetsRead: false
    // All of it, kept as it is: no rebuild for any.
    readonly property string widgetsFile: stateDir + "/widgets.json"
    property var timeZones: []

    property real now: Date.now()
    readonly property string elapsed: {
        const seconds = Math.max(0, Math.round((root.now - root.since) / 1000));
        return Math.floor(seconds / 60) + ":" + String(seconds % 60).padStart(2, "0");
    }
    readonly property bool generational: kind === "generation" || kind === "clean" || kind === "boot"
    readonly property string statusTitle: phase === "auth" ? (auth === "finger" ? Lang.cfgFingerAsk : Lang.cfgChecking)
        : phase === "applying" ? (kind === "update" ? Lang.updApplying.arg(elapsed)
            : kind === "generation" ? Lang.genSwitching.arg(elapsed).arg(target)
            : kind === "clean" ? Lang.genCleaning.arg(elapsed) : Lang.cfgApplying.arg(elapsed))
        : phase === "failed" ? (failure === "password" ? Lang.cfgWrongPassword : failure === "finger" ? Lang.cfgFingerFailed
            : failure === "menu" ? Lang.genNotInMenu
            : failure === "invalid" ? (generational ? Lang.genGone : Lang.cfgInvalid)
            : failure === "busy" ? Lang.cfgBusy : kind === "update" ? Lang.updFailed
            : kind === "generation" ? Lang.genSwitchFailed : kind === "clean" ? Lang.genCleanFailed
            : kind === "boot" ? Lang.genBootFailed : Lang.cfgApplyFailed)
        : changes > 0 ? (changes === 1 ? Lang.cfgPendingOne : Lang.cfgPending.arg(changes))
        : phase === "done" ? (kind === "update" ? Lang.updDone : kind === "generation" ? Lang.genSwitched.arg(target)
            : kind === "clean" ? Lang.genCleaned.arg(Dates.bytes(freed)) : kind === "boot" ? Lang.genBootSet.arg(target) : Lang.cfgApplied)
        : phase === "warning" ? (kind === "generation" ? Lang.genSwitchedWarn.arg(target) : Lang.cfgAppliedWarn)
        : Lang.cfgSaved
    readonly property string statusSub: phase === "applying" ? detail
        : phase === "failed" ? (failure === "rebuild" || failure === "start" ? (detail !== "" ? detail : Lang.cfgLogHint)
            : failure === "invalid" ? detail : "")
        : changes === 0 && phase === "warning" ? Lang.cfgLogHint
        : ""

    Timer {
        running: root.phase === "applying"
        interval: 1000
        repeat: true
        onTriggered: root.now = Date.now()
    }

    readonly property string stateDir: (Quickshell.env("XDG_STATE_HOME") || Quickshell.env("HOME") + "/.local/state") + "/nihil"

    function clone(value: var): var {
        return JSON.parse(JSON.stringify(value === undefined ? {} : value));
    }

    function get(path: string, fallback: var): var {
        let node = root.draft;
        const keys = path.split(".");
        for (let i = 0; i < keys.length; i++) {
            if (node === null || typeof node !== "object" || !(keys[i] in node))
                return fallback;
            node = node[keys[i]];
        }
        return node;
    }

    // fallback is the value get() gives for a key settings.json doesn't have: set to it, such a key
    // stays out, and choosing again what is already chosen changes nothing.
    function set(path: string, value: var, fallback: var): void {
        const next = clone(root.draft);
        const keys = path.split(".");
        let node = next;
        for (let i = 0; i < keys.length - 1; i++) {
            if (node[keys[i]] === null || typeof node[keys[i]] !== "object")
                node[keys[i]] = {};
            node = node[keys[i]];
        }
        const last = keys[keys.length - 1];
        const unsaved = fallback !== undefined && !root.holds(root.saved, keys)
            && JSON.stringify(value) === JSON.stringify(fallback);
        if (value === undefined || unsaved)
            delete node[last];
        else
            node[last] = value;
        root.draft = next;
    }

    function holds(tree: var, keys: var): bool {
        let node = tree;
        for (let i = 0; i < keys.length; i++) {
            if (node === null || typeof node !== "object" || !(keys[i] in node))
                return false;
            node = node[keys[i]];
        }
        return true;
    }

    function empty(value: var): bool {
        return value === undefined
            || (value !== null && typeof value === "object" && !Array.isArray(value) && Object.keys(value).length === 0);
    }

    // A key that isn't there and one that holds nothing ({}) are the same to NIHIL.
    function differences(a: var, b: var): int {
        if (root.empty(a) && root.empty(b))
            return 0;
        if (a === null || b === null || typeof a !== "object" || typeof b !== "object")
            return JSON.stringify(a) === JSON.stringify(b) ? 0 : 1;
        let count = 0;
        const keys = Object.keys(a).concat(Object.keys(b).filter(key => !(key in a)));
        for (let i = 0; i < keys.length; i++)
            count += differences(a[keys[i]], b[keys[i]]);
        return count;
    }

    // What the draft changed from `base`, over `next`: settings.json changed under a draft (by
    // nihil settings, say) keeps both, and applying the draft doesn't undo the other change. A
    // value both changed keeps the draft's, the one on screen.
    function rebase(base: var, draft: var, next: var): var {
        if (root.differences(base, draft) === 0)
            return next;
        if (root.differences(base, next) === 0)
            return draft;
        const plain = value => value !== null && typeof value === "object" && !Array.isArray(value);
        if (![base, draft, next].every(value => value === undefined || plain(value)))
            return draft;
        const node = value => value ?? {};
        const out = {};
        const keys = Object.keys(node(base)).concat(Object.keys(node(draft)), Object.keys(node(next)));
        for (const key of keys.filter((key, i) => keys.indexOf(key) === i)) {
            const value = root.rebase(node(base)[key], node(draft)[key], node(next)[key]);
            if (value !== undefined)
                out[key] = value;
        }
        return out;
    }

    function discard(): void {
        root.draft = clone(root.saved);
        if (!root.busy)
            root.phase = "";
    }

    function show(name: string, welcome: bool): void {
        root.screen = Hyprland.focusedMonitor?.name ?? "";
        root.welcoming = welcome;
        // What the last password change came to isn't news on the next visit; one under way is.
        if (!passwd.running)
            root.passwordState = "";
        // «phone», as the page was called before it had devices of every kind.
        root.page = name === "phone" ? "devices" : name !== "" ? name : (welcome ? "hello" : "you");
        root.shown = true;
        if (root.timeZones.length === 0 && !zones.running)
            zones.running = true;
    }

    function hide(): void {
        if (!root.welcoming)
            root.shown = false;
    }

    function markWelcomed(): void {
        Quickshell.execDetached([Config.cmd.sh, "-c", "mkdir -p \"$1\" && touch \"$1/welcomed\"", "sh", root.stateDir]);
    }

    function endWelcome(): void {
        markWelcomed();
        root.welcoming = false;
        root.shown = false;
    }

    // Written whole, and never as an argument, which anyone on the computer could read in /proc:
    // notes are in it.
    function saveWidgets(): void {
        if (root.arranging || !root.widgetsRead)
            return;
        widgetsKept.setText(JSON.stringify({ on: root.widgets, at: root.widgetPlaces, size: root.widgetSizes, opts: root.widgetOptions }));
    }

    // The widgets there are: one of each kind Config has, and photos and notes as many as wanted.
    function known(name: string): bool {
        return Widgets.known(name, Config.widgets);
    }

    function several(name: string): bool {
        return Widgets.several(name);
    }

    function kindOf(name: string): string {
        return Widgets.kindOf(name);
    }

    function setWidget(name: string, on: bool): void {
        const next = root.widgets.filter(widget => widget !== name);
        if (on)
            next.push(name);
        root.widgets = next;
        root.saveWidgets();
    }

    // A widget's own settings, over those it has: texts, numbers, yes or no; null takes one away.
    function setWidgetOptions(name: string, values: var): void {
        const mine = Object.assign({}, root.widgetOptions[name] ?? {}, values);
        for (const key of Object.keys(mine)) {
            if (mine[key] === null)
                delete mine[key];
        }
        root.widgetOptions = Object.assign({}, root.widgetOptions, { [name]: mine });
        root.saveWidgets();
    }

    function setWidgetOption(name: string, key: string, value: var): void {
        root.setWidgetOptions(name, { [key]: value });
    }

    // places: { name: [x, y] }, over what's kept.
    function placeWidgets(places: var): void {
        root.widgetPlaces = Object.assign({}, root.widgetPlaces, places);
        root.saveWidgets();
    }

    // How many times its size, or [width, height]; as it comes, it isn't kept.
    function sizeWidget(name: string, size: var): void {
        const sizes = Object.assign({}, root.widgetSizes);
        if (Array.isArray(size))
            sizes[name] = [Math.round(size[0]), Math.round(size[1])];
        else if (Math.abs(size - 1) < 0.005)
            delete sizes[name];
        else
            sizes[name] = Math.round(size * 1000) / 1000;
        root.widgetSizes = sizes;
        root.saveWidgets();
    }

    // Another of a kind there can be several of, where it's put and as big as it's made, or where
    // there's room and as it comes.
    function addWidget(kind: string, at: var, size: var): string {
        const name = Widgets.freeName(kind, root.widgets, root.doomed.concat(Object.keys(root.photoTaken)));
        if (at)
            root.widgetPlaces = Object.assign({}, root.widgetPlaces, { [name]: at });
        if (size)
            root.widgetSizes = Object.assign({}, root.widgetSizes, { [name]: size });
        root.widgets = root.widgets.concat([name]);
        root.saveWidgets();
        return name;
    }

    // Dropped on the cross: a photo or a note goes for good, with its picture or its text; any
    // other is turned off, keeping its place for when it's back.
    function removeWidget(name: string): void {
        if (!root.several(name)) {
            root.setWidget(name, false);
            return;
        }
        const places = Object.assign({}, root.widgetPlaces), sizes = Object.assign({}, root.widgetSizes);
        const options = Object.assign({}, root.widgetOptions), taken = Object.assign({}, root.photoTaken);
        delete places[name];
        delete sizes[name];
        delete options[name];
        delete taken[name];
        root.widgets = root.widgets.filter(widget => widget !== name);
        root.widgetPlaces = places;
        root.widgetSizes = sizes;
        root.widgetOptions = options;
        root.photoTaken = taken;
        root.saveWidgets();
        if (root.kindOf(name) !== "photo")
            return;
        if (root.arranging)
            root.doomed = root.doomed.concat([name]);
        else
            root.dropFiles([name, name + ".staged"], []);
    }

    // Files in the state folder, by name: some go, and some put in while arranging take their places.
    function dropFiles(gone: var, moved: var): void {
        if (gone.length === 0 && moved.length === 0)
            return;
        if (filing.running) {
            filing.queue = filing.queue.concat([[gone, moved]]);
            return;
        }
        root.moving = moved;
        filing.command = [Config.cmd.sh, "-c", 'dir=$1; shift; while [ "$1" != -- ]; do rm -f -- "$dir/$1"; shift; done; shift; '
                          + 'for name in "$@"; do mv -f -- "$dir/$name.staged" "$dir/$name"; done', "sh", root.stateDir].concat(gone, ["--"], moved);
        filing.running = true;
    }

    Process {
        id: filing

        property var queue: []

        // Read again from where they now are.
        onExited: {
            const taken = Object.assign({}, root.photoTaken);
            for (const name of root.moving)
                taken[name] = (taken[name] ?? 0) + 1;
            root.photoTaken = taken;
            root.moving = [];
            const next = filing.queue[0];
            filing.queue = filing.queue.slice(1);
            if (next !== undefined)
                root.dropFiles(next[0], next[1]);
        }
    }

    function arrangeWidgets(): void {
        root.hide();
        if (root.arranging)
            return;
        root.arrangedFrom = { on: root.widgets.slice(), at: Object.assign({}, root.widgetPlaces), size: Object.assign({}, root.widgetSizes),
                              opts: Object.assign({}, root.widgetOptions), taken: Object.assign({}, root.photoTaken) };
        root.doomed = [];
        root.staged = [];
        root.arranging = true;
    }

    // Enter keeps what's there, Esc puts back what was.
    function stopArranging(keep: bool): void {
        if (!root.arranging)
            return;
        const from = root.arrangedFrom;
        const files = Widgets.settle(keep, root.widgets, root.doomed, root.staged);
        if (!keep) {
            root.widgets = from.on;
            root.widgetPlaces = from.at;
            root.widgetSizes = from.size;
            root.widgetOptions = from.opts;
            root.photoTaken = from.taken;
        }
        root.arranging = false;
        root.keptLast = keep;
        root.arrangedFrom = null;
        root.doomed = [];
        root.staged = [];
        root.dropFiles(files.remove, files.move);
        if (keep)
            root.saveWidgets();
    }

    // Photos, each with its picture: a copy, so it stays when the one it came from goes, named as
    // its widget. The name says nothing of what it is; the picture itself does. Each one put in
    // counts, so the widget reads the file again; 0 is none yet.
    readonly property var photos: Widgets.instances(root.widgets, "photo")
    readonly property var notes: Widgets.instances(root.widgets, "note")
    property var photoTaken: ({})

    function photoFile(name: string): string {
        return root.stateDir + "/" + name;
    }

    function photoUrl(name: string): string {
        const taken = root.photoTaken[name] ?? 0;
        const file = root.photoFile(name) + (root.staged.indexOf(name) >= 0 || root.moving.indexOf(name) >= 0 ? ".staged" : "");
        return taken > 0 ? "file://" + file.split("/").map(encodeURIComponent).join("/") + "?" + taken : "";
    }

    // Qt reads PNG, JPEG, GIF and BMP by itself; a WebP one goes in as PNG.
    readonly property string photoScript: 'mkdir -p "$(dirname "$2")" && '
        + 'if [ "$(head -c 12 -- "$1" | tail -c 4)" = WEBP ]; then '
        + '"$3" -v error -y -f webp_pipe -i "file:$1" -frames:v 1 -c:v png -f image2pipe "file:$2.new"; '
        + 'else cp -f -- "$1" "$2.new"; fi && mv -f -- "$2.new" "$2"'

    // From a widget, where it shows at once; dropped on the desktop, a new one where it fell, at
    // `at`; or from Files' Open with, which says it's done: the first one on with none, else a new one.
    function setPhoto(path: string, told: bool, name: string, at: var): void {
        if (!path.startsWith("/")) {
            root.notify(Lang.widgetPhotoFailed, "");
            return;
        }
        if (photoCopy.running) {
            photoCopy.waiting = photoCopy.waiting.concat([[path, told, name, at]]);
            return;
        }
        const empty = root.photos.find(photo => (root.photoTaken[photo] ?? 0) === 0 && root.staged.indexOf(photo) < 0);
        const into = root.known(name) && root.kindOf(name) === "photo" ? name
            : at === null && empty !== undefined ? empty
            : Widgets.freeName("photo", root.widgets, root.doomed.concat(Object.keys(root.photoTaken)));
        photoCopy.path = path;
        photoCopy.told = told;
        photoCopy.into = into;
        photoCopy.at = at;
        photoCopy.staging = root.arranging;
        photoCopy.command = [Config.cmd.sh, "-c", root.photoScript, "sh", path, root.photoFile(into) + (root.arranging ? ".staged" : ""), Config.cmd.ffmpeg];
        photoCopy.running = true;
    }

    Process {
        id: photoCopy

        property string path: ""
        property bool told: false
        property string into: ""
        property var at: null
        property bool staging: false
        property var waiting: []

        onExited: code => {
            if (code !== 0) {
                root.notify(Lang.widgetPhotoFailed, "");
            } else if (photoCopy.staging && !root.arranging) {
                // Arranging ended while it was copied: put back, it goes; kept, it goes in again
                // as one put in now.
                root.dropFiles([photoCopy.into + ".staged"], []);
                if (root.keptLast)
                    root.setPhoto(photoCopy.path, photoCopy.told, photoCopy.into, photoCopy.at);
            } else {
                if (photoCopy.staging && root.staged.indexOf(photoCopy.into) < 0)
                    root.staged = root.staged.concat([photoCopy.into]);
                root.photoTaken = Object.assign({}, root.photoTaken, { [photoCopy.into]: (root.photoTaken[photoCopy.into] ?? 0) + 1 });
                if (photoCopy.at !== null)
                    root.widgetPlaces = Object.assign({}, root.widgetPlaces, { [photoCopy.into]: photoCopy.at });
                if (root.widgets.indexOf(photoCopy.into) < 0)
                    root.setWidget(photoCopy.into, true);
                else if (photoCopy.at !== null)
                    root.saveWidgets();
                if (photoCopy.told)
                    root.notify(Lang.widgetPhotoSet, "");
            }
            const next = photoCopy.waiting[0];
            photoCopy.waiting = photoCopy.waiting.slice(1);
            if (next !== undefined)
                root.setPhoto(next[0], next[1], next[2], next[3]);
        }
    }

    // The pictures there are, by the names of their widgets.
    Process {
        command: [Config.cmd.sh, "-c", 'mkdir -p "$0" && cd "$0" || exit 0; for name in photo photo-*; do '
                  + 'case "$name" in *[!a-z0-9-]*) continue ;; esac; [ -s "$name" ] && echo "$name"; done; true', root.stateDir]
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                const taken = Object.assign({}, root.photoTaken);
                for (const name of text.split("\n")) {
                    if (root.kindOf(name) === "photo" && (taken[name] ?? 0) === 0)
                        taken[name] = 1;
                }
                root.photoTaken = taken;
            }
        }
    }

    function liveWallpaper(name: string): void {
        if (name === "")
            return;
        root.wallpaper = name;
        Quickshell.execDetached([Config.cmd.wallpaper, "set", name]);
    }

    function setWallpaper(name: string): void {
        liveWallpaper(name);
    }

    function setGlass(on: bool): void {
        root.glass = on;
        Quickshell.execDetached([Config.cmd.wallpaper, "glass", on ? "on" : "off"]);
    }

    function apply(password: string): void {
        if (root.changes === 0 || root.switching(applier, password))
            return;
        root.kind = "settings";
        root.ask(applier, password, JSON.stringify(root.draft) + "\n");
    }

    function update(password: string): void {
        if (root.switching(updater, password))
            return;
        root.kind = "update";
        root.ask(updater, password, "");
    }

    function generation(action: string, value: int, password: string): void {
        if (root.switching(generator, password))
            return;
        root.kind = action === "switch" ? "generation" : action;
        root.target = action === "clean" ? 0 : value;
        generator.action = action;
        generator.value = value;
        root.ask(generator, password, "");
    }

    function ask(process: var, password: string, input: string): void {
        if (root.runtimeDir === "") {
            root.phase = "failed";
            root.failure = "start";
            return;
        }
        root.auth = password === "" && root.fingerprint ? "finger" : "password";
        root.phase = "auth";
        root.failure = "";
        root.detail = "";
        root.log = "";
        process.mode = root.auth;
        // The password first, the line sudo reads; what's left is the command's.
        process.input = (root.auth === "password" ? password + "\n" : "") + input;
        process.running = true;
    }

    function switching(process: var, password: string): bool {
        if (!root.busy)
            return false;
        if (root.phase === "auth" && root.auth === "finger" && password !== "" && process.running) {
            root.instead = { process: process, password: password, input: process === applier ? JSON.stringify(root.draft) + "\n" : "" };
            process.running = false;
        }
        return true;
    }

    function cancelFinger(): void {
        for (const process of [applier, updater, generator]) {
            if (root.phase === "auth" && root.auth === "finger" && process.running) {
                root.instead = { process: process, password: null };
                process.running = false;
            }
        }
    }

    function replaced(process: var): bool {
        if (root.instead === null || root.instead.process !== process)
            return false;
        const next = root.instead;
        root.instead = null;
        if (next.password === null) {
            root.phase = "";
            root.auth = "";
        } else {
            Qt.callLater(() => root.ask(next.process, next.password, next.input));
        }
        return true;
    }

    function changePassword(current: string, next: string): void {
        if (passwd.running)
            return;
        // One line each: chpasswd takes lines, and a pasted line break would change the wrong thing.
        if (/[\r\n]/.test(current + next) || next === "") {
            root.passwordState = "invalid";
            return;
        }
        if (root.runtimeDir === "") {
            root.passwordState = "failed";
            return;
        }
        root.passwordState = "busy";
        // The new one first, into a file of the user's own (sudoAsk), then the current one for
        // sudo alone: after it on stdin, a mistyped current one made sudo try the new one too.
        passwd.input = next + "\n" + current + "\n";
        passwd.running = true;
    }

    function notify(title: string, body: string): void {
        Quickshell.execDetached([Config.cmd.notifySend, "-a", "NIHIL", "--", title, body]);
    }

    function cause(lines: var): string {
        for (let i = 0; i < lines.length; i++) {
            if (/^\s*error:/.test(lines[i]))
                return lines[i].trim();
        }
        return lines.length > 0 ? lines[lines.length - 1].trim() : "";
    }

    readonly property string counting: "awk '/^these [0-9]+ derivations? will be built/ { total += $2 } "
        + "/^this derivation will be built/ { total += 1 } /^these [0-9]+ paths? will be fetched/ { total += $2 } "
        + "/^this path will be fetched/ { total += 1 } /^building .\\/nix\\/store\\// || /^copying path .\\/nix\\/store\\// { begun += 1 } "
        + "/^activating the configuration/ { active = 1 } END { print total + 0, begun + 0, active + 0 }'"

    function progress(counts: string): void {
        const numbers = counts.trim().split(/\s+/).map(Number);
        if (numbers.length < 3 || numbers.some(isNaN))
            return;
        const [total, begun, active] = numbers;
        Glyph.track("rebuild", active ? 0.95 : total > 0 ? 0.05 + 0.85 * Math.min(1, begun / total) : -1);
    }

    function report(text: string): void {
        const parts = text.split("--nihil--");
        const status = parts[0].trim();
        if (parts.length > 2 && parts[1].trim() !== "")
            root.kind = parts[1].trim();
        const lines = (parts.length > 2 ? parts[2] : "").split("\n").filter(line => line.trim() !== "");
        if (status === "running") {
            root.log = lines.join("\n");
            if (lines.length > 0)
                root.detail = lines[lines.length - 1].trim();
            if (root.phase !== "applying") {
                root.phase = "applying";
                root.since = Date.now();
            }
            if (parts.length > 3)
                root.progress(parts[3]);
            poll.start();
        } else if (root.phase === "applying" && (status === "done" || status === "warning" || status === "failed")) {
            poll.stop();
            Glyph.finish("rebuild", status === "failed" ? "failed" : "done");
            root.log = lines.join("\n");
            root.detail = status === "failed" ? root.cause(lines) : (lines.length > 0 ? lines[lines.length - 1].trim() : "");
            root.facts(lines);
            root.phase = status;
            root.failure = status === "failed" ? "rebuild" : "";
            if (status === "failed")
                root.notify(root.kind === "update" ? Lang.updNotifyFailed : root.kind === "generation" ? Lang.genSwitchFailed
                    : root.kind === "clean" ? Lang.genCleanFailed : Lang.cfgNotifyFailed, Lang.cfgLogHint);
            else if (root.kind === "generation")
                root.notify((status === "warning" ? Lang.genSwitchedWarn : Lang.genSwitched).arg(root.target), "");
            else if (root.kind === "clean")
                root.notify(Lang.genCleaned.arg(Dates.bytes(root.freed)), "");
            else
                root.notify(root.kind === "update" ? Lang.updDone : Lang.cfgNotifyApplied, status === "warning" ? Lang.cfgAppliedWarn : "");
            if (root.kind === "update")
                Updates.check();
            if (root.generational)
                Generations.refresh(root.kind === "clean");
        }
    }

    function facts(lines: var): void {
        for (let i = 0; i < lines.length; i++) {
            const to = /^nihil: generation ([0-9]+)$/.exec(lines[i].trim());
            if (to)
                root.target = Number(to[1]);
            const freed = /^nihil: freed ([0-9]+)$/.exec(lines[i].trim());
            if (freed)
                root.freed = Number(freed[1]);
        }
    }

    FileView {
        path: Config.settingsFile
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const next = JSON.parse(text());
                const pending = root.loaded && root.differences(root.saved, root.draft) > 0;
                root.draft = pending ? root.clone(root.rebase(root.saved, root.draft, next)) : root.clone(next);
                root.saved = next;
                root.loaded = true;
            } catch (error) {
                console.warn("nihil: settings:", path, "is not valid JSON:", error);
            }
        }
    }

    Process {
        command: [Config.cmd.sh, "-c", "[ -e \"$1\" ]", "sh", root.stateDir + "/welcomed"]
        running: true
        onExited: code => {
            if (code !== 0)
                welcomeDelay.start();
        }
    }

    Timer {
        id: welcomeDelay
        interval: 2500
        onTriggered: root.show("hello", true)
    }

    Process {
        id: zones
        command: [Config.cmd.timedatectl, "list-timezones", "--no-pager"]
        stdout: StdioCollector {
            onStreamFinished: root.timeZones = text.split("\n").filter(zone => zone !== "")
        }
    }

    FileView {
        id: widgetsKept
        path: root.widgetsFile
        printErrors: false
        // Read once: what's written after is what it already has.
        onLoaded: {
            if (root.widgetsRead)
                return;
            const kept = Widgets.read(text(), Config.widgets);
            if (kept !== null) {
                if (kept.on !== null)
                    root.widgets = kept.on;
                root.widgetPlaces = kept.at;
                root.widgetSizes = kept.size;
                root.widgetOptions = kept.opts;
            }
            root.widgetsRead = true;
        }
        onLoadFailed: root.widgetsRead = true
    }

    Process {
        command: [Config.cmd.wallpaper, "current"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.wallpaper = text.trim()
        }
    }

    Process {
        command: [Config.cmd.wallpaper, "glass"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.glass = text.trim() === "on"
        }
    }

    // Never /tmp: another user could make these files first, and root reads them.
    readonly property string runtimeDir: Quickshell.env("XDG_RUNTIME_DIR") ?? ""
    readonly property string newPassword: runtimeDir + "/nihil-new-password"
    readonly property string sudoAsk: 'umask 077; flag="${XDG_RUNTIME_DIR:?}/nihil-sudo-password"; '
        + 'if [ "$1" = password ]; then echo $$ > "$flag"; else rm -f "$flag"; fi; '
        + 'if [ -n "$2" ]; then IFS= read -r line && printf "%s\\n" "$line" > "$2" || exit 4; fi; '
        + 'shift 2; exec "$@"'

    Process {
        id: applier

        property string input: ""
        property string mode: "password"

        // The draft reaches root on stdin, after the password: a file, written before sudo asks
        // and read once it's answered (as long as a finger takes), could be changed in between by
        // anything running as this user, and applied with the authority given for this one.
        command: [Config.cmd.sh, "-c", root.sudoAsk, "sh", mode, "",
            Config.cmd.sudo, "-k", "-S", "-p", "", Config.cmd.nihil, "apply", "-"]
        stdinEnabled: true
        onStarted: {
            write(input);
            input = "";
            stdinEnabled = false;
        }
        stderr: SplitParser {
            onRead: line => {
                if (line.trim() !== "")
                    root.detail = line.trim();
            }
        }
        onExited: code => {
            stdinEnabled = true;
            if (root.replaced(applier))
                return;
            if (code === 0) {
                root.phase = "applying";
                root.since = Date.now();
                poll.start();
            } else {
                root.phase = "failed";
                root.failure = code === 1 ? root.auth : code === 2 ? "invalid" : code === 3 ? "busy" : "start";
            }
        }
    }

    Process {
        id: updater

        property string input: ""

        property string mode: "password"

        command: [Config.cmd.sh, "-c", root.sudoAsk, "sh", mode, "",
            Config.cmd.sudo, "-k", "-S", "-p", "", Config.cmd.nihil, "update", "--unit"]
        stdinEnabled: true
        onStarted: {
            write(input);
            input = "";
            stdinEnabled = false;
        }
        stderr: SplitParser {
            onRead: line => {
                if (line.trim() !== "")
                    root.detail = line.trim();
            }
        }
        onExited: code => {
            stdinEnabled = true;
            if (root.replaced(updater))
                return;
            if (code === 0) {
                root.phase = "applying";
                root.since = Date.now();
                poll.start();
            } else {
                root.phase = "failed";
                root.failure = code === 1 ? root.auth : code === 3 ? "busy" : "start";
            }
        }
    }

    Process {
        id: generator

        property string input: ""
        property string mode: "password"
        property string action: "boot"
        property int value: 0

        command: [Config.cmd.sh, "-c", root.sudoAsk, "sh", mode, "",
            Config.cmd.sudo, "-k", "-S", "-p", "", Config.cmd.nihil, "generations", action, String(value)]
            .concat(action === "boot" ? [] : ["--unit"])
        stdinEnabled: true
        onStarted: {
            write(input);
            input = "";
            stdinEnabled = false;
        }
        stderr: SplitParser {
            onRead: line => {
                if (line.trim() !== "")
                    root.detail = line.trim();
            }
        }
        onExited: code => {
            stdinEnabled = true;
            if (root.replaced(generator))
                return;
            if (code === 0 && generator.action === "boot") {
                root.phase = "done";
                root.detail = "";
                Generations.refresh(false);
            } else if (code === 0) {
                root.phase = "applying";
                root.since = Date.now();
                poll.start();
            } else {
                root.phase = "failed";
                root.failure = code === 1 ? root.auth : code === 2 ? "invalid" : code === 3 ? "busy" : code === 5 ? "menu" : "start";
            }
        }
    }

    Process {
        id: passwd

        property string input: ""

        command: [Config.cmd.sh, "-c", root.sudoAsk, "sh", "password", root.newPassword,
            Config.cmd.sudo, "-k", "-S", "-p", "", Config.cmd.nihil, "passwd"]
        stdinEnabled: true
        onStarted: {
            write(input);
            input = "";
            stdinEnabled = false;
        }
        onExited: code => {
            stdinEnabled = true;
            // sudo says 1 when the current password is wrong; nihil passwd, 3 or 4 when it can't change it.
            root.passwordState = code === 0 ? "done" : code === 1 ? "wrong" : "failed";
            // nihil passwd takes the file away; without it having run, it is still there.
            if (code !== 0)
                Quickshell.execDetached([Config.cmd.sh, "-c", 'rm -f -- "$1"', "sh", root.newPassword]);
        }
    }

    Timer {
        id: poll
        interval: 1000
        repeat: true
        onTriggered: {
            if (!peek.running)
                peek.running = true;
        }
    }

    // A unit killed outright (SIGKILL, out of memory) can't say how it ended: running with no
    // unit, for longer than starting one takes, is a failure, or the shell would wait for it.
    readonly property string statusScript: "s=$(cat /run/nihil/apply.status 2>/dev/null); if [ \"$s\" = running ] && ! "
        + Config.cmd.systemctl + " is-active --quiet nihil-apply.service && "
        + "[ $(( $(date +%s) - $(stat -c %Y /run/nihil/apply.status) )) -gt 10 ]; then s=failed; fi; echo \"$s\"; "

    Process {
        id: peek
        command: [Config.cmd.sh, "-c", root.statusScript + "echo --nihil--; cat /run/nihil/apply.kind 2>/dev/null; echo --nihil--; tail -n 60 /run/nihil/apply.log 2>/dev/null; echo --nihil--; " + root.counting + " /run/nihil/apply.log 2>/dev/null"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.report(text)
        }
    }

    IpcHandler {
        target: "widgets"

        function arrange(): void { root.arrangeWidgets(); }
        function done(): void { root.stopArranging(true); }
        function cancel(): void { root.stopArranging(false); }
        function list(): string { return JSON.stringify({ on: root.widgets, at: root.widgetPlaces, size: root.widgetSizes }); }
        // A whole path, from /, as Files' Open with gives it.
        function photo(path: string): void { root.setPhoto(path, true, "", null); }
    }

    IpcHandler {
        target: "settings"

        function open(): void { root.show("", false); }
        function page(name: string): void { root.show(name, false); }
        function toggle(): void { if (root.shown) root.hide(); else root.show("", false); }
        function close(): void {
            if (root.welcoming)
                root.endWelcome();
            else
                root.hide();
        }
        function welcome(): void { root.show("hello", true); }
        function wallpapers(): void { Drawers.toggle("wallpapers", ""); }
        function glass(on: string): void { root.setGlass(on === "on"); }
        function look(): string { return root.glass ? "glass" : "plain"; }
    }
}
