pragma Singleton

import QtQuick
import Quickshell
import qs.config

Singleton {
    function moment(seconds: real): string {
        const date = new Date(seconds * 1000);
        const time = Qt.formatDateTime(date, "HH:mm");
        const today = new Date();
        today.setHours(0, 0, 0, 0);
        const day = new Date(date.getTime());
        day.setHours(0, 0, 0, 0);
        const ago = Math.round((today.getTime() - day.getTime()) / 86400000);
        if (ago === 0)
            return Lang.genToday.arg(time);
        if (ago === 1)
            return Lang.genYesterday.arg(time);
        return Case.sentence(date.toLocaleString(Qt.locale(Lang.locale), Lang.dateShort)) + ", " + time;
    }

    // A day within a sentence: «3 de marzo».
    function day(seconds: real): string {
        return new Date(seconds * 1000).toLocaleString(Qt.locale(Lang.locale), Lang.dateShort);
    }

    function bytes(count: real): string {
        const units = ["B", "KB", "MB", "GB", "TB"];
        let value = Math.max(0, count);
        let unit = 0;
        while (value >= 1000 && unit < units.length - 1) {
            value /= 1000;
            unit++;
        }
        return value.toLocaleString(Qt.locale(Lang.locale), "f", value < 100 && unit > 0 ? 1 : 0) + " " + units[unit];
    }
}
