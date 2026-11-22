#!/usr/bin/env python3
# test_deck.py by poligle

import base64
import errno
import hashlib
import http.client
import http.server
import io
import json
import os
import re
import shutil
import socket
import ssl
import struct
import subprocess
import sys
import tempfile
import threading
import time
import unittest
import urllib.parse

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
import deck  # noqa: E402

OPENSSL = shutil.which("openssl")

APPS = [
    {"id": "zen-beta", "name": "Zen", "icon": "zen-browser"},
    {"id": "kitty", "name": "kitty", "icon": "kitty"},
    {"id": "org.gnome.Nautilus", "name": "Files", "icon": "/nowhere/files.png"},
]

FAKE_IPC = r'''#!/usr/bin/env python3
import json, os, sys
with open(os.environ["DECK_LOG"], "a") as log:
    log.write("ipc " + " ".join(sys.argv[1:]) + "\n")
if os.environ.get("DECK_SHELL_DOWN"):
    sys.exit(1)
args = sys.argv[1:]
apps = json.loads(os.environ["DECK_APPS"])
if args[:2] == ["apps", "list"]:
    print(json.dumps(apps))
elif args[:2] == ["apps", "launch"]:
    print("ok" if any(a["id"] == args[2] for a in apps) else "unknown")
elif args[:2] == ["apps", "url"]:
    print("ok")
elif args[:2] == ["media", "now"]:
    print(json.dumps({"title": "Song", "artist": "Someone", "player": "Spotify", "playing": True, "art": os.environ.get("DECK_ART", "")}))
elif args[:2] == ["tasks", "state"]:
    print(json.dumps({"cards": [{"id": "a", "text": "Desk", "column": 0, "textStamp": 1, "placeStamp": 1}], "removed": {}, "now": 5}))
elif args[:2] == ["tasks", "syncFile"]:
    board = json.load(open(args[2]))
    with open(os.environ["DECK_LOG"] + ".tasks", "w") as seen:
        seen.write(args[2] + "\n" + oct(os.stat(args[2]).st_mode & 0o777))
    board["cards"].append({"id": "a", "text": "Desk", "column": 0, "textStamp": 1, "placeStamp": 1})
    board["now"] = 5
    print(json.dumps(board))
elif args[:2] == ["toggles", "state"] or (args[:1] in (["caffeine"], ["night"]) and args[1:] in (["on"], ["off"], ["toggle"])):
    path = os.environ["DECK_LOG"] + ".toggles"
    state = json.load(open(path)) if os.path.exists(path) else {"caffeine": False, "night": False}
    if args[0] == "toggles":
        print(json.dumps(state))
    else:
        state[args[0]] = {"on": True, "off": False}.get(args[1], not state[args[0]])
        json.dump(state, open(path, "w"))
elif args[0] == "media" or args == ["session", "lock"]:
    pass
else:
    sys.exit(1)
'''

FAKE_LOGGER = r'''#!/bin/sh
echo "{name} $*" >> "$DECK_LOG"
'''

FAKE_WPCTL = r'''#!/bin/sh
echo "wpctl $*" >> "$DECK_LOG"
echo "Volume: 0.45"
'''

FAKE_WL_COPY = r'''#!/bin/sh
echo "$*" > "$XDG_RUNTIME_DIR/clipboard.args"
cat > "$XDG_RUNTIME_DIR/clipboard"
'''

FAKE_WL_PASTE = r'''#!/bin/sh
if [ "$1" = --list-types ]; then
    cat "$XDG_RUNTIME_DIR/clipboard.types" 2> /dev/null
    exit 0
fi
[ -s "$XDG_RUNTIME_DIR/clipboard" ] || exit 1
cat "$XDG_RUNTIME_DIR/clipboard"
'''

FAKE_IP = r'''#!/bin/sh
case "$*" in
    *"route get"*) echo '[{"dst":"192.0.2.1","gateway":"192.168.1.1","dev":"wlan0","prefsrc":"192.168.1.20"}]' ;;
    *"addr show"*) echo '[{"ifname":"wlan0","addr_info":[{"family":"inet","local":"192.168.1.20"}]},{"ifname":"docker0","addr_info":[{"family":"inet","local":"172.17.0.1"}]},{"ifname":"virbr0","addr_info":[{"family":"inet","local":"192.168.122.1"}]},{"ifname":"tailscale0","addr_info":[{"family":"inet","local":"100.64.0.7"}]}]' ;;
esac
'''


def script(folder, name, text):
    path = os.path.join(folder, name)
    with open(path, "w") as file:
        file.write(text)
    os.chmod(path, 0o755)
    return path


def spki_pin_with_openssl(cert):
    public = subprocess.run([OPENSSL, "x509", "-pubkey", "-noout", "-in", cert], check=True, capture_output=True).stdout
    der = subprocess.run([OPENSSL, "pkey", "-pubin", "-outform", "DER"], input=public, check=True, capture_output=True).stdout
    return base64.urlsafe_b64encode(hashlib.sha256(der).digest()).rstrip(b"=").decode()


class Phone:

    def __init__(self, port, pin, token=""):
        self.port = port
        self.pin = pin
        self.token = token

    def request(self, method, path, body=None, token=None):
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        connection = http.client.HTTPSConnection("127.0.0.1", self.port, context=context, timeout=10)
        connection.connect()
        der = connection.sock.getpeercert(binary_form=True)
        seen = deck.b64url(hashlib.sha256(deck.public_key_info(der)).digest())
        if seen != self.pin:
            raise AssertionError("the certificate is not the one pinned")
        headers = {}
        token = self.token if token is None else token
        if token:
            headers["Authorization"] = "Bearer " + token
        data = None
        if body is not None:
            data = json.dumps(body).encode()
            headers["Content-Type"] = "application/json"
        connection.request(method, path, body=data, headers=headers)
        return self.answer(connection)

    def send(self, path, data, headers):
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        connection = http.client.HTTPSConnection("127.0.0.1", self.port, context=context, timeout=10)
        connection.request("POST", path, body=data, headers=dict(headers, Authorization="Bearer " + self.token))
        return self.answer(connection)

    def answer(self, connection):
        response = connection.getresponse()
        self.last = response
        payload = response.read()
        kind = response.getheader("Content-Type")
        connection.close()
        if kind == "application/json":
            return response.status, json.loads(payload)
        return response.status, payload


@unittest.skipIf(OPENSSL is None, "needs openssl")
class Base(unittest.TestCase):
    def setUp(self):
        self.folder = tempfile.mkdtemp(prefix="deck-test-")
        self.addCleanup(shutil.rmtree, self.folder, True)
        self.log = os.path.join(self.folder, "log")
        open(self.log, "w").close()
        bin_dir = os.path.join(self.folder, "bin")
        os.makedirs(bin_dir)
        self.env = {"DECK_LOG": self.log, "DECK_APPS": json.dumps(APPS)}
        self.old_env = {key: os.environ.get(key) for key in list(self.env) + ["DECK_SHELL_DOWN", "XDG_CACHE_HOME", "XDG_RUNTIME_DIR"]}
        os.environ.update(self.env)
        os.environ["XDG_CACHE_HOME"] = os.path.join(self.folder, "cache")
        os.environ["XDG_RUNTIME_DIR"] = self.folder
        self.addCleanup(self.restore_env)
        self.addCleanup(setattr, deck, "VECTOR_SPARE", deck.VECTOR_SPARE)
        deck.VECTOR_SPARE = 0
        self.config = {
            "port": 0,
            "name": "nihil-test",
            "strings": {"deckPaired": "%1 is a deck now", "deckPairedBody": "Forget it in Preferences."},
            "ipc": script(bin_dir, "nihil-ipc", FAKE_IPC.replace("#!/usr/bin/env python3", "#!" + sys.executable)),
            "volume": script(bin_dir, "osd-volume", FAKE_LOGGER.replace("{name}", "osd-volume")),
            "notify": script(bin_dir, "notify-send", FAKE_LOGGER.replace("{name}", "notify-send")),
            "wpctl": script(bin_dir, "wpctl", FAKE_WPCTL),
            "ip": script(bin_dir, "ip", FAKE_IP),
            "wlCopy": script(bin_dir, "wl-copy", FAKE_WL_COPY),
            "wlPaste": script(bin_dir, "wl-paste", FAKE_WL_PASTE),
            "openssl": OPENSSL,
            "rsvg": "/nonexistent/rsvg-convert",
            "iconTheme": "Test-Theme",
        }

    def restore_env(self):
        for key, value in self.old_env.items():
            if value is None:
                os.environ.pop(key, None)
            else:
                os.environ[key] = value

    def logged(self):
        with open(self.log) as file:
            return file.read().splitlines()


class CertificateTest(Base):
    def test_made_once_private_and_pinned_by_its_public_key(self):
        state = os.path.join(self.folder, "state")
        cert, key = deck.ensure_certificate(state, OPENSSL)
        self.assertEqual(os.stat(key).st_mode & 0o777, 0o600)
        self.assertEqual(os.stat(state).st_mode & 0o777, 0o700)
        pin = deck.pin_of(cert)
        self.assertEqual(pin, spki_pin_with_openssl(cert))
        self.assertEqual(len(pin), 43)
        again, _ = deck.ensure_certificate(state, OPENSSL)
        self.assertEqual(deck.pin_of(again), pin)


