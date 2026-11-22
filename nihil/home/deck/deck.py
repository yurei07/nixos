#!/usr/bin/env python3
# deck.py by poligle

import argparse
import base64
import codecs
import collections
import ctypes
import errno
import fcntl
import functools
import hashlib
import hmac
import html.parser
import http.client
import http.server
import ipaddress
import json
import math
import mimetypes
import os
import re
import secrets
import shutil
import signal
import socket
import socketserver
import ssl
import struct
import subprocess
import sys
import tempfile
import threading
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request
import uuid

# BlueZ is reached over D-Bus to announce the computer over Bluetooth; without jeepney, the deck
# still runs, on the network alone (the tests need neither).
try:
    import jeepney
    import jeepney.io.blocking
except ImportError:
    jeepney = None

API = 1
PORT = 64445                    # NIHIL on a phone's keypad
BLE_PSM = 0x81                  # the LE channel, from the range left to programs (0x80 to 0xFF)
BLE_RETRY = 30                  # seconds between tries to announce, while Bluetooth is off or gone
CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
CODE_LENGTH = 8
CODE_LIFETIME = 300             # seconds a code pairs
CODES_OPEN = 4                  # codes open at once: the QR's, a watch's, a terminal's
CODE_TRIES = 30                 # wrong codes a minute, from anyone, before every try waits
TOKEN_DAYS = 90                 # a device not seen in these many days is forgotten
MAX_BODY = 4096
TASKS_MAX = 2 * 1024 * 1024     # a phone's whole kanban: 1000 long cards and 10,000 removals
VECTOR_MAX = 100 * 1024 * 1024
VECTOR_TEXT = 256 * 1024
VECTOR_WAIT = 50
VECTOR_LIVE = 120
VECTOR_SPARE = 1024 ** 3        # free space an upload has to leave on the disk
NAME_BYTES = 240                # a file's name: Linux takes 255, and « (2)» needs room
SNIFF = 4096                    # the bytes a file is told by
CHUNK = 64 * 1024
COVER_MAX = 4 * 1024 * 1024
CARDS_MAX = 1000
AHEAD = 86_400_000          # how far ahead of this clock a stamp may be, in ms: a day
FAIL_WINDOW = 60
FAIL_LIMIT = 10
FAIL_KEPT = 1024
CONNECTIONS = 32
PER_ADDRESS = 16            # connections at once from one address: half, so one can't take them all
QUEUED = 256                # trackpad frames waiting to be played
LATEST = 0.5                # the furthest ahead a frame is played, in seconds
REQUEST_SECONDS = 10        # to send a request, however slowly, before it's cut
PAIR_WAIT = 8               # for the computer to allow a pairing: the launcher waits 9
SEEN_EVERY = 60
ICON_SIZE = 128
APPS_FOR = 20
APP_ID = re.compile(r"[A-Za-z0-9._+-]{1,160}")
MIME = re.compile(r"[a-z0-9][a-z0-9!#$&^_.+-]{0,63}/[a-z0-9][a-z0-9!#$&^_.+-]{0,126}")
EXTENSIONS = {"text/plain": ".txt", "image/png": ".png", "image/jpeg": ".jpg", "image/gif": ".gif",
              "image/webp": ".webp", "video/mp4": ".mp4", "video/webm": ".webm", "video/quicktime": ".mov",
              "audio/mpeg": ".mp3", "audio/ogg": ".ogg", "application/pdf": ".pdf"}
COPIED = ("x-special/gnome-copied-files", "text/uri-list")
SECRET = "x-kde-passwordManagerHint"
VIRTUAL = re.compile(r"(docker|br-|virbr|veth|vnet|lxcbr|lxdbr|podman|cni|flannel)")
ACTIONS = {
    "media": ("toggle", "next", "previous"),
    "volume": ("up", "down", "mute"),
    "caffeine": ("on", "off", "toggle"),
    "night": ("on", "off", "toggle"),
}


def now():
    return time.time()


def origin(address):
    """Who an address is, to count its failures and connections: with IPv6, a device takes any
    address of its /64, so the /64 is the one counted."""
    try:
        ip = ipaddress.ip_address(address.split("%")[0])
    except ValueError:
        return address
    if ip.version == 6 and ip.ipv4_mapped:
        return str(ip.ipv4_mapped)
    if ip.version == 6:
        return str(ipaddress.ip_network(f"{ip}/64", strict=False))
    return str(ip)


def b64url(data):
    return base64.urlsafe_b64encode(data).rstrip(b"=").decode()


def digest(token):
    return hashlib.sha256(token.encode()).hexdigest()


def home_dir(variable, fallback):
    return os.environ.get(variable) or os.path.join(os.path.expanduser("~"), fallback)


def state_dir():
    return os.path.join(home_dir("XDG_STATE_HOME", ".local/state"), "nihil", "deck")


def cache_dir():
    return os.path.join(home_dir("XDG_CACHE_HOME", ".cache"), "nihil", "deck")


def control_path():
    runtime = os.environ.get("XDG_RUNTIME_DIR") or state_dir()
    return os.path.join(runtime, "nihil-deck.sock")


def write_private(path, text):
    folder = os.path.dirname(path)
    os.makedirs(folder, mode=0o700, exist_ok=True)
    fd, temporary = tempfile.mkstemp(dir=folder, prefix=".deck-")
    try:
        with os.fdopen(fd, "w") as file:
            file.write(text)
        os.chmod(temporary, 0o600)
        os.replace(temporary, path)
    except BaseException:
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        raise


def ensure_certificate(folder, openssl):
    cert = os.path.join(folder, "cert.pem")
    key = os.path.join(folder, "key.pem")
    if os.path.isfile(cert) and os.path.isfile(key):
        return cert, key
    os.makedirs(folder, mode=0o700, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=folder, prefix=".cert-") as work:
        new_cert = os.path.join(work, "cert.pem")
        new_key = os.path.join(work, "key.pem")
        old = os.umask(0o077)
        try:
            subprocess.run([openssl, "req", "-x509", "-newkey", "ec", "-pkeyopt", "ec_paramgen_curve:P-256",
                            "-nodes", "-days", "3650", "-subj", "/CN=nihil-deck",
                            "-keyout", new_key, "-out", new_cert],
                           check=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, timeout=60)
        finally:
            os.umask(old)
        os.chmod(new_key, 0o600)
        os.replace(new_key, key)
        os.replace(new_cert, cert)
    return cert, key


def _tlv(data, at):
    tag = data[at]
    length = data[at + 1]
    at += 2
    if length & 0x80:
        count = length & 0x7F
        length = int.from_bytes(data[at:at + count], "big")
        at += count
    return tag, at, at + length


def public_key_info(der):
    _, start, _ = _tlv(der, 0)
    _, tbs, tbs_end = _tlv(der, start)
    fields = []
    at = tbs
    while at < tbs_end:
        tag, _, end = _tlv(der, at)
        fields.append((tag, at, end))
        at = end
    if fields and fields[0][0] == 0xA0:
        fields = fields[1:]
    if len(fields) < 6 or fields[5][0] != 0x30:
        raise ValueError("not a certificate this can read")
    _, begin, end = fields[5]
    return der[begin:end]


def pin_of(cert_path):
    with open(cert_path) as file:
        der = ssl.PEM_cert_to_DER_cert(file.read())
    return b64url(hashlib.sha256(public_key_info(der)).digest())


class Devices:

    def __init__(self, path):
        self.path = path
        self.lock = threading.Lock()
        self.items = []
        self.saved = 0
        self.bluetooth = set()      # the devices whose last request came over Bluetooth, while the deck runs
        try:
            with open(path) as file:
                found = json.load(file)
            self.items = [item for item in found.get("devices", [])
                          if isinstance(item, dict) and isinstance(item.get("token"), str) and isinstance(item.get("id"), str)]
        except (FileNotFoundError, ValueError, AttributeError):
            self.items = []
        for item in self.items:
            if not isinstance(item.get("seen"), int) or isinstance(item.get("seen"), bool):
                item["seen"] = int(now())

    def _save(self):
        write_private(self.path, json.dumps({"devices": self.items}, indent=2) + "\n")
        self.saved = now()

    # A device not seen in TOKEN_DAYS is forgotten, as from Devices: one lost in a drawer doesn't
    # keep this computer for good.
    def _sweep(self):
        kept = [item for item in self.items if now() - item["seen"] <= TOKEN_DAYS * 86400]
        if len(kept) != len(self.items):
            self.items = kept
            self._save()

    def add(self, name):
        token = secrets.token_urlsafe(32)
        with self.lock:
            ids = {item["id"] for item in self.items}
            device = secrets.token_hex(4)
            while device in ids:
                device = secrets.token_hex(4)
            moment = int(now())
            self.items.append({"id": device, "name": name, "token": digest(token), "paired": moment, "seen": moment})
            self._save()
        return device, token

    def find(self, token):
        if not token:
            return None
        wanted = digest(token)
        found = None
        with self.lock:
            self._sweep()
            for item in self.items:
                if hmac.compare_digest(item["token"], wanted):
                    found = item
        return found

    def touch(self, device, bluetooth=False):
        with self.lock:
            device["seen"] = int(now())
            if bluetooth:
                self.bluetooth.add(device["id"])
            else:
                self.bluetooth.discard(device["id"])
            if now() - self.saved >= SEEN_EVERY:
                self._save()

    def flush(self):
        with self.lock:
            if self.items or os.path.exists(self.path):
                self._save()

    def known(self, device):
        with self.lock:
            self._sweep()
            return any(item["id"] == device for item in self.items)

    def forget(self, device):
        with self.lock:
            kept = [item for item in self.items if device != "all" and item["id"] != device]
            if len(kept) == len(self.items):
                return False
            self.items = kept
            self._save()
        return True

    def listing(self):
        with self.lock:
            self._sweep()
            return [{**{key: item.get(key) for key in ("id", "name", "paired", "seen")},
                     "expires": item["seen"] + TOKEN_DAYS * 86400, "bluetooth": item["id"] in self.bluetooth}
                    for item in self.items]


