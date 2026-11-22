# Keys, commands and options

## Options

Under `nihil.*`, across [`modules/`](../modules). A machine's `settings.json` sets those with
a key in the last column ([`modules/settings.nix`](../modules/settings.nix)); its `local.nix`
sets any of them, those without one only there.

| Option          | Default    | What it does                                                    | `settings.json` |
|-----------------|------------|-----------------------------------------------------------------|-----------------|
| `user.name`     | `"nihil"`  | The account of the person using the machine                     | `user.name`     |
| `user.fullName` | `""`       | Their name, as the greeter and the welcome say it               | `user.fullName` |
| `user.greeting` | Its first word | The name the greeter uses                                   | —               |
| `language`      | `"en"`     | `"es"` or `"en"`: shell, lock screen, greeter, script messages and their dates | `language` |
| `outputs`       | —          | Screens of the host, by connector: `width` and `height`, the mode's pixels after rotation and before the scale; `bar`, whether it has the bar; `pitch`, between dots (`9`); and Hyprland's `mode` (`"preferred"`), `position` (`"auto"`), `scale` (`1`) and `transform` (`0`) | `outputs` |
| `primaryOutput` | A laptop's panel, else the first | Screen for the desktop widgets, lock and login backgrounds | `primaryOutput` |
| `wallpaper`     | `"night"`  | Default wallpaper, by name: its file's without the extension, with spaces and accents made plain (`Captura de pantalla.png` is `Captura-de-pantalla`) | `wallpaper` |
| `extraWallpapers` | `[ ]`    | More folders of pictures, drawn as dots too; a machine's `local.nix` adds its `/etc/nixos/wallpapers`. A picture with the name of one of NIHIL's takes its place | — |
| `binds`, `gestures` | See [Keybindings](#keybindings) | Keys and touchpad fingers for NIHIL's actions; `null` turns one off | `binds`, `gestures` |
| `programs`      | Terminal, Files, Zen | Programs with a key: a name, the command that opens it and its keys ([Keybindings](#keybindings)) | `programs` |
| `clipboard`     | `8`        | How many copies the clipboard history keeps; `0` turns it off   | `clipboard`     |
| `generations.days` | `7`     | How long generations stay: the weekly clean removes older ones, but the one in use and the one in use that many days ago | `generations.days` |
| `bootSound`     | `true`     | A sound with the boot splash, unless the session was left muted | `bootSound`     |
| `fingerprint`   | `false`    | The fingerprint reader for sudo, polkit and the greeter (fprintd) | `fingerprint` |
| `greeter`       | `"nihil"`  | The login screen: NIHIL's own (`greeter/shell.qml`), with ReGreet in its place should it not start, or `"regreet"` alone | — |
| `trayHidden`    | `[ "nm-applet" "blueman" ]` | Tray items to hide, by part of their id or title. The Wi-Fi and Bluetooth applets keep running for password and pairing prompts | — |
| `nilo.enable`   | `false`    | Nilo, the assistant, and Ollama to run its model ([Nilo](nilo.md)) | `nilo.enable` |
| `nilo.acceleration` | `"cpu"` | `"cpu"`, `"vulkan"`, `"rocm"` or `"cuda"`: what runs the model | `nilo.acceleration` |
| `nilo.integratedGpu` | `false` | Let Ollama use an integrated GPU (it leaves them out by default) | `nilo.integratedGpu` |
| `nilo.models`   | Qwen 3.5, 0.8B to 35B-A3B | Models offered in Nilo's settings                   | —               |
| `nilo.loadedModels` | `1` | Models Ollama keeps in memory at once; `2` lets the automatic choice switch without reloading | — |
| `nilo.contextLength` | `16384` | Context window, in tokens                                     | —               |
| `nilo.searxng`  | `null`     | A SearXNG instance for web searches instead of DuckDuckGo       | —               |
| `nilo.coauthor` | [nilo-nihil](https://github.com/nilo-nihil) | Who Nilo signs its commits as (`Co-authored-by`); `null` for no trailer | — |
| `deck.enable`   | `false`    | Devices as decks ([Devices](devices.md)): its service, its port in the firewall, its announcement on the network (mDNS), uinput for the trackpad | `deck.enable` |
| `deck.interfaces` | `[ ]`    | The network interfaces where the deck is reached and announced; every one when empty | `deck.interfaces` |
| `deck.port`     | `64445`    | The deck's HTTPS port ("NIHIL" on a phone's keypad)             | —               |

`settings.json` also has the computer's name (`host.name`), `locale`, `timeZone`,
`keyboard` (`layout`, `variant`, `model`), `ssh` and `sshKeys` ([Install](install.md)). A key
it doesn't know makes the rebuild warn.

Read-only: `tokens` (the design tokens), `strings` (the selected language), `sounds`,
`wallpapers` and `fonts`. To add a language, add a block to
[`theme/i18n.nix`](../theme/i18n.nix) and its code to the `language` enum.

---

## Keybindings

| Keys                              | Action                                        |
|-----------------------------------|-----------------------------------------------|
| `SUPER + Space`, 3 fingers up     | Launcher (`>` actions, `=` calculator; also by resting the pointer on the bottom edge) |
| `SUPER + I`, the Copilot key      | Nilo (also `?` in the launcher)               |
| `SUPER + D`                       | Dashboard (also by hovering the top edge)     |
| `SUPER + P`                       | Settings panel (or rest the pointer in the top-right corner) |
| `SUPER + K`                       | Lock                                          |
| `SUPER + O`                       | Preferences (also the cog in quick settings, and `>` in the launcher) |
| `SUPER + W`                       | Wallpapers, out of the bottom edge, each shown as it's reached. Held as `SUPER + A`: `W` again the next, `SHIFT + W` the one before, letting go of `SUPER` keeps it; let go first and it stays, for the arrows, Enter, Escape or a click |
| `SUPER` (alone)                   | Terminal (kitty), a program                   |
| `SUPER + E / X`                   | Files (Thunar) and Zen, programs too          |
| `SUPER + C` / `SUPER + V`         | Copy / paste; `SUPER + V` held, the clipboard history (`V` again for the next one, let go to paste, `Esc`: none) |
| `SUPER + Q`, 3 fingers down       | Close window                                  |
| `SUPER + SHIFT + Space`           | Toggle floating                               |
| `SUPER + F` / `SUPER + SHIFT + F` | Maximise / fullscreen; 3 fingers spread maximise, together put it back |
| `SUPER + arrows`                  | Move focus                                    |
| `SUPER + 1…0`                     | Workspace (`SHIFT` moves the window there)    |
| `SUPER + Tab`, 3 fingers sideways | Next workspace / switch workspaces            |
| `SUPER + A`                       | All workspaces, with their windows over the wallpaper. Held as `SUPER + V`: `A` again chooses the next, `SHIFT + A` the one before, letting go of `SUPER` goes there; let go first and it stays, for the arrows, Enter, Escape or a click (a click on a window goes to it) |
| `SUPER + Escape`, 4 fingers       | Scratchpad (`SUPER + SHIFT + Escape` sends the window) |
| `SUPER + H`                       | Colour picker                                 |
| `Print` / `SHIFT + Print`         | Screenshot of the screen the pointer is on, kept in Pictures (Screenshots, or Capturas in Spanish) and copied / record it |
| Snipping key / `SHIFT` with it    | Screenshot of an area, kept and copied / record it (`XF86SelectiveScreenshot`; another key in Preferences, Shortcuts). Recordings go to Videos and are copied as a file; either key stops them (also in the quick settings) |
| Volume, brightness, mic keys      | Change the value and show the OSD             |

Scrolling over the bar switches workspaces (on the LEDs) or changes the volume (on the
status icons).

These are the defaults. Preferences (Shortcuts) changes the keys of NIHIL's actions and
the programs with a key of their own: a name, the command that opens it and its keys, to
edit, remove or add. A machine keeps them in its `settings.json`, by the names in
[`modules/binds.nix`](../modules/binds.nix): `binds`, a new combination for an action or
`null` for none; `programs`, the whole list, which replaces NIHIL's; and `gestures`, the
fingers of each one or `null` for none, which only change there.

```json
"binds": { "screenshot": "SUPER + SHIFT + S", "colourPicker": null },
"programs": [
  { "name": "Terminal", "exec": "kitty", "keys": "SUPER + Super_L" },
  { "name": "Files", "exec": "thunar", "keys": "SUPER + E" },
  { "name": "Zen", "exec": "zen-beta", "keys": "SUPER + X" },
  { "name": "Spotify", "exec": "spotify", "keys": "SUPER + M" }
],
"gestures": { "close": null, "launcher": null, "special": 3 }
```

The actions: `launcher`, `dashboard`, `panel`, `settings`, `wallpapers`, `copy`,
`clipboard`, `nilo`, `colourPicker`, `lock`, `close`, `float`, `maximize`, `fullscreen`,
`special`, `toSpecial`, `nextWorkspace`, `overview`, `screenshot`, `snip`. While the clipboard history is out
the window keeps the keyboard and the history's keys come through Hyprland; letting go of
one of its key's modifiers pastes: any combination works (`CTRL + V` too, if you want it
on the paste key itself, at the cost of `CTRL + V` in the terminal; one without a
modifier takes the keyboard and waits for `Enter`). The gestures: `workspaces`, `close`,
`launcher`, `maximize`, `special`. Workspaces, focus, media keys and the mouse stay as they are.
`terminal`, `files`, `browser`, `notes`, `code`, `music` and `pixels` were actions and
are programs now: a `settings.json` that still names them under `binds` is read without
them.

---

## Shell

The shell lives in [`home/shell/`](../home/shell) and runs as the `nihil-shell` user
service. [`home/shell.nix`](../home/shell.nix) generates `Tokens.qml`, `Config.qml` and
`Lang.qml` from the Nix side and references every external program by its store path.

```bash
nihil-ipc drawers toggle launcher     # launcher | dashboard | panel | wallpapers; also: open <name>, close
nihil-ipc osd volume 40 false
nihil-ipc glyph test true             # light the frame (critical = red)
nihil-ipc glyph charge                # the charger's light, rising from the bottom
nihil-ipc glyph progress <id> 0.4     # work that takes a while; then done, failed or clear <id>
nihil-ipc notifs toggleDnd            # also: hide (the popups, keeping the list), clear
nihil-ipc nilo toggle                 # also: open, sleep, ask "…" (the chat says who asked), state, reset
nihil-ipc caffeine toggle             # also: on, off, status
nihil-ipc toggles state               # caffeine and the night light, as JSON
nihil-ipc night level 40              # the night light at 40 %; also: toggle, on, off, status
nihil-ipc tasks add "Hand in the lab" # also: list
nihil-ipc battery warn 10             # show the low-battery warning
nihil-ipc settings open               # Preferences; also: toggle, close, page keys, welcome, wallpapers, glass on|off, look
nihil-ipc widgets arrange             # move the desktop widgets; also: done, cancel (what Enter and Esc do), list (which are on, where and how big, as JSON)
nihil-ipc widgets photo /path/to.jpg  # a photo widget's picture, from a whole path: one with none, else a new one
nihil-ipc clipboard open              # the history; also: next, previous, released, paste, cancel
nihil-ipc apps list                   # the launcher's apps, as JSON; also: launch <id>, url <https://…>
nihil-ipc media toggle                # also: next, previous, now (what plays, as JSON)
nihil-ipc session lock                # the lock screen
nihil-ipc recorder status             # whether it records; started and stopped are the recorder's own
nihil-ipc vector received             # the deck, when the phone has sent something; reload, quietly
nihil-wallpaper next                  # also: prev, set <name>, list, current, restore, glass [on|off]
nihil-calendar list                   # the calendars, without their addresses; also: sync, remove <id>,
                                      # add (the address on stdin: an argument shows in /proc)
journalctl --user -u nihil-shell -f   # logs
```

| Folder        | Contents                                                        |
|---------------|-----------------------------------------------------------------|
| `frame/`      | Frame geometry (one path with the drawers as bumps), Glyph light, bar |
| `drawers/`    | Dashboard, quick settings, launcher, wallpapers, clipboard history, OSD, notifications |
| `background/` | Desktop widgets                                                 |
| `services/`   | Audio, network (nmcli), Bluetooth, battery, MPRIS, IPC, system stats, tasks, caffeine, clipboard, Nilo, the machine's settings (`Machine.qml`), its generations, the deck and Vector |
| `settings/`   | Preferences and the welcome                                     |
| `components/` | LEDs, dials, segmented sliders, dot-matrix image, keys and buttons, switches, choices, fields, text, a QR in dots |
| `nilo/`       | Nilo: the eyes, the conversation, the introduction and its settings |
| `theme/`      | The shell's Nerd Font glyphs; `Tokens.qml` is generated here |