class PairingTest(unittest.TestCase):
    def test_once_and_failures_dont_close_it(self):
        pairing = deck.Pairing()
        self.assertEqual(pairing.take("ANY"), "wrong")
        code, _, _ = pairing.open()
        self.assertEqual(len(code), deck.CODE_LENGTH)
        self.assertTrue(set(code) <= set(deck.CODE_ALPHABET))
        for _ in range(deck.CODE_TRIES - 2):
            self.assertEqual(pairing.take("WRONG"), "wrong")
        self.assertEqual(pairing.take(code.lower()), "ok")
        self.assertEqual(pairing.take(code), "wrong")

    def test_too_many_wrong_codes_from_anyone_wait(self):
        pairing = deck.Pairing()
        code, _, _ = pairing.open()
        for _ in range(deck.CODE_TRIES):
            self.assertEqual(pairing.take("WRONG"), "wrong")
        self.assertEqual(pairing.take(code), "wait")
        pairing.wrong = deck.collections.deque(moment - deck.FAIL_WINDOW for moment in pairing.wrong)
        self.assertEqual(pairing.take(code), "ok")

    def test_expires(self):
        pairing = deck.Pairing()
        code, _, invite = pairing.open()
        pairing.codes[code] = (time.time() - 1, invite)
        self.assertFalse(pairing.open_now)
        self.assertEqual(pairing.take(code), "wrong")

    def test_several_at_once_each_its_own(self):
        pairing = deck.Pairing()
        shown, _, mine = pairing.open()
        watch, _, theirs = pairing.open()
        self.assertEqual(sorted(pairing.invites()), sorted([mine, theirs]))
        pairing.close(mine)
        self.assertEqual(pairing.invites(), [theirs])
        self.assertEqual(pairing.take(shown), "wrong")
        self.assertEqual(pairing.take(watch), "ok")
        for _ in range(deck.CODES_OPEN + 2):
            pairing.open()
        self.assertEqual(len(pairing.invites()), deck.CODES_OPEN)
        pairing.close()
        self.assertFalse(pairing.open_now)


class UrlTest(unittest.TestCase):
    def test_only_web_pages(self):
        for url in ("https://nixos.org", "http://192.168.1.1:8080/admin?x=1#y", "https://example.com/a%20b"):
            self.assertTrue(deck.valid_url(url), url)
        for url in ("javascript:alert(1)", "file:///etc/passwd", "https://", "https://exa mple.com",
                    "https://example.com/\n", "ftp://example.com", "", None, 42, "https://" + "a" * 2050,
                    "nihil-deck://pair", "about:blank"):
            self.assertFalse(deck.valid_url(url), url)


class QrTest(unittest.TestCase):
    def ascii(self, rows):
        return "\n".join("".join("##" if module == "1" else "  " for module in row).rstrip() for row in rows) + "\n"

    def test_modules_from_qrencode_ascii(self):
        rows = ["".join("1" if (x * 7 + y * 3) % 5 == 0 or x < 7 and y < 7 else "0" for x in range(21)) for y in range(21)]
        self.assertEqual(deck.qr_rows(self.ascii(rows)), rows)

    def test_not_a_qr(self):
        with self.assertRaises(ValueError):
            deck.qr_rows("##  ##\n##  ##\n")
        with self.assertRaises(ValueError):
            deck.qr_rows("")


class IconTest(unittest.TestCase):
    def setUp(self):
        self.base = tempfile.mkdtemp(prefix="deck-icons-")
        self.addCleanup(shutil.rmtree, self.base, True)

    def theme(self, name, inherits, files):
        root = os.path.join(self.base, "icons", name)
        directories = sorted({os.path.dirname(path) for path in files})
        os.makedirs(root, exist_ok=True)
        with open(os.path.join(root, "index.theme"), "w") as file:
            file.write("[Icon Theme]\nName=%s\n" % name)
            if inherits:
                file.write("Inherits=%s\n" % inherits)
            file.write("Directories=%s\n\n" % ",".join(directories))
            for directory in directories:
                scalable = "scalable" in directory
                file.write("[%s]\nSize=%s\nType=%s\n\n" % (directory, 48 if scalable else directory.split("x")[0].split("/")[-1],
                                                           "Scalable" if scalable else "Fixed"))
        for path in files:
            full = os.path.join(root, path)
            os.makedirs(os.path.dirname(full), exist_ok=True)
            open(full, "w").close()
        return root

    def test_theme_then_what_it_inherits_then_hicolor(self):
        deck.theme_index.cache_clear()
        child = self.theme("Child", "Parent", ["apps/scalable/zen-browser.svg"])
        parent = self.theme("Parent", "", ["32x32/apps/kitty.png", "128x128/apps/kitty.png"])
        hicolor = self.theme("hicolor", "", ["48x48/apps/thunar.png"])
        dirs = [self.base]
        self.assertEqual(deck.icon_file("zen-browser", "Child", dirs), os.path.join(child, "apps/scalable/zen-browser.svg"))
        self.assertEqual(deck.icon_file("kitty", "Child", dirs), os.path.join(parent, "128x128/apps/kitty.png"))
        self.assertEqual(deck.icon_file("thunar", "Child", dirs), os.path.join(hicolor, "48x48/apps/thunar.png"))
        self.assertIsNone(deck.icon_file("nothing", "Child", dirs))
        self.assertIsNone(deck.icon_file("../../etc/passwd", "Child", dirs))
        self.assertIsNone(deck.icon_file("/etc/passwd", "Child", dirs))

    def test_the_size_closest_to_the_phones(self):
        deck.theme_index.cache_clear()
        big = self.theme("Big", "", ["48x48/apps/foot.png", "256x256/apps/foot.png", "512x512/apps/foot.png"])
        small = self.theme("Small", "", ["32x32/apps/foot.png", "64x64/apps/foot.png"])
        self.assertEqual(deck.icon_file("foot", "Big", [self.base]), os.path.join(big, "256x256/apps/foot.png"))
        self.assertEqual(deck.icon_file("foot", "Small", [self.base]), os.path.join(small, "64x64/apps/foot.png"))


class AddressesTest(Base):
    def test_the_default_route_first(self):
        self.assertEqual(deck.addresses(self.config["ip"]), ["192.168.1.20", "100.64.0.7"])


