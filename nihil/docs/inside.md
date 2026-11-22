# Inside NIHIL

## Structure

```
Nihil-Shell/
├── flake.nix, flake.lock, home.nix   nihil.lib.mkSystem, the module, the ISO
├── theme/            Design system: tokens, i18n, fonts, wallpaper and boot renderers
│   ├── nihil.nix     palette, base16, fonts, frame geometry, motion
│   ├── i18n.nix      every string, per language
│   ├── dotmatrix.py  photo → LED matrix (wallpapers.nix runs it per output)
│   ├── plymouth.*    boot splash frames and theme
│   ├── qml.nix       Tokens.qml and Lang.qml, for the shell and the greeter
│   └── art/          LED maps of the NixOS snowflake (19 for fastfetch, 29 for boot)
├── modules/          system modules (default.nix gathers them; settings.nix reads settings.json)
├── installer/        the ISO, nihil-install and gui/ (the installer's window, in Quickshell under cage)
├── templates/        machine/: what the installer writes to /etc/nixos; example/: CI's machine
├── home/             Home Manager: shell/, nilo/ (Nilo's agent), deck/ (the phone's), hyprland, hyprlock, …
├── greeter/          the login screen, in Quickshell under cage (modules/greeter.nix)
├── sounds/           interface sounds (nihil/ is the NIHIL pack)
├── assets/brand/     logo and mark (SVG), social preview
├── docs/             the website, served by GitHub Pages from this folder; deck.md, the deck's protocol
│                     assets/screens: the desktop as it comes, glass/ the same in smoked glass, android/ the phone's
├── .github/          release.yml: the ISO in Releases; update.yml: the inputs, every week;
│                     auto-pull-request.yml: a push to any other branch, as a pull request into nihil
└── wallpapers/       source photos, rendered as dots at build time
```

---

## Technical details

- **Filesystem:** btrfs with subvolumes (`@`, `@home`, `@nix`, `@log`), zstd compression
  and `noatime`. Swap via zram.
- **Boot:** UEFI + systemd-boot with a systemd initrd and the NIHIL Plymouth theme
  (frames rendered at build time from `theme/art/snowflake-29.txt`). Its sound
  (`sounds/nihil/boot.wav`, the power-off notes going up) plays through ALSA once the
  sound card is up and while the splash is still there: PipeWire only starts with the
  session (`modules/boot-sound.nix`). The snowflake's LEDs wait unlit for it and switch on
  as it starts (`plymouth update --status=nihil-open`), the last of them with its last
  note; without it, they don't wait.
- **Login:** greetd + NIHIL's greeter (`greeter/shell.qml`, Quickshell) in cage, with every
  screen on and the greeter on the main one (`nihil.primaryOutput`, else the computer's own
  panel), with the shell's tokens and strings. If it isn't up within ten seconds,
  ReGreet takes its place, themed by Stylix plus NIHIL CSS; `nihil.greeter = "regreet"`
  keeps ReGreet alone.
- **Hyprland in Lua:** the whole configuration is declared in Nix and Home Manager
  generates `hyprland.lua`. Under Lua, dispatchers are Lua too
  (`hl.dsp.focus({ workspace = "e+1" })`); Quickshell 0.3 detects it (`Hyprland.usingLua`).
  Stylix's Hyprland target is off: NIHIL sets the colours itself.
- **Quickshell and Hyprland focus:** drawers that take the keyboard use
  `WlrKeyboardFocus.OnDemand` together with a `HyprlandFocusGrab`. `Exclusive` would not
  work: Hyprland drops every focus grab when a layer becomes exclusive. The clipboard
  history takes none: while it is out its keys come through a Hyprland submap
  (`nihil-clipboard`) and the window keeps the keyboard; only a paste key without a
  modifier makes the frame `Exclusive` until it pastes.
- **Charger:** plugging it in lights the frame from the bottom and plays `charge`, three
  climbing notes.
- **Battery:** the shell reads it through UPower, which `modules/nihil.nix` enables. At
  15, 10 and 5 % it sends a critical notification, once per threshold and discharge; each
  one replaces the last (`x-nihil-tag` hint) and plugging in the charger dismisses it.
- **Notifications:** a popup lasts what its app asks for (`notify-send -t`, at most 30 s)
  or 5 s, and critical ones 15 s; the pointer on a popup holds it, and every notification
  stays in the panel's history. Quickshell hands the timeout on in milliseconds, although
  its documentation says seconds.
- **Caffeine:** while it is on, every frame window holds a Wayland idle inhibitor, which
  hypridle honours: no dimming, no lock, no screen off, no suspend on its own. Closing the
  lid still suspends. It starts off with every session.
- **Lid:** closing it suspends the laptop, on the charger too, locked first. With another
  screen connected logind leaves it awake: the laptop's panel turns off and the session
  goes on on the other screen (`modules/hardware.nix`, and the lid binds in
  `home/hyprland.nix`). A machine changes it in `local.nix`, for instance
  `services.logind.settings.Login.HandleLidSwitchExternalPower = "lock";`.
- **Tasks:** the kanban lives in `~/.local/state/nihil/tasks.json`; edit it by hand and the
  board follows. Each card keeps when its text and its place (its column and its rank there)
  were last set: that is how it merges with the phone's.
- **Lock screen media:** [`home/lock/media.sh`](../home/lock/media.sh) asks the players
  (playerctl) at most once a second and hyprlock's labels read the result; covers are
  drawn as dot matrices by [`home/lock/cover.py`](../home/lock/cover.py) and cached in
  `$XDG_RUNTIME_DIR`. The background has a variant with the player's panel baked in, and
  hyprlock asks which one every two seconds (`media.sh backdrop`). The cursor stays visible on
  the lock screen so the buttons can be clicked; the media keys work as well.
- **Viewers:** imv, mpv and Zathura are installed without their own desktop entries, so
  nothing of theirs reaches the launcher; three of NIHIL's, hidden, open pictures, videos
  and music, and documents, and are the defaults for them (`home/viewers.nix`). A picture
  goes to imv with the others of its folder, starting at it.
- **Pre-existing files:** if a file Home Manager wants to manage already exists, it is
  renamed to `*.hm-backup` instead of aborting the activation.
- **Own scripts:** packaged with `writeShellScriptBin` and explicit dependencies:
  `osd-volume`, `osd-brightness`, `osd-mic`, `mic-led-sync`, `lock-screen`, `power-off`,
  `nihil-wallpaper`, `nihil-ipc`.
