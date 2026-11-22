# Devices: phone, tablet and watch as decks

[NIHIL for Android](https://github.com/poligle/Nihil-Launcher), the launcher, can be a deck for the computer:
its apps and web pages open here, its music plays and skips, its volume goes up and down,
its screen locks and its pointer moves, from the phone, and Vector carries things between them. That is all it can do: an app is one
the launcher shows, a page is `http` or `https`, the trackpad points and clicks as a touchpad
here would, Vector has only what was sent to it, and there is no way to run a command or read a file.

On the wrist, [NIHIL for Wear OS](https://github.com/poligle/Nihil-Wear) makes the watch one more deck: its
music, its volume on the bezel or the crown, its caffeine, night light and lock, from a watch face
in dots. It pairs over adb with the same code the QR holds. Preferences, Devices, **Install on a
watch** (or `nihil watch`) does it all from here, with nothing to clone or build: it finds the
watch's Wireless debugging on the network, so only the code the watch shows is typed, installs
the latest release with its face (checked against its SHA-256), hands the watch the invitation
and turns on its light on the edge. `nihil watch update` brings a newer release, `nihil watch
forget` unpairs it.

Preferences, Devices turns it on (a rebuild: the service, its port in the firewall and its
name on the local network) and pairs a phone with a QR. The QR holds the computer's
addresses, a one-time code (once, for five minutes) and the pin of its certificate: the
phone talks HTTPS only to the computer whose public key it was shown, and pairing gives it
a token of its own. The computer keeps only the token's hash, says when a phone pairs, and
lists the phones, each to forget. When its address changes, the phone finds it again by
mDNS (`_nihil-deck._tcp`).

On the phone the deck is one landscape screen in workspaces: the music and the volume in one;
the apps and the webs in the next, each with its icon; the trackpad in the last. Above them, this computer's caffeine,
night light and lock, with the desktop's own icons and lit while on. The apps' come from this
computer's icon theme; the webs' (`GET /v1/favicon`) are found by this computer on each site,
only at public addresses and kept a week, so the phone talks to no one else. The phone reads
the QR with a reader of its own, and sharing a web to *Open on the computer* opens it here. It
shows the cover of what plays, and keeps the dashboard's kanban in sync with its own, the
order of each column too: each side goes on when they are apart, and the next sync keeps what
both did (`docs/deck.md`).

Vector carries one thing at a time, 100 MB at most: a text, a picture, a video or any file.
Paste it on the dashboard's Vector (`CTRL + V`, or a click: what the clipboard holds, a file
copied in Thunar too), or drag it to the top of the screen, where the dashboard opens, and drop
it there: it shrinks away to the phone, and a notification says to which. On the phone it waits
in Tasks, above the kanban, with a notification. What the phone sends (from its Vector, a tap
to pick a picture or a file, or **Vector** in the share sheet) waits on the dashboard the same
way: copy it, save it in `~/Vector` or open it from there, and its place is empty again. Each
side keeps only the last one, and what a password manager copies is not sent.
`nihil-deck vector send FILE | text TEXT | copy | save | open | clear | status` does the same
from a terminal.

The trackpad is a touchpad here (`GET /v1/trackpad`). The phone streams its fingers, every
sample with its time, and the deck writes them to a touchpad it makes with uinput (`NIHIL deck
trackpad`), as wide and tall as the phone's screen: libinput reads it as it reads the laptop's,
with the same settings, so a tap clicks, two fingers right-click and scroll, three
middle-click, a pinch zooms and the touchpad gestures run. The frames keep the phone's pace,
25 ms late, and the touchpad goes when the stream does. With the deck on, uinput is the
session's to use (a udev rule, `uaccess`), and libinput takes the touchpad as an external one,
so it works with the lid closed.

The service is [`home/deck/deck.py`](../home/deck/deck.py), standard-library Python in the
user's session, which opens what it is asked through the shell (`nihil-ipc apps`,
`nihil-ipc media`) and the volume and lock as the keys do. The protocol, for the phone's
side, is in [`docs/deck.md`](deck.md). Its tests run a real HTTPS server on
`127.0.0.1` with fake programs: `python3 -m unittest home/deck/test_deck.py`.

```bash
nihil-deck pair                       # the QR in the terminal, and its URI
nihil-deck devices                    # the devices paired; forget ID|all
systemctl --user status nihil-deck    # the service; journalctl --user -u nihil-deck
```