class ServerTest(Base):
    def setUp(self):
        super().setUp()
        state = os.path.join(self.folder, "state")
        self.server = deck.make_server(self.config, state, host="127.0.0.1")
        self.deck = self.server.deck
        self.thread = threading.Thread(target=self.server.serve_forever, daemon=True)
        self.thread.start()
        self.addCleanup(self.stop)
        self.phone = Phone(self.deck.port, self.deck.pin)

    def stop(self):
        self.server.shutdown()
        self.server.server_close()

    def answering(self, op="allow"):
        """Someone at the computer, answering the next pairing that asks."""
        def answer():
            for _ in range(200):
                waiting = self.deck.control({"op": "devices"})["asking"]
                if waiting:
                    self.deck.control({"op": op, "id": waiting[0]["id"]})
                    return
                time.sleep(0.02)
        threading.Thread(target=answer, daemon=True).start()

    def pair(self, name="Phone"):
        reply = self.deck.control({"op": "pair"})
        self.answering()
        status, body = self.phone.request("POST", "/v1/pair", {"code": reply["code"], "device": name})
        self.assertEqual(status, 200, body)
        self.phone.token = body["token"]
        return body

    def test_pairing_waits_for_the_computer(self):
        # The right code only asks: denied, or not answered in time, nothing is paired.
        reply = self.deck.control({"op": "pair"})
        self.answering("deny")
        status, body = self.phone.request("POST", "/v1/pair", {"code": reply["code"], "device": "-Intruder"})
        self.assertEqual((status, body), (403, {"error": "declined"}))
        self.assertEqual(self.deck.control({"op": "devices"})["devices"], [])
        self.assertEqual(deck.clean_name("--app-name=x", "Android"), "app-name=x")

    def test_a_slow_request_is_cut(self):
        # Dripping a request a byte at a time doesn't hold a connection past REQUEST_SECONDS.
        old = deck.REQUEST_SECONDS
        deck.REQUEST_SECONDS = 0.5
        self.addCleanup(setattr, deck, "REQUEST_SECONDS", old)
        context = ssl.create_default_context()
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        with socket.create_connection(("127.0.0.1", self.deck.port)) as raw, context.wrap_socket(raw) as tls:
            tls.sendall(b"GET /v1/hel")
            tls.settimeout(5)
            started = time.monotonic()
            try:
                self.assertEqual(tls.recv(1), b"")
            except (ssl.SSLError, ConnectionError):
                pass
            self.assertLess(time.monotonic() - started, 3)

    def test_forgetting_cuts_the_trackpad(self):
        self.pair()
        device = self.deck.control({"op": "devices"})["devices"][0]["id"]
        left, right = socket.socketpair()
        self.addCleanup(left.close)
        self.addCleanup(right.close)
        self.deck.claim(device, left)
        self.assertTrue(self.deck.control({"op": "forget", "id": device})["ok"])
        right.settimeout(2)
        self.assertEqual(right.recv(1), b"")

    def test_pairing_with_the_code_in_the_qr(self):
        status, body = self.phone.request("GET", "/v1/hello")
        self.assertEqual((status, body), (200, {"deck": deck.API}))
        self.assertEqual(self.phone.request("GET", "/v1/apps")[0], 401)

        reply = self.deck.control({"op": "pair"})
        self.assertIn("code=" + reply["code"], reply["uri"])
        self.assertIn("pin=" + self.deck.pin, reply["uri"])
        self.assertIn("hosts=192.168.1.20,100.64.0.7", reply["uri"])
        self.assertTrue(reply["uri"].startswith("nihil-deck://pair?v=1&name=nihil-test&"))

        self.assertEqual(self.phone.request("POST", "/v1/pair", {"code": "WRONGCODE", "device": "x"})[0], 403)
        self.answering()
        status, body = self.phone.request("POST", "/v1/pair", {"code": reply["code"], "device": "Pho\x07ne"})
        self.assertEqual(status, 200, body)
        self.assertEqual(body["name"], "nihil-test")
        self.assertEqual(self.phone.request("POST", "/v1/pair", {"code": reply["code"], "device": "other"}),
                         (403, {"error": "wrong"}))

        devices = self.deck.control({"op": "devices"})["devices"]
        self.assertEqual([(d["id"], d["name"]) for d in devices], [(body["device"], "Phone")])
        self.assertIn("notify-send -a NIHIL -- Phone is a deck now Forget it in Preferences.", self.logged())
        with open(os.path.join(self.folder, "state", "devices.json")) as file:
            stored = file.read()
        self.assertNotIn(body["token"], stored)
        self.assertEqual(os.stat(os.path.join(self.folder, "state", "devices.json")).st_mode & 0o777, 0o600)

    def test_what_a_paired_phone_may_do(self):
        self.pair()
        status, body = self.phone.request("GET", "/v1/apps")
        self.assertEqual(status, 200)
        self.assertEqual([a["id"] for a in body["apps"]], ["zen-beta", "kitty", "org.gnome.Nautilus"])

        self.assertEqual(self.phone.request("POST", "/v1/open", {"app": "zen-beta"}), (200, {"ok": True}))
        self.assertEqual(self.phone.request("POST", "/v1/open", {"app": "rm -rf ~"})[0], 404)
        self.assertEqual(self.phone.request("POST", "/v1/open", {"app": "steam"})[0], 404)
        self.assertEqual(self.phone.request("POST", "/v1/open", {"url": "https://nixos.org"}), (200, {"ok": True}))
        self.assertEqual(self.phone.request("POST", "/v1/open", {"url": "file:///etc/shadow"})[0], 400)
        self.assertEqual(self.phone.request("POST", "/v1/open", {})[0], 400)

        self.assertEqual(self.phone.request("POST", "/v1/media", {"action": "toggle"}), (200, {"ok": True}))
        self.assertEqual(self.phone.request("POST", "/v1/media", {"action": "shutdown"})[0], 400)
        self.assertEqual(self.phone.request("POST", "/v1/volume", {"action": "up"}), (200, {"level": 45, "muted": False}))
        self.assertEqual(self.phone.request("POST", "/v1/lock", {}), (200, {"ok": True}))
        self.assertEqual(self.phone.request("POST", "/v1/caffeine", {"action": "toggle"}), (200, {"on": True}))
        self.assertEqual(self.phone.request("POST", "/v1/night", {"action": "on"}), (200, {"on": True}))
        self.assertEqual(self.phone.request("POST", "/v1/night", {"action": "toggle"}), (200, {"on": False}))
        self.assertEqual(self.phone.request("POST", "/v1/caffeine", {"action": "sudo"})[0], 400)

        status, body = self.phone.request("GET", "/v1/state")
        self.assertEqual(status, 200)
        self.assertEqual(body["media"]["title"], "Song")
        self.assertEqual(body["volume"], {"level": 45, "muted": False})
        self.assertEqual((body["caffeine"], body["night"]), (True, False))

        calls = self.logged()
        self.assertIn("ipc apps launch zen-beta", calls)
        self.assertIn("ipc apps url https://nixos.org", calls)
        self.assertNotIn("ipc apps launch steam", calls)
        self.assertIn("ipc media toggle", calls)
        self.assertIn("osd-volume up", calls)
        self.assertIn("ipc session lock", calls)
        self.assertIn("ipc caffeine toggle", calls)
        self.assertNotIn("ipc caffeine sudo", calls)
        self.assertFalse(any("shadow" in call or "rm -rf" in call for call in calls))

        self.assertEqual(self.phone.request("GET", "/v1/nothing")[0], 404)
        self.assertEqual(self.phone.request("POST", "/v1/unpair", {}), (200, {"ok": True}))
        self.assertEqual(self.phone.request("GET", "/v1/apps")[0], 401)

    def test_vector_to_the_phone(self):
        self.pair()
        status, empty = self.phone.request("GET", "/v1/vector")
        self.assertEqual((status, empty["id"]), (200, ""))
        self.assertLess(abs(empty["now"] - time.time()), 5)
        photo = os.path.join(self.folder, "Ñandú en la nieve.jpg")
        with open(photo, "wb") as file:
            file.write(b"\xff\xd8" + os.urandom(200000))
        sent = deck.vector_send(self.config, self.deck.vector, photo)
        self.assertEqual(sent, {"ok": True, "kind": "image", "name": "Ñandú en la nieve.jpg",
                                "path": os.path.join(self.deck.vector.slot("out"), "Ñandú en la nieve.jpg")})
        status, item = self.phone.request("GET", "/v1/vector")
        self.assertEqual((status, item["kind"], item["mime"], item["size"]), (200, "image", "image/jpeg", 200002))
        self.assertLessEqual(item["time"], item["now"])
        status, data = self.phone.request("GET", "/v1/vector/data?id=" + item["id"])
        with open(photo, "rb") as file:
            self.assertEqual((status, data), (200, file.read()))
        self.assertIn("Ñandú", urllib.parse.unquote(self.phone.last.getheader("Content-Disposition")))
        self.assertEqual(self.phone.request("GET", "/v1/vector/data?id=0000")[0], 404)
        self.assertEqual(self.phone.request("GET", "/v1/vector", token="nope")[0], 401)

        answers = []
        waiting = threading.Thread(target=lambda: answers.append(
            self.phone.request("GET", "/v1/vector?wait=8&since=" + item["id"])))
        started = time.monotonic()
        waiting.start()
        time.sleep(0.5)
        self.assertEqual(self.deck.control({"op": "vector"}), {"devices": ["Phone"]})
        note = os.path.join(self.folder, "note")
        with open(note, "w") as file:
            file.write("ex nihilo")
        deck.vector_send(self.config, self.deck.vector, "file://" + urllib.parse.quote(note))
        waiting.join(10)
        self.assertLess(time.monotonic() - started, 6)
        status, newer = answers[0]
        self.assertEqual((status, newer["name"], newer["kind"]), (200, "note", "file"))
        self.assertNotEqual(newer["id"], item["id"])
        self.assertEqual(sorted(os.listdir(self.deck.vector.slot("out"))), [".item.json", "note"])

    def test_vector_from_the_phone(self):
        self.pair()
        video = b"\x00\x00\x00\x18ftypmp42" + os.urandom(300000 - 12)
        status, item = self.phone.send("/v1/vector", video, {"Content-Type": "video/mp4",
                                                             "X-Vector-Name": urllib.parse.quote("Café.mp4")})
        self.assertEqual((status, item["kind"], item["name"], item["size"]), (200, "video", "Café.mp4", 300000))
        received = self.deck.vector.item("in")
        with open(received["path"], "rb") as file:
            self.assertEqual(file.read(), video)
        self.assertEqual(received["from"], "Phone")
        self.assertIn("ipc vector received", self.logged())
        status, text = self.phone.send("/v1/vector", "ñ".encode(), {"Content-Type": "text/plain; charset=utf-8"})
        self.assertEqual((status, text["kind"]), (200, "text"))
        self.assertRegex(text["name"], r"^Vector_\d{4}-\d\d-\d\d_\d\d\.\d\d\.\d\d\.txt$")
        self.assertEqual(sorted(os.listdir(self.deck.vector.slot("in"))), [".item.json", text["name"]])
        status, hidden = self.phone.send("/v1/vector", b"x", {"X-Vector-Name": "../.item.json"})
        self.assertEqual((status, hidden["kind"]), (200, "file"))
        self.assertRegex(hidden["name"], r"^Vector_[\d._-]+$")
        self.addCleanup(setattr, deck, "VECTOR_TEXT", deck.VECTOR_TEXT)
        deck.VECTOR_TEXT = 4
        status, long = self.phone.send("/v1/vector", b"hello", {"Content-Type": "text/plain", "X-Vector-Name": "notes.txt"})
        self.assertEqual((status, long["kind"], long["name"]), (200, "file", "notes.txt"))
        old = deck.VECTOR_MAX
        deck.VECTOR_MAX = 10
        self.addCleanup(setattr, deck, "VECTOR_MAX", old)
        self.assertEqual(self.phone.send("/v1/vector", b"x" * 11, {"Content-Type": "image/png"})[0], 413)

    def test_vector_and_the_clipboard(self):
        self.pair()
        vector = self.deck.vector
        runtime = self.folder

        def clipboard(data, types):
            with open(os.path.join(runtime, "clipboard"), "wb") as file:
                file.write(data)
            with open(os.path.join(runtime, "clipboard.types"), "w") as file:
                file.write("\n".join(types) + "\n")

        clipboard(b"\x89PNG" + os.urandom(64), ["image/png", "text/html"])
        sent = deck.vector_send(self.config, vector)
        self.assertEqual((sent["kind"], sent["path"]), ("image", vector.item("out")["path"]))
        self.assertTrue(sent["name"].startswith("Vector_") and sent["name"].endswith(".png"))
        song = os.path.join(self.folder, "Song.ogg")
        with open(song, "wb") as file:
            file.write(b"OggS")
        clipboard(("file://" + urllib.parse.quote(song) + "\r\n").encode(), ["text/uri-list", "text/plain"])
        self.assertEqual(deck.vector_send(self.config, vector)["name"], "Song.ogg")
        report = os.path.join(self.folder, "Un informe.pdf")
        with open(report, "wb") as file:
            file.write(b"%PDF")
        clipboard(("copy\nfile://" + urllib.parse.quote(report)).encode(), ["x-special/gnome-copied-files", "UTF8_STRING"])
        self.assertEqual(deck.vector_send(self.config, vector)["name"], "Un informe.pdf")
        clipboard(b"hunter2", ["text/plain", "x-kde-passwordManagerHint"])
        self.assertEqual(deck.vector_send(self.config, vector), {"error": "secret"})
        clipboard(b"hola", ["text/plain;charset=utf-8", "UTF8_STRING"])
        sent = deck.vector_send(self.config, vector)
        self.assertEqual((sent["kind"], sent["preview"]), ("text", "hola"))
        self.assertEqual(deck.vector_send(self.config, vector, text="ex nihilo")["preview"], "ex nihilo")
        clipboard(b"", [])
        self.assertEqual(deck.vector_send(self.config, vector), {"error": "empty"})
        self.assertEqual(deck.vector_send(self.config, vector, self.folder), {"error": "folder"})

        folder = os.path.join(self.folder, "Vector")
        self.config["vectorFolder"] = folder
        self.config["open"] = script(os.path.join(self.folder, "bin"), "xdg-open", FAKE_LOGGER.replace("{name}", "xdg-open"))
        self.assertEqual(deck.vector_command(self.config, "copy", None), {"error": "empty"})
        self.phone.send("/v1/vector", PNG, {"Content-Type": "image/png"})
        self.assertEqual(deck.vector_command(self.config, "copy", None), {"ok": True})
        with open(os.path.join(runtime, "clipboard.args")) as file:
            self.assertEqual(file.read().split(), ["--type", "image/png"])
        self.assertIsNone(vector.item("in"))
        self.assertEqual(os.listdir(vector.slot("in")), [])

        for copy in range(2):
            self.phone.send("/v1/vector", b"%PDF", {"Content-Type": "application/pdf", "X-Vector-Name": "Una factura.pdf"})
            self.assertEqual(deck.vector_command(self.config, "copy", None), {"error": "kind"})
            kept = deck.vector_command(self.config, "save", None)
            self.assertEqual(kept["path"], os.path.join(folder, ["Una factura.pdf", "Una factura (2).pdf"][copy]))
            self.assertIsNone(vector.item("in"))
        with open(os.path.join(folder, "Una factura (2).pdf"), "rb") as file:
            self.assertEqual(file.read(), b"%PDF")

        self.phone.send("/v1/vector", b"\x00\x00\x00 ftyp", {"Content-Type": "video/mp4", "X-Vector-Name": "clip.mp4"})
        opened = deck.vector_command(self.config, "open", None)
        self.assertEqual(opened["path"], os.path.join(folder, "clip.mp4"))
        for _ in range(50):
            if "xdg-open " + opened["path"] in self.logged():
                break
            time.sleep(0.05)
        self.assertIn("xdg-open " + opened["path"], self.logged())
        self.phone.send("/v1/vector", b"bye", {"Content-Type": "text/plain"})
        self.assertEqual(deck.vector_command(self.config, "clear", None), {"ok": True})
        self.assertEqual(deck.vector_command(self.config, "clear", None), {"error": "empty"})

    def test_without_the_shell(self):
        self.pair()
        os.environ["DECK_SHELL_DOWN"] = "1"
        self.deck.session.cached = None
        self.assertEqual(self.phone.request("GET", "/v1/apps")[0], 503)
        self.assertEqual(self.phone.request("POST", "/v1/media", {"action": "next"})[0], 503)
        self.assertEqual(self.phone.request("POST", "/v1/night", {"action": "toggle"})[0], 503)
        self.assertNotIn("caffeine", self.phone.request("GET", "/v1/state")[1])

    def test_icons(self):
        theme = os.path.join(self.folder, "share", "icons", "Test-Theme", "48x48", "apps")
        os.makedirs(theme)
        with open(os.path.join(self.folder, "share", "icons", "Test-Theme", "index.theme"), "w") as file:
            file.write("[Icon Theme]\nName=Test\nDirectories=48x48/apps\n\n[48x48/apps]\nSize=48\nType=Fixed\n")
        with open(os.path.join(theme, "kitty.png"), "wb") as file:
            file.write(b"\x89PNG\r\n\x1a\nfake")
        old = os.environ.get("XDG_DATA_DIRS")
        os.environ["XDG_DATA_DIRS"] = os.path.join(self.folder, "share")
        self.addCleanup(lambda: os.environ.__setitem__("XDG_DATA_DIRS", old) if old is not None else os.environ.pop("XDG_DATA_DIRS", None))
        deck.theme_index.cache_clear()
        self.pair()
        self.assertEqual(self.phone.request("GET", "/v1/apps/kitty/icon"), (200, b"\x89PNG\r\n\x1a\nfake"))
        self.assertEqual(self.phone.request("GET", "/v1/apps/zen-beta/icon")[0], 404)
        self.assertEqual(self.phone.request("GET", "/v1/apps/..%2F..%2Fetc/icon")[0], 404)

    def test_the_icon_of_a_web(self):
        site = Site({"/": (200, "text/html", b'<link rel="icon" href="/i.png" sizes="64x64">'),
                     "/i.png": (200, "image/png", PNG + b"64")})
        self.addCleanup(site.stop)
        deck.PUBLIC_ONLY = False
        self.addCleanup(setattr, deck, "PUBLIC_ONLY", True)
        old = os.environ.get("XDG_CACHE_HOME")
        os.environ["XDG_CACHE_HOME"] = os.path.join(self.folder, "cache")
        self.addCleanup(lambda: os.environ.__setitem__("XDG_CACHE_HOME", old) if old is not None else os.environ.pop("XDG_CACHE_HOME", None))
        self.pair()
        quoted = urllib.parse.quote(site.url + "/blog/post", safe="")
        self.assertEqual(self.phone.request("GET", "/v1/favicon?url=" + quoted), (200, PNG + b"64"))
        self.assertEqual(self.phone.last.getheader("Content-Type"), "image/png")
        self.assertEqual(self.phone.request("GET", "/v1/favicon?url=" + urllib.parse.quote("file:///etc/passwd", safe=""))[0], 400)
        self.assertEqual(self.phone.request("GET", "/v1/favicon")[0], 400)
        self.assertEqual(self.phone.request("GET", "/v1/favicon?url=x", token="nope")[0], 401)

    def test_the_kanban(self):
        self.pair()
        status, body = self.phone.request("GET", "/v1/tasks")
        self.assertEqual((status, body["cards"][0]["text"], body["now"]), (200, "Desk", 5))
        phone = {"cards": [{"id": "p", "text": "  Phone   card ", "column": 1, "textStamp": 3, "placeStamp": 4}], "removed": {"z": 2}}
        status, body = self.phone.request("POST", "/v1/tasks", phone)
        self.assertEqual(status, 200)
        self.assertEqual([c["id"] for c in body["cards"]], ["p", "a"])
        self.assertEqual(body["cards"][0]["text"], "Phone card")
        self.assertEqual(body["removed"], {"z": 2})
        ranked = {"cards": [{"id": "r", "text": "Ranked", "column": 0, "textStamp": 1, "placeStamp": 1, "rank": 2.5}]}
        status, body = self.phone.request("POST", "/v1/tasks", ranked)
        self.assertEqual((status, body["cards"][0]["rank"]), (200, 2.5))
        self.assertNotIn("rank", body["cards"][1])
        self.assertEqual(self.phone.request("POST", "/v1/tasks", {"cards": [dict(ranked["cards"][0], rank="first")]})[0], 400)
        for bad in ({"cards": [{"id": "x", "text": "No column", "textStamp": 1, "placeStamp": 1}]},
                    {"cards": "nope"}, {"removed": {"x": "yesterday"}}):
            self.assertEqual(self.phone.request("POST", "/v1/tasks", bad)[0], 400)
        many = {"cards": [{"id": "c%d" % i, "text": "Task %d" % i, "column": 0, "textStamp": i, "placeStamp": i} for i in range(80)]}
        self.assertEqual(self.phone.request("POST", "/v1/tasks", many)[0], 200)
        # A whole board past 128 KiB, the most an argument takes, goes through a private file.
        long = {"cards": [{"id": f"l{i}", "text": f"Task {i} " * 20, "column": i % 3, "textStamp": i, "placeStamp": i}
                          for i in range(900)]}
        self.assertGreater(len(json.dumps(long)), 128 * 1024)
        status, body = self.phone.request("POST", "/v1/tasks", long)
        self.assertEqual((status, len(body["cards"])), (200, 901))
        with open(self.log + ".tasks") as seen:
            path, mode = seen.read().split("\n")
        self.assertEqual(mode, "0o600")
        self.assertFalse(os.path.exists(path))
        with open(self.log) as log:
            self.assertNotIn("Task 899", log.read())
        # Stamps a merge can live with: whole milliseconds, no further than a day ahead.
        ahead = int(time.time() * 1000) + 2 * 86_400_000
        for stamp in (10 ** 400, ahead, -1, 1.5, True):
            card = {"id": "s", "text": "Stamp", "column": 0, "textStamp": stamp, "placeStamp": 1}
            self.assertEqual(self.phone.request("POST", "/v1/tasks", {"cards": [card]})[0], 400, stamp)
            self.assertEqual(self.phone.request("POST", "/v1/tasks", {"removed": {"s": stamp}})[0], 400, stamp)
        # A rank too big for a float is a 400, not a connection dropped.
        for rank, status in ((10 ** 400, 400), (2 ** 53 + 1, 400), (-(2 ** 53), 200), (1e308, 200)):
            card = {"id": "r", "text": "Rank", "column": 0, "textStamp": 1, "placeStamp": 1, "rank": rank}
            self.assertEqual(self.phone.request("POST", "/v1/tasks", {"cards": [card]})[0], status, rank)

    def upgrade(self, path, protocol="nihil-trackpad"):
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        connection = context.wrap_socket(socket.create_connection(("127.0.0.1", self.deck.port), timeout=10))
        connection.sendall((f"GET {path} HTTP/1.1\r\nHost: 127.0.0.1\r\nAuthorization: Bearer {self.phone.token}\r\n"
                            f"Connection: Upgrade\r\nUpgrade: {protocol}\r\n\r\n").encode())
        head = b""
        while b"\r\n\r\n" not in head:
            chunk = connection.recv(1)
            if not chunk:
                break
            head += chunk
        text = head.decode()
        length = re.search(r"Content-Length: (\d+)", text)
        body = b""
        while length and len(body) < int(length.group(1)):
            body += connection.recv(4096)
        return int(text.split(" ", 2)[1]), (json.loads(body) if body else None), connection

    def test_the_trackpad(self):
        self.pair()
        made = []

        class Pad:
            def __init__(self, width, height, resolution):
                self.width, self.height, self.resolution = width, height, resolution
                self.events = []
                self.closed = threading.Event()
                made.append(self)

            def write(self, events):
                self.events += events

            def close(self):
                self.closed.set()

        self.deck.make_trackpad = Pad
        status, _, connection = self.upgrade("/v1/trackpad?w=2800&h=1200&r=20")
        self.assertEqual(status, 101)
        self.assertEqual((made[0].width, made[0].height, made[0].resolution), (2800, 1200, 20))

        def frame(millis, *fingers):
            return struct.pack("!BIB", 1, millis, len(fingers)) + b"".join(struct.pack("!BHH", *finger) for finger in fingers)

        connection.sendall(frame(1000, (0, 100, 200)) + frame(1008, (0, 120, 200)) + frame(1016, (0, 9000, 200)) + frame(1024))
        connection.sendall(struct.pack("!BI", 2, 1030))
        self.assertEqual(connection.recv(1), b"\x02")
        connection.close()
        self.assertTrue(made[0].closed.wait(5))
        xs = [value for kind, code, value in made[0].events if (kind, code) == (deck.EV_ABS, deck.ABS_MT_POSITION_X)]
        self.assertEqual(xs, [100, 120, 2800])          # past the edge: at the edge
        self.assertEqual(made[0].events[-2:], [(deck.EV_KEY, deck.BTN_TOUCH, 0), (deck.EV_SYN, deck.SYN_REPORT, 0)])

        _, _, first = self.upgrade("/v1/trackpad?w=2800&h=1200&r=20")
        _, _, second = self.upgrade("/v1/trackpad?w=2800&h=1200&r=20")
        self.assertTrue(made[1].closed.wait(5))
        self.assertFalse(made[2].closed.is_set())
        first.close()
        second.close()
        self.assertTrue(made[2].closed.wait(5))

        self.assertEqual(self.upgrade("/v1/trackpad?w=20&h=1200&r=20")[:2], (400, {"error": "invalid"}))
        self.assertEqual(self.upgrade("/v1/trackpad?w=2800&h=1200&r=20", protocol="websocket")[:2], (400, {"error": "invalid"}))

        def denied(width, height, resolution):
            raise PermissionError(errno.EACCES, "denied")

        self.deck.make_trackpad = denied
        self.assertEqual(self.upgrade("/v1/trackpad?w=2800&h=1200&r=20")[:2], (503, {"error": "access"}))

    def test_several_devices_at_once(self):
        made = []

        class Pad:
            def __init__(self, width, height, resolution):
                self.closed = threading.Event()
                made.append(self)

            def write(self, events):
                pass

            def close(self):
                self.closed.set()

        self.deck.make_trackpad = Pad
        tokens = {name: self.pair(name)["token"] for name in ("Phone", "Tablet", "Watch")}
        devices = self.deck.control({"op": "devices"})["devices"]
        self.assertEqual(sorted(device["name"] for device in devices), ["Phone", "Tablet", "Watch"])

        answers = []

        def ask(token):
            for _ in range(5):
                answers.append(self.phone.request("GET", "/v1/state", token=token)[0])

        threads = [threading.Thread(target=ask, args=(token,)) for token in tokens.values()]
        for thread in threads:
            thread.start()
        for thread in threads:
            thread.join()
        self.assertEqual(answers, [200] * 15)

        self.phone.token = tokens["Phone"]
        first, _, phone = self.upgrade("/v1/trackpad?w=2800&h=1200&r=20")
        self.phone.token = tokens["Tablet"]
        second, _, tablet = self.upgrade("/v1/trackpad?w=2800&h=1200&r=20")
        self.assertEqual((first, second), (101, 101))
        self.assertEqual(self.phone.request("GET", "/v1/state", token=tokens["Watch"])[0], 200)
        time.sleep(0.3)
        self.assertFalse(made[0].closed.is_set() or made[1].closed.is_set())
        phone.close()
        tablet.close()
        self.assertTrue(made[0].closed.wait(5) and made[1].closed.wait(5))

        self.deck.control({"op": "forget", "id": next(d["id"] for d in devices if d["name"] == "Tablet")})
        statuses = {name: self.phone.request("GET", "/v1/state", token=token)[0] for name, token in tokens.items()}
        self.assertEqual(statuses, {"Phone": 200, "Tablet": 401, "Watch": 200})

    def test_the_cover(self):
        art = os.path.join(self.folder, "cover.png")
        with open(art, "wb") as file:
            file.write(deck.PNG_MAGIC + b"cover")
        old = os.environ.get("DECK_ART")
        os.environ["DECK_ART"] = "file://" + art
        self.addCleanup(lambda: os.environ.__setitem__("DECK_ART", old) if old is not None else os.environ.pop("DECK_ART", None))
        self.pair()
        status, body = self.phone.request("GET", "/v1/state")
        token = body["media"]["cover"]
        self.assertNotIn("art", body["media"])
        self.assertEqual(len(token), 16)
        self.assertEqual(self.phone.request("GET", "/v1/cover?c=" + token), (200, deck.PNG_MAGIC + b"cover"))
        self.assertEqual(self.phone.request("GET", "/v1/cover?c=0123456789abcdef")[0], 404)
        self.assertEqual(self.phone.request("GET", "/v1/cover?c=../../etc")[0], 404)

    def test_wrong_tokens_wait(self):
        for _ in range(deck.FAIL_LIMIT):
            self.assertEqual(self.phone.request("GET", "/v1/apps", token="nope")[0], 401)
        self.assertEqual(self.phone.request("GET", "/v1/hello")[0], 429)
        self.assertEqual(self.phone.last.getheader("Connection"), "close")

    def test_a_body_too_big(self):
        self.pair()
        status, body = self.phone.request("POST", "/v1/open", {"url": "https://example.com/" + "a" * deck.MAX_BODY})
        self.assertEqual((status, body), (400, {"error": "body"}))
        self.assertEqual(self.phone.last.getheader("Connection"), "close")
        self.assertEqual(self.phone.request("GET", "/v1/hello")[0], 200)
        self.assertIsNone(self.phone.last.getheader("Connection"))

    def test_whether_the_code_still_pairs(self):
        reply = self.deck.control({"op": "pair"})
        listed = self.deck.control({"op": "devices"})
        self.assertEqual((listed["pairing"], listed["invites"]), (True, [reply["invite"]]))
        self.answering()
        self.assertEqual(self.phone.request("POST", "/v1/pair", {"code": reply["code"], "device": "Phone"})[0], 200)
        listed = self.deck.control({"op": "devices"})
        self.assertEqual((listed["pairing"], listed["invites"]), (False, []))

    def test_who_sends_it_before_its_body(self):
        # Without a token, a body isn't read, whatever size it says, and the connection ends.
        context = ssl.SSLContext(ssl.PROTOCOL_TLS_CLIENT)
        context.check_hostname = False
        context.verify_mode = ssl.CERT_NONE
        connection = http.client.HTTPSConnection("127.0.0.1", self.deck.port, context=context, timeout=10)
        connection.putrequest("POST", "/v1/tasks")
        connection.putheader("Content-Type", "application/json")
        connection.putheader("Content-Length", str(deck.TASKS_MAX))
        connection.endheaders()
        response = connection.getresponse()
        self.assertEqual((response.status, response.getheader("Connection")), (401, "close"))
        connection.close()
        # Paired, JSON nested past what Python parses is a 400 too.
        self.pair()
        nested = b"[" * 100000 + b"]" * 100000
        self.assertEqual(self.phone.send("/v1/tasks", nested, {"Content-Type": "application/json"}), (400, {"error": "body"}))

    def test_a_code_says_nothing_and_two_are_open_at_once(self):
        shown = self.deck.control({"op": "pair"})
        watch = self.deck.control({"op": "pair"})
        invites = self.deck.control({"op": "devices"})["invites"]
        self.assertEqual(sorted(invites), sorted([shown["invite"], watch["invite"]]))
        self.deck.control({"op": "cancel", "invite": shown["invite"]})
        for code in (shown["code"], "WRONGCODE"):
            self.assertEqual(self.phone.request("POST", "/v1/pair", {"code": code, "device": "x"}), (403, {"error": "wrong"}))
        self.answering()
        status, body = self.phone.request("POST", "/v1/pair", {"code": watch["code"], "device": "Watch"})
        self.assertEqual(status, 200, body)

    def test_a_device_unseen_for_ninety_days_is_forgotten(self):
        self.pair()
        listed = self.deck.control({"op": "devices"})["devices"][0]
        self.assertEqual(listed["expires"], listed["seen"] + deck.TOKEN_DAYS * 86400)
        self.deck.devices.items[0]["seen"] -= deck.TOKEN_DAYS * 86400 + 1
        self.assertEqual(self.phone.request("GET", "/v1/apps")[0], 401)
        self.assertEqual(self.deck.control({"op": "devices"})["devices"], [])

    def test_what_a_device_names_and_sends(self):
        self.pair()
        status, item = self.phone.send("/v1/vector", b"[Desktop Entry]\nExec=sh\n",
                                       {"Content-Type": "image/jpeg", "X-Vector-Name": urllib.parse.quote("foto\u202egpj.desktop")})
        self.assertEqual((status, item["name"], item["kind"], item["mime"]), (200, "fotogpj.desktop", "file", "application/octet-stream"))
        long = "字" * 100 + ".txt"
        self.assertGreater(len(long.encode()), 255)
        folder = os.path.join(self.folder, "Vector")
        self.config["vectorFolder"] = folder
        self.config["open"] = script(os.path.join(self.folder, "bin"), "xdg-open", FAKE_LOGGER.replace("{name}", "xdg-open"))
        for copy in range(2):
            status, item = self.phone.send("/v1/vector", b"ok", {"Content-Type": "text/plain", "X-Vector-Name": urllib.parse.quote(long)})
            self.assertEqual((status, item["kind"]), (200, "text"))
            self.assertTrue(item["name"].endswith(".txt") and len(item["name"].encode()) <= deck.NAME_BYTES)
            kept = deck.vector_command(self.config, "save", None)
            self.assertTrue(os.path.isfile(kept["path"]), kept)
        self.assertTrue(kept["path"].endswith(" (2).txt"))
        # Open hands the program only what is a picture, a video, a PDF or a text, by its bytes and its name.
        self.phone.send("/v1/vector", b"#!/bin/sh\n", {"Content-Type": "text/plain", "X-Vector-Name": "run.sh"})
        self.assertEqual(deck.vector_command(self.config, "open", None)["path"], os.path.join(folder, "run.sh"))
        for _ in range(50):
            if "xdg-open " + folder in self.logged():
                break
            time.sleep(0.05)
        self.assertIn("xdg-open " + folder, self.logged())
        for name, mime, path in (("a.png", "image/png", "a.png"), ("a.svg", "image/svg+xml", "a.svg"), ("a.html", "text/plain", "a.html"),
                                 ("notes", "text/plain", "notes"), ("a.pdf", "application/pdf", "a.pdf"), ("a.zip", "application/zip", "a.zip")):
            self.assertEqual(deck.openable({"mime": mime}, path), name in ("a.png", "notes", "a.pdf"), name)

    def test_one_thing_at_a_time_and_room_left(self):
        self.pair()
        device = self.deck.control({"op": "devices"})["devices"][0]["id"]
        self.deck.uploading.add(device)
        self.assertEqual(self.phone.send("/v1/vector", b"x", {"Content-Type": "text/plain"}), (409, {"error": "busy"}))
        self.deck.uploading.clear()
        deck.VECTOR_SPARE = shutil.disk_usage(self.folder).total
        self.assertEqual(self.phone.send("/v1/vector", b"x", {"Content-Type": "text/plain"}), (507, {"error": "full"}))
        deck.VECTOR_SPARE = 0
        self.assertEqual(self.phone.send("/v1/vector", b"x", {"Content-Type": "text/plain"})[0], 200)
        self.assertEqual(self.deck.uploading, set())

    def test_a_notifications_body_as_written(self):
        self.deck.session.notify("A <b>title</b>", "Forget <img src=x> & go")
        self.assertIn("notify-send -a NIHIL -- A <b>title</b> Forget &lt;img src=x&gt; &amp; go", self.logged())

    def test_a_text_like_an_option_from_the_command_line(self):
        config = os.path.join(self.folder, "config.json")
        with open(config, "w") as file:
            json.dump(self.config, file)
        done = subprocess.run([sys.executable, os.path.join(HERE, "deck.py"), "--config", config, "vector", "text", "-"],
                              input=b"-v --force", capture_output=True, timeout=30, check=False)
        result = json.loads(done.stdout)
        self.assertEqual((done.returncode, result["kind"], result["preview"]), (0, "text", "-v --force"))

    def test_forgetting_from_here(self):
        paired = self.pair()
        self.assertEqual(self.deck.control({"op": "forget", "id": "nope"}), {"ok": False})
        self.assertEqual(self.deck.control({"op": "forget", "id": paired["device"]}), {"ok": True})
        self.assertEqual(self.phone.request("GET", "/v1/apps")[0], 401)