class Pairing:

    def __init__(self):
        self.lock = threading.Lock()
        self.codes = {}             # each code open: (when it stops pairing, its invite); each pairs once
        self.wrong = collections.deque()    # when wrong codes came, from anyone
        self.asking = {}            # devices with the right code, waiting for the computer to allow them

    def _sweep(self):
        moment = now()
        for code, (expires, _) in list(self.codes.items()):
            if moment > expires:
                del self.codes[code]
        while self.wrong and self.wrong[0] <= moment - FAIL_WINDOW:
            self.wrong.popleft()

    # Several at once, each its own: the QR in Devices and a watch being installed don't undo
    # each other. Past CODES_OPEN, the oldest goes.
    def open(self):
        with self.lock:
            self._sweep()
            code = "".join(secrets.choice(CODE_ALPHABET) for _ in range(CODE_LENGTH))
            invite = secrets.token_hex(4)
            self.codes[code] = (now() + CODE_LIFETIME, invite)
            while len(self.codes) > CODES_OPEN:
                del self.codes[min(self.codes, key=lambda key: self.codes[key][0])]
            return code, self.codes[code][0], invite

    def close(self, invite=None):
        with self.lock:
            for code, (_, which) in list(self.codes.items()):
                if invite is None or which == invite:
                    del self.codes[code]

    def invites(self):
        with self.lock:
            self._sweep()
            return [invite for _, invite in self.codes.values()]

    @property
    def open_now(self):
        return bool(self.invites())

    # Wrong, run out or used, a code gets the same answer, so trying says nothing of when this
    # computer is pairing; and failing doesn't close it, so no one can spoil the code in the QR.
    # Past CODE_TRIES wrong ones a minute, from anyone, every try waits.
    def take(self, code):
        with self.lock:
            self._sweep()
            if len(self.wrong) >= CODE_TRIES:
                return "wait"
            given = str(code or "").strip().upper().encode()
            for known in list(self.codes):
                if hmac.compare_digest(given, known.encode()):
                    del self.codes[known]
                    return "ok"
            self.wrong.append(now())
            return "wrong"

    # The code alone doesn't pair: whoever saw the QR could have it. The computer is asked first.
    def ask(self, name):
        asking = {"id": secrets.token_hex(4), "name": name, "event": threading.Event(), "allowed": False}
        with self.lock:
            self.asking[asking["id"]] = asking
        return asking

    def answer(self, asked, allowed):
        with self.lock:
            asking = self.asking.get(asked)
        if asking is None:
            return False
        asking["allowed"] = bool(allowed)
        asking["event"].set()
        return True

    def done(self, asked):
        with self.lock:
            self.asking.pop(asked, None)

    def waiting(self):
        with self.lock:
            return [{"id": asking["id"], "name": asking["name"]} for asking in self.asking.values()]


class Throttle:

    def __init__(self):
        self.lock = threading.Lock()
        self.failures = {}

    def _recent(self, address):
        cutoff = now() - FAIL_WINDOW
        times = [moment for moment in self.failures.get(address, []) if moment > cutoff]
        if times:
            self.failures[address] = times
        else:
            self.failures.pop(address, None)
        return times

    def blocked(self, address):
        with self.lock:
            return len(self._recent(address)) >= FAIL_LIMIT

    def fail(self, address):
        with self.lock:
            self.failures.setdefault(address, []).append(now())
            self._recent(address)
            if len(self.failures) > FAIL_KEPT:
                for other in list(self.failures):
                    self._recent(other)


def valid_url(url):
    if not isinstance(url, str) or not 0 < len(url) <= 2048:
        return False
    if any(ord(char) < 0x21 or ord(char) == 0x7F for char in url):
        return False
    try:
        parts = urllib.parse.urlsplit(url)
    except ValueError:
        return False
    return parts.scheme in ("http", "https") and bool(parts.hostname)


def clean_name(name, fallback):
    # Not starting with -, which a command line would take for an option.
    text = "".join(char for char in str(name or "") if char.isprintable()).strip().lstrip("-").strip()
    return text[:40] or fallback


class Session:

    def __init__(self, config):
        self.config = config
        self.lock = threading.Lock()
        self.cached = None
        self.cached_at = 0

    def run(self, command, timeout=6):
        try:
            done = subprocess.run(command, stdin=subprocess.DEVNULL, capture_output=True, text=True,
                                  errors="replace", timeout=timeout)
        except (OSError, subprocess.SubprocessError):
            return None
        return done.stdout.strip() if done.returncode == 0 else None

    cover_cache = None

    def ipc(self, *arguments):
        return self.run([self.config["ipc"], *arguments])

    def apps(self, fresh=False):
        with self.lock:
            if not fresh and self.cached is not None and now() - self.cached_at < APPS_FOR:
                return self.cached
        text = self.ipc("apps", "list")
        if text is None:
            return None
        try:
            found = json.loads(text)
        except ValueError:
            return None
        listed = []
        for entry in found if isinstance(found, list) else []:
            if not isinstance(entry, dict):
                continue
            app, name = entry.get("id"), entry.get("name")
            if isinstance(app, str) and APP_ID.fullmatch(app) and isinstance(name, str) and name:
                icon = entry.get("icon") if isinstance(entry.get("icon"), str) else ""
                listed.append({"id": app, "name": name, "icon": icon})
        with self.lock:
            self.cached, self.cached_at = listed, now()
        return listed

    def app(self, app):
        if not isinstance(app, str) or not APP_ID.fullmatch(app):
            return None
        for fresh in (False, True):
            listed = self.apps(fresh)
            if listed is None:
                return None
            for entry in listed:
                if entry["id"] == app:
                    return entry
        return None

    def launch(self, app):
        if self.app(app) is None:
            return "unknown"
        answer = self.ipc("apps", "launch", app)
        return "ok" if answer == "ok" else "unknown" if answer == "unknown" else "shell"

    def open_url(self, url):
        if not valid_url(url):
            return "invalid"
        answer = self.ipc("apps", "url", url)
        return "ok" if answer == "ok" else "invalid" if answer == "invalid" else "shell"

    def media(self, action):
        return self.ipc("media", action) is not None

    def playing(self):
        text = self.ipc("media", "now")
        if not text:
            return None
        try:
            found = json.loads(text)
        except ValueError:
            return None
        if not isinstance(found, dict):
            return None
        art = str(found.pop("art", "") or "")
        found["cover"] = hashlib.sha256(art.encode()).hexdigest()[:16] if art else ""
        return found

    def cover(self, token):
        text = self.ipc("media", "now")
        try:
            art = str(json.loads(text or "null").get("art") or "")
        except (ValueError, AttributeError):
            return None
        if not art or hashlib.sha256(art.encode()).hexdigest()[:16] != token:
            return None
        with self.lock:
            if self.cover_cache and self.cover_cache[0] == art:
                return self.cover_cache[1]
        found = None
        try:
            if art.startswith("file://"):
                local = urllib.parse.unquote(urllib.parse.urlsplit(art).path)
                if os.path.getsize(local) <= COVER_MAX:
                    with open(local, "rb") as file:
                        found = as_image(file.read(), self.config.get("rsvg", "rsvg-convert"))
            elif valid_url(art):
                found = as_image(fetch(art, COVER_MAX)[1], self.config.get("rsvg", "rsvg-convert"))
        except (OSError, ValueError, urllib.error.URLError, http.client.HTTPException):
            found = None
        with self.lock:
            self.cover_cache = (art, found)
        return found

    def tasks(self, board=None):
        if board is None:
            text = self.ipc("tasks", "state")
        else:
            # A file of this user's rather than an argument: one can't pass 128 KiB, and anyone sees it in /proc.
            path = os.path.join(os.environ.get("XDG_RUNTIME_DIR") or state_dir(),
                                f"nihil-deck-tasks-{secrets.token_hex(8)}.json")
            try:
                write_private(path, json.dumps(board))
                text = self.ipc("tasks", "syncFile", path)
            except OSError:
                text = None
            finally:
                try:
                    os.unlink(path)
                except OSError:
                    pass
        try:
            found = json.loads(text or "")
        except ValueError:
            return None
        return found if isinstance(found, dict) else None

    def volume(self, action=None):
        if action is not None and self.run([self.config["volume"], action]) is None:
            return None
        text = self.run([self.config["wpctl"], "get-volume", "@DEFAULT_AUDIO_SINK@"])
        found = re.search(r"Volume:\s*([0-9.]+)", text or "")
        if not found:
            return None
        return {"level": round(float(found.group(1)) * 100), "muted": "[MUTED]" in text}

    def lock_screen(self):
        return self.ipc("session", "lock") is not None

    def toggles(self):
        try:
            found = json.loads(self.ipc("toggles", "state") or "")
        except ValueError:
            return {}
        if not isinstance(found, dict):
            return {}
        return {key: found[key] for key in ("caffeine", "night") if isinstance(found.get(key), bool)}

    def switch(self, kind, action):
        if self.ipc(kind, action) is None:
            return None
        return self.toggles().get(kind)

    def notify(self, title, body):
        # A body is markup, as the notification spec has it: what it says is shown as written.
        command = [self.config["notify"], "-a", "NIHIL", "--", title]
        if body:
            command.append(html.escape(body, quote=False))
        self.run(command)


def data_dirs():
    dirs = [home_dir("XDG_DATA_HOME", ".local/share")]
    dirs += [d for d in os.environ.get("XDG_DATA_DIRS", "").split(":") if d]
    user = os.environ.get("USER", "")
    dirs += [os.path.expanduser("~/.nix-profile/share"), f"/etc/profiles/per-user/{user}/share",
             "/run/current-system/sw/share", "/usr/local/share", "/usr/share"]
    seen, ordered = set(), []
    for d in dirs:
        if d not in seen:
            seen.add(d)
            ordered.append(d)
    return ordered


@functools.lru_cache(maxsize=64)
def theme_index(root):
    inherits, directories, sizes, kinds = [], [], {}, {}
    section = None
    try:
        with open(os.path.join(root, "index.theme"), encoding="utf-8", errors="replace") as file:
            for raw in file:
                line = raw.strip()
                if line.startswith("[") and line.endswith("]"):
                    section = line[1:-1]
                elif "=" in line:
                    key, value = (part.strip() for part in line.split("=", 1))
                    if section == "Icon Theme" and key == "Inherits":
                        inherits = [name.strip() for name in value.split(",") if name.strip()]
                    elif section == "Icon Theme" and key in ("Directories", "ScaledDirectories"):
                        directories += [name.strip() for name in value.split(",") if name.strip()]
                    elif section and key == "Size" and value.isdigit():
                        sizes[section] = int(value)
                    elif section and key == "Type":
                        kinds[section] = value
    except OSError:
        return (), ()
    unique = list(dict.fromkeys(directories))
    def order(directory):
        size = sizes.get(directory, 0)
        scalable = kinds.get(directory) == "Scalable" or "scalable" in directory
        return (0 if scalable else 1, size < ICON_SIZE, abs(size - ICON_SIZE))
    unique.sort(key=order)
    return tuple(inherits), tuple(unique)


def icon_file(name, theme, dirs=None):
    if not name:
        return None
    if os.path.isabs(name):
        return name if os.path.isfile(name) and name.endswith((".png", ".svg")) else None
    if "/" in name or name.startswith("."):
        return None
    dirs = dirs or data_dirs()
    queue, visited = [theme, "hicolor"] if theme else ["hicolor"], set()
    while queue:
        current = queue.pop(0)
        if not current or current in visited:
            continue
        visited.add(current)
        for base in dirs:
            root = os.path.join(base, "icons", current)
            if not os.path.isdir(root):
                continue
            inherits, directories = theme_index(root)
            for directory in directories:
                for extension in (".svg", ".png"):
                    path = os.path.join(root, directory, name + extension)
                    if os.path.isfile(path):
                        return path
            queue[0:0] = [parent for parent in inherits if parent not in visited and parent != "hicolor"]
    for base in dirs:
        for extension in (".png", ".svg"):
            path = os.path.join(base, "pixmaps", name + extension)
            if os.path.isfile(path):
                return path
    return None


