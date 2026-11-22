.pragma library

var KEEP_REMOVED = 60 * 24 * 60 * 60 * 1000;
var AHEAD = 24 * 60 * 60 * 1000;
// The most the deck takes in one board (deck.py's): past them, a device's sync would fail for good.
var CARDS_MAX = 1000;
var REMOVED_MAX = 10000;
var ID_MAX = 64;

// A stamp from elsewhere (a device, tasks.json), as the merge can use it: whole milliseconds, at
// most a day ahead of now, or else the oldest. One past 2^53, or Infinity, would stop the clock
// for good, and every edit made here would lose from then on.
function stampOf(value, now) {
    return Number.isSafeInteger(value) && value >= 0 && value <= now + AHEAD ? value : 0;
}

// An id the deck takes, and one a plain object can be keyed by: «__proto__» or «constructor»
// would reach into what every object shares.
function usable(id) {
    return typeof id === "string" && id !== "" && id.length <= ID_MAX && !(id in Object.prototype);
}

function trusted(board, now) {
    const cards = (Array.isArray(board?.cards) ? board.cards : []).filter(c => c && typeof c === "object" && usable(c.id))
        .map(c => Object.assign({}, c, { textStamp: stampOf(c.textStamp, now), placeStamp: stampOf(c.placeStamp, now) }));
    const gone = board?.removed && typeof board.removed === "object" && !Array.isArray(board.removed) ? board.removed : {};
    const removed = {};
    Object.keys(gone).forEach(id => {
        const at = stampOf(gone[id], now);
        if (at > 0 && usable(id))
            removed[id] = at;
    });
    return { cards: cards, removed: removed };
}

// What a device brings that this computer doesn't know, and that no one has changed since
// before the removals still kept: removed here, too long ago for that to be remembered, so it
// stays out rather than coming back. One changed since comes back, as after a removal kept.
function recent(mine, theirs, now) {
    const known = new Set((mine.cards || []).map(c => c.id).concat(Object.keys(mine.removed || {})));
    return { cards: (theirs.cards || []).filter(c => known.has(c.id) || now - Math.max(c.textStamp, c.placeStamp) < KEEP_REMOVED),
             removed: theirs.removed || {} };
}

// A device's board, as this computer takes it in.
function sync(mine, board, now) {
    return merge(mine, recent(mine, trusted(board, now), now), now);
}

// The newest REMOVED_MAX removals: all a board the deck takes back can hold.
function newest(removed) {
    const ids = Object.keys(removed);
    if (ids.length <= REMOVED_MAX)
        return removed;
    const kept = {};
    ids.sort((p, q) => removed[q] - removed[p] || (p < q ? -1 : 1)).slice(0, REMOVED_MAX).forEach(id => { kept[id] = removed[id]; });
    return kept;
}

function merge(a, b, now) {
    const mine = {};
    const theirs = {};
    (a.cards || []).forEach(c => { mine[c.id] = c; });
    (b.cards || []).forEach(c => { theirs[c.id] = c; });
    const removedA = a.removed || {};
    const removedB = b.removed || {};
    const ids = new Set([].concat(Object.keys(mine), Object.keys(theirs), Object.keys(removedA), Object.keys(removedB)));
    const cards = [];
    const removed = {};
    ids.forEach(id => {
        const x = mine[id];
        const y = theirs[id];
        const card = x && y ? combine(x, y) : (x || y);
        const gone = Math.max(id in removedA ? removedA[id] : -Infinity, id in removedB ? removedB[id] : -Infinity);
        if (card && gone < Math.max(card.textStamp, card.placeStamp))
            cards.push(card);
        else if (gone !== -Infinity && now - gone < KEEP_REMOVED)
            removed[id] = gone;
    });
    return { cards: ordered(cards), removed: newest(removed) };
}

function combine(x, y) {
    const text = x.textStamp !== y.textStamp ? (x.textStamp > y.textStamp ? x : y) : (x.text >= y.text ? x : y);
    const place = x.placeStamp !== y.placeStamp ? (x.placeStamp > y.placeStamp ? x : y) : tie(x, y);
    const card = { id: x.id, text: text.text, column: place.column, textStamp: text.textStamp, placeStamp: place.placeStamp };
    if (ranked(place))
        card.rank = place.rank;
    return card;
}

function tie(x, y) {
    if (ranked(x) !== ranked(y))
        return ranked(x) ? x : y;
    if (x.column !== y.column)
        return x.column > y.column ? x : y;
    return ranked(x) && y.rank > x.rank ? y : x;
}

function ranked(card) {
    return typeof card.rank === "number" && isFinite(card.rank);
}

function position(card) {
    return ranked(card) ? card.rank : card.placeStamp;
}

function ordered(cards) {
    return cards.slice().sort((p, q) => p.column - q.column || position(p) - position(q) || (p.id < q.id ? -1 : p.id > q.id ? 1 : 0));
}

function rankAt(others, index, now) {
    const i = Math.max(0, Math.min(others.length, index));
    const before = i > 0 ? position(others[i - 1]) : null;
    const after = i < others.length ? position(others[i]) : null;
    if (before === null && after === null)
        return now;
    if (before === null)
        return after - 1;
    if (after === null)
        return before + 1;
    const middle = (before + after) / 2;
    return middle > before && middle < after ? middle : null;
}

function place(cards, id, column, index, now) {
    const card = cards.find(c => c.id === id);
    if (!card)
        return cards;
    const lane = ordered(cards.filter(c => c.column === column));
    const others = lane.filter(c => c.id !== id);
    const at = Math.max(0, Math.min(others.length, index));
    if (card.column === column && lane.indexOf(card) === at)
        return cards;
    const ranks = {};
    const rank = rankAt(others, at, now);
    if (rank !== null)
        ranks[id] = rank;
    else
        others.slice(0, at).concat([card], others.slice(at)).forEach((c, i) => { ranks[c.id] = now + i; });
    return ordered(cards.map(c => c.id in ranks
        ? { id: c.id, text: c.text, column: column, textStamp: c.textStamp, placeStamp: now, rank: ranks[c.id] }
        : c));
}

function latest(board) {
    let last = 0;
    (board.cards || []).forEach(c => { last = Math.max(last, c.textStamp, c.placeStamp); });
    Object.keys(board.removed || {}).forEach(id => { last = Math.max(last, board.removed[id]); });
    return last;
}