class ConnectionsTest(Base):

    def setUp(self):
        super().setUp()
        self.old = deck.CONNECTIONS
        deck.CONNECTIONS = 2
        self.addCleanup(setattr, deck, "CONNECTIONS", self.old)
        self.server = deck.make_server(self.config, os.path.join(self.folder, "state"), host="127.0.0.1")
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.addCleanup(self.server.server_close)
        self.addCleanup(self.server.shutdown)
        self.phone = Phone(self.server.deck.port, self.server.deck.pin)

    def test_one_too_many_is_closed_and_the_rest_go_on(self):
        idle = [socket.create_connection(("127.0.0.1", self.server.deck.port)) for _ in range(2)]
        time.sleep(0.3)
        extra = socket.create_connection(("127.0.0.1", self.server.deck.port))
        extra.settimeout(3)
        self.assertEqual(extra.recv(1), b"")
        extra.close()
        for connection in idle:
            connection.close()
        for _ in range(50):
            try:
                if self.phone.request("GET", "/v1/hello")[0] == 200:
                    break
            except (OSError, ssl.SSLError):
                time.sleep(0.1)
        else:
            self.fail("the deck did not answer once the connections were closed")


class ThrottleTest(unittest.TestCase):
    def test_addresses_that_went_are_swept(self):
        old = deck.FAIL_KEPT
        deck.FAIL_KEPT = 3
        self.addCleanup(setattr, deck, "FAIL_KEPT", old)
        throttle = deck.Throttle()
        throttle.failures = {f"2001:db8::{i}": [time.time() - 2 * deck.FAIL_WINDOW] for i in range(10)}
        throttle.fail("2001:db8::ff")
        self.assertEqual(list(throttle.failures), ["2001:db8::ff"])
        for _ in range(deck.FAIL_LIMIT):
            throttle.fail("192.0.2.9")
        self.assertTrue(throttle.blocked("192.0.2.9"))
        self.assertFalse(throttle.blocked("2001:db8::ff"))