def icon_png(path, rsvg, cache):
    if path.endswith(".png"):
        return path
    stamp = hashlib.sha256(f"{os.path.realpath(path)}:{os.path.getmtime(path)}:{ICON_SIZE}".encode()).hexdigest()[:24]
    out = os.path.join(cache, stamp + ".png")
    if os.path.isfile(out):
        return out
    os.makedirs(cache, mode=0o700, exist_ok=True)
    temporary = out + ".new"
    try:
        subprocess.run([rsvg, "-w", str(ICON_SIZE), "-h", str(ICON_SIZE), "-a", "-f", "png", "-o", temporary, path],
                       check=True, capture_output=True, timeout=10)
        os.replace(temporary, out)
    except (OSError, subprocess.SubprocessError):
        try:
            os.unlink(temporary)
        except FileNotFoundError:
            pass
        return None
    return out


def stamped(stamp):
    # Milliseconds, up to a day ahead of this clock: one past 2^53 (or 10^400, Infinity to the
    # shell) would stop its clock for good, and every edit on the computer would lose from then on.
    return isinstance(stamp, int) and not isinstance(stamp, bool) and 0 <= stamp <= int(now() * 1000) + AHEAD


def clean_board(body):
    cards = body.get("cards", [])
    removed = body.get("removed", {})
    if not isinstance(cards, list) or not isinstance(removed, dict) or len(cards) > CARDS_MAX or len(removed) > 10 * CARDS_MAX:
        return None
    clean = []
    for card in cards:
        if not isinstance(card, dict):
            return None
        ident, text, column = card.get("id"), card.get("text"), card.get("column")
        stamps = (card.get("textStamp"), card.get("placeStamp"))
        if not isinstance(ident, str) or not 0 < len(ident) <= 64 or not isinstance(text, str) or not text.strip():
            return None
        if not isinstance(column, int) or isinstance(column, bool) or not 0 <= column <= 2:
            return None
        if not all(stamped(t) for t in stamps):
            return None
        kept = {"id": ident, "text": " ".join(text.split())[:160], "column": column,
                "textStamp": stamps[0], "placeStamp": stamps[1]}
        rank = card.get("rank")
        if rank is not None:
            if not isinstance(rank, (int, float)) or isinstance(rank, bool):
                return None
            # A whole number is checked as one: 10^400 has no float to be, and isfinite would raise.
            if not (abs(rank) <= 2 ** 53 if isinstance(rank, int) else math.isfinite(rank)):
                return None
            kept["rank"] = rank
        clean.append(kept)
    gone = {}
    for ident, when in removed.items():
        if not isinstance(ident, str) or not 0 < len(ident) <= 64 or not stamped(when):
            return None
        gone[ident] = when
    return {"cards": clean, "removed": gone}


EV_SYN, EV_KEY, EV_ABS = 0, 1, 3
SYN_REPORT = 0
BTN_TOUCH = 330
FINGER_TOOLS = (325, 333, 334, 335, 328)
ABS_X, ABS_Y = 0, 1
ABS_MT_SLOT, ABS_MT_POSITION_X, ABS_MT_POSITION_Y, ABS_MT_TRACKING_ID = 47, 53, 54, 57
INPUT_PROP_POINTER = 0
BUS_VIRTUAL = 6
TRACKPAD_NAME = "NIHIL deck trackpad"
TRACKPAD_PROTOCOL = "nihil-trackpad"
TRACKPAD_SLOTS = 5
TRACKPAD_IDLE = 4
TRACKPAD_SETTLE = 0.25
TRACKPAD_DELAY = 0.025
TOUCH_FRAME, KEEPALIVE = 1, 2
MAX_FINGERS = 10


def _ioc(number, size=0):
    return ((1 << 30) if size else 0) | (size << 16) | (ord("U") << 8) | number


UI_DEV_CREATE = _ioc(1)
UI_DEV_DESTROY = _ioc(2)
UI_DEV_SETUP = _ioc(3, 92)      # struct uinput_setup
UI_ABS_SETUP = _ioc(4, 28)      # struct uinput_abs_setup
UI_SET_EVBIT = _ioc(100, 4)
UI_SET_KEYBIT = _ioc(101, 4)
UI_SET_ABSBIT = _ioc(103, 4)
UI_SET_PROPBIT = _ioc(110, 4)


class Uinput:

    def __init__(self, path, width, height, resolution):
        self.width, self.height = width, height
        self.fd = os.open(path, os.O_WRONLY | os.O_NONBLOCK | os.O_CLOEXEC)
        try:
            for kind in (EV_KEY, EV_ABS):
                fcntl.ioctl(self.fd, UI_SET_EVBIT, kind)
            for key in (BTN_TOUCH, *FINGER_TOOLS):
                fcntl.ioctl(self.fd, UI_SET_KEYBIT, key)
            fcntl.ioctl(self.fd, UI_SET_PROPBIT, INPUT_PROP_POINTER)
            for code, top in ((ABS_X, width), (ABS_Y, height), (ABS_MT_POSITION_X, width), (ABS_MT_POSITION_Y, height)):
                self.axis(code, top, resolution)
            self.axis(ABS_MT_SLOT, TRACKPAD_SLOTS - 1, 0)
            self.axis(ABS_MT_TRACKING_ID, 65535, 0)
            setup = struct.pack("=4H80sI", BUS_VIRTUAL, 0x6E69, 0x6C64, 1, TRACKPAD_NAME.encode(), 0)
            fcntl.ioctl(self.fd, UI_DEV_SETUP, setup)
            fcntl.ioctl(self.fd, UI_DEV_CREATE)
        except OSError:
            os.close(self.fd)
            raise

    def axis(self, code, top, resolution):
        fcntl.ioctl(self.fd, UI_SET_ABSBIT, code)
        fcntl.ioctl(self.fd, UI_ABS_SETUP, struct.pack("=HH6i", code, 0, 0, 0, top, 0, 0, resolution))

    def write(self, events):
        # Once closed, its number may be another file's: never written to again.
        if self.fd < 0:
            raise OSError(errno.EBADF, "the trackpad is closed")
        os.write(self.fd, b"".join(struct.pack("@llHHi", 0, 0, kind, code, value) for kind, code, value in events))

    def close(self):
        if self.fd < 0:
            return
        fd, self.fd = self.fd, -1
        try:
            fcntl.ioctl(fd, UI_DEV_DESTROY)
        except OSError:
            pass
        os.close(fd)


class Fingers:

    def __init__(self):
        self.slots = [None] * TRACKPAD_SLOTS    # [finger, tracking id, x, y]
        self.slot = -1
        self.next_id = 0
        self.count = 0
        self.primary = None

    def frame(self, contacts):
        events = []
        touching = {finger for finger, _, _ in contacts}
        for index, held in enumerate(self.slots):
            if held is not None and held[0] not in touching:
                self.select(events, index)
                events.append((EV_ABS, ABS_MT_TRACKING_ID, -1))
                self.slots[index] = None
        for finger, x, y in contacts:
            index = next((i for i, held in enumerate(self.slots) if held is not None and held[0] == finger), None)
            if index is None:
                index = next((i for i, held in enumerate(self.slots) if held is None), None)
                if index is None:
                    continue
                self.select(events, index)
                events += [(EV_ABS, ABS_MT_TRACKING_ID, self.next_id), (EV_ABS, ABS_MT_POSITION_X, x), (EV_ABS, ABS_MT_POSITION_Y, y)]
                self.slots[index] = [finger, self.next_id, x, y]
                self.next_id = (self.next_id + 1) % 65536
                continue
            held = self.slots[index]
            if held[2] != x or held[3] != y:
                self.select(events, index)
                if held[2] != x:
                    events.append((EV_ABS, ABS_MT_POSITION_X, x))
                if held[3] != y:
                    events.append((EV_ABS, ABS_MT_POSITION_Y, y))
                held[2], held[3] = x, y
        self.legacy(events)
        events.append((EV_SYN, SYN_REPORT, 0))
        return events

    def release(self):
        return self.frame([]) if self.count else []

    def select(self, events, index):
        if self.slot != index:
            events.append((EV_ABS, ABS_MT_SLOT, index))
            self.slot = index

    def legacy(self, events):
        held = [slot for slot in self.slots if slot is not None]
        count = len(held)
        if count != self.count:
            if self.count:
                events.append((EV_KEY, FINGER_TOOLS[self.count - 1], 0))
            if count:
                events.append((EV_KEY, FINGER_TOOLS[count - 1], 1))
            if bool(count) != bool(self.count):
                events.append((EV_KEY, BTN_TOUCH, 1 if count else 0))
            self.count = count
        if not held:
            self.primary = None
            return
        first = max(held, key=lambda slot: (self.next_id - slot[1]) % 65536)
        if (first[2], first[3]) != self.primary:
            if self.primary is None or self.primary[0] != first[2]:
                events.append((EV_ABS, ABS_X, first[2]))
            if self.primary is None or self.primary[1] != first[3]:
                events.append((EV_ABS, ABS_Y, first[3]))
            self.primary = (first[2], first[3])


class Pace:

    WINDOW = 2.0
    SQUEEZE = 0.9

    def __init__(self, delay=TRACKPAD_DELAY):
        self.delay = delay
        self.quickest = collections.deque()
        self.last = None                        # (phone, due) of the last frame
        self.raw = None
        self.wraps = 0

    def seconds(self, millis):
        if self.raw is not None and millis < self.raw and self.raw - millis > 1 << 31:
            self.wraps += 1
        self.raw = millis
        return (self.wraps * (1 << 32) + millis) / 1000

    def heard(self, phone, arrived):
        offset = arrived - phone
        while self.quickest and self.quickest[-1][1] >= offset:
            self.quickest.pop()
        self.quickest.append((arrived, offset))
        while self.quickest[0][0] < arrived - self.WINDOW:
            self.quickest.popleft()

    def due(self, phone, arrived):
        self.heard(phone, arrived)
        due = phone + self.quickest[0][1] + self.delay
        if self.last is not None and 0 <= phone - self.last[0] < 0.1:
            due = max(due, self.last[1] + self.SQUEEZE * (phone - self.last[0]))
        # Never long after it came: a phone's clock running ahead would push every frame later.
        due = min(max(due, arrived), arrived + LATEST)
        self.last = (phone, due)
        return due


def stream(reader, writer, pad, clock=time.monotonic):
    fingers = Fingers()
    pace = Pace()
    # Each frame says where every finger is, so the oldest can go when too many wait.
    queue = collections.deque(maxlen=QUEUED)
    ready = threading.Condition()
    finished = []

    def emit():
        try:
            while True:
                with ready:
                    while not queue and not finished:
                        ready.wait()
                    if not queue:
                        break
                    due, contacts = queue.popleft()
                    # Each waits for its moment, unless the stream ends: then what's left goes at once.
                    wait = due - clock()
                    if wait > 0 and not finished:
                        ready.wait_for(lambda: finished, timeout=wait)
                pad.write(fingers.frame(contacts))
        except OSError:
            pass
        finally:
            try:
                events = fingers.release()
                if events:
                    pad.write(events)
            except OSError:
                pass

    worker = threading.Thread(target=emit, daemon=True)
    worker.start()
    try:
        while True:
            head = reader.read(5)
            if len(head) < 5:
                break
            arrived = clock()
            kind, millis = struct.unpack("!BI", head)
            phone = pace.seconds(millis)
            if kind == KEEPALIVE:
                pace.heard(phone, arrived)
                writer.write(bytes([KEEPALIVE]))
                continue
            count = reader.read(1) if kind == TOUCH_FRAME else b""
            if len(count) < 1 or count[0] > MAX_FINGERS:
                break
            body = reader.read(5 * count[0])
            if len(body) < 5 * count[0]:
                break
            contacts = []
            for index in range(count[0]):
                finger, x, y = struct.unpack_from("!BHH", body, 5 * index)
                contacts.append((finger, min(x, pad.width), min(y, pad.height)))
            due = pace.due(phone, arrived)
            with ready:
                queue.append((due, contacts))
                ready.notify()
    except (OSError, ValueError):
        pass
    finally:
        with ready:
            finished.append(True)
            ready.notify()
        # Until it's done: the pad closes after, and a writer left behind would write to whatever
        # file got its number next.
        worker.join()


