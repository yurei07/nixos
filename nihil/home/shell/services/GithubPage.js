.pragma library

// The page GitHub draws a profile's contribution calendar from (github.com/users/NAME/contributions):
// a table with a cell a day, each with data-date="YYYY-MM-DD" and data-level from 0 to 4. Nothing else
// in it is counted on but the year's total, and a page without one still gives its days.

// A GitHub login: letters, digits and single hyphens between them, up to 39.
function valid(user) {
    return /^[A-Za-z0-9](?:[A-Za-z0-9]|-(?=[A-Za-z0-9])){0,38}$/.test(String(user ?? ""));
}

// { days: [{ date, level }] from the oldest, one a date, total: a number or -1 }, or null with no days.
function parse(html) {
    const text = String(html ?? "");
    const byDate = {};
    for (const cell of text.match(/<td\b[^>]*>/gi) ?? []) {
        const date = /\sdata-date\s*=\s*["']?(\d{4}-\d{2}-\d{2})\b/i.exec(cell);
        const level = /\sdata-level\s*=\s*["']?([0-4])\b/i.exec(cell);
        if (date !== null && level !== null)
            byDate[date[1]] = Number(level[1]);
    }
    const days = clean(Object.keys(byDate).map(date => ({ date: date, level: byDate[date] })));
    if (days.length === 0)
        return null;
    const sum = /(\d[\d,.]*)\s+contributions?\s+in\s+the\s+last\s+year/i.exec(text);
    const none = /\bno\s+contributions\s+in\s+the\s+last\s+year/i.test(text);
    return { days: days, total: sum !== null ? Number(sum[1].replace(/\D/g, "")) : none ? 0 : -1 };
}

// Days as kept or read, only the well-formed ones, one a date, from the oldest.
function clean(days) {
    const byDate = {};
    for (const day of Array.isArray(days) ? days : []) {
        if (/^\d{4}-\d{2}-\d{2}$/.test(day?.date ?? "") && Number.isInteger(day?.level) && day.level >= 0 && day.level <= 4)
            byDate[day.date] = day.level;
    }
    return Object.keys(byDate).sort().map(date => ({ date: date, level: byDate[date] }));
}

function dayNumber(date) {
    const [y, m, d] = String(date).split("-").map(Number);
    return Math.round(Date.UTC(y, m - 1, d) / 86400000);
}

function dateOf(n) {
    return new Date(n * 86400000).toISOString().slice(0, 10);
}

// The last `weeks` weeks to `today` (YYYY-MM-DD), a column a week beginning on `first` (0 Sunday,
// 1 Monday…): weeks × 7 levels, column after column; 0 for a day not read, -1 for one after today.
// Today is the later of the one given and the last read: GitHub's day can be ahead of this one.
function grid(days, weeks, first, today) {
    const level = {};
    let last = dayNumber(today);
    for (const day of days ?? []) {
        level[day.date] = day.level;
        last = Math.max(last, dayNumber(day.date));
    }
    const weekday = (last + 4) % 7;   // 1 January 1970 was a Thursday
    const start = last - (weekday - first + 7) % 7 - (weeks - 1) * 7;
    const out = [];
    for (let n = start; n < start + weeks * 7; n++)
        out.push(n > last ? -1 : (level[dateOf(n)] ?? 0));
    return out;
}
