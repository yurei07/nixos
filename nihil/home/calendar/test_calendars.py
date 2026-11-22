#!/usr/bin/env python3
# test_calendars.py by poligle

import datetime as dt
import io
import json
import os
import stat
import sys
import tempfile
import time
import unittest
import urllib.error
from unittest import mock

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import calendars  # noqa: E402

# A lab on six Thursdays at 10 in Madrid's time, but not the 26th; a day off on the 20th, all
# day; a meeting at 09:00 UTC; one called off; and a floating one at 18:00, on whatever clock.
LAB = b"""BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//test//EN
X-WR-CALNAME:Uni
BEGIN:VTIMEZONE
TZID:Europe/Madrid
BEGIN:STANDARD
DTSTART:19701025T030000
TZOFFSETFROM:+0200
TZOFFSETTO:+0100
RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU
END:STANDARD
BEGIN:DAYLIGHT
DTSTART:19700329T020000
TZOFFSETFROM:+0100
TZOFFSETTO:+0200
RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU
END:DAYLIGHT
END:VTIMEZONE
BEGIN:VEVENT
UID:lab@test
DTSTART;TZID=Europe/Madrid:20261022T100000
DTEND;TZID=Europe/Madrid:20261022T120000
RRULE:FREQ=WEEKLY;COUNT=6
EXDATE;TZID=Europe/Madrid:20261126T100000
SUMMARY:Lab
LOCATION:Q2/1004
END:VEVENT
BEGIN:VEVENT
UID:off@test
DTSTART;VALUE=DATE:20261120
DTEND;VALUE=DATE:20261121
SUMMARY:Day off
END:VEVENT
BEGIN:VEVENT
UID:meet@test
DTSTART:20261118T090000Z
DURATION:PT30M
SUMMARY:  Meeting\\n  with   tutor
END:VEVENT
BEGIN:VEVENT
UID:gone@test
DTSTART:20261119T150000Z
DTEND:20261119T160000Z
STATUS:CANCELLED
SUMMARY:Called off
END:VEVENT
BEGIN:VEVENT
UID:float@test
DTSTART:20261121T180000
DTEND:20261121T190000
SUMMARY:Dinner
END:VEVENT
END:VCALENDAR
"""

OTHER = b"""BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//test//EN
BEGIN:VEVENT
UID:a@other
DTSTART:20261119T080000Z
DTEND:20261119T090000Z
SUMMARY:Gym
END:VEVENT
END:VCALENDAR
"""

TODAY = dt.date(2026, 11, 18)


def at(*parts):
    return int(time.mktime(dt.datetime(*parts).timetuple()))