FAVICON_DAYS = 7
FAVICONS_KEPT = 500
PAGE_MAX = 512 * 1024
FAVICON_MAX = 256 * 1024
FETCH_TIMEOUT = 5
PUBLIC_ONLY = True
PNG_MAGIC = b"\x89PNG\r\n\x1a\n"


def public(host):
    if not PUBLIC_ONLY:
        return True
    try:
        found = socket.getaddrinfo(host, None)
    except (OSError, UnicodeError):
        return False
    return bool(found) and all(ipaddress.ip_address(item[4][0].split("%")[0]).is_global for item in found)


class PublicRedirects(urllib.request.HTTPRedirectHandler):

    max_redirections = 3

    def redirect_request(self, req, fp, code, msg, headers, newurl):
        if not valid_url(newurl) or not public(urllib.parse.urlsplit(newurl).hostname):
            raise urllib.error.URLError("redirected somewhere not public")
        return super().redirect_request(req, fp, code, msg, headers, newurl)


def reached(sock):
    """Where a connection went, checked once it's there: a name can answer public when it's
    looked up and this computer's network when it's connected to (DNS rebinding)."""
    try:
        ip = ipaddress.ip_address(sock.getpeername()[0].split("%")[0])
    except (OSError, ValueError):
        ip = None
    if ip is not None and ip.version == 6 and ip.ipv4_mapped:
        ip = ip.ipv4_mapped
    if PUBLIC_ONLY and (ip is None or not ip.is_global):
        sock.close()
        raise OSError("connected somewhere not public")


class PublicHTTPConnection(http.client.HTTPConnection):
    def connect(self):
        super().connect()
        reached(self.sock)


class PublicHTTPSConnection(http.client.HTTPSConnection):
    def connect(self):
        super().connect()
        reached(self.sock)


class PublicHTTP(urllib.request.HTTPHandler):
    def http_open(self, req):
        return self.do_open(PublicHTTPConnection, req)


class PublicHTTPS(urllib.request.HTTPSHandler):
    def https_open(self, req):
        return self.do_open(PublicHTTPSConnection, req, context=self._context)


def fetch(url, limit, whole=True):
    if not valid_url(url) or not public(urllib.parse.urlsplit(url).hostname):
        raise ValueError("not a public web page")
    # No proxy: the address checked has to be the one asked.
    opener = urllib.request.build_opener(urllib.request.ProxyHandler({}), PublicHTTP(), PublicHTTPS(), PublicRedirects())
    request = urllib.request.Request(url, headers={"User-Agent": "NIHIL deck (icons)", "Accept": "*/*"})
    with opener.open(request, timeout=FETCH_TIMEOUT) as response:
        data = response.read(limit + 1)
        if len(data) > limit:
            if whole:
                raise ValueError("too big")
            data = data[:limit]
        return response.geturl(), data


class IconLinks(html.parser.HTMLParser):

    def __init__(self, base):
        super().__init__()
        self.base = base
        self.found = []
        self.done = False

    def handle_starttag(self, tag, attrs):
        if self.done or tag == "body":
            self.done = True
            return
        if tag != "link":
            return
        attrs = {key: value or "" for key, value in attrs}
        rel = set(attrs.get("rel", "").lower().split())
        href = attrs.get("href", "").strip()
        touch = bool(rel & {"apple-touch-icon", "apple-touch-icon-precomposed"})
        if not href or not (touch or "icon" in rel):
            return
        sizes = [int(size) for size in re.findall(r"(\d+)x\d+", attrs.get("sizes", "").lower())]
        if "svg" in attrs.get("type", "").lower() or href.lower().split("?")[0].endswith(".svg"):
            score = 1024
        else:
            score = max(sizes or [180 if touch else 32])
        self.found.append((score, urllib.parse.urljoin(self.base, href)))

    def handle_endtag(self, tag):
        if tag == "head":
            self.done = True


def ico_png(data):
    try:
        best = None
        for index in range(min(struct.unpack_from("<H", data, 4)[0], 64)):
            width, height, _, _, _, _, size, offset = struct.unpack_from("<BBBBHHII", data, 6 + 16 * index)
            chunk = data[offset:offset + size]
            if chunk.startswith(PNG_MAGIC) and (best is None or (width or 256) * (height or 256) > best[0]):
                best = ((width or 256) * (height or 256), chunk)
        return (best[1], "image/png") if best else None
    except struct.error:
        return None


def as_image(data, rsvg):
    head = data[:16]
    if head.startswith(PNG_MAGIC):
        return data, "image/png"
    if head.startswith(b"\xff\xd8\xff"):
        return data, "image/jpeg"
    if head[:6] in (b"GIF87a", b"GIF89a"):
        return data, "image/gif"
    if head[:4] == b"RIFF" and head[8:12] == b"WEBP":
        return data, "image/webp"
    if head[:4] == b"\x00\x00\x01\x00":
        return ico_png(data)
    if b"<svg" in data[:2048].lower():
        try:
            drawn = subprocess.run([rsvg, "-w", str(ICON_SIZE), "-h", str(ICON_SIZE), "-a", "-f", "png"],
                                   input=data, check=True, capture_output=True, timeout=10).stdout
        except (OSError, subprocess.SubprocessError):
            return None
        return (drawn, "image/png") if drawn.startswith(PNG_MAGIC) else None
    return None


def favicon(url, rsvg, cache):
    parts = urllib.parse.urlsplit(url)
    origin = f"{parts.scheme}://{parts.netloc}".lower()
    path = os.path.join(cache, hashlib.sha256(origin.encode()).hexdigest()[:24])
    try:
        if time.time() - os.path.getmtime(path) < FAVICON_DAYS * 86400:
            with open(path, "rb") as file:
                kept = file.read()
            return as_image(kept, rsvg) if kept else None
    except OSError:
        pass
    failed = (OSError, ValueError, urllib.error.URLError, http.client.HTTPException)
    candidates = []
    try:
        where, page = fetch(origin + "/", PAGE_MAX, whole=False)
        links = IconLinks(where)
        links.feed(page.decode("utf-8", "replace"))
        candidates = [href for _, href in sorted(links.found, key=lambda item: -item[0])]
    except failed:
        pass
    found = None
    for href in candidates[:4] + [origin + "/favicon.ico"]:
        try:
            found = as_image(fetch(href, FAVICON_MAX)[1], rsvg)
        except failed:
            continue
        if found:
            break
    os.makedirs(cache, mode=0o700, exist_ok=True)
    fd, temporary = tempfile.mkstemp(dir=cache, prefix=".icon-")
    with os.fdopen(fd, "wb") as file:
        file.write(found[0] if found else b"")
    os.replace(temporary, path)
    prune(cache)
    return found


# The icons kept, misses too, go after their week, and past FAVICONS_KEPT the oldest go: a device
# can name any number of sites.
def prune(cache):
    kept = []
    try:
        names = os.listdir(cache)
    except OSError:
        return
    for name in names:
        path = os.path.join(cache, name)
        try:
            moment = os.path.getmtime(path)
        except OSError:
            continue
        if name.startswith("."):
            if now() - moment > 3600:
                kept.append((0, path))
            continue
        kept.append((moment, path))
    kept.sort(reverse=True)
    for index, (moment, path) in enumerate(kept):
        if index >= FAVICONS_KEPT or now() - moment >= FAVICON_DAYS * 86400:
            try:
                os.unlink(path)
            except OSError:
                pass


def addresses(ip):
    found = []
    if ip:
        try:
            route = json.loads(subprocess.run([ip, "-j", "-4", "route", "get", "192.0.2.1"],
                                              capture_output=True, text=True, timeout=5).stdout or "[]")
            if route and route[0].get("prefsrc"):
                found.append(route[0]["prefsrc"])
        except (OSError, ValueError, subprocess.SubprocessError, AttributeError, IndexError):
            pass
        try:
            links = json.loads(subprocess.run([ip, "-j", "-4", "addr", "show", "up", "scope", "global"],
                                              capture_output=True, text=True, timeout=5).stdout or "[]")
            for link in links:
                if VIRTUAL.match(str(link.get("ifname", ""))):
                    continue
                for info in link.get("addr_info", []):
                    if info.get("family") == "inet" and info.get("local"):
                        found.append(info["local"])
        except (OSError, ValueError, subprocess.SubprocessError, AttributeError):
            pass
    if not found:
        try:
            with socket.socket(socket.AF_INET, socket.SOCK_DGRAM) as probe:
                probe.connect(("192.0.2.1", 9))
                found.append(probe.getsockname()[0])
        except OSError:
            pass
    return [address for address in dict.fromkeys(found) if not address.startswith("127.")]


def pair_uri(name, port, hosts, code, pin, ble=None):
    fields = {"v": API, "name": name, "hosts": ",".join(hosts), "port": port, "code": code, "pin": pin}
    if ble:
        fields.update(ble=ble["uuid"], psm=ble["psm"])
    return "nihil-deck://pair?" + urllib.parse.urlencode(fields, safe=",")


def ble_uuid(pin):
    """The UUID this computer announces itself by over Bluetooth: from its pin, so a phone paired
    before Bluetooth came knows it without pairing again, and anyone else learns only that some
    computer is near. A version 8 UUID (RFC 9562): the first 16 bytes of SHA-256 over
    "nihil-deck ble", a zero byte and the pin, with the version and variant bits set."""
    raw = bytearray(hashlib.sha256(b"nihil-deck ble\0" + pin.encode()).digest()[:16])
    raw[6] = (raw[6] & 0x0F) | 0x80
    raw[8] = (raw[8] & 0x3F) | 0x80
    return str(uuid.UUID(bytes=bytes(raw)))


def vector_dir():
    return os.path.join(home_dir("XDG_CACHE_HOME", ".cache"), "nihil", "vector")


def kind_of(mime):
    if mime.startswith("text/"):
        return "text"
    for kind in ("image", "video"):
        if mime.startswith(kind + "/"):
            return kind
    return "file"


def clean_mime(value):
    mime = str(value or "").split(";")[0].strip().lower()
    return mime if MIME.fullmatch(mime) else "application/octet-stream"


def fit(stem, ending, limit=NAME_BYTES):
    """A name Linux takes, cut by its bytes, not its characters, and keeping how it ends."""
    while stem and len((stem + ending).encode()) > limit:
        stem = stem[:-1]
    return stem + ending


def file_name(value, mime):
    name = os.path.basename(str(value or "").replace("\\", "/"))
    # Without control or format characters: «photo», U+202E, «gpj.desktop» would show as a photo.
    name = "".join(char for char in name if unicodedata.category(char) not in ("Cc", "Cf", "Zl", "Zp")).strip()
    stem, extension = os.path.splitext(name)
    if len(extension.encode()) > 16:
        stem, extension = name, ""
    name = fit(stem, extension)
    if name in ("", ".", "..") or name.startswith("."):
        name = time.strftime("Vector_%Y-%m-%d_%H.%M.%S") + EXTENSIONS.get(mime, "")
    return name


