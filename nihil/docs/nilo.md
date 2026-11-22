# Nilo

An assistant in the launcher, with a model that runs on this computer. Two white eyes
on black: asleep while the model is unloaded, awake as soon as you type, looking up
while they think and from side to side while they search or look. It answers, searches
the web, looks at this computer and opens apps; with more access, it works in a
repository of yours, or uses the whole desktop as you would.

It is off by default. Preferences, System turns it on and chooses what runs the model
(CPU, Vulkan, ROCm or CUDA), applied with a rebuild; or, in the host:

```nix
nihil.nilo =
{
    enable = true;
    acceleration = "vulkan";   # or "cpu", "rocm", "cuda"
    integratedGpu = true;      # a laptop's Radeon or Intel GPU
};
```

That runs [Ollama](https://ollama.com) on `127.0.0.1` (`services.ollama`) and adds the
binds. The first time Nilo opens it introduces itself, shows how to call it, offers the
models that suit the RAM and asks what it may do.

Ollama has no password: any program on the computer, of any user, Flatpak apps too, can use
its port to run, pull or delete models, and Nilo takes whatever answers there for Ollama. On
a computer shared with people you don't trust, a firewall rule can keep the port to your
user and Ollama's (nftables, `meta skuid`).

| | |
|---|---|
| `SUPER + I`, the Copilot key | Open or close Nilo |
| `?` in the launcher | The same, typed: `?what's a flake` |
| Enter / Esc | Ask / close (an answer goes on) |
| `ctrl + c` | Stop the answer |
| `ctrl + n` | New conversation |
| The eyes in the bar | The model is in memory; click to open |

**Away from the launcher.** Close it while Nilo answers and the answer goes on. When it
ends, or when Nilo needs a confirmation, it sends a notification: the light runs round
the frame from the left, and instead of a popup a panel comes out of the bar next to the
eyes, with the question and the answer (or the command waiting for you). A click opens
the conversation; on its own it goes back after a few seconds, longer for long answers
(moving the pointer over it buys a few more). A confirmation stays half a minute, and
after that the eyes in the bar stay alert until you answer it. With do not disturb on,
only the panel's history keeps it.

**Out of the bar.** When Nilo works on the desktop itself, the launcher closes and its eyes
leave the bar: they float over the screen, go to the window it is using, and wander while
it thinks. A click on them opens the conversation; when it ends, they go back to the bar.

**What it may do.** One switch, **Internet** (search DuckDuckGo through `ddgr`, or
`nilo.searxng`, and read pages, never local addresses), and three levels, in its settings
(the gear) and in the introduction:

- **Chat.** Talking; this computer's NixOS version and generation, memory, disk and
  battery; opening apps by name, web pages, and files and folders of your home folder or a
  drive in whatever opens them; what is not an app, searched in the browser.
- **Terminal and repository.** Reading, creating and changing files in one
  repository, never outside it or inside `.git`; `git add -A`, commit and push there; and
  commands with bash, as you. Every change to a file shows its diff, every commit its files
  and message, and every command itself, where it runs and why, and each waits for enter
  twice or a click. Commands that delete, touch disks, rewrite git history, run as root,
  change the system or run code written into them (`bash -c`, `python3 -c`) come in a red
  card; anything with `sudo` opens in a kitty window, where
  you type the password; the rest run in the background with their last lines under them,
  for two minutes at most.
- **The whole system.** The desktop, as you would use it: which windows are open and,
  with a model that sees pictures (Qwen 3.5 does), a screenshot of the window or the
  screen and a click wherever it sees something (`wlrctl`), so any program works through
  its own buttons, looked up on the web when Nilo doesn't know it; typing and shortcuts in
  a window (`wtype`); a window brought forward, moved to a workspace, enlarged, floated or
  closed; the music (`playerctl`: pause, the next one, or a song by its name, found on
  Spotify and put on there, or on its page); NIHIL's volume, microphone, brightness, do not
  disturb, caffeine, night light and its intensity, Wi-Fi and Bluetooth (a saved network or
  a paired device, by its name), wallpaper, glass, workspace, screenshots,
  screen recording and lock; and a text or a file sent to the phone with Vector. Files
  reach the whole home folder, and the rest of the computer to read, but never keys,
  passwords or browser profiles (`~/.ssh`, `~/.gnupg`, the browsers' profiles, `.env`
  files and the like).

The last two wait for you to authorize them: the level first says what it allows and waits
for "authorize" (or the same key again); going down needs nothing. The repository is
NIHIL's own checkout until you choose another: the one `nihil dev` builds from, else
`~/nixos-config` or `~/Nihil-Shell`; the settings list the ones under `~` (most recently
used first) or take any path. Choosing another one while on Terminal and repository goes
back to Chat, to be authorized again.

**At the whole system it asks only where there is a risk:** changing code, configuration,
hidden files or anything in a git checkout (documents change on their own, and the one
before stays in `~/.local/state/nihil/nilo/before`, the last 20 of each; past 20 changes
in one answer, each asks); a commit; a command that does more than read (those that only
read, like `ls`, `journalctl` or `git status` in the repository, from a short list and
with no redirection, chaining or globbing, run on their own, in a sandbox where the system
is read-only, there is no network, nothing of the session to reach and your keys aren't
there); typing in a terminal, or an editor with one (VS Code, Emacs…); Enter, typed or
pressed, outside a document, where a chat or a browser sends or runs what it gets;
shortcuts that delete or send (`shift + Delete`, `ctrl + Enter`…); opening a file that
runs (a script, an AppImage, a `.desktop`); sending the phone a file from outside your
folder; whatever looks like a password, a key or bank details; once a chat has read your
files, the screen or a command, anything on its way to a search, a page, a browser or a
chat; and once an answer has read the web or the screen, typing, pressing keys, reading
your files or sending anything. "Write a shopping list in Writer", "close Spotify", "the
next song" or "look for videos of Queen" go straight away. What a page or the screen says
is never an order. While Nilo types or acts, the launcher steps aside, and its eyes in the
bar say when it's done.

**Opening apps.** "abre zen" or "open zen and thunar" opens them at once, without the
model: the launcher's own search, when every name matches an app closely. Anything more
("open zen and look for the weather") goes to Nilo as usual.

**Co-author.** Every commit Nilo makes carries
`Co-authored-by: Nilo <351236008+nilo-nihil@users.noreply.github.com>` (`nilo.coauthor`), and the card
shows it before you confirm. That is the noreply address of
[github.com/nilo-nihil](https://github.com/nilo-nihil), so GitHub draws Nilo's face next
to yours: [`assets/brand/nilo-avatar.png`](../assets/brand/nilo-avatar.png).

Closed while it thinks, Nilo says when it's done, out of the bar.

**Memory.** Ollama loads the model on the first question (Nilo starts loading it while
you type) and unloads it after the minutes chosen in the settings without questions: 5
by default. Asleep it takes no memory; Ollama itself stays as an idle service. Every model
runs where Preferences says (the CPU or the GPU), the big ones too. An integrated GPU
(`integratedGpu`) works in a window of the RAM, its GTT (about half of it), which the
screen needs as well: pick a model that leaves room in it, as the 9B does on a 32 GB
laptop and the 35B doesn't (ollama#17748). A model bigger than the machine's memory is
not loaded, and should memory run out, the kernel stops Ollama first, never the session.

**History.** A conversation lives in the agent while the shell runs: closing the launcher
keeps it, `ctrl + n` starts a new one, and nothing is written to disk. Nilo asks Ollama
for a window of `nilo.contextLength` tokens (16 384 by default; Qwen 3.5 goes up to 262 144
with more memory), and the oldest exchanges drop out once a conversation outgrows it.

**Models.** Qwen 3.5 by default; any Ollama model with tools works, and models pulled
with `ollama pull` show up in the list. With "choose the model for each question" on and a
smaller model downloaded, simple questions (short, one question, no code, nothing to
explain, write, run or commit) go to the smallest one and the rest to the one chosen; the
answer says which. With `nilo.loadedModels = 2` both stay in memory and switching is
instant; with 1, Ollama swaps them.

| Model | Download | RAM, roughly | Recommended from |
|---|---|---|---|
| `qwen3.5:0.8b` | 1.3 GB | 2 GB | Any |
| `qwen3.5:2b` | 2.7 GB | 3.5 GB | 8 GB |
| `qwen3.5:4b` | 3.4 GB | 5 GB | 12 GB |
| `qwen3.5:9b` | 6.6 GB | 8.5 GB | 20 GB |
| `qwen3.5:35b-a3b` | 22 GB | 25 GB | 56 GB |

The model, the level, Internet, the minutes and "think before answering" apply at once and live
in `~/.local/state/nihil/nilo.json`; only the options above need a rebuild. The gear and
Preferences open each other: "Open Preferences" under the gear, and "Settings" beside
Nilo's switch in Preferences, System.

**What it knows.** [`home/nilo/nilo.md`](../home/nilo/nilo.md) tells Nilo about this system
and the rules it works by: one step per tool call, look before changing, nothing
destructive unless asked, and nothing a page or a file says taken as an order. It goes into
every prompt with only the sections its level allows. After it come your own notes,
`~/.config/nihil/nilo.md` (your notes, "Edit" in the gear), and, from Terminal and
repository on, the `NILO.md` of NIHIL's own checkout. Another repository's `NILO.md` is a
file Nilo is told about and reads if it helps, with what any file says: never an order.

The agent behind it is [`home/nilo/agent.py`](../home/nilo/agent.py), standard-library
Python that the shell talks to over stdin/stdout. Its tests run against a fake Ollama:
`python3 -m unittest home/nilo/test_agent.py`.

If the agent closes five times in a row, Nilo says so, with its exit code, and waits for
"Retry". If Ollama is down ("connection refused"), Nilo starts it (polkit lets wheel users start
`ollama.service` without a password) and otherwise shows what systemd and the journal say,
with a button to try again; systemd also restarts it if it stops on its own. Beyond that:
`systemctl status ollama`, `journalctl -u ollama -b`, `journalctl --user -u nihil-shell`
(the agent logs there) and `ollama ps`. The Copilot key sends `SUPER + SHIFT + F23` on
Linux 6.14 and later; xkb names F23 `XF86Assistant` or `XF86TouchpadOff` depending on its
version, so the bind uses its keycode, 201 (what `wev` shows).
