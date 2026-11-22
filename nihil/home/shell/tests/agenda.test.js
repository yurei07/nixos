// On a clock with summer time, as the days that change it are where days go wrong.
process.env.TZ = "Europe/Madrid";

const fs = require("fs");
const path = require("path");
const assert = require("assert");
const source = fs.readFileSync(path.join(__dirname, "../services/Agenda.js"), "utf8").replace(".pragma library", "");
const A = new Function(source + "\nreturn { key, midnight, touches, busy, month, upcoming, daysAway };")();

let passed = 0;
function test(name, body) { body(); passed++; console.log("ok", name); }

const at = (y, m, d, h = 0, min = 0) => new Date(y, m, d, h, min).getTime() / 1000;
const ev = (title, start, end, allDay = false) => ({ cal: "c", title: title, where: "", allDay: allDay, start: start, end: end });

const events = [
    ev("Trip", at(2026, 9, 24), at(2026, 9, 27), true),               // 24 to 26 October, over the change
    ev("Lab", at(2026, 10, 19, 10), at(2026, 10, 19, 12)),
    ev("Reminder", at(2026, 10, 19, 18), at(2026, 10, 19, 18)),      // no length
    ev("Late", at(2026, 10, 19, 23), at(2026, 10, 20, 1)),           // past midnight
    ev("Day off", at(2026, 10, 20), at(2026, 10, 21), true),
    ev("Exam", at(2026, 11, 1, 9), at(2026, 11, 1, 11)),
];

test("a day's key, on this clock", () => {
    assert.strictEqual(A.key(new Date(2026, 0, 5, 23, 59)), "2026-01-05");
    assert.strictEqual(A.key(new Date(2026, 10, 30)), "2026-11-30");
});

test("what touches a day, from midnight to midnight", () => {
    const day = (y, m, d) => events.filter(e => A.touches(e, A.midnight(y, m, d), A.midnight(y, m, d + 1))).map(e => e.title);
    assert.deepStrictEqual(day(2026, 10, 19), ["Lab", "Reminder", "Late"]);
    assert.deepStrictEqual(day(2026, 10, 20), ["Late", "Day off"]);
    assert.deepStrictEqual(day(2026, 10, 21), []);
    // An all-day one ends at the next midnight, which isn't its day.
    assert.deepStrictEqual(day(2026, 9, 27), []);
    assert.deepStrictEqual(day(2026, 9, 25), ["Trip"]);
});

test("the busy days of a month, one lasting several marking each", () => {
    assert.deepStrictEqual(Object.keys(A.busy(events, 2026, 9)).sort(), ["2026-10-24", "2026-10-25", "2026-10-26"]);
    assert.deepStrictEqual(Object.keys(A.busy(events, 2026, 10)).sort(), ["2026-11-19", "2026-11-20"]);
    assert.deepStrictEqual(Object.keys(A.busy(events, 2026, 11)), ["2026-12-01"]);
    assert.deepStrictEqual(A.busy(undefined, 2026, 11), {});
});

test("one running from a month into the next marks only this month's days in it", () => {
    const long = [ev("Holidays", at(2026, 11, 30), at(2027, 0, 3), true)];
    assert.deepStrictEqual(Object.keys(A.busy(long, 2026, 11)).sort(), ["2026-12-30", "2026-12-31"]);
    assert.deepStrictEqual(Object.keys(A.busy(long, 2027, 0)).sort(), ["2027-01-01", "2027-01-02"]);
});

test("a month as six weeks from the first day of the week", () => {
    const monday = A.month(2026, 10, 1);
    assert.strictEqual(monday.length, 42);
    // 1 November 2026 is a Sunday: Monday first, six days of October lead.
    assert.deepStrictEqual(monday[0], { y: 2026, m: 9, d: 26, inMonth: false });
    assert.deepStrictEqual(monday[6], { y: 2026, m: 10, d: 1, inMonth: true });
    assert.deepStrictEqual(monday[41], { y: 2026, m: 11, d: 6, inMonth: false });
    const sunday = A.month(2026, 10, 0);
    assert.deepStrictEqual(sunday[0], { y: 2026, m: 10, d: 1, inMonth: true });
    assert.strictEqual(sunday.filter(day => day.inMonth).length, 30);
});

test("what's next: under way first, nothing over", () => {
    const now = at(2026, 10, 19, 11);
    assert.deepStrictEqual(A.upcoming(events, now, 3).map(e => e.title), ["Lab", "Reminder", "Late"]);
    assert.deepStrictEqual(A.upcoming(events, at(2026, 10, 19, 18), 2).map(e => e.title), ["Reminder", "Late"]);
    assert.deepStrictEqual(A.upcoming(events, at(2027, 0, 1), 3), []);
});

test("days away count days, not hours, over summer time's end", () => {
    assert.strictEqual(A.daysAway(at(2026, 9, 26, 0, 30), at(2026, 9, 24, 23)), 2);
    assert.strictEqual(A.daysAway(at(2026, 10, 19, 23, 59), at(2026, 10, 19, 0, 1)), 0);
    assert.strictEqual(A.daysAway(at(2026, 10, 20, 0, 1), at(2026, 10, 19, 23, 59)), 1);
    assert.strictEqual(A.daysAway(at(2026, 10, 18), at(2026, 10, 19)), -1);
});

console.log(`${passed} passed`);