def told(head):
    """What a file is by its first bytes, as far as matters here: an image, a video, a PDF or a
    text, or nothing of those."""
    if (head.startswith((PNG_MAGIC, b"\xff\xd8\xff")) or head[:6] in (b"GIF87a", b"GIF89a")
            or (head[:4] == b"RIFF" and head[8:12] == b"WEBP") or head[4:12] in (b"ftypavif", b"ftypheic", b"ftypheix", b"ftypmif1")):
        return "image"
    if head[4:8] == b"ftyp" or head.startswith(b"\x1a\x45\xdf\xa3"):
        return "video"
    if head.startswith(b"%PDF"):
        return "pdf"
    if b"\x00" not in head:
        try:
            codecs.getincrementaldecoder("utf-8")().decode(head)
            return "text"
        except UnicodeDecodeError:
            pass
    return ""


def confirmed(mime, path):
    """What a device says it sent, if its bytes agree for what's shown or opened here (an image,
    a video, a PDF, a text); otherwise just bytes."""
    try:
        with open(path, "rb") as file:
            head = file.read(SNIFF)
    except OSError:
        return "application/octet-stream"
    seen = told(head)
    if mime == "image/svg+xml":
        agrees = seen == "text" and b"<svg" in head.lower()
    elif mime == "application/pdf":
        agrees = seen == "pdf"
    elif kind_of(mime) != "file":
        agrees = seen == kind_of(mime)
    else:
        agrees = True
    return mime if agrees else "application/octet-stream"


# Open hands a file to the program for its type only when it's a picture, a video, a PDF or a
# text, by its bytes and by its name, which may be what picks the program: anything else, an
# SVG or a page with scripts among them, is shown in its folder.
OPENED = (("image/",), ("video/",), ("application/pdf",), ("text/plain", "text/markdown"))


def openable(item, path):
    named = mimetypes.guess_type(os.path.basename(path))[0]
    if named is None and os.path.splitext(path)[1]:
        return False
    for wanted in OPENED:
        if item["mime"].startswith(wanted) and (named is None or named.startswith(wanted)):
            return "image/svg+xml" not in (item["mime"], named)
    return False


def vector_item(item):
    if not item:
        return {"id": ""}
    return {key: item[key] for key in ("id", "kind", "name", "mime", "size", "time")}


class Vector:

    def __init__(self, folder=None):
        self.folder = folder or vector_dir()
        self.changed = threading.Condition()
        self.waiting = collections.Counter()
        self.heard = {}

    def slot(self, side):
        return os.path.join(self.folder, side)

    def item(self, side):
        try:
            with open(os.path.join(self.slot(side), ".item.json")) as file:
                item = json.load(file)
            path = os.path.join(self.slot(side), item["name"])
        except (OSError, ValueError, KeyError, TypeError):
            return None
        if not os.path.isfile(path):
            return None
        item["path"] = path
        return item

    def part(self, side):
        folder = self.slot(side)
        os.makedirs(folder, mode=0o700, exist_ok=True)
        return os.path.join(folder, ".part-" + secrets.token_hex(6))

    def store(self, side, part, name, mime, origin=""):
        folder = self.slot(side)
        mime = clean_mime(mime)
        if side == "in":
            mime = confirmed(mime, part)
        name = file_name(name, mime)
        for entry in os.listdir(folder):
            path = os.path.join(folder, entry)
            if path == part or entry == ".item.json" or entry.startswith(".deck-"):
                continue
            if entry.startswith(".part-") and now() - os.path.getmtime(path) < 600:
                continue
            try:
                if os.path.isdir(path) and not os.path.islink(path):
                    shutil.rmtree(path)
                else:
                    os.unlink(path)
            except OSError:
                pass
        target = os.path.join(folder, name)
        os.replace(part, target)
        size = os.path.getsize(target)
        kind = kind_of(mime)
        item = {"id": secrets.token_hex(8), "kind": "file" if kind == "text" and size > VECTOR_TEXT else kind,
                "name": name, "mime": mime, "size": size, "time": round(now()), "from": origin}
        write_private(os.path.join(folder, ".item.json"), json.dumps(item))
        self.poke()
        item["path"] = target
        return item

    def drop(self, side):
        folder = self.slot(side)
        try:
            entries = os.listdir(folder)
        except OSError:
            return
        for entry in entries:
            if entry.startswith((".part-", ".deck-")):
                continue
            try:
                os.unlink(os.path.join(folder, entry))
            except OSError:
                pass
        self.poke()

    def poke(self):
        with self.changed:
            self.changed.notify_all()

    def wait(self, device, since, seconds):
        deadline = now() + seconds
        with self.changed:
            self.waiting[device] += 1
            try:
                while True:
                    item = self.item("out")
                    if (item["id"] if item else "") != since or now() >= deadline:
                        return item
                    self.changed.wait(min(deadline - now(), 5))
            finally:
                self.waiting[device] -= 1
                if self.waiting[device] <= 0:
                    del self.waiting[device]
                self.heard[device] = now()

    def connected(self, devices):
        live = {key for key, count in self.waiting.items() if count > 0}
        live |= {key for key, seen in list(self.heard.items()) if now() - seen < VECTOR_LIVE}
        return [device["name"] for device in devices.listing() if device["id"] in live]


class Deck:

    def __init__(self, config, folder, pin):
        self.config = config
        self.pin = pin
        self.name = config.get("name") or socket.gethostname()
        self.port = int(config.get("port", PORT))
        self.devices = Devices(os.path.join(folder, "devices.json"))
        self.pairing = Pairing()
        self.throttle = Throttle()
        self.session = Session(config)
        self.vector = Vector(config.get("vector"))
        self.strings = config.get("strings", {})
        self.make_trackpad = lambda width, height, resolution: Uinput(config.get("uinput", "/dev/uinput"), width, height, resolution)
        self.streams = {}
        self.streams_lock = threading.Lock()
        self.uploading = set()      # devices sending to Vector: one thing at a time each
        self.ble = None             # {"uuid", "psm"} once listening over Bluetooth

    def control(self, request):
        op = request.get("op") if isinstance(request, dict) else None
        if op == "pair":
            code, expires, invite = self.pairing.open()
            hosts = addresses(self.config.get("ip"))
            return {"uri": pair_uri(self.name, self.port, hosts, code, self.pin, self.ble), "code": code,
                    "invite": invite, "expires": int(expires), "hosts": hosts, "port": self.port, "pin": self.pin,
                    **({"ble": self.ble} if self.ble else {})}
        if op == "cancel":
            self.pairing.close(str(request.get("invite") or "") or None)
            return {"ok": True}
        if op == "devices":
            return {"devices": self.devices.listing(), "pairing": self.pairing.open_now,
                    "invites": self.pairing.invites(), "asking": self.pairing.waiting()}
        if op in ("allow", "deny"):
            return {"ok": self.pairing.answer(str(request.get("id", "")), op == "allow")}
        if op == "forget":
            target = str(request.get("id", ""))
            ok = self.devices.forget(target)
            if ok:
                self.cut(target)
            return {"ok": ok}
        if op == "status":
            return {"port": self.port, "pin": self.pin, "devices": len(self.devices.listing()),
                    "pairing": self.pairing.open_now, "ble": self.ble}
        if op == "vector":
            self.vector.poke()
            return {"devices": self.vector.connected(self.devices)}
        return {"error": "unknown"}

    def claim(self, device, connection):
        with self.streams_lock:
            before = self.streams.get(device)
            self.streams[device] = connection
        if before is not None and before is not connection:
            try:
                socket.socket.shutdown(before, socket.SHUT_RDWR)
            except OSError:
                pass

    # A forgotten device loses its trackpad at once: a stream never authenticates again.
    def cut(self, target):
        with self.streams_lock:
            gone = [connection for device, connection in self.streams.items() if target in ("all", device)]
        for connection in gone:
            try:
                socket.socket.shutdown(connection, socket.SHUT_RDWR)
            except OSError:
                pass

    def unclaim(self, device, connection):
        with self.streams_lock:
            if self.streams.get(device) is connection:
                del self.streams[device]

    def paired(self, name):
        title = self.strings.get("deckPaired", "%1 can now use this computer as a deck").replace("%1", name)
        self.session.notify(title, self.strings.get("deckPairedBody", ""))


