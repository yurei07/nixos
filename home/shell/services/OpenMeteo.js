.pragma library

// Open-Meteo's answers, read (open-meteo.com: a forecast and a place's search, with no key).

function round(n) {
    return Math.round(n * 1e4) / 1e4;
}

// The search for a place by its name, in a language (es, en): the first one found.
function searchUrl(name, language) {
    return "https://geocoding-api.open-meteo.com/v1/search?count=1&format=json&language="
        + encodeURIComponent(String(language)) + "&name=" + encodeURIComponent(String(name));
}

// Now and the next days at a place, in degrees Celsius and on the place's own clock.
function forecastUrl(lat, lon) {
    return "https://api.open-meteo.com/v1/forecast?latitude=" + round(lat) + "&longitude=" + round(lon)
        + "&current=temperature_2m,apparent_temperature,weather_code,is_day"
        + "&daily=weather_code,temperature_2m_max,temperature_2m_min&timezone=auto&forecast_days=4";
}

// What curl printed with -w '\n%{http_code}': { status, body }, status "000" when nothing answered.
function answer(text) {
    const all = String(text ?? "");
    const cut = all.lastIndexOf("\n");
    return { status: all.slice(cut + 1).trim(), body: cut >= 0 ? all.slice(0, cut) : "" };
}

function json(text) {
    try {
        return JSON.parse(String(text ?? ""));
    } catch (error) {
        return null;
    }
}

// The first place found: { name, label, lat, lon }, label being the name with its region and
// country when they say more; or null.
function place(text) {
    const found = json(text)?.results?.[0];
    if (!found || typeof found.name !== "string" || found.name === ""
        || !Number.isFinite(found.latitude) || !Number.isFinite(found.longitude))
        return null;
    const parts = [found.name, found.admin1, found.country]
        .filter((part, i, all) => typeof part === "string" && part !== "" && all.indexOf(part) === i);
    return { name: found.name, label: parts.join(", "), lat: round(found.latitude), lon: round(found.longitude) };
}

// { now: { temp, feels, code, day }, days: [{ date, code, max, min }] from today }, or null.
function forecast(text) {
    const data = json(text);
    const now = data?.current;
    if (!now || !Number.isFinite(now.temperature_2m) || !Number.isInteger(now.weather_code))
        return null;
    const daily = data.daily ?? {};
    const days = [];
    for (let i = 0; i < (Array.isArray(daily.time) ? daily.time.length : 0); i++) {
        const day = { date: daily.time[i], code: daily.weather_code?.[i], max: daily.temperature_2m_max?.[i], min: daily.temperature_2m_min?.[i] };
        if (/^\d{4}-\d{2}-\d{2}$/.test(String(day.date)) && Number.isInteger(day.code) && Number.isFinite(day.max) && Number.isFinite(day.min))
            days.push(day);
    }
    return {
        now: { temp: now.temperature_2m, feels: Number.isFinite(now.apparent_temperature) ? now.apparent_temperature : now.temperature_2m,
               code: now.weather_code, day: now.is_day !== 0 },
        days: days,
    };
}

// A WMO weather code as the sky it says: clear, fewClouds, partly, cloudy, fog, drizzle, rain,
// showers, snow or storm; "" for one it doesn't.
function sky(code) {
    if (code === 0) return "clear";
    if (code === 1) return "fewClouds";
    if (code === 2) return "partly";
    if (code === 3) return "cloudy";
    if (code === 45 || code === 48) return "fog";
    if (code >= 51 && code <= 57) return "drizzle";
    if (code >= 61 && code <= 67) return "rain";
    if (code >= 80 && code <= 82) return "showers";
    if ((code >= 71 && code <= 77) || code === 85 || code === 86) return "snow";
    if (code >= 95 && code <= 99) return "storm";
    return "";
}
