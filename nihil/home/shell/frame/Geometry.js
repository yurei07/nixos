.pragma library

const K = 0.5523;

function fmt(p) {
    return (Math.round(p[0] * 100) / 100) + " " + (Math.round(p[1] * 100) / 100);
}

function edges(W, H, L, T, R, B) {
    const x0 = L, y0 = T, x1 = W - R, y1 = H - B;
    return [
        { o: [x0, y0], d: [1, 0], n: [0, 1], len: x1 - x0, s: v => v - x0 },
        { o: [x1, y0], d: [0, 1], n: [-1, 0], len: y1 - y0, s: v => v - y0 },
        { o: [x1, y1], d: [-1, 0], n: [0, -1], len: x1 - x0, s: v => x1 - v },
        { o: [x0, y1], d: [0, -1], n: [1, 0], len: y1 - y0, s: v => y1 - v }
    ];
}

function at(e, s, n) {
    return [e.o[0] + e.d[0] * s + e.n[0] * n, e.o[1] + e.d[1] * s + e.n[1] * n];
}

function corner(a, v, b) {
    const c1 = [a[0] + K * (v[0] - a[0]), a[1] + K * (v[1] - a[1])];
    const c2 = [b[0] + K * (v[0] - b[0]), b[1] + K * (v[1] - b[1])];
    return " C" + fmt(c1) + " " + fmt(c2) + " " + fmt(b);
}

function bump(e, b, fillet, radius) {
    const f = Math.min(fillet, b.d / 2);
    const r = Math.max(0, Math.min(radius, b.d - f, (b.s1 - b.s0) / 2));
    let p = " L" + fmt(at(e, b.s0 - f, 0));
    p += corner(at(e, b.s0 - f, 0), at(e, b.s0, 0), at(e, b.s0, f));
    p += " L" + fmt(at(e, b.s0, b.d - r));
    p += corner(at(e, b.s0, b.d - r), at(e, b.s0, b.d), at(e, b.s0 + r, b.d));
    p += " L" + fmt(at(e, b.s1 - r, b.d));
    p += corner(at(e, b.s1 - r, b.d), at(e, b.s1, b.d), at(e, b.s1, b.d - r));
    p += " L" + fmt(at(e, b.s1, f));
    p += corner(at(e, b.s1, f), at(e, b.s1, 0), at(e, b.s1 + f, 0));
    return p;
}

function cornerBump(prev, e, b, fillet, radius) {
    const f = Math.min(fillet, b.d / 2);
    const r = Math.max(0, Math.min(radius, b.d - f, b.s1 - f));
    const side = prev.len - b.d;
    let p = " L" + fmt(at(prev, side - f, 0));
    p += corner(at(prev, side - f, 0), at(prev, side, 0), at(prev, side, f));
    p += " L" + fmt(at(prev, side, b.s1 - r));
    p += corner(at(prev, side, b.s1 - r), at(prev, side, b.s1), at(e, b.s1, b.d - r));
    p += " L" + fmt(at(e, b.s1, f));
    p += corner(at(e, b.s1, f), at(e, b.s1, 0), at(e, b.s1 + f, 0));
    return p;
}

function outline(W, H, L, T, R, B, radius, fillet, drawerRadius, bumps, start) {
    if (W <= 0 || H <= 0) return "";
    const es = edges(W, H, L, T, R, B);
    const first = start || 0;

    const lists = es.map((e, i) => (bumps || [])
        .filter(b => b.edge === i && b.d > 0.5)
        .map(b => {
            const s0 = e.s(b.a), s1 = e.s(b.b);
            return { s0: Math.min(s0, s1), s1: Math.max(s0, s1), d: b.d };
        })
        .sort((u, v) => u.s0 - v.s0));
    const atCorner = lists.map(list => list.length > 0 && list[0].s0 <= 0.5 ? list[0] : null);

    const firstCorner = atCorner[first];
    let p = "M" + fmt(firstCorner ? at(es[first], firstCorner.s1 + Math.min(fillet, firstCorner.d / 2), 0)
                                  : at(es[first], radius, 0));
    for (let k = 0; k < 4; k++) {
        const i = (first + k) % 4;
        const n = (i + 1) % 4;
        const e = es[i];
        for (const b of lists[i])
            if (b !== atCorner[i])
                p += bump(e, b, fillet, drawerRadius);
        if (atCorner[n]) {
            p += cornerBump(e, es[n], atCorner[n], fillet, drawerRadius);
        } else {
            p += " L" + fmt(at(e, e.len - radius, 0));
            p += corner(at(e, e.len - radius, 0), at(e, e.len, 0), at(es[n], radius, 0));
        }
    }
    return p + " Z";
}

function ringLength(W, H, L, T, R, B, radius) {
    return 2 * ((W - L - R) + (H - T - B)) - 8 * radius + 2 * Math.PI * radius;
}

function rise(W, H, L, T, R, B, radius, side) {
    if (W <= 0 || H <= 0) return "";
    const x0 = L, y0 = T, x1 = W - R, y1 = H - B;
    const cx = (x0 + x1) / 2;
    const x = side > 0 ? x1 : x0;          // the side it climbs
    const inward = side > 0 ? -radius : radius;
    let p = "M" + fmt([cx, y1]);
    p += " L" + fmt([x + inward, y1]);
    p += corner([x + inward, y1], [x, y1], [x, y1 - radius]);
    p += " L" + fmt([x, y0 + radius]);
    p += corner([x, y0 + radius], [x, y0], [x + inward, y0]);
    p += " L" + fmt([cx, y0]);
    return p;
}