class Calendars(unittest.TestCase):
    def setUp(self):
        self.dir = tempfile.mkdtemp()
        self.env = mock.patch.dict(os.environ, {"XDG_CONFIG_HOME": self.dir + "/config", "XDG_CACHE_HOME": self.dir + "/cache",
                                                "TZ": "Europe/Madrid"})
        self.env.start()
        time.tzset()
        self.pages = {}

    def tearDown(self):
        self.env.stop()
        time.tzset()

    def reader(self, url):
        page = self.pages.get(url)
        if isinstance(page, Exception):
            raise page
        if page is None:
            raise urllib.error.URLError("nothing there")
        return page

    def add(self, url, page):
        self.pages[calendars.address(url)] = page
        return calendars.add(url, reader=self.reader)

    def test_addresses(self):
        self.assertEqual(calendars.address("  webcal://p01-caldav.icloud.com/published/2/abc  "),
                         "https://p01-caldav.icloud.com/published/2/abc")
        self.assertEqual(calendars.address("https://calendar.google.com/calendar/ical/x/private-y/basic.ics"),
                         "https://calendar.google.com/calendar/ical/x/private-y/basic.ics")
        for bad in ["ftp://x/y.ics", "file:///etc/passwd", "javascript:alert(1)", "calendar.ics", "https://", ""]:
            self.assertIsNone(calendars.address(bad), bad)

    def test_added_once_kept_by_the_user_alone(self):
        first = self.add("webcal://example.org/uni.ics", LAB)
        self.assertEqual(first["name"], "Uni")
        self.assertEqual(self.add("https://example.org/uni.ics", LAB), first)
        path = calendars.config_path()
        self.assertEqual(stat.S_IMODE(os.stat(path).st_mode), 0o600)
        with open(path, encoding="utf-8") as f:
            self.assertEqual(json.load(f), [{"id": first["id"], "url": "https://example.org/uni.ics", "name": "Uni"}])
        self.assertEqual(calendars.listed(), [{"id": first["id"], "name": "Uni", "host": "example.org"}])

    def test_what_isnt_added(self):
        self.assertEqual(calendars.add("ftp://example.org/a.ics", reader=self.reader), {"error": "url"})
        self.assertEqual(calendars.add("https://example.org/none.ics", reader=self.reader), {"error": "fetch"})
        self.assertEqual(self.add("https://example.org/page", b"<html>not one</html>"), {"error": "calendar"})
        self.assertEqual(calendars.listed(), [])
        self.assertFalse(os.path.exists(calendars.config_path()))

    def test_sync_unfolds_and_keeps(self):
        uni = self.add("https://example.org/uni.ics", LAB)["id"]
        gym = self.add("https://example.org/gym.ics", OTHER)["id"]
        kept = calendars.sync(today=TODAY, reader=self.reader)
        self.assertEqual([(c["name"], c["ok"]) for c in kept["calendars"]], [("Uni", True), ("example.org", True)])
        events = [(e["title"], e["start"], e["end"], e["allDay"], e["cal"]) for e in kept["events"]]
        lab = [e for e in events if e[0] == "Lab"]
        # 22 and 29 October, 5, 12 and 19 November: six counted, the 26th among them and taken out,
        # and summer time over on the 25th of October without moving the lab from ten.
        self.assertEqual([e[1] for e in lab], [at(2026, 10, 22, 10), at(2026, 10, 29, 10), at(2026, 11, 5, 10),
                                              at(2026, 11, 12, 10), at(2026, 11, 19, 10)])
        self.assertEqual(lab[0][2] - lab[0][1], 2 * 3600)
        self.assertIn(("Day off", at(2026, 11, 20), at(2026, 11, 21), True, uni), events)
        self.assertIn(("Meeting with tutor", at(2026, 11, 18, 10), at(2026, 11, 18, 10, 30), False, uni), events)
        self.assertIn(("Dinner", at(2026, 11, 21, 18), at(2026, 11, 21, 19), False, uni), events)
        self.assertIn(("Gym", at(2026, 11, 19, 9), at(2026, 11, 19, 10), False, gym), events)
        self.assertNotIn("Called off", [e[0] for e in events])
        self.assertEqual([e[1] for e in events], sorted(e[1] for e in events))
        self.assertEqual(next(e for e in kept["events"] if e["title"] == "Lab")["where"], "Q2/1004")
        self.assertEqual(stat.S_IMODE(os.stat(calendars.cache_path()).st_mode), 0o600)

    def test_one_that_cant_be_read_shows_what_it_showed(self):
        uni = self.add("https://example.org/uni.ics", LAB)["id"]
        self.add("https://example.org/gym.ics", OTHER)
        calendars.sync(today=TODAY, reader=self.reader)
        self.pages["https://example.org/uni.ics"] = urllib.error.URLError("offline")
        self.pages["https://example.org/gym.ics"] = b"BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:x\nEND:VCALENDAR\n"
        kept = calendars.sync(today=TODAY, reader=self.reader)
        self.assertEqual([(c["name"], c["ok"]) for c in kept["calendars"]], [("Uni", False), ("example.org", True)])
        titles = {e["title"] for e in kept["events"]}
        self.assertEqual(titles, {"Lab", "Day off", "Meeting with tutor", "Dinner"})
        self.assertTrue(all(e["cal"] == uni for e in kept["events"]))

    def test_one_event_in_two_calendars_shows_once(self):
        # The organiser's calendar and the guest's have the same meeting, the guest's an older copy;
        # the guest's also has it imported twice under other names, and a talk at other times.
        mine = self.add("https://example.org/mine.ics", b"""BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//test//EN
BEGIN:VEVENT
UID:meet@org
SEQUENCE:0
DTSTART:20261120T090000Z
DTEND:20261120T100000Z
SUMMARY:Meeting
END:VEVENT
BEGIN:VEVENT
UID:copy-1@me
DTSTART:20261121T090000Z
DTEND:20261121T100000Z
SUMMARY:Talk
END:VEVENT
BEGIN:VEVENT
UID:copy-2@me
DTSTART:20261121T090000Z
DTEND:20261121T100000Z
SUMMARY:talk
END:VEVENT
BEGIN:VEVENT
UID:copy-3@me
DTSTART:20261122T090000Z
DTEND:20261122T100000Z
SUMMARY:Talk
END:VEVENT
END:VCALENDAR
""")["id"]
        team = self.add("https://example.org/team.ics", b"""BEGIN:VCALENDAR
VERSION:2.0
PRODID:-//test//EN
BEGIN:VEVENT
UID:meet@org
SEQUENCE:2
DTSTART:20261120T090000Z
DTEND:20261120T100000Z
SUMMARY:Meeting, room 3
END:VEVENT
END:VCALENDAR
""")["id"]
        kept = calendars.sync(today=TODAY, reader=self.reader)
        events = [(e["title"], e["start"], e["cal"]) for e in kept["events"]]
        self.assertEqual(events, [("Meeting, room 3", at(2026, 11, 20, 10), team), ("Talk", at(2026, 11, 21, 10), mine),
                                  ("Talk", at(2026, 11, 22, 10), mine)])
        self.assertTrue(all(not key.startswith("_") for e in kept["events"] for key in e))
        # And so when one can't be read: what it showed doesn't come back beside the same, read now.
        self.pages["https://example.org/team.ics"] = urllib.error.URLError("offline")
        self.pages["https://example.org/mine.ics"] = self.pages["https://example.org/mine.ics"].replace(b"Meeting", b"Meeting, room 3")
        again = calendars.sync(today=TODAY, reader=self.reader)
        self.assertEqual([e["title"] for e in again["events"]].count("Meeting, room 3"), 1)

    def test_removed(self):
        uni = self.add("https://example.org/uni.ics", LAB)["id"]
        self.assertEqual(calendars.remove("nope"), {"error": "unknown"})
        self.assertEqual(calendars.remove(uni), {"ok": True})
        self.assertEqual(calendars.listed(), [])
        self.assertEqual(calendars.sync(today=TODAY, reader=self.reader)["events"], [])

    def test_window(self):
        self.assertEqual(calendars.window(TODAY), (dt.date(2026, 10, 14), dt.date(2027, 1, 28)))

    def test_an_address_comes_on_stdin(self):
        self.pages["https://example.org/uni.ics"] = LAB
        out = io.StringIO()
        with mock.patch.object(calendars, "fetch", self.reader), mock.patch.object(sys, "stdin", io.StringIO("webcal://example.org/uni.ics\n")), \
                mock.patch.object(sys, "stdout", out):
            self.assertEqual(calendars.main(["nihil-calendar", "add"]), 0)
        self.assertEqual(json.loads(out.getvalue())["name"], "Uni")
        with mock.patch.object(sys, "stderr", io.StringIO()):
            self.assertEqual(calendars.main(["nihil-calendar", "add", "https://example.org/uni.ics"]), 2)


if __name__ == "__main__":
    unittest.main()