class Handler(http.server.BaseHTTPRequestHandler):
    protocol_version = "HTTP/1.1"
    disable_nagle_algorithm = True
    server_version = "nihil-deck/" + str(API)
    sys_version = ""

    # A request has REQUEST_SECONDS to arrive, handshake, line, headers and body, however slowly it
    # drips, so a slot isn't held by someone who never gets to authenticate. route() lifts it.
    def setup(self):
        self.deadline = threading.Timer(REQUEST_SECONDS, self.cut)
        self.deadline.daemon = True
        self.deadline.start()
        self.request.do_handshake()
        super().setup()

    def handle_one_request(self):
        self.deadline.cancel()
        self.deadline = threading.Timer(REQUEST_SECONDS, self.cut)
        self.deadline.daemon = True
        self.deadline.start()
        try:
            super().handle_one_request()
        finally:
            self.deadline.cancel()

    def cut(self):
        try:
            socket.socket.shutdown(self.request, socket.SHUT_RDWR)
        except OSError:
            pass

    def log_message(self, format, *args):
        pass

    def reply(self, status, body):
        data = json.dumps(body).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "no-store")
        if self.close_connection:
            self.send_header("Connection", "close")
        self.end_headers()
        self.wfile.write(data)

    def png(self, path):
        with open(path, "rb") as file:
            self.image(file.read(), "image/png")

    def image(self, data, kind):
        self.send_response(200)
        self.send_header("Content-Type", kind)
        self.send_header("Content-Length", str(len(data)))
        self.send_header("Cache-Control", "private, max-age=86400")
        self.end_headers()
        self.wfile.write(data)

    def read_body(self, limit=MAX_BODY):
        try:
            length = int(self.headers.get("Content-Length") or 0)
        except ValueError:
            length = -1
        if length < 0 or length > limit:
            self.close_connection = True
            return None
        data = self.rfile.read(length) if length else b""
        if not data:
            return {}
        try:
            body = json.loads(data)
        except (ValueError, RecursionError):
            return None
        return body if isinstance(body, dict) else None

    def body(self, path):
        """What a request brings, read once it's known who sends it; None, answered, if it isn't JSON."""
        found = self.read_body(TASKS_MAX if path == "/v1/tasks" else MAX_BODY)
        if found is None:
            self.reply(400, {"error": "body"})
        return found

    def do_GET(self):
        self.route("GET")

    def do_POST(self):
        self.route("POST")

    def send_file(self, item):
        try:
            file = open(item["path"], "rb")
        except OSError:
            self.reply(404, {"error": "vector"})
            return
        with file:
            self.send_response(200)
            self.send_header("Content-Type", item["mime"])
            self.send_header("Content-Length", str(os.fstat(file.fileno()).st_size))
            self.send_header("Content-Disposition", "attachment; filename*=UTF-8''" + urllib.parse.quote(item["name"]))
            self.send_header("Cache-Control", "no-store")
            self.end_headers()
            shutil.copyfileobj(file, self.wfile, CHUNK)

    def receive(self, deck, device):
        try:
            length = int(self.headers.get("Content-Length") or -1)
        except ValueError:
            length = -1
        if length <= 0 or length > VECTOR_MAX:
            self.reply(413 if length > VECTOR_MAX else 400, {"error": "big" if length > VECTOR_MAX else "body"})
            return
        with deck.streams_lock:
            busy = device["id"] in deck.uploading
            deck.uploading.add(device["id"])
        if busy:
            self.reply(409, {"error": "busy"})
            return
        try:
            self.upload(deck, device, length)
        finally:
            with deck.streams_lock:
                deck.uploading.discard(device["id"])

    def upload(self, deck, device, length):
        vector = deck.vector
        part = vector.part("in")
        try:
            free = shutil.disk_usage(os.path.dirname(part)).free
        except OSError:
            free = length + VECTOR_SPARE
        if free - length < VECTOR_SPARE:
            self.reply(507, {"error": "full"})
            return
        try:
            with open(part, "wb") as file:
                left = length
                while left:
                    chunk = self.rfile.read(min(CHUNK, left))
                    if not chunk:
                        raise ConnectionError("short")
                    file.write(chunk)
                    left -= len(chunk)
            name = urllib.parse.unquote(self.headers.get("X-Vector-Name", ""))
            item = vector.store("in", part, name, self.headers.get("Content-Type"), device["name"])
        except (OSError, ConnectionError, socket.timeout):
            try:
                os.unlink(part)
            except OSError:
                pass
            self.reply(503, {"error": "vector"})
            return
        vector.heard[device["id"]] = now()
        deck.session.ipc("vector", "received")
        self.reply(200, vector_item(item))

    def route(self, method):
        deck = self.server.deck
        address = origin(self.client_address[0])
        path = urllib.parse.urlsplit(self.path).path
        if deck.throttle.blocked(address):
            self.close_connection = True
            self.reply(429, {"error": "wait"})
            return
        # Whether it is there, not which computer: the phone has the name from the QR.
        if method == "GET" and path == "/v1/hello":
            self.reply(200, {"deck": API})
            return
        if method == "POST" and path == "/v1/pair":
            body = self.body(path)
            if body is not None:
                self.deadline.cancel()
                self.pair(deck, address, body)
            return
        auth = self.headers.get("Authorization", "")
        device = deck.devices.find(auth[7:].strip() if auth.startswith("Bearer ") else "")
        if device is None:
            deck.throttle.fail(address)
            self.close_connection = True        # what it sent is left unread
            self.reply(401, {"error": "unpaired"})
            return
        # Only a device that's paired has its body read, and may take its time.
        self.deadline.cancel()
        deck.devices.touch(device, self.client_address[0].startswith(BLUETOOTH_ORIGIN))
        body = {}
        if method == "POST" and path == "/v1/vector":
            self.close_connection = True
        elif method == "POST":
            body = self.body(path)
            if body is None:
                return
        self.paired_route(deck, device, method, path, body)

    def pair(self, deck, address, body):
        result = deck.pairing.take(body.get("code"))
        if result != "ok":
            deck.throttle.fail(address)
            if result == "wait":
                self.close_connection = True
            self.reply(429 if result == "wait" else 403, {"error": result})
            return
        name = clean_name(body.get("device"), "Android")
        asking = deck.pairing.ask(name)
        deck.session.ipc("deck", "asking")
        try:
            allowed = asking["event"].wait(PAIR_WAIT) and asking["allowed"]
        finally:
            deck.pairing.done(asking["id"])
            deck.session.ipc("deck", "asking")
        if not allowed:
            self.reply(403, {"error": "declined"})
            return
        device, token = deck.devices.add(name)
        deck.paired(name)
        self.reply(200, {"token": token, "device": device, "name": deck.name, **({"ble": deck.ble} if deck.ble else {})})

    def trackpad(self, deck, device):
        query = urllib.parse.parse_qs(urllib.parse.urlsplit(self.path).query)
        try:
            width, height, resolution = (int(query.get(key, ["0"])[0]) for key in ("w", "h", "r"))
        except ValueError:
            width = height = resolution = 0
        sized = 5 <= resolution <= 100 and all(10 * resolution <= side <= min(500 * resolution, 65535) for side in (width, height))
        if not sized or self.headers.get("Upgrade", "").strip().lower() != TRACKPAD_PROTOCOL:
            self.reply(400, {"error": "invalid"})
            return
        try:
            pad = deck.make_trackpad(width, height, resolution)
        except OSError as error:
            self.reply(503, {"error": "access" if error.errno in (errno.EACCES, errno.EPERM) else "trackpad"})
            return
        deck.claim(device["id"], self.connection)
        try:
            # Forgotten while it was starting: the cut only reaches what was claimed by then.
            if not deck.devices.known(device["id"]):
                self.reply(401, {"error": "unpaired"})
                return
            time.sleep(TRACKPAD_SETTLE)
            self.send_response(101)
            self.send_header("Upgrade", TRACKPAD_PROTOCOL)
            self.send_header("Connection", "Upgrade")
            self.end_headers()
            self.close_connection = True
            self.connection.settimeout(TRACKPAD_IDLE)
            try:
                self.connection.setsockopt(socket.IPPROTO_TCP, socket.TCP_NODELAY, 1)
            except OSError:
                pass
            stream(self.rfile, self.wfile, pad)
        finally:
            deck.unclaim(device["id"], self.connection)
            pad.close()

    def paired_route(self, deck, device, method, path, body):
        session = deck.session
        if method == "GET" and path == "/v1/apps":
            listed = session.apps()
            if listed is None:
                self.reply(503, {"error": "shell"})
                return
            self.reply(200, {"apps": [{"id": a["id"], "name": a["name"]} for a in listed]})
        elif method == "GET" and path.startswith("/v1/apps/") and path.endswith("/icon"):
            app = session.app(urllib.parse.unquote(path[len("/v1/apps/"):-len("/icon")]))
            found = icon_file(app["icon"], deck.config.get("iconTheme", "")) if app else None
            picture = icon_png(found, deck.config.get("rsvg", "rsvg-convert"), os.path.join(cache_dir(), "icons")) if found else None
            if picture is None:
                self.reply(404, {"error": "icon"})
            else:
                self.png(picture)
        elif method == "GET" and path == "/v1/favicon":
            url = urllib.parse.parse_qs(urllib.parse.urlsplit(self.path).query).get("url", [""])[0]
            if not valid_url(url):
                self.reply(400, {"error": "invalid"})
                return
            found = favicon(url, deck.config.get("rsvg", "rsvg-convert"), os.path.join(cache_dir(), "favicons"))
            if found is None:
                self.reply(404, {"error": "icon"})
            else:
                self.image(*found)
        elif method == "GET" and path == "/v1/cover":
            token = urllib.parse.parse_qs(urllib.parse.urlsplit(self.path).query).get("c", [""])[0]
            found = session.cover(token) if re.fullmatch(r"[0-9a-f]{16}", token) else None
            if found is None:
                self.reply(404, {"error": "cover"})
            else:
                self.image(*found)
        elif method == "GET" and path == "/v1/tasks":
            board = session.tasks()
            if board is None:
                self.reply(503, {"error": "shell"})
            else:
                self.reply(200, board)
        elif method == "POST" and path == "/v1/tasks":
            board = clean_board(body)
            if board is None:
                self.reply(400, {"error": "invalid"})
                return
            merged = session.tasks(board)
            if merged is None:
                self.reply(503, {"error": "shell"})
            else:
                self.reply(200, merged)
        elif method == "GET" and path == "/v1/state":
            self.reply(200, {"media": session.playing(), "volume": session.volume(), **session.toggles(),
                             **({"ble": deck.ble} if deck.ble else {})})
        elif method == "POST" and path == "/v1/open":
            if "app" in body:
                result = session.launch(body.get("app"))
            elif "url" in body:
                result = session.open_url(body.get("url"))
            else:
                result = "invalid"
            status = {"ok": 200, "unknown": 404, "invalid": 400, "shell": 503}[result]
            self.reply(status, {"ok": True} if result == "ok" else {"error": result})
        elif method == "POST" and path in ("/v1/media", "/v1/volume", "/v1/caffeine", "/v1/night"):
            kind = path[len("/v1/"):]
            action = body.get("action")
            if action not in ACTIONS[kind]:
                self.reply(400, {"error": "action"})
            elif kind in ("caffeine", "night"):
                on = session.switch(kind, action)
                if on is None:
                    self.reply(503, {"error": "shell"})
                else:
                    self.reply(200, {"on": on})
            elif kind == "media":
                if session.media(action):
                    self.reply(200, {"ok": True})
                else:
                    self.reply(503, {"error": "shell"})
            else:
                volume = session.volume(action)
                if volume is not None:
                    self.reply(200, volume)
                else:
                    self.reply(503, {"error": "volume"})
        elif method == "GET" and path == "/v1/vector":
            query = urllib.parse.parse_qs(urllib.parse.urlsplit(self.path).query)
            try:
                wait = max(0, min(VECTOR_WAIT, int(query.get("wait", ["0"])[0])))
            except ValueError:
                wait = 0
            since = query.get("since", [""])[0]
            deck.vector.heard[device["id"]] = now()
            item = deck.vector.wait(device["id"], since, wait) if wait else deck.vector.item("out")
            if not deck.devices.known(device["id"]):
                self.reply(401, {"error": "unpaired"})
                return
            self.reply(200, dict(vector_item(item), now=round(now())))
        elif method == "GET" and path == "/v1/vector/data":
            wanted = urllib.parse.parse_qs(urllib.parse.urlsplit(self.path).query).get("id", [""])[0]
            item = deck.vector.item("out")
            if not item or item["id"] != wanted:
                self.reply(404, {"error": "vector"})
            else:
                deck.vector.heard[device["id"]] = now()
                self.send_file(item)
        elif method == "POST" and path == "/v1/vector":
            self.receive(deck, device)
        elif method == "POST" and path == "/v1/lock":
            if session.lock_screen():
                self.reply(200, {"ok": True})
            else:
                self.reply(503, {"error": "lock"})
        elif method == "GET" and path == "/v1/trackpad":
            self.trackpad(deck, device)
        elif method == "POST" and path == "/v1/unpair":
            deck.devices.forget(device["id"])
            self.reply(200, {"ok": True})
        else:
            self.reply(404, {"error": "path"})