PNG = deck.PNG_MAGIC + b"an icon"


def ico(*entries):
    head = struct.pack("<HHH", 0, 1, len(entries))
    offset = 6 + 16 * len(entries)
    table, body = b"", b""
    for size, data in entries:
        table += struct.pack("<BBBBHHII", size % 256, size % 256, 0, 0, 1, 32, len(data), offset + len(body))
        body += data
    return head + table + body


class Site:

    def __init__(self, pages):
        site = self
        self.pages = pages
        self.asked = []

        class Pages(http.server.BaseHTTPRequestHandler):
            def do_GET(self):
                site.asked.append(self.path)
                status, kind, body = site.pages.get(self.path, (404, "text/plain", b"no"))
                self.send_response(status)
                self.send_header("Content-Type", kind)
                self.send_header("Content-Length", str(len(body)))
                self.end_headers()
                self.wfile.write(body)

            def log_message(self, *args):
                pass

        self.server = http.server.ThreadingHTTPServer(("127.0.0.1", 0), Pages)
        threading.Thread(target=self.server.serve_forever, daemon=True).start()
        self.url = "http://127.0.0.1:%d" % self.server.server_address[1]

    def stop(self):
        self.server.shutdown()
        self.server.server_close()


class FaviconTest(unittest.TestCase):
    def setUp(self):
        self.cache = tempfile.mkdtemp(prefix="deck-icons-")
        self.addCleanup(shutil.rmtree, self.cache, True)
        deck.PUBLIC_ONLY = False
        self.addCleanup(setattr, deck, "PUBLIC_ONLY", True)

    def site(self, pages):
        site = Site(pages)
        self.addCleanup(site.stop)
        return site

    def test_the_best_icon_the_home_page_names(self):
        page = (b'<html><head><link rel="icon" href="/small.png" sizes="16x16">'
                b'<link rel="apple-touch-icon" href="/touch.png"></head><body>'
                b'<link rel="icon" href="/late.png" sizes="512x512"></body></html>')
        site = self.site({"/": (200, "text/html", page), "/small.png": (200, "image/png", PNG + b"16"),
                          "/touch.png": (200, "image/png", PNG + b"180"), "/late.png": (200, "image/png", PNG + b"late")})
        self.assertEqual(deck.favicon(site.url + "/some/page?q=1", "rsvg-convert", self.cache), (PNG + b"180", "image/png"))
        asked = len(site.asked)
        self.assertEqual(deck.favicon(site.url + "/other", "rsvg-convert", self.cache), (PNG + b"180", "image/png"))
        self.assertEqual(len(site.asked), asked)

    def test_the_png_inside_the_ico_when_the_page_names_none(self):
        site = self.site({"/": (200, "text/html", b"<html><head></head></html>"),
                          "/favicon.ico": (200, "image/x-icon", ico((16, b"BM bitmap"), (32, PNG + b"32"), (24, PNG + b"24")))})
        self.assertEqual(deck.favicon(site.url, "rsvg-convert", self.cache), (PNG + b"32", "image/png"))

    def test_none_and_it_is_remembered(self):
        site = self.site({"/favicon.ico": (200, "image/x-icon", ico((16, b"BM only bitmaps")))})
        self.assertIsNone(deck.favicon(site.url + "/", "rsvg-convert", self.cache))
        asked = len(site.asked)
        self.assertIsNone(deck.favicon(site.url + "/", "rsvg-convert", self.cache))
        self.assertEqual(len(site.asked), asked)

    def test_jpeg_and_webp_as_they_come_and_nothing_else(self):
        self.assertEqual(deck.as_image(b"\xff\xd8\xffjpeg", "x"), (b"\xff\xd8\xffjpeg", "image/jpeg"))
        self.assertEqual(deck.as_image(b"RIFF\x00\x00\x00\x00WEBPVP8 ", "x")[1], "image/webp")
        self.assertIsNone(deck.as_image(b"<html>not an icon</html>", "x"))

    def test_a_week_and_so_many_at_most(self):
        old = deck.FAVICONS_KEPT
        deck.FAVICONS_KEPT = 3
        self.addCleanup(setattr, deck, "FAVICONS_KEPT", old)
        for i in range(5):
            path = os.path.join(self.cache, f"site{i}")
            open(path, "wb").close()
            os.utime(path, (time.time() - 60 * (i + 1),) * 2)
        stale = os.path.join(self.cache, "stale")
        open(stale, "wb").close()
        os.utime(stale, (time.time() - 8 * 86400,) * 2)
        site = self.site({"/favicon.ico": (200, "image/x-icon", ico((16, PNG + b"16")))})
        self.assertEqual(deck.favicon(site.url, "rsvg-convert", self.cache), (PNG + b"16", "image/png"))
        self.assertEqual(sorted(os.listdir(self.cache))[1:], ["site0", "site1"])
        self.assertEqual(len(os.listdir(self.cache)), 3)

    def test_where_it_connected_not_what_the_name_said(self):
        # A name that answers public when it's looked up and this computer when it's connected to.
        site = self.site({"/": (200, "text/html", b"")})
        deck.PUBLIC_ONLY = True
        self.addCleanup(setattr, deck, "public", deck.public)
        deck.public = lambda host: True
        with self.assertRaises(OSError):
            deck.fetch(site.url + "/", 100)
        self.assertEqual(site.asked, [])

    def test_only_public_addresses(self):
        deck.PUBLIC_ONLY = True
        for host in ("127.0.0.1", "localhost", "10.0.0.7", "192.168.1.1", "169.254.169.254", "::1"):
            self.assertFalse(deck.public(host), host)
        site = self.site({"/": (200, "text/html", b"")})
        with self.assertRaises(ValueError):
            deck.fetch(site.url + "/", 100)
        redirect = deck.PublicRedirects()
        with self.assertRaises(deck.urllib.error.URLError):
            redirect.redirect_request(None, None, 302, "Found", {}, "http://192.168.1.1/admin")


