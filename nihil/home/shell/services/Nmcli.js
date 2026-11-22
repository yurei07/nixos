.pragma library

// What nmcli -t prints, read. Names and SSIDs are anyone's to choose (an access point's, whoever
// set it up), so nothing here takes a separator for granted inside one.

// One line's fields: split at a colon, where \: and \\ are a colon and a backslash.
function fields(line) {
    const out = [];
    let cur = "";
    for (let i = 0; i < line.length; i++) {
        const c = line[i];
        if (c === "\\" && i + 1 < line.length) {
            cur += line[++i];
            continue;
        }
        if (c === ":") {
            out.push(cur);
            cur = "";
            continue;
        }
        cur += c;
    }
    out.push(cur);
    return out;
}

// Several commands' output in one, each after a line that says only `mark`: the lines of each,
// or null if a mark is missing. Only the first count - 1 split it, so the last command's, the
// one that names things, can hold any line at all.
function sections(text, mark, count) {
    const out = [[]];
    for (const line of String(text).split("\n")) {
        if (line === mark && out.length < count)
            out.push([]);
        else if (line !== "")
            out[out.length - 1].push(line);
    }
    return out.length === count ? out : null;
}

// `-f WIFI general`, `-f IN-USE,SIGNAL device wifi list` and `-f TYPE,STATE,CON-UUID,CONNECTION
// device`, in that order, the names last.
function status(text, mark) {
    const parts = sections(text, mark, 3);
    if (parts === null)
        return null;
    const out = { wifiEnabled: parts[0].join("").trim() === "enabled", strength: 0, wifi: "", wifiUuid: "", ethernet: "" };
    for (const line of parts[1]) {
        const f = fields(line);
        if (f[0] === "*")
            out.strength = parseInt(f[1]) || 0;
    }
    for (const line of parts[2]) {
        const f = fields(line);
        if (f.length < 4 || !/^connected( |$)/.test(f[1]))
            continue;
        if (f[0] === "wifi" && out.wifi === "") {
            out.wifi = f.slice(3).join(":");
            out.wifiUuid = f[2];
        }
        if (f[0] === "ethernet" && out.ethernet === "")
            out.ethernet = f.slice(3).join(":");
    }
    return out;
}

// `-f TYPE,UUID,TIMESTAMP,NAME connection show`: the Wi-Fi profiles, and when each last connected.
function profiles(text) {
    const out = [];
    for (const line of String(text).split("\n")) {
        const f = fields(line);
        if (f.length >= 4 && f[0] === "802-11-wireless" && f[1] !== "")
            out.push({ uuid: f[1], used: Number(f[2]) || 0, name: f.slice(3).join(":") });
    }
    return out;
}

// A «UUID:SSID» line for each profile asked about (`-g 802-11-wireless.ssid`, escaped as -t is).
// Any other line is the rest of an SSID with a line break in it, which stops at the break; a
// profile with no line, gone meanwhile, has none.
function ssids(text, asked) {
    const out = {};
    for (const line of String(text).split("\n")) {
        const at = line.indexOf(":");
        const uuid = line.slice(0, at);
        if (at <= 0 || asked.indexOf(uuid) < 0 || out.hasOwnProperty(uuid))
            continue;
        out[uuid] = fields(line.slice(at + 1)).join(":");
    }
    for (const uuid of asked) {
        if (!out.hasOwnProperty(uuid))
            out[uuid] = "";
    }
    return out;
}

// Each SSID's profile: the one last used, where there are several (one made again, «Casa 1»).
function savedBySsid(profiles, ssidOf) {
    const out = Object.create(null);
    for (const profile of profiles) {
        const ssid = ssidOf[profile.uuid];
        if (!ssid)
            continue;
        if (!(ssid in out) || profile.used > out[ssid].used)
            out[ssid] = profile;
    }
    return out;
}

// `-f IN-USE,SIGNAL,SECURITY,SSID device wifi list`: one network per SSID, the one in use or else
// the strongest; the connected one first, then the saved ones, then by signal.
function networks(text, saved) {
    const bySsid = Object.create(null);
    for (const line of String(text).split("\n")) {
        const f = fields(line);
        if (f.length < 4)
            continue;
        const ssid = f.slice(3).join(":");
        if (ssid === "")
            continue;
        const profile = saved[ssid] ?? null;
        const net = {
            ssid: ssid,
            signal: parseInt(f[1]) || 0,
            secure: f[2] !== "" && f[2] !== "--",
            enterprise: f[2].indexOf("802.1X") >= 0,
            active: f[0] === "*",
            saved: profile !== null,
            uuid: profile !== null ? profile.uuid : ""
        };
        const old = bySsid[ssid];
        if (!old || net.active || (!old.active && net.signal > old.signal))
            bySsid[ssid] = net;
    }
    return Object.keys(bySsid).map(ssid => bySsid[ssid])
        .sort((a, b) => (b.active - a.active) || (b.saved - a.saved) || (b.signal - a.signal));
}

// The network Nilo was asked to join: the one with that name, spaces, dashes, underscores and
// case aside, or else the only one that holds it or that it holds. The saved ones first
// (`saved`: a profile's name or its SSID, to its UUID), then those in range (`seen`: SSID, to
// whether it asks for a password).
function pick(name, saved, seen) {
    const flat = t => String(t ?? "").toLowerCase().replace(/[\s_-]+/g, "");
    const wanted = flat(name);
    if (!wanted)
        return null;
    const near = list => {
        const same = list.filter(n => flat(n) === wanted);
        if (same.length > 0)
            return same[0];
        const close = list.filter(n => flat(n).length > 2 && (flat(n).includes(wanted) || wanted.includes(flat(n))));
        return close.length === 1 ? close[0] : "";
    };
    const known = near(Object.keys(saved));
    if (known)
        return { uuid: saved[known], label: known };
    const visible = near(Object.keys(seen));
    if (!visible)
        return null;
    return { ssid: visible, secure: seen[visible] };
}
