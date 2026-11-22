pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import "Nmcli.js" as Nmcli

Singleton {
    id: root

    property bool wifiEnabled: true
    property string ssid: ""        // the active Wi-Fi connection's name
    property string wifiUuid: ""    // and its profile's
    property int strength: 0
    property string ethernet: ""    // the active wired connection's name
    property var networks: []
    property bool scanning: false
    property string pending: ""     // SSID being connected
    property string askPassword: "" // SSID waiting for a password
    property string error: ""
    // What has the networks in view (a panel on each screen, Preferences): while anything does,
    // they're scanned and the state read more often. Each says so for itself, so one closing
    // doesn't stop what another still shows.
    property var watchers: []
    readonly property bool watch: watchers.length > 0

    // The Wi-Fi profiles, and the network each one is for, looked up once a profile: its name
    // needn't be its network's (nm-connection-editor's are «Wi-Fi connection 1»).
    property var profiles: []
    property var ssidOf: ({})

    readonly property bool connected: ssid !== "" || ethernet !== ""
    readonly property string mark: "--nihil--"

    function watching(who: var, on: bool): void {
        const others = root.watchers.filter(other => other !== who);
        root.watchers = on ? others.concat([who]) : others;
    }

    function refresh(): void {
        if (!status.running) status.running = true;
    }

    // A scan asked for while one runs comes after it, once however often it was asked: what
    // asked may know of something newer (a network just joined, Wi-Fi just turned on for Nilo).
    // What waits for one is told when it's read.
    property var scanWaiting: []
    property var scanNext: []
    property bool scanAgain: false

    function scan(then: var): void {
        if (listing.running || lookup.running || inRange.running) {
            root.scanAgain = true;
            if (then)
                root.scanNext = root.scanNext.concat([then]);
            return;
        }
        root.scanning = true;
        root.scanWaiting = then ? [then] : [];
        listing.running = true;
    }

    function scanned(): void {
        const waiting = root.scanWaiting;
        root.scanWaiting = root.scanNext;
        root.scanNext = [];
        if (root.scanAgain) {
            root.scanAgain = false;
            listing.running = true;
        } else {
            root.scanning = false;
        }
        for (const then of waiting)
            then();
    }

    function rescan(): void {
        if (!rescanning.running) rescanning.running = true;
    }

    // Shown at once; the last click is the one that counts, and the state read while it's
    // being changed doesn't show the old one back.
    function setWifi(on: bool): void {
        root.wifiEnabled = on;
        radio.wanted = on;
        if (!radio.running) radio.send();
    }

    // The body is markup, as the notification spec has it: an SSID is shown as written.
    function notify(text: string): void {
        Quickshell.execDetached([Config.cmd.notifySend, "-a", "NIHIL", "-u", "low", "--", "Wi-Fi",
            text.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;")]);
    }

    function editor(): void {
        Apps.run([Config.cmd.nmEditor]);
    }

    function finish(net, code: int): void {
        root.pending = "";
        if (code === 0) {
            root.askPassword = "";
            root.error = "";
            root.notify(Lang.connectedTo.arg(net.ssid));
        } else if (net.secure && !net.enterprise) {
            root.askPassword = net.ssid;
            root.error = Lang.connectFailed;
        } else {
            root.error = Lang.connectFailed;
        }
        root.refresh();
        root.scan();
    }

    function connect(net, password: string): void {
        root.error = "";
        // One saved already (eduroam, set up once in the editor) connects as any other.
        if (net.enterprise && !net.saved) {
            root.notify(Lang.enterpriseHint.arg(net.ssid));
            root.editor();
            return;
        }
        const nm = Config.cmd.nmcli;
        const done = code => root.finish(net, code);
        // The key goes through stdin, and from there only through sh's own printf: a command's
        // arguments are there for any process to read in /proc while nmcli waits for the network.
        // A saved one is brought up by its profile, the one that's for this network, whatever
        // it's called.
        if (net.saved && !password) {
            root.run([nm, "connection", "up", "uuid", net.uuid], done, "", net.ssid);
        } else if (net.saved) {
            root.run([Config.cmd.sh, "-c", 'IFS= read -r key; printf "802-11-wireless-security.psk:%s\\n" "$key" | "$1" connection up uuid "$2" passwd-file /dev/stdin',
                      "sh", nm, net.uuid], done, password + "\n", net.ssid);
        } else if (!net.secure) {
            root.run([nm, "device", "wifi", "connect", net.ssid], done, "", net.ssid);
        } else if (password) {
            // A key that doesn't work leaves the profile it was saved in, made by this attempt;
            // that one goes, and only that one: another might have this network's name.
            root.run([Config.cmd.sh, "-c", 'IFS= read -r key; before=$("$1" -t -f UUID connection show)\n'
                      + 'printf "%s\\n" "$key" | "$1" --ask device wifi connect "$2" && exit 0\n'
                      + '"$1" -t -f UUID,TYPE connection show | while IFS=: read -r uuid type; do\n'
                      + '    [ "$type" = 802-11-wireless ] || continue\n'
                      + '    case "$before" in *"$uuid"*) ;; *) "$1" connection delete uuid "$uuid" > /dev/null 2>&1 ;; esac\n'
                      + 'done\nexit 1',
                      "sh", nm, net.ssid], done, password + "\n", net.ssid);
        } else {
            root.askPassword = net.ssid;
        }
    }

    function disconnect(): void {
        if (root.wifiUuid)
            root.run([Config.cmd.nmcli, "connection", "down", "uuid", root.wifiUuid], () => { root.refresh(); root.scan(); }, "", "");
    }

    property var joining: null

    function join(name: string, done: var): void {
        if (root.joining) {
            done({ ok: false, error: "Wi-Fi is already joining a network: try again in a moment" });
            return;
        }
        root.joining = { name: name, done: done };
        joinLimit.restart();
        looking.running = true;
    }

    function joined(answer: var): void {
        const done = root.joining?.done;
        root.joining = null;
        joinLimit.stop();
        root.refresh();
        if (done) done(answer);
    }

    function choose(): void {
        if (!root.joining)
            return;
        const name = root.joining.name;
        root.wifiEnabled = true;
        // What Nilo may call a saved one: its profile's name, or its network's.
        const saved = Object.create(null);
        for (const profile of root.profiles)
            saved[profile.name] = profile.uuid;
        const bySsid = Nmcli.savedBySsid(root.profiles, root.ssidOf);
        for (const ssid of Object.keys(bySsid))
            saved[ssid] = bySsid[ssid].uuid;
        const seen = Object.create(null);
        for (const net of root.networks)
            seen[net.ssid] = net.secure;
        const net = Nmcli.pick(name, saved, seen);
        if (!net) {
            const names = Object.keys(saved), around = Object.keys(seen).slice(0, 8);
            root.joined({ ok: false, error: "no Wi-Fi network called " + name
                + (names.length ? "; saved: " + names.join(", ") : "")
                + (around.length ? "; in range: " + around.join(", ") : "") });
        } else if (!net.uuid && net.secure) {
            root.joined({ ok: false, error: net.ssid + " needs its password: join it once from the panel" });
        } else {
            joinUp.target = net.label || net.ssid;
            joinUp.command = net.uuid
                ? [Config.cmd.nmcli, "--wait", "30", "connection", "up", "uuid", net.uuid]
                : [Config.cmd.nmcli, "--wait", "30", "device", "wifi", "connect", net.ssid];
            joinUp.running = true;
        }
    }

    // One connection command at a time. One asked for while another runs waits, and only the
    // latest: the network clicked last is the one wanted, and the outcome of what it replaces
    // isn't told.
    property var afterAction: null
    property var queued: null

    function run(command: var, callback: var, input: var, ssid: var): void {
        const job = { command: command, callback: callback ?? null, input: input ?? "", ssid: ssid ?? "" };
        if (action.running) {
            root.queued = job;
            root.pending = job.ssid;
            return;
        }
        root.start(job);
    }

    function start(job: var): void {
        root.afterAction = job.callback;
        root.pending = job.ssid;
        action.input = job.input;
        action.command = job.command;
        action.running = true;
    }

    Process {
        id: action

        property string input: ""

        stdinEnabled: true
        onStarted: {
            write(input);
            input = "";
            stdinEnabled = false;
        }
        onExited: (code, status) => {
            stdinEnabled = true;
            const callback = root.afterAction;
            root.afterAction = null;
            const next = root.queued;
            root.queued = null;
            if (next !== null)
                root.start(next);
            else if (callback)
                callback(code);
        }
    }

    Process {
        id: radio

        property bool wanted: true
        property bool sent: true

        function send(): void {
            radio.sent = radio.wanted;
            radio.command = [Config.cmd.nmcli, "radio", "wifi", radio.wanted ? "on" : "off"];
            radio.running = true;
        }

        onExited: {
            if (radio.wanted !== radio.sent) {
                radio.send();
                return;
            }
            root.refresh();
            root.scan();
        }
    }

    Process {
        id: rescanning
        command: [Config.cmd.nmcli, "device", "wifi", "rescan"]
        onExited: root.scan()
    }

    // Wi-Fi on, and the card ready for it, before the networks are read for Nilo.
    Process {
        id: looking
        command: [Config.cmd.sh, "-c", `nm=$1
"$nm" radio wifi on
for _ in 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19 20; do
    case "$("$nm" -t -f TYPE,STATE device)" in *wifi:disconnected*|*wifi:conn*) break ;; esac
    sleep 0.3
done`, "sh", Config.cmd.nmcli]
        onExited: if (root.joining) root.scan(() => root.choose())
    }

    Process {
        id: joinUp
        property string target: ""
        property string said: ""
        onRunningChanged: if (running) said = ""
        stderr: SplitParser { onRead: line => { if (line.trim() !== "") joinUp.said = line.trim(); } }
        onExited: code => root.joined(code === 0 ? { ok: true, value: joinUp.target }
            : { ok: false, error: "could not join " + joinUp.target + (joinUp.said ? ": " + joinUp.said : "") })
    }

    Timer {
        id: joinLimit
        interval: 50000
        onTriggered: if (root.joining) root.joined({ ok: false, error: "Wi-Fi did not answer" })
    }

    // Each command on its own, or the names last: an SSID or a profile's name can hold whatever
    // would separate two outputs.
    Process {
        id: status
        command: [Config.cmd.sh, "-c", 'nm=$1; mark=$2; "$nm" -t -f WIFI general; echo "$mark"; '
            + '"$nm" -t -f IN-USE,SIGNAL device wifi list --rescan no; echo "$mark"; "$nm" -t -f TYPE,STATE,CON-UUID,CONNECTION device',
            "sh", Config.cmd.nmcli, root.mark]
        stdout: StdioCollector {
            onStreamFinished: {
                const now = Nmcli.status(text, root.mark);
                if (now === null)
                    return;
                if (!radio.running)
                    root.wifiEnabled = now.wifiEnabled;
                root.ssid = now.wifi;
                root.wifiUuid = now.wifiUuid;
                root.ethernet = now.ethernet;
                root.strength = now.strength;
            }
        }
    }

    Process {
        id: listing
        command: [Config.cmd.nmcli, "-t", "-f", "TYPE,UUID,TIMESTAMP,NAME", "connection", "show"]
        stdout: StdioCollector {
            onStreamFinished: {
                const found = Nmcli.profiles(text);
                const known = {};
                for (const profile of found) {
                    if (root.ssidOf.hasOwnProperty(profile.uuid))
                        known[profile.uuid] = root.ssidOf[profile.uuid];
                }
                root.profiles = found;
                root.ssidOf = known;
                const unknown = found.map(profile => profile.uuid).filter(uuid => !known.hasOwnProperty(uuid));
                if (unknown.length > 0) {
                    lookup.asked = unknown;
                    lookup.running = true;
                } else {
                    inRange.running = true;
                }
            }
        }
    }

    Process {
        id: lookup
        property var asked: []
        command: [Config.cmd.sh, "-c", 'nm=$1; shift; for uuid; do '
            + 'ssid=$("$nm" -g 802-11-wireless.ssid connection show uuid "$uuid" 2> /dev/null) || ssid=""; '
            + 'printf "%s:%s\\n" "$uuid" "$ssid"; done', "sh", Config.cmd.nmcli].concat(asked)
        stdout: StdioCollector {
            onStreamFinished: {
                root.ssidOf = Object.assign({}, root.ssidOf, Nmcli.ssids(text, lookup.asked));
                inRange.running = true;
            }
        }
    }

    Process {
        id: inRange
        command: [Config.cmd.nmcli, "-t", "-f", "IN-USE,SIGNAL,SECURITY,SSID", "device", "wifi", "list", "--rescan", "auto"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.networks = Nmcli.networks(text, Nmcli.savedBySsid(root.profiles, root.ssidOf));
                root.scanned();
            }
        }
    }

    // NetworkManager tells of every change, so the state is read then, and once a minute besides,
    // not every few seconds whether anything changed or not. Its lines aren't read: they're in
    // the user's language, and any of them means a change.
    Process {
        id: monitor
        running: true
        command: [Config.cmd.nmcli, "monitor"]
        stdout: SplitParser { onRead: line => changed.restart() }
        onExited: monitorAgain.restart()
    }

    Timer {
        id: changed
        interval: 300
        onTriggered: {
            root.refresh();
            if (root.watch)
                root.scan();
        }
    }

    Timer {
        id: monitorAgain
        interval: 10000
        onTriggered: monitor.running = true
    }

    // The signal has no event: while the networks are in view, it's read every few seconds.
    Timer {
        interval: root.watch ? 2500 : 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Timer {
        interval: 12000
        running: root.watch && root.wifiEnabled
        repeat: true
        triggeredOnStart: true
        onTriggered: root.scan()
    }
}