class TrackpadTest(unittest.TestCase):
    def test_the_kernels_numbers(self):
        self.assertEqual((deck.UI_DEV_CREATE, deck.UI_DEV_DESTROY, deck.UI_DEV_SETUP, deck.UI_ABS_SETUP),
                         (0x5501, 0x5502, 0x405C5503, 0x401C5504))
        self.assertEqual((deck.UI_SET_EVBIT, deck.UI_SET_KEYBIT, deck.UI_SET_ABSBIT, deck.UI_SET_PROPBIT),
                         (0x40045564, 0x40045565, 0x40045567, 0x4004556E))
        self.assertEqual(len(struct.pack("@llHHi", 0, 0, 0, 0, 0)), 24 if struct.calcsize("l") == 8 else 16)

    def test_fingers_in_slots(self):
        fingers = deck.Fingers()
        A, K, S, ID = deck.EV_ABS, deck.EV_KEY, deck.ABS_MT_SLOT, deck.ABS_MT_TRACKING_ID
        X, Y, tools, sync = deck.ABS_MT_POSITION_X, deck.ABS_MT_POSITION_Y, deck.FINGER_TOOLS, (deck.EV_SYN, deck.SYN_REPORT, 0)
        self.assertEqual(fingers.frame([(3, 100, 200)]),
                         [(A, S, 0), (A, ID, 0), (A, X, 100), (A, Y, 200), (K, tools[0], 1), (K, deck.BTN_TOUCH, 1),
                          (A, deck.ABS_X, 100), (A, deck.ABS_Y, 200), sync])
        self.assertEqual(fingers.frame([(3, 100, 200), (5, 300, 400)]),
                         [(A, S, 1), (A, ID, 1), (A, X, 300), (A, Y, 400), (K, tools[0], 0), (K, tools[1], 1), sync])
        self.assertEqual(fingers.frame([(3, 110, 200)]),
                         [(A, ID, -1), (A, S, 0), (A, X, 110), (K, tools[1], 0), (K, tools[0], 1), (A, deck.ABS_X, 110), sync])
        self.assertEqual(fingers.release(), [(A, ID, -1), (K, tools[0], 0), (K, deck.BTN_TOUCH, 0), sync])
        self.assertEqual(fingers.release(), [])
        many = fingers.frame([(i, i, i) for i in range(6)])
        self.assertEqual(sum(1 for event in many if event[:2] == (A, ID)), 5)
        self.assertIn((K, tools[4], 1), many)

    def test_the_phones_pace(self):
        pace = deck.Pace(delay=0.025)
        times = [(0.000, 10.010), (0.008, 10.018), (0.016, 10.060), (0.024, 10.060), (0.032, 10.061)]
        due = [pace.due(phone, arrived) for phone, arrived in times]
        self.assertAlmostEqual(due[0], 10.035)
        self.assertAlmostEqual(due[1], 10.043)
        self.assertAlmostEqual(due[2], 10.060)          # late: as soon as it came
        for before, after in zip(due, due[1:]):
            self.assertGreaterEqual(after - before, 0.9 * 0.008 - 1e-9)
        self.assertLess(due[4], 10.061 + 0.025)
        clock = deck.Pace()
        self.assertAlmostEqual(clock.seconds(2 ** 32 - 6) + 0.011, clock.seconds(5))
        # A phone whose frames come with its clock running ahead: never played later than LATEST.
        ahead = deck.Pace(delay=0.025)
        dues = [ahead.due(0.099 * i, 10 + 0.001 * i) for i in range(2000)]
        self.assertTrue(all(due <= 10 + 0.001 * i + deck.LATEST + 1e-9 for i, due in enumerate(dues)))

    def test_a_stream_ends_with_its_writer(self):
        written, closed = [], []

        class Pad:
            width = height = 1000

            def write(self, events):
                if closed:
                    raise AssertionError("written after closing")
                written.append(events)

        frames = b"".join(struct.pack("!BIB", 1, 1000 + i, 1) + struct.pack("!BHH", 0, i % 1000, 5) for i in range(5000))
        began = time.monotonic()
        deck.stream(io.BytesIO(frames), io.BytesIO(), Pad())
        closed.append(True)
        self.assertLess(time.monotonic() - began, 5)
        # At most QUEUED waited, and the fingers were lifted at the end.
        self.assertLessEqual(len(written), deck.QUEUED + 2)
        self.assertIn((deck.EV_KEY, deck.BTN_TOUCH, 0), written[-1])

    def test_a_closed_trackpad_is_not_written(self):
        pad = deck.Uinput.__new__(deck.Uinput)
        read, pad.fd = os.pipe()
        pad.close()
        pad.close()
        self.assertEqual(pad.fd, -1)
        with self.assertRaises(OSError):
            pad.write([(deck.EV_SYN, deck.SYN_REPORT, 0)])
        os.close(read)

    def test_ipv6_devices_count_by_their_64(self):
        self.assertEqual(deck.origin("2001:db8:1:2:aaaa::1"), deck.origin("2001:db8:1:2:bbbb::9"))
        self.assertNotEqual(deck.origin("2001:db8:1:2::1"), deck.origin("2001:db8:1:3::1"))
        self.assertEqual(deck.origin("::ffff:192.168.1.5"), "192.168.1.5")
        self.assertEqual(deck.origin("192.168.1.5"), "192.168.1.5")
        self.assertEqual(deck.origin("fe80::1%wlan0"), deck.origin("fe80::2"))