class DeckServer(http.server.ThreadingHTTPServer):

    daemon_threads = True
    timeout_seconds = 15

    def __init__(self, address, deck, context):
        self.deck = deck
        self.context = context
        self.slots = threading.BoundedSemaphore(CONNECTIONS)
        self.per_address = {}
        self.per_address_lock = threading.Lock()
        host, port = address
        self.address_family = socket.AF_INET6 if ":" in host else socket.AF_INET
        super().__init__((host, port), Handler)

    def process_request(self, request, client_address):
        address = origin(client_address[0])
        with self.per_address_lock:
            if self.per_address.get(address, 0) >= PER_ADDRESS:
                self.shutdown_request(request)
                return
            self.per_address[address] = self.per_address.get(address, 0) + 1
        if not self.slots.acquire(blocking=False):
            self.leave(address)
            self.shutdown_request(request)
            return
        try:
            super().process_request(request, client_address)
        except BaseException:
            self.slots.release()
            self.leave(address)
            raise

    def leave(self, address):
        with self.per_address_lock:
            left = self.per_address.get(address, 1) - 1
            if left > 0:
                self.per_address[address] = left
            else:
                self.per_address.pop(address, None)

    def process_request_thread(self, request, client_address):
        try:
            super().process_request_thread(request, client_address)
        finally:
            self.slots.release()
            self.leave(origin(client_address[0]))

    def server_bind(self):
        if self.address_family == socket.AF_INET6:
            try:
                self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
            except OSError:
                pass
        socketserver.TCPServer.server_bind(self)
        self.server_name = "nihil-deck"
        self.server_port = self.server_address[1]

    def get_request(self):
        connection, address = self.socket.accept()
        connection.settimeout(self.timeout_seconds)
        return self.context.wrap_socket(connection, server_side=True, do_handshake_on_connect=False), address

    def handle_error(self, request, client_address):
        error = sys.exc_info()[1]
        if not isinstance(error, (ssl.SSLError, ConnectionError, TimeoutError, socket.timeout)):
            print(f"nihil-deck: {client_address[0]}: {error!r}", file=sys.stderr)


# Without a network: Bluetooth LE. A phone that reaches none of the computer's addresses looks for
# its UUID and opens an LE connection-oriented channel (L2CAP) on BLE_PSM: a stream of bytes, and on
# it the same TLS and HTTP as over TCP, the pin the check as ever. No pairing in the system's
# Bluetooth settings: the channel is open to devices that aren't bonded, as the port is to the
# network, and only one with the pin and a token gets anything (docs/deck.md).

SOL_BLUETOOTH = 274
BT_SECURITY = 4
BT_SECURITY_LOW = 1             # no bonding or encryption at the link: TLS is on top
BT_RCVMTU = 13
BLE_MTU = 4096                  # the biggest piece the phone may send in one go: fewer, larger pieces
BDADDR_LE_PUBLIC = 1
BLUETOOTH_ORIGIN = "bt:"        # before a channel's address, where a connection's IP would be


class SockaddrL2(ctypes.Structure):
    """Linux's struct sockaddr_l2, for Python before 3.14, whose sockets can't say an address is LE."""
    _fields_ = [("family", ctypes.c_ushort), ("psm", ctypes.c_ushort), ("bdaddr", ctypes.c_ubyte * 6),
                ("cid", ctypes.c_ushort), ("bdaddr_type", ctypes.c_ubyte)]


def bluetooth_order(value):
    """A 16-bit number as Bluetooth has it, little-endian, in a field the host reads in its own order."""
    return int.from_bytes(value.to_bytes(2, "little"), sys.byteorder)


def ble_listener(psm):
    """A socket that takes LE channels on psm, set as BlueZ's l2test listens for Android: a stream,
    at the lowest security, so devices that aren't bonded get in."""
    listener = socket.socket(socket.AF_BLUETOOTH, socket.SOCK_STREAM, socket.BTPROTO_L2CAP)
    try:
        listener.setsockopt(SOL_BLUETOOTH, BT_SECURITY, struct.pack("BB", BT_SECURITY_LOW, 0))
        if hasattr(socket, "BDADDR_LE_PUBLIC"):
            listener.bind((socket.BDADDR_ANY, psm, 0, socket.BDADDR_LE_PUBLIC))
        else:
            libc = ctypes.CDLL(None, use_errno=True)
            libc.bind.argtypes = [ctypes.c_int, ctypes.POINTER(SockaddrL2), ctypes.c_uint]
            address = SockaddrL2(socket.AF_BLUETOOTH, bluetooth_order(psm), (ctypes.c_ubyte * 6)(), 0, BDADDR_LE_PUBLIC)
            if libc.bind(listener.fileno(), ctypes.byref(address), ctypes.sizeof(address)) != 0:
                code = ctypes.get_errno()
                raise OSError(code, os.strerror(code))
        try:
            listener.setsockopt(SOL_BLUETOOTH, BT_RCVMTU, struct.pack("H", BLE_MTU))
        except OSError:
            pass                    # an older kernel keeps its own, smaller
        listener.listen(8)
    except BaseException:
        listener.close()
        raise
    return listener


def ble_serve(server, listener):
    """Each channel goes to the network's server as a connection would, counted, limited and timed
    as one: its address is the device's Bluetooth address, after BLUETOOTH_ORIGIN."""
    while True:
        try:
            connection, address = listener.accept()
        except OSError as error:
            if error.errno in (errno.EBADF, errno.EINVAL):
                return
            time.sleep(1)
            continue
        connection.settimeout(server.timeout_seconds)
        request = server.context.wrap_socket(connection, server_side=True, do_handshake_on_connect=False)
        server.process_request(request, (BLUETOOTH_ORIGIN + str(address[0]), address[1] if len(address) > 1 else 0))


class Advert:
    """The computer's Bluetooth LE advertisement, through BlueZ's D-Bus API: connectable, and with
    nothing in it but the UUID, no name. BlueZ asks this object for what it says (GetAll) and tells
    it when it's dropped (Release); it's offered again when Bluetooth comes back, as BlueZ restarts
    or the adapter is powered on."""

    PATH = "/org/nihil/deck/advert"
    IFACE = "org.bluez.LEAdvertisement1"
    MANAGER = "org.bluez.LEAdvertisingManager1"

    def __init__(self, ble_id, bus="SYSTEM"):
        self.uuid = ble_id
        self.bus = bus
        self.adapter = None
        self.registered = False
        self.said = None             # the last thing logged, so it isn't said again every retry

    def log(self, text):
        if text != self.said:
            self.said = text
            print(f"nihil-deck: {text}", file=sys.stderr)

    def properties(self):
        return {"Type": ("s", "peripheral"), "ServiceUUIDs": ("as", [self.uuid]), "Discoverable": ("b", True)}

    # What BlueZ sends this object; any other call is answered as unknown, a signal only listened to.
    def handle(self, connection, message):
        fields = message.header.fields
        kind = message.header.message_type
        if kind == jeepney.MessageType.signal:
            member = fields.get(jeepney.HeaderFields.member)
            if member == "NameOwnerChanged" and message.body[:1] == ("org.bluez",):
                self.registered = False
            return
        if kind != jeepney.MessageType.method_call:
            return
        path = fields.get(jeepney.HeaderFields.path)
        member = fields.get(jeepney.HeaderFields.member)
        if path == self.PATH and member == "GetAll" and message.body[:1] == (self.IFACE,):
            connection.send(jeepney.new_method_return(message, "a{sv}", (self.properties(),)))
        elif path == self.PATH and member == "Get" and message.body[:1] == (self.IFACE,) and message.body[1] in self.properties():
            connection.send(jeepney.new_method_return(message, "v", (self.properties()[message.body[1]],)))
        elif path == self.PATH and member == "Release":
            self.registered = False
            connection.send(jeepney.new_method_return(message))
        else:
            connection.send(jeepney.new_error(message, "org.freedesktop.DBus.Error.UnknownMethod"))

    # A call that waits for its answer and meanwhile answers BlueZ, which asks GetAll before it
    # answers RegisterAdvertisement: jeepney's own send_and_get_reply would drop that and wait.
    def call(self, connection, message, timeout=10):
        serial = next(connection.outgoing_serial)
        connection.send(message, serial=serial)
        deadline = time.monotonic() + timeout
        while True:
            reply = connection.receive(timeout=max(0.0, deadline - time.monotonic()))
            if reply.header.fields.get(jeepney.HeaderFields.reply_serial) == serial:
                if reply.header.message_type == jeepney.MessageType.error:
                    raise jeepney.DBusErrorResponse(reply)
                return reply.body
            self.handle(connection, reply)

    def find_adapter(self, connection):
        objects = self.call(connection, jeepney.new_method_call(
            jeepney.DBusAddress("/", bus_name="org.bluez", interface="org.freedesktop.DBus.ObjectManager"),
            "GetManagedObjects"))[0]
        for path, interfaces in sorted(objects.items()):
            powered = interfaces.get("org.bluez.Adapter1", {}).get("Powered", ("b", False))[1]
            if self.MANAGER in interfaces and powered:
                return path
        return None

    def offer(self, connection):
        self.adapter = self.find_adapter(connection)
        if self.adapter is None:
            self.log("no Bluetooth adapter on: the deck is on the network alone until there is")
            return
        self.call(connection, jeepney.new_method_call(
            jeepney.DBusAddress(self.adapter, bus_name="org.bluez", interface=self.MANAGER),
            "RegisterAdvertisement", "oa{sv}", (self.PATH, {})))
        self.registered = True
        self.log(f"announced over Bluetooth as {self.uuid}")

    def run(self):
        while True:
            try:
                with jeepney.io.blocking.open_dbus_connection(bus=self.bus) as connection:
                    rule = jeepney.MatchRule(type="signal", sender="org.freedesktop.DBus", interface="org.freedesktop.DBus",
                                             member="NameOwnerChanged", path="/org/freedesktop/DBus")
                    rule.add_arg_condition(0, "org.bluez")
                    self.call(connection, jeepney.message_bus.AddMatch(rule))
                    tried = 0.0
                    while True:
                        if not self.registered and time.monotonic() - tried >= BLE_RETRY:
                            tried = time.monotonic()
                            try:
                                self.offer(connection)
                            except jeepney.DBusErrorResponse as error:
                                self.log(f"Bluetooth won't announce it: {error.name}")
                        try:
                            self.handle(connection, connection.receive(timeout=BLE_RETRY))
                        except TimeoutError:
                            pass
            except (OSError, ValueError, EOFError) as error:
                self.registered = False
                self.log(f"no D-Bus for Bluetooth ({error.__class__.__name__}): trying again")
            time.sleep(BLE_RETRY)


def start_bluetooth(server, psm):
    """The channel and the advertisement, if this computer can: with no Bluetooth in the kernel or
    no jeepney, the deck goes on, on the network alone."""
    deck = server.deck
    try:
        listener = ble_listener(psm)
    except (OSError, AttributeError) as error:
        print(f"nihil-deck: not over Bluetooth: {error}", file=sys.stderr)
        return None
    deck.ble = {"uuid": ble_uuid(deck.pin), "psm": psm}
    threading.Thread(target=ble_serve, args=(server, listener), daemon=True).start()
    if jeepney is None:
        print("nihil-deck: listening over Bluetooth but not announced: jeepney is missing", file=sys.stderr)
    else:
        threading.Thread(target=Advert(deck.ble["uuid"]).run, daemon=True).start()
    return listener


class ControlHandler(socketserver.StreamRequestHandler):
    def handle(self):
        line = self.rfile.readline(65536)
        try:
            request = json.loads(line)
        except ValueError:
            request = None
        reply = self.server.deck.control(request)
        self.wfile.write((json.dumps(reply) + "\n").encode())


class ControlServer(socketserver.ThreadingMixIn, socketserver.UnixStreamServer):
    daemon_threads = True

    def __init__(self, path, deck):
        self.deck = deck
        if os.path.exists(path):
            os.unlink(path)
        old = os.umask(0o177)
        try:
            super().__init__(path, ControlHandler)
        finally:
            os.umask(old)


