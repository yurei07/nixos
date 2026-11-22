.pragma library

// Where widgets go on the desktop, as plain boxes { x, y, w, h } in the desk's pixels: on a grid
// of `cell`, within the desk { w, h }, and a `gap` clear of each other.

function clear(box, others, gap) {
    return others.every(o => box.x + box.w + gap <= o.x || box.x >= o.x + o.w + gap
        || box.y + box.h + gap <= o.y || box.y >= o.y + o.h + gap);
}

// The place nearest (x, y) where a w × h box fits.
function room(w, h, x, y, others, desk, gap, cell) {
    const fit = (v, size, limit) => Math.max(0, Math.min(Math.floor((limit - size) / cell) * cell, Math.round(v / cell) * cell));
    const sx = fit(x, w, desk.w), sy = fit(y, h, desk.h);
    const free = (px, py) => clear({ x: px, y: py, w: w, h: h }, others, gap);
    if (free(sx, sy))
        return { x: sx, y: sy };
    for (let ring = 1; ring < 120; ring++) {
        let best = null, far = Infinity;
        for (let i = -ring; i <= ring; i++) {
            for (const [dx, dy] of [[i, -ring], [i, ring], [-ring, i], [ring, i]]) {
                const px = sx + dx * cell, py = sy + dy * cell;
                if (px < 0 || py < 0 || px + w > desk.w || py + h > desk.h)
                    continue;
                const d = dx * dx + dy * dy;
                if (d < far && free(px, py)) {
                    best = { x: px, y: py };
                    far = d;
                }
            }
        }
        if (best !== null)
            return best;
    }
    return { x: sx, y: sy };
}

// Beside a box, right of it or left, if there's room; else under it or over it; else wherever is
// nearest, or right of it if nowhere is free.
function beside(box, w, h, others, desk, gap, cell) {
    const up = v => Math.ceil(v / cell) * cell, down = v => Math.floor(v / cell) * cell;
    const all = others.concat([box]);
    const ways = [[up(box.x + box.w + gap), box.y], [down(box.x - gap - w), box.y],
                  [box.x, up(box.y + box.h + gap)], [box.x, down(box.y - gap - h)]];
    for (const [x, y] of ways) {
        if (x >= 0 && y >= 0 && x + w <= desk.w && y + h <= desk.h && clear({ x: x, y: y, w: w, h: h }, all, gap))
            return { x: x, y: y };
    }
    return room(w, h, box.x + box.w + gap, box.y, all, desk, gap, cell);
}

// How big one that grows as a whole gets as its corner goes (dx, dy) from where it was at size
// `from`: card { x, y, base, tall } is at its top left, and base × tall its size at 1. Its
// width on the grid, within the desk, and short of the others it would run into.
function scaled(card, from, dx, dy, others, desk, s) {
    const want = Math.max(from + dx / card.base, from + dy / card.tall);
    let most = Math.min(s.largest, (desk.w - card.x) / card.base, (desk.h - card.y) / card.tall);
    for (const o of others) {
        if (o.x + o.w + s.gap <= card.x || o.y + o.h + s.gap <= card.y)
            continue;
        const room = Math.max((o.x - card.x - s.gap) / card.base, (o.y - card.y - s.gap) / card.tall);
        if (room >= from - 0.001)
            most = Math.min(most, room);
    }
    const size = Math.max(s.smallest, Math.min(most, want));
    const snapped = Math.round(card.base * size / s.cell) * s.cell / card.base;
    return snapped > most ? Math.floor(card.base * most / s.cell) * s.cell / card.base : Math.max(s.smallest, snapped);
}

// The width and height of one made to any shape as its corner goes (dx, dy) from `from` { w, h }:
// card { x, y, least: { w, h } }. Within the desk, and against each one it would run into, back
// to its edge on the side that gives up less.
function stretched(card, from, dx, dy, others, desk, s) {
    let w = Math.min(Math.max(card.least.w, from.w + dx), desk.w - card.x);
    let h = Math.min(Math.max(card.least.h, from.h + dy), desk.h - card.y);
    for (const o of others) {
        // Left of it or over it, never in the way; in the way from the start, nothing to keep clear.
        if (o.x + o.w + s.gap <= card.x || o.y + o.h + s.gap <= card.y)
            continue;
        if (card.x + from.w + s.gap > o.x && card.y + from.h + s.gap > o.y)
            continue;
        if (card.x + w + s.gap <= o.x || card.y + h + s.gap <= o.y)
            continue;
        const across = o.x - s.gap - card.x, under = o.y - s.gap - card.y;
        if (across >= card.least.w && (w - across <= h - under || under < card.least.h))
            w = across;
        else
            h = Math.max(card.least.h, under);
    }
    return { w: Math.max(card.least.w, Math.floor(w / s.cell) * s.cell), h: Math.max(card.least.h, Math.floor(h / s.cell) * s.cell) };
}