class ControlTest(Base):
    def test_the_socket(self):
        state = os.path.join(self.folder, "state")
        server = deck.make_server(self.config, state, host="127.0.0.1")
        path = os.path.join(self.folder, "control.sock")
        control = deck.ControlServer(path, server.deck)
        threading.Thread(target=control.serve_forever, daemon=True).start()
        self.addCleanup(server.server_close)
        self.addCleanup(control.server_close)
        self.addCleanup(control.shutdown)
        self.assertEqual(os.stat(path).st_mode & 0o777, 0o600)
        reply = deck.ask({"op": "pair"}, path)
        self.assertTrue(reply["uri"].startswith("nihil-deck://pair?"))
        self.assertTrue(deck.ask({"op": "status"}, path)["pairing"])
        self.assertEqual(deck.ask({"op": "cancel"}, path), {"ok": True})
        self.assertFalse(deck.ask({"op": "status"}, path)["pairing"])
        self.assertEqual(deck.ask({"op": "devices"}, path), {"devices": [], "pairing": False, "invites": [], "asking": []})
        self.assertEqual(deck.ask({"op": "nonsense"}, path), {"error": "unknown"})
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as raw:
            raw.connect(path)
            raw.sendall(b"not json\n")
            self.assertEqual(json.loads(raw.recv(4096)), {"error": "unknown"})


