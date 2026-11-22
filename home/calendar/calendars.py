#!/usr/bin/env python3
# calendars.py by poligle

"""nihil-calendar: the calendars NIHIL shows, read from their iCalendar addresses.

An address is a secret: whoever has it reads the calendar. They live in a file only the user can
read, $XDG_CONFIG_HOME/nihil/calendars.json, never in settings.json, which ends in the Nix store
for every user to read. What they hold, from a month back to two ahead, is kept for the shell in
$XDG_CACHE_HOME/nihil/calendar.json, the user's alone as well.

  nihil-calendar list          the calendars, without their addresses: [{id, name, host}]
  nihil-calendar add           an address on stdin, read once and kept if it gives a calendar:
                               {id, name}, or {error}: url, fetch or calendar
  nihil-calendar remove ID     {ok} or {error}
  nihil-calendar sync          reads them all, keeps what they hold and prints it

Every answer is JSON on stdout. An address comes on stdin, never as an argument, which anyone on
the computer could read in /proc. A calendar that can't be read keeps what was read of it before.
An event in two of them (an invitation is in the organiser's calendar and in the guest's, and a
calendar can be added by two addresses) shows once.
"""

import datetime as dt
import hashlib
import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

import icalendar
import recurring_ical_events

TIMEOUT = 20
MAX_BYTES = 20 * 1000 * 1000
DAYS_BEFORE = 35
DAYS_AFTER = 70
MAX_EVENTS = 3000
MAX_TEXT = 200


def home_dir(variable, fallback):
    base = os.environ.get(variable) or os.path.join(os.path.expanduser("~"), fallback)
    return os.path.join(base, "nihil")


def config_path():
    return os.path.join(home_dir("XDG_CONFIG_HOME", ".config"), "calendars.json")


def cache_path():
    return os.path.join(home_dir("XDG_CACHE_HOME", ".cache"), "calendar.json")


def read_json(path, empty):
    try:
        with open(path, encoding="utf-8") as f:
            return json.load(f)
    except (OSError, ValueError):
        return empty


def write_private(path, value):
    """Written whole or not at all, and readable by the user alone from its first byte."""
    os.makedirs(os.path.dirname(path), mode=0o700, exist_ok=True)
    fresh = path + ".new"
    fd = os.open(fresh, os.O_WRONLY | os.O_CREAT | os.O_TRUNC, 0o600)
    with os.fdopen(fd, "w", encoding="utf-8") as f:
        json.dump(value, f, ensure_ascii=False)
    os.chmod(fresh, 0o600)
    os.replace(fresh, path)


def kept_calendars():
    kept = read_json(config_path(), [])
    return [c for c in kept if isinstance(c, dict) and isinstance(c.get("id"), str) and isinstance(c.get("url"), str)] \
        if isinstance(kept, list) else []


def address(text):
    """webcal is https by another name; anything but http and https is no calendar's address."""
    url = str(text).strip()
    parts = urllib.parse.urlsplit(url)
    scheme = parts.scheme.lower()
    if scheme == "webcal":
        url = urllib.parse.urlunsplit(("https",) + tuple(parts[1:]))
        scheme = "https"
    if scheme not in ("http", "https") or not parts.netloc:
        return None
    return url


def calendar_id(url):
    return hashlib.sha256(url.encode("utf-8")).hexdigest()[:10]


def host(url):
    return urllib.parse.urlsplit(url).hostname or ""


def fetch(url):
    request = urllib.request.Request(url, headers={"User-Agent": "NIHIL calendar", "Accept": "text/calendar, */*"})
    with urllib.request.urlopen(request, timeout=TIMEOUT) as answer:
        data = answer.read(MAX_BYTES + 1)
    if len(data) > MAX_BYTES:
        raise ValueError("too big")
    return data


def parse(data):
    calendar = icalendar.Calendar.from_ical(data)
    if calendar.name != "VCALENDAR":
        raise ValueError("not a calendar")
    return calendar


def text(value):
    return " ".join(str(value or "").split())[:MAX_TEXT]


def stamp(moment):
    """Seconds since 1970: a time with its zone is that instant; one without (floating) and a day
    (from its midnight) are on this computer's clock, summer time included."""
    if isinstance(moment, dt.datetime):
        if moment.tzinfo is not None:
            return int(moment.timestamp())
        return int(time.mktime(moment.timetuple()))
    return int(time.mktime((moment.year, moment.month, moment.day, 0, 0, 0, 0, 0, -1)))


