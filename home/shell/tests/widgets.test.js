const fs = require("fs");
const path = require("path");
const assert = require("assert");
const load = (file, names) => new Function(fs.readFileSync(path.join(__dirname, file), "utf8").replace(".pragma library", "")
    + "\nreturn { " + names + " };")();
const W = load("../services/Widgets.js", "kindOf, several, known, instances, freeName, size, read, settle");
const D = load("../background/Desk.js", "clear, room, beside, scaled, stretched");

let passed = 0;
function test(name, body) { body(); passed++; console.log("ok", name); }

const kinds = ["clock", "calendar", "photo", "note", "github"];

test("photos and notes can be several, the rest one each", () => {
    assert.strictEqual(W.kindOf("photo-12"), "photo");
    assert.strictEqual(W.kindOf("note"), "note");
    assert.strictEqual(W.kindOf("note-2"), "note");
    assert.strictEqual(W.kindOf("clock-2"), "clock-2");
    assert.strictEqual(W.kindOf("photo-1"), "photo-1");
    assert.strictEqual(W.kindOf("photo-02"), "photo-02");
    assert.ok(W.several("photo") && W.several("note-3") && !W.several("clock"));
    assert.ok(W.known("photo-7", kinds) && W.known("clock", kinds));
    assert.ok(!W.known("clock-2", kinds) && !W.known("weather", kinds) && !W.known("photo-1", kinds));
});

test("those of a kind, the first first, by number and not by name", () => {
    assert.deepStrictEqual(W.instances(["clock", "photo-10", "note", "photo-2", "photo"], "photo"), ["photo", "photo-2", "photo-10"]);
    assert.deepStrictEqual(W.instances(["clock"], "note"), []);
});

test("a new one takes the first name no one has", () => {
    assert.strictEqual(W.freeName("photo", [], []), "photo");
    assert.strictEqual(W.freeName("photo", ["photo", "photo-3"], []), "photo-2");
    assert.strictEqual(W.freeName("photo", ["photo"], ["photo-2"]), "photo-3");
    assert.strictEqual(W.freeName("note", ["photo", "photo-2"], []), "note");
});

test("sizes as they're kept", () => {
    assert.strictEqual(W.size(1.25), 1.25);
    assert.deepStrictEqual(W.size([320.4, 248]), [320, 248]);
    for (const bad of [0.2, 4, NaN, "1", [10, 10], [300], [300, 200, 1], [300, Infinity], null])
        assert.strictEqual(W.size(bad), null, String(bad));
});

test("what widgets.json holds, kept to what makes sense", () => {
    const kept = W.read(JSON.stringify({
        on: ["clock", "photo", "photo-2", "photo-2", "weather", "clock-2", 3],
        at: { clock: [16.4, 8], "photo-2": [-1, 0], note: [0, 0], weather: [0, 0] },
        size: { clock: 1.5, "photo-2": [300, 200], note: "big" },
        opts: { github: { user: "poligle", n: 1, ok: true, bad: { a: 1 } }, "note-2": { text: "# Hi" }, weather: { place: "x" }, photo: [1] },
    }), kinds);
    assert.deepStrictEqual(kept.on, ["clock", "photo", "photo-2"]);
    assert.deepStrictEqual(kept.at, { clock: [16, 8], note: [0, 0] });
    assert.deepStrictEqual(kept.size, { clock: 1.5, "photo-2": [300, 200] });
    assert.deepStrictEqual(kept.opts, { github: { user: "poligle", n: 1, ok: true }, "note-2": { text: "# Hi" } });
    assert.deepStrictEqual(W.read(JSON.stringify(["clock", "nope"]), kinds).on, ["clock"]);
    assert.strictEqual(W.read(JSON.stringify({ at: {} }), kinds).on, null);
    assert.strictEqual(W.read("not json", kinds), null);
});

test("pictures once arranging ends", () => {
    // photo-2 got a new picture, photo-3 came and went, photo-4 was thrown away, photo-5 is new.
    const on = ["photo", "photo-2", "photo-5"];
    assert.deepStrictEqual(W.settle(true, on, ["photo-4"], ["photo-2", "photo-3", "photo-5"]),
        { remove: ["photo-4", "photo-4.staged", "photo-3.staged"], move: ["photo-2", "photo-5"] });
    assert.deepStrictEqual(W.settle(false, on, ["photo-4"], ["photo-2", "photo-3", "photo-5"]),
        { remove: ["photo-2.staged", "photo-3.staged", "photo-5.staged"], move: [] });
    // One given a picture and then thrown away goes with both.
    assert.deepStrictEqual(W.settle(true, ["photo"], ["photo-2"], ["photo-2"]), { remove: ["photo-2", "photo-2.staged"], move: [] });
});