def tls_context(cert, key):
    context = ssl.SSLContext(ssl.PROTOCOL_TLS_SERVER)
    context.minimum_version = ssl.TLSVersion.TLSv1_2
    context.load_cert_chain(cert, key)
    return context


def make_server(config, folder, host="::"):
    cert, key = ensure_certificate(folder, config.get("openssl", "openssl"))
    deck = Deck(config, folder, pin_of(cert))
    context = tls_context(cert, key)
    try:
        server = DeckServer((host, deck.port), deck, context)
    except OSError:
        if host != "::":
            raise
        server = DeckServer(("0.0.0.0", deck.port), deck, context)
    deck.port = server.server_address[1]
    return server


def serve(config):
    server = make_server(config, state_dir())
    deck = server.deck
    listener = start_bluetooth(server, int(config.get("blePsm", BLE_PSM))) if config.get("bluetooth", True) else None
    path = control_path()
    control = ControlServer(path, deck)
    threading.Thread(target=control.serve_forever, daemon=True).start()

    def stop(*_):
        threading.Thread(target=server.shutdown, daemon=True).start()

    signal.signal(signal.SIGTERM, stop)
    signal.signal(signal.SIGINT, stop)
    print(f"nihil-deck: on port {deck.port}, devices paired: {len(deck.devices.listing())}", file=sys.stderr)
    try:
        server.serve_forever()
    finally:
        control.shutdown()
        if listener is not None:
            listener.close()
        try:
            os.unlink(path)
        except FileNotFoundError:
            pass
        deck.devices.flush()


def ask(request, path=None):
    with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
        connection.settimeout(5)
        connection.connect(path or control_path())
        connection.sendall((json.dumps(request) + "\n").encode())
        data = b""
        while not data.endswith(b"\n"):
            chunk = connection.recv(65536)
            if not chunk:
                break
            data += chunk
    return json.loads(data)


def qr_rows(text):
    lines = text.split("\n")
    while lines and lines[-1].strip() == "":
        lines.pop()
    while lines and lines[0].strip() == "":
        lines.pop(0)
    size = len(lines)
    rows = []
    for line in lines:
        line = line.ljust(size * 2)
        rows.append("".join("1" if line[2 * i] == "#" else "0" for i in range(size)))
    if size < 21 or size > 177 or (size - 21) % 4 != 0:
        raise ValueError(f"not a QR: {size} rows")
    return rows


def qr(uri, qrencode):
    done = subprocess.run([qrencode, "-t", "ASCII", "-m", "0", "-l", "M", uri],
                          check=True, capture_output=True, text=True, timeout=10)
    return qr_rows(done.stdout)


def clipboard_source(config):
    def paste(*arguments):
        return subprocess.run([config["wlPaste"], *arguments], stdin=subprocess.DEVNULL,
                              capture_output=True, timeout=20).stdout

    try:
        types = paste("--list-types").decode(errors="replace").split()
        if SECRET in types:
            return "secret", None
        for kind in COPIED:
            if kind in types:
                for line in paste("--type", kind).decode(errors="replace").splitlines():
                    if line.strip().startswith("file://"):
                        return "file", urllib.parse.unquote(urllib.parse.urlsplit(line.strip()).path)
        for prefix in ("image/", "video/", "audio/", "application/pdf"):
            found = [kind for kind in types if kind.startswith(prefix)]
            if found:
                kind = "image/png" if "image/png" in found else found[0]
                return "data", paste("--type", kind), kind
        for kind in ("text/plain;charset=utf-8", "text/plain", "UTF8_STRING", "STRING", "TEXT"):
            if kind in types:
                data = paste("--no-newline", "--type", kind)
                return ("data", data, "text/plain") if data else None
    except (OSError, subprocess.SubprocessError):
        return None
    return None


def vector_send(config, vector, argument=None, text=None):
    if text is not None:
        source = ("data", text.encode(), "text/plain")
    elif argument:
        path = urllib.parse.unquote(urllib.parse.urlsplit(argument).path) if argument.startswith("file://") else argument
        source = ("file", path)
    else:
        source = clipboard_source(config)
    if source is None:
        return {"error": "empty"}
    if source[0] == "secret":
        return {"error": "secret"}
    part = vector.part("out")
    try:
        if source[0] == "file":
            path = source[1]
            if os.path.isdir(path):
                return {"error": "folder"}
            if not os.path.isfile(path):
                return {"error": "empty"}
            if os.path.getsize(path) > VECTOR_MAX:
                return {"error": "big"}
            shutil.copyfile(path, part)
            name, mime = os.path.basename(path), mimetypes.guess_type(path)[0] or "application/octet-stream"
        else:
            data, mime, name = source[1], source[2], ""
            if not data:
                return {"error": "empty"}
            if len(data) > VECTOR_MAX:
                return {"error": "big"}
            with open(part, "wb") as file:
                file.write(data)
        item = vector.store("out", part, name, mime)
    except OSError:
        return {"error": "vector"}
    finally:
        if os.path.exists(part):
            os.unlink(part)
    result = {"ok": True, "kind": item["kind"], "name": item["name"], "path": item["path"]}
    if item["kind"] == "text":
        with open(item["path"], "rb") as file:
            result["preview"] = file.read(600).decode(errors="replace")
    return result


def vector_folder(config):
    return config.get("vectorFolder") or os.path.join(os.path.expanduser("~"), "Vector")


def vector_keep(config, vector, item):
    folder = vector_folder(config)
    os.makedirs(folder, exist_ok=True)
    stem, extension = os.path.splitext(item["name"])
    target = os.path.join(folder, item["name"])
    number = 2
    while os.path.lexists(target):
        target = os.path.join(folder, fit(stem, f" ({number}){extension}", 255))
        number += 1
    shutil.move(item["path"], target)
    vector.drop("in")
    return target


def vector_copy(config, vector, item):
    if item["kind"] == "text":
        command = [config["wlCopy"]]
    elif item["kind"] == "image":
        command = [config["wlCopy"], "--type", item["mime"]]
    else:
        return {"error": "kind"}
    with open(item["path"], "rb") as file:
        data = file.read()
    try:
        done = subprocess.run(command, input=data, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=10)
    except (OSError, subprocess.SubprocessError):
        return {"error": "clipboard"}
    if done.returncode != 0:
        return {"error": "clipboard"}
    vector.drop("in")
    return {"ok": True}


def vector_command(config, action, argument):
    vector = Vector(config.get("vector"))
    if action in ("send", "text"):
        result = vector_send(config, vector, *((None, argument or "") if action == "text" else (argument,)))
        if "error" in result:
            return result
        try:
            result["devices"] = ask({"op": "vector"}).get("devices", [])
        except (OSError, ValueError):
            result["devices"] = []
        return result
    if action == "status":
        item = vector.item("in")
        return {"in": dict(vector_item(item), path=item["path"], **{"from": item.get("from", "")}) if item else {"id": ""},
                "out": vector_item(vector.item("out"))}
    if action not in ("copy", "save", "open", "clear"):
        return {"error": "usage"}
    item = vector.item("in")
    if item is None:
        return {"error": "empty"}
    if action == "copy":
        return vector_copy(config, vector, item)
    if action == "clear":
        vector.drop("in")
        return {"ok": True}
    try:
        path = vector_keep(config, vector, item)
    except OSError:
        return {"error": "save"}
    if action == "open":
        try:
            subprocess.Popen([config["open"], path if openable(item, path) else os.path.dirname(path)],
                             stdin=subprocess.DEVNULL, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                             start_new_session=True)
        except OSError:
            return {"error": "open", "path": path}
    return {"ok": True, "path": path, "kind": item["kind"], "name": os.path.basename(path)}


def main():
    parser = argparse.ArgumentParser(prog="nihil-deck", description="Your devices as a deck for this computer (docs/deck.md).")
    parser.add_argument("--config", help="configuration written by home/deck/default.nix")
    parser.add_argument("command", nargs="?", default="devices",
                        choices=["serve", "pair", "cancel", "devices", "forget", "allow", "deny", "vector"])
    parser.add_argument("target", nargs="?", help="forget: a device's id, or all; cancel: the invite to close (every one "
                                                  "without); vector: send, text, copy, save, open, clear or status")
    parser.add_argument("argument", nargs="?",
                        help="vector send: a file (the clipboard without one); vector text: the text, or - to read it")
    parser.add_argument("--json", action="store_true", help="for the shell")
    options = parser.parse_args()

    config = {}
    if options.config:
        with open(options.config) as file:
            config = json.load(file)
    for key, command in (("ipc", "nihil-ipc"), ("volume", "osd-volume"),
                         ("notify", "notify-send"), ("openssl", "openssl"), ("qrencode", "qrencode"),
                         ("rsvg", "rsvg-convert"), ("ip", "ip"), ("wpctl", "wpctl"),
                         ("wlCopy", "wl-copy"), ("wlPaste", "wl-paste"), ("open", "xdg-open")):
        config.setdefault(key, shutil.which(command) or command)

    if options.command == "serve":
        serve(config)
        return 0
    if options.command == "vector":
        argument = options.argument
        if options.target == "text" and argument == "-":
            # From stdin: no limit of an argument's 128 KiB, and nothing in /proc for others to read.
            data = sys.stdin.buffer.read(VECTOR_MAX + 1)
            if len(data) > VECTOR_MAX:
                print(json.dumps({"error": "big"}))
                return 1
            argument = data.decode("utf-8", "replace")
        result = vector_command(config, options.target, argument)
        print(json.dumps(result))
        return 1 if "error" in result else 0

    request = {"pair": {"op": "pair"}, "cancel": {"op": "cancel", "invite": options.target or ""}, "devices": {"op": "devices"},
               "forget": {"op": "forget", "id": options.target or ""}, "allow": {"op": "allow", "id": options.target or ""},
               "deny": {"op": "deny", "id": options.target or ""}}[options.command]
    if options.command == "forget" and not options.target:
        print("Usage: nihil-deck forget ID|all", file=sys.stderr)
        return 2
    try:
        reply = ask(request)
    except (OSError, ValueError):
        print("The deck is not running (systemctl --user status nihil-deck).", file=sys.stderr)
        return 1

    if options.command == "pair":
        try:
            reply["qr"] = qr(reply["uri"], config["qrencode"])
        except (OSError, ValueError, subprocess.SubprocessError) as error:
            reply["qr"] = []
            if options.json:
                reply["error"] = str(error)
        if options.json:
            print(json.dumps(reply))
        else:
            for row in reply["qr"]:
                print("".join("██" if module == "1" else "  " for module in row))
            print(reply["uri"])
            print(f"Valid until {time.strftime('%H:%M', time.localtime(reply['expires']))}, once.")
        return 0
    if options.command == "devices" and not options.json:
        for device in reply.get("devices", []):
            seen = time.strftime("%Y-%m-%d %H:%M", time.localtime(device.get("seen") or 0))
            over = ", over Bluetooth" if device.get("bluetooth") else ""
            print(f"{device['id']}  {device['name']}  (last seen {seen}{over})")
        return 0
    if options.json or options.command == "devices":
        print(json.dumps(reply))
    elif options.command == "forget" and not reply.get("ok"):
        print(f"No device {options.target}.", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