def occurrences(calendar, cal_id, first_day, last_day):
    """Each event between two days (the second left out), repeats unfolded, as the shell reads them."""
    out = []
    for event in recurring_ical_events.of(calendar).between(first_day, last_day):
        if str(event.get("STATUS", "")).upper() == "CANCELLED":
            continue
        begin = event.get("DTSTART")
        if begin is None:
            continue
        begin = begin.dt
        finish = event.get("DTEND")
        finish = finish.dt if finish is not None else None
        if finish is None and event.get("DURATION") is not None:
            finish = begin + event.get("DURATION").dt
        all_day = not isinstance(begin, dt.datetime)
        if finish is None:
            finish = begin + dt.timedelta(days=1) if all_day else begin
        start, end = stamp(begin), stamp(finish)
        out.append({
            "cal": cal_id,
            "title": text(event.get("SUMMARY")),
            "where": text(event.get("LOCATION")),
            "allDay": all_day,
            "start": start,
            "end": max(start, end),
            # Only to tell copies apart, and not kept.
            "_uid": str(event.get("UID") or ""),
            "_seq": sequence(event),
        })
    return out


def sequence(event):
    try:
        return int(event.get("SEQUENCE", 0))
    except (TypeError, ValueError):
        return 0


def merged(events):
    """One of each: the same event at the same time in two calendars, the newest of its copies,
    and of those that would show alike (the same title at the same times) the first."""
    newest = {}
    for event in events:
        if event.get("_uid"):
            key = (event["_uid"], event.get("start"), event.get("end"))
            if key not in newest or event.get("_seq", 0) > newest[key].get("_seq", 0):
                newest[key] = event
    out, shown = [], set()
    for event in events:
        if event.get("_uid") and newest[(event["_uid"], event.get("start"), event.get("end"))] is not event:
            continue
        looks = (str(event.get("title", "")).casefold(), event.get("start"), event.get("end"), bool(event.get("allDay")))
        if looks in shown:
            continue
        shown.add(looks)
        out.append({key: value for key, value in event.items() if not key.startswith("_")})
    return out


def window(today=None):
    today = today or dt.date.today()
    return today - dt.timedelta(days=DAYS_BEFORE), today + dt.timedelta(days=DAYS_AFTER + 1)


def name_of(calendar, url):
    return text(calendar.get("X-WR-CALNAME")) or host(url)


def sync(today=None, reader=None):
    reader = reader or fetch
    first_day, last_day = window(today)
    before = read_json(cache_path(), {})
    old = before.get("events", []) if isinstance(before, dict) else []
    calendars, events = [], []
    for cal in kept_calendars():
        try:
            calendar = parse(reader(cal["url"]))
            found = occurrences(calendar, cal["id"], first_day, last_day)
            calendars.append({"id": cal["id"], "name": name_of(calendar, cal["url"]), "ok": True})
            events += found
        except Exception:  # noqa: BLE001 — a calendar that can't be read shows what it showed
            calendars.append({"id": cal["id"], "name": cal.get("name") or host(cal["url"]), "ok": False})
            events += [e for e in old if isinstance(e, dict) and e.get("cal") == cal["id"]]
    events = merged(events)
    events.sort(key=lambda e: (e.get("start", 0), e.get("end", 0), e.get("title", "")))
    kept = {"updated": int(time.time()), "calendars": calendars, "events": events[:MAX_EVENTS]}
    write_private(cache_path(), kept)
    return kept


def add(given, reader=None):
    reader = reader or fetch
    url = address(given)
    if url is None:
        return {"error": "url"}
    cal_id = calendar_id(url)
    kept = kept_calendars()
    for cal in kept:
        if cal["id"] == cal_id:
            return {"id": cal_id, "name": cal.get("name") or host(url)}
    try:
        data = reader(url)
    except (urllib.error.URLError, OSError, ValueError):
        return {"error": "fetch"}
    try:
        calendar = parse(data)
    except Exception:  # noqa: BLE001 — anything that isn't a calendar
        return {"error": "calendar"}
    name = name_of(calendar, url)
    write_private(config_path(), kept + [{"id": cal_id, "url": url, "name": name}])
    return {"id": cal_id, "name": name}


def remove(cal_id):
    kept = kept_calendars()
    left = [cal for cal in kept if cal["id"] != cal_id]
    if len(left) == len(kept):
        return {"error": "unknown"}
    write_private(config_path(), left)
    return {"ok": True}


def listed():
    return [{"id": cal["id"], "name": cal.get("name") or host(cal["url"]), "host": host(cal["url"])} for cal in kept_calendars()]


def main(argv):
    os.umask(0o077)
    if len(argv) == 2 and argv[1] == "list":
        answer = listed()
    elif len(argv) == 2 and argv[1] == "sync":
        answer = sync()
    elif len(argv) == 2 and argv[1] == "add":
        answer = add(sys.stdin.readline())
    elif len(argv) == 3 and argv[1] == "remove":
        answer = remove(argv[2])
    else:
        print(__doc__.strip().split("\n\n")[1], file=sys.stderr)
        return 2
    json.dump(answer, sys.stdout, ensure_ascii=False)
    print()
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
