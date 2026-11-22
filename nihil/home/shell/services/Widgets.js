.pragma library

// The desktop widgets as widgets.json keeps them: { on, at, size, opts }. Photos and notes can be
// several, each named as its kind and then -2, -3…; of the rest there's one each.

const SEVERAL = ["photo", "note"];

function kindOf(name) {
    const m = /^([a-z]+)-([2-9]|[1-9][0-9]+)$/.exec(String(name));
    return m !== null && SEVERAL.indexOf(m[1]) >= 0 ? m[1] : String(name);
}

function several(name) {
    return SEVERAL.indexOf(kindOf(name)) >= 0;
}

function known(name, kinds) {
    return kinds.indexOf(kindOf(name)) >= 0;
}

function number(name) {
    return kindOf(name) === name ? 1 : Number(name.slice(name.lastIndexOf("-") + 1));
}

// Those of a kind that are on, the first first.
function instances(on, kind) {
    return on.filter(name => kindOf(name) === kind).sort((a, b) => number(a) - number(b));
}

// The first name of a kind nothing has: not on, and none of `taken`, such as a picture left
// behind or one thrown away while arranging, whose file only goes once that's kept.
function freeName(kind, on, taken) {
    for (let n = 1; ; n++) {
        const name = n === 1 ? kind : kind + "-" + n;
        if (on.indexOf(name) < 0 && taken.indexOf(name) < 0)
            return name;
    }
}

// A size as it's kept: how many times bigger, for one that grows as a whole, or its width and
// height, for one made to any shape.
function size(value) {
    if (Number.isFinite(value) && value >= 0.5 && value <= 3)
        return value;
    if (Array.isArray(value) && value.length === 2 && value.every(n => Number.isFinite(n) && n >= 80 && n <= 8000))
        return [Math.round(value[0]), Math.round(value[1])];
    return null;
}

// What widgets.json holds, of widgets there are and in shapes that make sense: null if it isn't
// JSON. An older file was only the list of those on; on is null when it says nothing of them.
function read(text, kinds) {
    let kept = null;
    try {
        kept = JSON.parse(text);
    } catch (error) {
        return null;
    }
    const on = Array.isArray(kept) ? kept : kept?.on;
    const out = { on: null, at: {}, size: {}, opts: {} };
    if (Array.isArray(on))
        out.on = on.filter((name, i) => typeof name === "string" && known(name, kinds) && on.indexOf(name) === i);
    for (const [name, at] of Object.entries(kept?.at ?? {})) {
        if (known(name, kinds) && Array.isArray(at) && at.length === 2 && at.every(n => Number.isFinite(n) && n >= 0))
            out.at[name] = [Math.round(at[0]), Math.round(at[1])];
    }
    for (const [name, value] of Object.entries(kept?.size ?? {})) {
        const shape = size(value);
        if (known(name, kinds) && shape !== null)
            out.size[name] = shape;
    }
    for (const [name, set] of Object.entries(kept?.opts ?? {})) {
        if (!known(name, kinds) || set === null || typeof set !== "object" || Array.isArray(set))
            continue;
        out.opts[name] = {};
        for (const [key, value] of Object.entries(set)) {
            if (typeof value === "string" || typeof value === "boolean" || Number.isFinite(value))
                out.opts[name][key] = value;
        }
    }
    return out;
}

// The pictures' files once arranging ends, by name in the state folder. Kept: those thrown away
// go, and those put in while it lasted take their places, or go if their widget went too. Not
// kept: only those put in go.
function settle(keep, on, doomed, staged) {
    if (!keep)
        return { remove: staged.map(name => name + ".staged"), move: [] };
    const gone = staged.filter(name => on.indexOf(name) < 0 && doomed.indexOf(name) < 0);
    return {
        remove: doomed.reduce((out, name) => out.concat([name, name + ".staged"]), []).concat(gone.map(name => name + ".staged")),
        move: staged.filter(name => on.indexOf(name) >= 0),
    };
}
