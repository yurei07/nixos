pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth
import Quickshell.Io
import qs.config

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool enabled: turningOn || adapter?.state === BluetoothAdapterState.Enabled
    readonly property bool discovering: adapter?.discovering ?? false

    readonly property var all: (adapter?.devices ?? Bluetooth.devices)?.values ?? []
    readonly property var devices: all
        .filter(d => d.paired || d.connected || root.discovering)
        .sort((a, b) => (b.connected - a.connected) || (b.paired - a.paired) || a.name.localeCompare(b.name))
    readonly property var connected: all.filter(d => d.connected)

    property bool turningOn: false
    property int waited: 0

    // Off is an rfkill block, not just the adapter powered down: systemd-rfkill keeps it
    // through restarts and sleep, and BlueZ powers the adapter on whenever it's unblocked.
    function setEnabled(on: bool): void {
        power.stop();
        root.turningOn = on;
        if (on) {
            root.waited = 0;
            unblock.running = true;
        } else {
            block.running = true;
        }
    }

    function write(adapter: var, on: bool): void {
        if (adapter.enabled === on) adapter.enabled = !on;
        adapter.enabled = on;
    }

    function scan(on: bool): void {
        if (adapter) adapter.discovering = on;
    }

    function toggleDevice(d): void {
        if (d.connected) d.disconnect();
        else if (d.paired) d.connect();
        else { d.trusted = true; d.pair(); }
    }

    property var reaching: null

    function find(name: string, among: var): var {
        const flat = t => String(t ?? "").toLowerCase().replace(/[\s_-]+/g, "");
        const wanted = flat(name);
        if (!wanted) return null;
        const close = among.filter(d => flat(d.name).length > 2 && (flat(d.name).includes(wanted) || wanted.includes(flat(d.name))));
        return among.find(d => flat(d.name) === wanted) ?? (close.length === 1 ? close[0] : null);
    }

    function reach(name: string, connect: bool, done: var): void {
        if (!connect) {
            const targets = name ? [root.find(name, root.connected)].filter(d => d) : root.connected;
            if (targets.length === 0) {
                done({ ok: false, error: name ? name + " is not connected" : "no Bluetooth device is connected" });
                return;
            }
            for (const d of targets) d.disconnect();
            done({ ok: true, value: targets.map(d => d.name).join(", ") });
            return;
        }
        if (root.reaching) {
            done({ ok: false, error: "Bluetooth is already connecting a device: try again in a moment" });
            return;
        }
        root.reaching = { name: name, done: done, device: null, waited: 0 };
        if (!root.enabled) root.setEnabled(true);
        reacher.start();
    }

    function reached(answer: var): void {
        const done = root.reaching?.done;
        root.reaching = null;
        reacher.stop();
        if (done) done(answer);
    }

    Timer {
        id: reacher
        interval: 500
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const r = root.reaching;
            if (!r) {
                stop();
                return;
            }
            r.waited++;
            if (!r.device) {
                if (root.adapter?.state !== BluetoothAdapterState.Enabled) {
                    if (r.waited > 30) root.reached({ ok: false, error: "Bluetooth did not come on" });
                    return;
                }
                const paired = root.all.filter(d => d.paired);
                const d = root.find(r.name, paired);
                if (!d) {
                    root.reached({ ok: false, error: paired.length === 0 ? "there are no paired devices: pair it once from the panel"
                        : "no paired device called " + r.name + "; paired: " + paired.map(d => d.name).join(", ") });
                    return;
                }
                if (d.connected) {
                    root.reached({ ok: true, value: d.name });
                    return;
                }
                r.device = d;
                r.waited = 0;
                d.connect();
                return;
            }
            if (r.device.connected) root.reached({ ok: true, value: r.device.name });
            else if (r.waited > 40) root.reached({ ok: false, error: r.device.name + " did not connect: is it on and nearby?" });
        }
    }

    Process {
        id: unblock
        command: [Config.cmd.rfkill, "unblock", "bluetooth"]
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") console.warn("nihil: bluetooth: rfkill:", text.trim())
        }
        // Turned off again while this ran: block it once more, whichever finished first.
        onExited: {
            if (root.turningOn) power.start();
            else block.running = true;
        }
    }

    Process {
        id: block
        command: [Config.cmd.rfkill, "block", "bluetooth"]
        stderr: StdioCollector {
            onStreamFinished: if (text.trim() !== "") console.warn("nihil: bluetooth: rfkill:", text.trim())
        }
    }

    Timer {
        id: power
        interval: 500
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            const adapter = root.adapter;
            if (adapter?.state === BluetoothAdapterState.Enabled) {
                root.turningOn = false;
                stop();
            } else if (++root.waited > 30) {
                console.warn("nihil: bluetooth: did not come on:", adapter ? BluetoothAdapterState.toString(adapter.state) : "no adapter");
                root.turningOn = false;
                stop();
            } else if (adapter?.state === BluetoothAdapterState.Disabled) {
                root.write(adapter, true);
            }
        }
    }
}