class BluetoothTest(Base):
    PIN = "8-eMVPli0fpzjeUBe-b_bmRtjDMwo1bNYXaVTyPSbVc"

    def test_the_uuid_comes_from_the_pin(self):
        raw = bytearray(hashlib.sha256(b"nihil-deck ble\0" + self.PIN.encode()).digest()[:16])
        made = deck.ble_uuid(self.PIN)
        self.assertEqual(made, deck.ble_uuid(self.PIN))
        self.assertNotEqual(made, deck.ble_uuid(self.PIN[:-1] + "d"))
        self.assertRegex(made, r"^[0-9a-f]{8}-[0-9a-f]{4}-8[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$")
        # Only the version's and the variant's bits are the UUID's own; the rest is the hash.
        got = bytes.fromhex(made.replace("-", ""))
        self.assertEqual(got[:6] + got[7:8] + got[9:], bytes(raw[:6] + raw[7:8] + raw[9:]))
        self.assertEqual(got[6] & 0x0F, raw[6] & 0x0F)
        self.assertEqual(got[8] & 0x3F, raw[8] & 0x3F)

    def test_the_qr_says_where_over_bluetooth(self):
        plain = deck.pair_uri("nihil", 64445, ["192.168.1.20"], "7JTX39F4", self.PIN)
        self.assertNotIn("ble=", plain)
        uri = deck.pair_uri("nihil", 64445, ["192.168.1.20"], "7JTX39F4", self.PIN, {"uuid": deck.ble_uuid(self.PIN), "psm": 129})
        query = urllib.parse.parse_qs(urllib.parse.urlsplit(uri).query)
        self.assertEqual(query["ble"], [deck.ble_uuid(self.PIN)])
        self.assertEqual(query["psm"], ["129"])
        self.assertEqual(query["pin"], [self.PIN])

    def test_the_address_as_linux_has_it(self):
        L2 = deck.SockaddrL2
        self.assertEqual(deck.ctypes.sizeof(L2), 14)
        self.assertEqual([L2.family.offset, L2.psm.offset, L2.bdaddr.offset, L2.cid.offset, L2.bdaddr_type.offset], [0, 2, 4, 10, 12])
        self.assertEqual(deck.bluetooth_order(0x81).to_bytes(2, sys.byteorder), b"\x81\x00")

    def test_a_channel_is_served_as_a_connection_is(self):
        state = os.path.join(self.folder, "state")
        server = deck.make_server(self.config, state, host="127.0.0.1")
        server.deck.ble = {"uuid": deck.ble_uuid(server.deck.pin), "psm": 129}
        threading.Thread(target=server.serve_forever, daemon=True).start()
        self.addCleanup(server.server_close)
        self.addCleanup(server.shutdown)
        # A stream like an LE channel's, from a TCP socket: what comes in goes where a connection does.
        channel = socket.socket()
        channel.bind(("127.0.0.1", 0))
        channel.listen(4)
        self.addCleanup(channel.close)
        threading.Thread(target=deck.ble_serve, args=(server, channel), daemon=True).start()
        phone = Phone(channel.getsockname()[1], server.deck.pin)
        self.assertEqual(phone.request("GET", "/v1/hello"), (200, {"deck": deck.API}))
        code = server.deck.control({"op": "pair"})
        self.assertIn("ble=" + server.deck.ble["uuid"], code["uri"])
        self.assertEqual(code["ble"], server.deck.ble)
        answer = {}
        asking = threading.Thread(target=lambda: answer.update(reply=phone.request("POST", "/v1/pair", {"code": code["code"], "device": "Phone"})))
        asking.start()
        for _ in range(100):
            waiting = server.deck.pairing.waiting()
            if waiting:
                server.deck.pairing.answer(waiting[0]["id"], True)
                break
            time.sleep(0.05)
        asking.join(10)
        status, paired = answer["reply"]
        self.assertEqual(status, 200)
        self.assertEqual(paired["ble"], server.deck.ble)
        phone.token = paired["token"]
        status, state_now = phone.request("GET", "/v1/state")
        self.assertEqual(status, 200)
        self.assertEqual(state_now["ble"], server.deck.ble)
        # Devices says the phone came over Bluetooth, until it comes over the network again.
        listed = lambda: [device["bluetooth"] for device in server.deck.control({"op": "devices"})["devices"]]
        self.assertEqual(listed(), [True])
        self.assertEqual(Phone(server.deck.port, server.deck.pin, phone.token).request("GET", "/v1/state")[0], 200)
        self.assertEqual(listed(), [False])


DBUS_DAEMON = shutil.which("dbus-daemon")


class FakeBluez:
    """BlueZ as the deck meets it on D-Bus: an adapter with LE advertising, which asks an
    advertisement for its properties before it answers RegisterAdvertisement, and can drop it."""

    def __init__(self, address):
        self.address = address
        self.adverts = []        # (registrant, path, properties), one per registration
        self.stop = False

    def serve(self):
        with deck.jeepney.io.blocking.open_dbus_connection(bus=self.address) as connection:
            self.connection = connection
            connection.send_and_get_reply(deck.jeepney.message_bus.RequestName("org.bluez"))
            while not self.stop:
                try:
                    message = connection.receive(timeout=0.2)
                except TimeoutError:
                    continue
                except OSError:
                    return
                fields = message.header.fields
                if message.header.message_type != deck.jeepney.MessageType.method_call:
                    continue
                member = fields.get(deck.jeepney.HeaderFields.member)
                if member == "GetManagedObjects":
                    objects = {"/org/bluez/hci0": {"org.bluez.Adapter1": {"Powered": ("b", True)},
                                                   "org.bluez.LEAdvertisingManager1": {"ActiveInstances": ("y", len(self.adverts))}}}
                    connection.send(deck.jeepney.new_method_return(message, "a{oa{sa{sv}}}", (objects,)))
                elif member == "RegisterAdvertisement":
                    sender = fields.get(deck.jeepney.HeaderFields.sender)
                    path = message.body[0]
                    ask = deck.jeepney.new_method_call(deck.jeepney.DBusAddress(path, bus_name=sender, interface="org.freedesktop.DBus.Properties"),
                                                      "GetAll", "s", ("org.bluez.LEAdvertisement1",))
                    reply = connection.send_and_get_reply(ask, timeout=5)
                    self.adverts.append((sender, path, reply.body[0]))
                    connection.send(deck.jeepney.new_method_return(message))

    def release(self):
        sender, path, _ = self.adverts[-1]
        self.connection.send(deck.jeepney.new_method_call(deck.jeepney.DBusAddress(path, bus_name=sender, interface="org.bluez.LEAdvertisement1"), "Release"))


@unittest.skipIf(deck.jeepney is None or DBUS_DAEMON is None, "needs jeepney and dbus-daemon")
class AdvertTest(unittest.TestCase):
    def setUp(self):
        self.addCleanup(setattr, deck, "BLE_RETRY", deck.BLE_RETRY)
        deck.BLE_RETRY = 0.2
        self.bus = subprocess.Popen([DBUS_DAEMON, "--session", "--nofork", "--print-address"], stdout=subprocess.PIPE, text=True)
        self.addCleanup(self.bus.stdout.close)
        self.addCleanup(self.bus.wait)
        self.addCleanup(self.bus.kill)
        self.address = self.bus.stdout.readline().strip()
        self.bluez = FakeBluez(self.address)
        threading.Thread(target=self.bluez.serve, daemon=True).start()
        self.addCleanup(setattr, self.bluez, "stop", True)
        time.sleep(0.3)

    def until(self, test, seconds=5):
        end = time.monotonic() + seconds
        while time.monotonic() < end:
            if test():
                return True
            time.sleep(0.05)
        return False

    def test_announced_with_the_uuid_alone_and_again_when_dropped(self):
        advert = deck.Advert(deck.ble_uuid(BluetoothTest.PIN), bus=self.address)
        threading.Thread(target=advert.run, daemon=True).start()
        self.assertTrue(self.until(lambda: len(self.bluez.adverts) == 1))
        _, path, properties = self.bluez.adverts[0]
        self.assertEqual(path, deck.Advert.PATH)
        self.assertEqual(properties["Type"], ("s", "peripheral"))
        self.assertEqual(properties["ServiceUUIDs"], ("as", [deck.ble_uuid(BluetoothTest.PIN)]))
        self.assertNotIn("LocalName", properties)
        self.assertTrue(self.until(lambda: advert.registered))
        self.bluez.release()
        self.assertTrue(self.until(lambda: len(self.bluez.adverts) == 2))


if __name__ == "__main__":
    unittest.main()
