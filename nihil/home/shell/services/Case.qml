pragma Singleton

import Quickshell

Singleton {
    function sentence(text: string): string {
        const s = String(text ?? "");
        return s.length > 0 ? s.charAt(0).toLocaleUpperCase() + s.slice(1) : s;
    }

    function key(name: string): string {
        const part = String(name ?? "").trim();
        const upper = part.toUpperCase();
        const modifiers = { SUPER: "Super", WIN: "Super", LOGO: "Super", MOD4: "Super", META: "Super",
                            CTRL: "Ctrl", CONTROL: "Ctrl", SHIFT: "Shift", ALT: "Alt", MOD1: "Alt" };
        if (upper in modifiers)
            return modifiers[upper];
        if (part.length === 1 || /^F[0-9]+$/i.test(part))
            return upper;
        if (part.indexOf(":") >= 0)
            return part;
        if (part === upper)
            return part.charAt(0) + part.slice(1).toLowerCase();
        return part.charAt(0).toUpperCase() + part.slice(1);
    }

    // A count in a text: `one` for one, in its own words («1 archivo»), `many` with the number for
    // any other. Either takes the text's other %n after it, as .arg fills the lowest one left.
    function count(n: real, one: string, many: string): string {
        return n === 1 ? one : many.arg(n);
    }

    function keys(combo: string): string {
        return String(combo ?? "").split("+").map(part => part.trim()).filter(part => part !== "")
            .map(part => key(part)).join(" + ");
    }
}
