const fs = require("fs");
const path = require("path");
const assert = require("assert");
const source = fs.readFileSync(path.join(__dirname, "../services/Nmcli.js"), "utf8").replace(".pragma library", "");
const N = new Function(source + "\nreturn { fields, sections, status, profiles, ssids, savedBySsid, networks, pick };")();

const mark = "--nihil--";
let passed = 0;
function test(name, body) { body(); passed++; console.log("ok", name); }

test("fields keep an escaped colon and backslash", () => {
    assert.deepStrictEqual(N.fields("*:80:WPA2:Casa\\:5G"), ["*", "80", "WPA2", "Casa:5G"]);
    assert.deepStrictEqual(N.fields("a\\\\b:c"), ["a\\b", "c"]);
});

test("a name with the separator in it is a name", () => {
    const text = ["enabled", mark, "*:71", " :40", mark,
        "wifi:connected:1111-aaaa:Casa---5G", "ethernet:unavailable::", "loopback:connected (externally):2222:lo", ""].join("\n");
    assert.deepStrictEqual(N.status(text, mark), { wifiEnabled: true, strength: 71, wifi: "Casa---5G", wifiUuid: "1111-aaaa", ethernet: "" });
});

test("a whole line of the mark in a name stays in it", () => {
    const text = ["disabled", mark, mark, "wifi:connected:3333:x", mark, "ethernet:connected:4444:Cable", ""].join("\n");
    const now = N.status(text, mark);
    assert.strictEqual(now.wifiEnabled, false);
    assert.strictEqual(now.wifi, "x");
    assert.strictEqual(now.ethernet, "Cable");
});

test("output cut short changes nothing", () => {
    assert.strictEqual(N.status("enabled\n", mark), null);
    assert.strictEqual(N.status("", mark), null);
});

test("the Wi-Fi profiles, each with when it was used", () => {
    const text = ["802-11-wireless:aaaa:1700000000:Wi-Fi connection 1", "802-3-ethernet:bbbb:0:Wired",
        "802-11-wireless:cccc:0:Bar\\:2", ""].join("\n");
    assert.deepStrictEqual(N.profiles(text), [
        { uuid: "aaaa", used: 1700000000, name: "Wi-Fi connection 1" },
        { uuid: "cccc", used: 0, name: "Bar:2" }
    ]);
});

test("each profile's network, and none for one gone", () => {
    const text = ["aaaa:eduroam", "cccc:Bar\\:2", "dddd:", "rest of a broken name", "eeee:not asked", ""].join("\n");
    assert.deepStrictEqual(N.ssids(text, ["aaaa", "cccc", "dddd", "ffff"]),
        { aaaa: "eduroam", cccc: "Bar:2", dddd: "", ffff: "" });
});

test("saved by the network, not the profile's name, the latest of several", () => {
    const profiles = [{ uuid: "a", used: 10, name: "Wi-Fi connection 1" }, { uuid: "b", used: 50, name: "Casa 1" },
        { uuid: "c", used: 20, name: "Casa" }, { uuid: "d", used: 0, name: "Gone" }];
    const saved = N.savedBySsid(profiles, { a: "eduroam", b: "Casa", c: "Casa", d: "" });
    assert.deepStrictEqual(Object.keys(saved).sort(), ["Casa", "eduroam"]);
    assert.strictEqual(saved.Casa.uuid, "b");
    assert.strictEqual(saved.eduroam.uuid, "a");
});

test("networks: one per SSID, an SSID with the separator, a saved enterprise one", () => {
    const saved = N.savedBySsid([{ uuid: "a", used: 1, name: "Wi-Fi connection 1" }], { a: "eduroam" });
    const text = [" :40:WPA2 802.1X:eduroam", " :62:WPA2 802.1X:eduroam", "*:80:WPA2:Casa", " :30:WPA2:a---b",
        " :90:--:Cafe", " :55::constructor", " :20:WPA2:", ""].join("\n");
    const nets = N.networks(text, saved);
    assert.deepStrictEqual(nets.map(n => n.ssid), ["Casa", "eduroam", "Cafe", "constructor", "a---b"]);
    const edu = nets.find(n => n.ssid === "eduroam");
    assert.deepStrictEqual(edu, { ssid: "eduroam", signal: 62, secure: true, enterprise: true, active: false, saved: true, uuid: "a" });
    assert.strictEqual(nets.find(n => n.ssid === "Cafe").secure, false);
    assert.strictEqual(nets.find(n => n.ssid === "constructor").saved, false);
});

test("Nilo's pick: saved first, by name or network, then in range", () => {
    const saved = Object.assign(Object.create(null), { "Wi-Fi connection 1": "a", eduroam: "a", "Casa": "b" });
    const seen = Object.assign(Object.create(null), { "MOVISTAR_1234": true, "Cafe Libre": false });
    assert.deepStrictEqual(N.pick("casa", saved, seen), { uuid: "b", label: "Casa" });
    assert.deepStrictEqual(N.pick("Edu Roam", saved, seen), { uuid: "a", label: "eduroam" });
    assert.deepStrictEqual(N.pick("cafe", saved, seen), { ssid: "Cafe Libre", secure: false });
    assert.strictEqual(N.pick("", saved, seen), null);
    assert.strictEqual(N.pick("hotel", saved, seen), null);
});

console.log(passed, "passed");
