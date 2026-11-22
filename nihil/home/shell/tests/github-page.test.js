const fs = require("fs");
const path = require("path");
const assert = require("assert");
const source = fs.readFileSync(path.join(__dirname, "../services/GithubPage.js"), "utf8").replace(".pragma library", "");
const G = new Function(source + "\nreturn { valid, parse, clean, grid };")();

let passed = 0;
function test(name, body) { body(); passed++; console.log("ok", name); }

// The shape GitHub's page has had: attributes in any order, over lines, a tool-tip a day.
const cell = (date, level, id) => `<td tabindex="0" data-ix="${id}" aria-selected="false"
    aria-describedby="contribution-graph-legend-level-${level}" style="width: 10px"
    data-date="${date}" id="contribution-day-component-${id}" data-level="${level}" role="gridcell"
    data-view-component="true" class="ContributionCalendar-day"></td>
  <tool-tip for="contribution-day-component-${id}" class="sr-only">${level ? level + " contributions" : "No contributions"} on a day.</tool-tip>`;
const page = days => `<div class="js-yearly-contributions"><h2 class="f4 text-normal mb-2">
      1,234
      contributions
        in the last year
    </h2><table class="ContributionCalendar-grid"><tbody><tr>
    <td class="ContributionCalendar-label"><span class="sr-only">Monday</span></td>
    ${days.map(([date, level], i) => cell(date, level, i)).join("\n")}
    </tr></tbody></table></div>`;

test("a login is letters, digits and single hyphens inside", () => {
    for (const ok of ["poligle", "a", "nilo-nihil", "A1-b2-c3", "x".repeat(39)])
        assert.ok(G.valid(ok), ok);
    for (const bad of ["", "-a", "a-", "a--b", "a b", "a/b", "../x", "x".repeat(40), "a?x=1", null])
        assert.ok(!G.valid(bad), String(bad));
});

test("days and the year's total, from the oldest", () => {
    const read = G.parse(page([["2026-11-18", 2], ["2026-11-16", 0], ["2026-11-17", 4]]));
    assert.deepStrictEqual(read.days, [
        { date: "2026-11-16", level: 0 }, { date: "2026-11-17", level: 4 }, { date: "2026-11-18", level: 2 }]);
    assert.strictEqual(read.total, 1234);
});

test("attributes in another order, quoted otherwise or not, still count", () => {
    const html = `<td data-level='3' class="x" data-date='2026-01-02'></td><TD DATA-LEVEL=1 DATA-DATE=2026-01-01>`;
    assert.deepStrictEqual(G.parse(html).days, [{ date: "2026-01-01", level: 1 }, { date: "2026-01-02", level: 3 }]);
});

test("a page with no total keeps its days; none in the year is 0", () => {
    assert.strictEqual(G.parse(`<td data-date="2026-01-01" data-level="0">`).total, -1);
    assert.strictEqual(G.parse(`No contributions in the last year<td data-date="2026-01-01" data-level="0">`).total, 0);
    assert.strictEqual(G.parse(`1 contribution in the last year<td data-date="2026-01-01" data-level="1">`).total, 1);
});

test("what isn't a day isn't one: labels, levels out of range, a page that isn't the calendar", () => {
    assert.strictEqual(G.parse(`<td class="ContributionCalendar-label">Mon</td><td data-date="2026-01-01" data-level="7">`), null);
    assert.strictEqual(G.parse(`<html><body>Not Found</body></html>`), null);
    assert.strictEqual(G.parse(""), null);
    assert.strictEqual(G.parse(undefined), null);
});

test("kept days are taken only well formed", () => {
    assert.deepStrictEqual(G.clean([{ date: "2026-01-02", level: 2 }, { date: "x", level: 1 }, { date: "2026-01-01", level: 5 },
        { date: "2026-01-01", level: 1.5 }, null, { date: "2026-01-01", level: 0 }]),
        [{ date: "2026-01-01", level: 0 }, { date: "2026-01-02", level: 2 }]);
    assert.deepStrictEqual(G.clean("nonsense"), []);
});

test("the grid ends in today's week, beginning on the locale's first day", () => {
    // Wednesday 18 November 2026; Monday first: Monday 16 opens the last column.
    const days = [{ date: "2026-11-16", level: 1 }, { date: "2026-11-18", level: 4 }, { date: "2026-11-09", level: 2 }];
    const monday = G.grid(days, 2, 1, "2026-11-18");
    assert.deepStrictEqual(monday, [2, 0, 0, 0, 0, 0, 0, 1, 0, 4, -1, -1, -1, -1]);
    // Sunday first: Sunday 15 opens it, so the 9th is Monday's row of the column before.
    const sunday = G.grid(days, 2, 0, "2026-11-18");
    assert.deepStrictEqual(sunday, [0, 2, 0, 0, 0, 0, 0, 0, 1, 0, 4, -1, -1, -1]);
});

test("a day GitHub has that this clock hasn't reached yet still shows", () => {
    const cells = G.grid([{ date: "2026-11-19", level: 3 }], 1, 1, "2026-11-18");
    assert.deepStrictEqual(cells, [0, 0, 0, 3, -1, -1, -1]);
});

test("a whole year of weeks, a week a column", () => {
    const cells = G.grid([], 53, 1, "2026-11-18");
    assert.strictEqual(cells.length, 53 * 7);
    assert.strictEqual(cells.filter(level => level < 0).length, 4);
});

console.log(`${passed} passed`);