const desk = { w: 1000, h: 600 };
const box = (x, y, w, h) => ({ x: x, y: y, w: w, h: h });
const s = { gap: 14, cell: 8, smallest: 0.75, largest: 2.5 };

test("a place on the grid, clear of the others", () => {
    assert.deepStrictEqual(D.room(100, 100, 3, 5, [], desk, 14, 8), { x: 0, y: 8 });
    const taken = [box(0, 0, 200, 200)];
    const at = D.room(100, 100, 0, 0, taken, desk, 14, 8);
    assert.ok(D.clear(box(at.x, at.y, 100, 100), taken, 14));
    assert.ok(at.x % 8 === 0 && at.y % 8 === 0);
    // Within the desk, however far it's asked.
    assert.deepStrictEqual(D.room(100, 100, 5000, 5000, [], desk, 14, 8), { x: 896, y: 496 });
});

test("beside one: right or left, then under or over, then the nearest", () => {
    const note = box(0, 0, 240, 160);
    assert.deepStrictEqual(D.beside(note, 240, 160, [], desk, 14, 8), { x: 256, y: 0 });
    assert.deepStrictEqual(D.beside(note, 240, 160, [box(256, 0, 100, 100)], desk, 14, 8), { x: 0, y: 176 });
    const right = box(760, 0, 240, 160);
    assert.deepStrictEqual(D.beside(right, 240, 160, [], desk, 14, 8), { x: 504, y: 0 });
    // Hemmed in on both sides and below: the nearest place free, clear of it too.
    const hemmed = box(400, 0, 200, 160);
    const around = [box(0, 0, 386, 600), box(614, 0, 386, 600), box(400, 174, 200, 100)];
    const at = D.beside(hemmed, 100, 100, around, desk, 14, 8);
    assert.ok(D.clear(box(at.x, at.y, 100, 100), around.concat([hemmed]), 14), JSON.stringify(at));
    // Nowhere free: right of it all the same.
    assert.deepStrictEqual(D.beside(note, 240, 160, [box(256, 0, 744, 600), box(0, 176, 256, 424)], desk, 14, 8), { x: 256, y: 0 });
});

test("growing as a whole stops short of the one in its way", () => {
    const clock = { x: 0, y: 0, base: 320, tall: 185 };
    assert.strictEqual(D.scaled(clock, 1, 160, 60, [box(344, 0, 320, 148)], desk, s), 328 / 320);
    assert.strictEqual(D.scaled(clock, 1, 2000, 2000, [], desk, s), 2.5);
    assert.strictEqual(D.scaled(clock, 1, 2000, 2000, [], { w: 1000, h: 400 }, s), Math.floor(320 * 400 / 185 / 8) * 8 / 320);
    assert.strictEqual(D.scaled(clock, 1, -1000, -1000, [], desk, s), 0.75);
    // One it overlapped from the start doesn't hold it back.
    assert.strictEqual(D.scaled(clock, 1, 64, 0, [box(100, 100, 50, 50)], desk, s), 384 / 320);
});

test("made to any shape, back to the edge that gives up less", () => {
    const photo = { x: 0, y: 0, least: { w: 160, h: 120 } };
    const from = { w: 320, h: 248 };
    assert.deepStrictEqual(D.stretched(photo, from, 100, -50, [], desk, s), { w: 416, h: 192 });
    assert.deepStrictEqual(D.stretched(photo, from, -1000, -1000, [], desk, s), { w: 160, h: 120 });
    assert.deepStrictEqual(D.stretched(photo, from, 5000, 5000, [], desk, s), { w: 1000, h: 600 });
    // One under it: the height gives way, as the width is free.
    assert.deepStrictEqual(D.stretched(photo, from, 200, 200, [box(0, 300, 320, 100)], desk, s), { w: 520, h: 280 });
    // One right of it: the width gives way.
    assert.deepStrictEqual(D.stretched(photo, from, 200, 100, [box(400, 0, 100, 600)], desk, s), { w: 384, h: 344 });
    // One across its corner: whichever gives up less.
    const corner = [box(400, 300, 100, 100)];
    assert.deepStrictEqual(D.stretched(photo, from, 300, 100, corner, desk, s), { w: 616, h: 280 });
    assert.deepStrictEqual(D.stretched(photo, from, 100, 300, corner, desk, s), { w: 384, h: 544 });
});

console.log(passed, "passed");
