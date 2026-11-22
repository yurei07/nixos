const fs = require("fs");
const path = require("path");
const assert = require("assert");
const source = fs.readFileSync(path.join(__dirname, "../services/OpenMeteo.js"), "utf8").replace(".pragma library", "");
const O = new Function(source + "\nreturn { searchUrl, forecastUrl, answer, place, forecast, sky };")();

let passed = 0;
function test(name, body) { body(); passed++; console.log("ok", name); }

test("a name goes in the search whole, whatever it has in it", () => {
    assert.strictEqual(O.searchUrl("L'Hospitalet & co?", "es"),
        "https://geocoding-api.open-meteo.com/v1/search?count=1&format=json&language=es&name=L'Hospitalet%20%26%20co%3F");
});

test("the forecast asks for a place to four decimals", () => {
    const url = O.forecastUrl(41.387917, -2.169919);
    assert.ok(url.startsWith("https://api.open-meteo.com/v1/forecast?latitude=41.3879&longitude=-2.1699&"), url);
    assert.ok(url.includes("timezone=auto"));
});

test("what curl answered, and its status", () => {
    assert.deepStrictEqual(O.answer('{"a":1}\n200'), { status: "200", body: '{"a":1}' });
    assert.deepStrictEqual(O.answer("\n000"), { status: "000", body: "" });
    assert.deepStrictEqual(O.answer(""), { status: "", body: "" });
});

test("the first place found, with what says more of where it is", () => {
    const text = JSON.stringify({ results: [
        { name: "Barcelona", latitude: 41.38879, longitude: 2.15899, country: "España", admin1: "Cataluña" },
        { name: "Barcelona", latitude: 10.13, longitude: -64.68, country: "Venezuela" }] });
    assert.deepStrictEqual(O.place(text), { name: "Barcelona", label: "Barcelona, Cataluña, España", lat: 41.3888, lon: 2.159 });
    const city = JSON.stringify({ results: [{ name: "Madrid", latitude: 40.4, longitude: -3.7, admin1: "Madrid", country: "España" }] });
    assert.strictEqual(O.place(city).label, "Madrid, España");
});

test("none found, or not an answer, is no place", () => {
    assert.strictEqual(O.place(JSON.stringify({ generationtime_ms: 0.5 })), null);
    assert.strictEqual(O.place(JSON.stringify({ results: [{ name: "X", latitude: "41" , longitude: 2 }] })), null);
    assert.strictEqual(O.place("<html>"), null);
    assert.strictEqual(O.place(undefined), null);
});

test("now and the days, the ill-formed ones left out", () => {
    const text = JSON.stringify({
        current: { time: "2026-11-18T17:00", temperature_2m: 14.2, apparent_temperature: 12.9, weather_code: 3, is_day: 0 },
        daily: { time: ["2026-11-18", "2026-11-19", "x", "2026-11-21"], weather_code: [3, 61, 0, null],
                 temperature_2m_max: [18.1, 15, 20, 16], temperature_2m_min: [9.4, 8, 10, 7] },
    });
    assert.deepStrictEqual(O.forecast(text), {
        now: { temp: 14.2, feels: 12.9, code: 3, day: false },
        days: [{ date: "2026-11-18", code: 3, max: 18.1, min: 9.4 }, { date: "2026-11-19", code: 61, max: 15, min: 8 }],
    });
});

test("a forecast with nothing for now is none", () => {
    assert.strictEqual(O.forecast(JSON.stringify({ error: true, reason: "Latitude must be in range" })), null);
    assert.strictEqual(O.forecast(""), null);
    const bare = O.forecast(JSON.stringify({ current: { temperature_2m: -0.4, weather_code: 71 } }));
    assert.deepStrictEqual(bare, { now: { temp: -0.4, feels: -0.4, code: 71, day: true }, days: [] });
});

test("each WMO code is a sky, and one unknown is none", () => {
    const skies = { 0: "clear", 1: "fewClouds", 2: "partly", 3: "cloudy", 45: "fog", 48: "fog", 51: "drizzle", 57: "drizzle",
                    61: "rain", 67: "rain", 71: "snow", 77: "snow", 80: "showers", 82: "showers", 85: "snow", 86: "snow",
                    95: "storm", 96: "storm", 99: "storm", 4: "", 100: "" };
    for (const [code, sky] of Object.entries(skies))
        assert.strictEqual(O.sky(Number(code)), sky, code);
});

console.log(`${passed} passed`);
