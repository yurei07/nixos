// The shell's JavaScript runs in Qt's engine, which has ECMAScript up to about 2017: what node runs
// in the other tests may still fail there. Each of these is a TypeError or a SyntaxError in it.
const fs = require("fs");
const path = require("path");
const assert = require("assert");

const repo = path.join(__dirname, "../../..");
const roots = ["home/shell", "greeter", "installer/gui"];
const missing = [
    [/\.flatMap\(/, "Array.prototype.flatMap"],
    [/\.flat\(/, "Array.prototype.flat"],
    [/Object\.fromEntries\b/, "Object.fromEntries"],
    [/Object\.hasOwn\b/, "Object.hasOwn"],
    [/\.trim(Start|End)\(/, "String.prototype.trimStart/trimEnd"],
    [/\.replaceAll\(/, "String.prototype.replaceAll"],
    [/\.matchAll\(/, "String.prototype.matchAll"],
    [/[\w\])]\.at\(/, "Array.prototype.at"],
    [/\.findLast(Index)?\(/, "Array.prototype.findLast"],
    [/(\?\?|\|\||&&)=/, "logical assignment"],
    [/catch\s*\{/, "catch without a binding"],
    [/\(\?<[=!A-Za-z]/, "lookbehind or a named group in a regular expression"],
];

function files(dir) {
    const out = [];
    for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory() && entry.name !== "tests")
            out.push(...files(full));
        else if (/\.(qml|js)$/.test(entry.name))
            out.push(full);
    }
    return out;
}

let passed = 0;
function test(name, body) { body(); passed++; console.log("ok", name); }

// Spread into arrays and calls is ES2015 and runs; into an object it doesn't.
const objectSpread = (line) => {
    for (const m of line.matchAll(/\.\.\./g)) {
        let i = m.index - 1;
        while (i >= 0 && /\s/.test(line[i])) i--;
        if (line[i] === "{" || (line[i] === "," && /\{[^[\]]*$/.test(line.slice(0, i))))
            return true;
    }
    return false;
};

test("nothing Qt's engine can't run", () => {
    const found = [];
    for (const root of roots) {
        for (const file of files(path.join(repo, root))) {
            const lines = fs.readFileSync(file, "utf8").split("\n");
            lines.forEach((line, i) => {
                const code = line.replace(/\/\/.*$/, "");
                for (const [pattern, what] of missing) {
                    if (pattern.test(code))
                        found.push(`${path.relative(repo, file)}:${i + 1}: ${what}`);
                }
                if (objectSpread(code))
                    found.push(`${path.relative(repo, file)}:${i + 1}: spread in an object`);
            });
        }
    }
    assert.deepStrictEqual(found, []);
});

test("and the scan sees them", () => {
    for (const [line, what] of [["xs.flatMap(x => x)", true], ["const a = { ...b };", true], ["f({ a: 1, ...b })", true],
                                 ["[...a, ...b]", false], ["f(...args)", false], ["a ??= 1", true], ["/(?<=a)b/", true]]) {
        const hit = missing.some(([pattern]) => pattern.test(line)) || objectSpread(line);
        assert.strictEqual(hit, what, line);
    }
});

console.log(`${passed} passed`);
