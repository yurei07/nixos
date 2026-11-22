.pragma library

// Days and events as the calendar widget shows them, on this computer's clock.
// Events are what nihil-calendar keeps: { cal, title, where, allDay, start, end }, from the
// soonest, start and end in seconds (end left out; an event without length ends as it starts).

function key(date) {
    const pad = n => (n < 10 ? "0" : "") + n;
    return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate());
}

// Seconds at the midnight a day begins; a day past the month's end is the next month's.
function midnight(y, m, d) {
    return new Date(y, m, d).getTime() / 1000;
}

function touches(event, from, to) {
    return event.start < to && (event.end > from || (event.end === event.start && event.start >= from));
}

// The days of a month that have something, as keys: one lasting several marks each of them.
function busy(events, y, m) {
    const marked = {};
    const first = midnight(y, m, 1), last = midnight(y, m + 1, 1);
    for (const event of events ?? []) {
        if (!touches(event, first, last))
            continue;
        const begin = new Date(Math.max(event.start, first) * 1000);
        const end = Math.min(Math.max(event.end, event.start + 1), last);
        for (let day = new Date(begin.getFullYear(), begin.getMonth(), begin.getDate());
             day.getTime() / 1000 < end; day = new Date(day.getFullYear(), day.getMonth(), day.getDate() + 1))
            marked[key(day)] = true;
    }
    return marked;
}

// A month as six weeks from the locale's first day (0 Sunday, 1 Monday…): 42 of { y, m, d, inMonth }.
function month(y, m, first) {
    const lead = (new Date(y, m, 1).getDay() - first + 7) % 7;
    const out = [];
    for (let i = 0; i < 42; i++) {
        const day = new Date(y, m, 1 - lead + i);
        out.push({ y: day.getFullYear(), m: day.getMonth(), d: day.getDate(), inMonth: day.getMonth() === m });
    }
    return out;
}

// The next ones not over at `now` (seconds), those under way first, as they're kept.
function upcoming(events, now, count) {
    return (events ?? []).filter(event => event.end > now || (event.end === event.start && event.start >= now)).slice(0, count);
}

// How many days from `now`'s to the one a moment falls on: 0 today, 1 tomorrow, -1 yesterday.
function daysAway(seconds, now) {
    const a = new Date(seconds * 1000), b = new Date(now * 1000);
    return Math.round((midnight(a.getFullYear(), a.getMonth(), a.getDate()) - midnight(b.getFullYear(), b.getMonth(), b.getDate())) / 86400);
}
