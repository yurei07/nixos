pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.UPower
import qs.config

Singleton {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property bool present: device?.isLaptopBattery ?? false
    readonly property real level: {
        const p = device?.percentage ?? 0;
        return p > 1 ? p / 100 : p;
    }
    readonly property bool charging: device?.state === UPowerDeviceState.Charging
                                     || device?.state === UPowerDeviceState.PendingCharge
    readonly property bool full: device?.state === UPowerDeviceState.FullyCharged
    readonly property bool low: present && !charging && level <= 0.15

    readonly property var thresholds: [0.15, 0.10, 0.05]
    readonly property int band: thresholds.filter(t => level <= t + 0.0001).length
    property int warned: 0

    property bool armed: false

    Timer {
        interval: 4000
        running: true
        onTriggered: {
            root.armed = true;
            root.check();
        }
    }

    onChargingChanged: {
        if (charging && armed) {
            Glyph.charge();
            if (!Notifs.dnd) Sounds.play(Config.sounds.charge, 0.4);
        }
        check();
    }
    onBandChanged: check()
    onFullChanged: check()
    onPresentChanged: check()

    function check(): void {
        if (!armed || !present) return;
        if (charging || full) {
            if (warned > 0) Notifs.dismissTag("battery");
            warned = Math.min(warned, band);
            return;
        }
        if (band > warned) {
            warned = band;
            warn(Math.round(level * 100), band === thresholds.length);
        }
    }

    function warn(percent: int, last: bool): void {
        Quickshell.execDetached([Config.cmd.notifySend, "--urgency=critical", "--app-name=" + Lang.batteryApp,
                                 "--hint=string:x-nihil-tag:battery", "--",
                                 Lang.batteryLow.arg(percent), last ? Lang.batteryLowLast : Lang.batteryLowPlug]);
    }

    IpcHandler {
        target: "battery"

        function warn(percent: int): void { root.warn(percent, percent <= 5); }
    }
}
