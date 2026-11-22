# What's in it

- **Frame and bar.** One black shape around every screen. Its left side widens into the
  bar: NixOS mark, workspaces as LEDs, the active app, tray, status, a 10-LED battery
  gauge, the clock in dots and a red privacy LED while something records the mic.
- **Drawers.** The dashboard, the quick settings and the launcher are bumps of the frame
  itself, with concave joints, so they look like part of the hardware.
- **Dashboard.** Time, music with the cover rendered as a dot matrix and a spectrum in
  LED columns, CPU/RAM/temperature dials, a network oscilloscope, a kanban (to do, doing,
  done: drag a card where it goes, its pencil writes it again, a broom clears the done ones),
  and Vector, a box in LEDs: paste or drop on it a text, a picture, a video or any file and
  it shrinks away to the phone; what the phone sends waits there, to copy, save or open.
- **Calendars.** Read-only subscriptions by their secret iCal address, added in Preferences,
  Appearance: in Google Calendar, a calendar's settings, “Secret address in iCal format”; in
  Outlook, Settings, Calendar, Shared calendars, “Publish a calendar”, its ICS link; in
  iCloud, a public calendar's link; in Nextcloud, “Copy subscription link”. No account and
  no app to register: whoever has the address reads the calendar, so it's kept in
  `~/.config/nihil/calendars.json`, readable by you alone, and never in `settings.json`,
  which ends in the Nix store. While the calendar widget is on, they're read every quarter of
  an hour, a month back to two ahead, repeats and time zones included (`home/calendar`); an
  event in two of them, as an invitation is in the organiser's calendar and in yours, shows once.
- **Quick settings.** Circular toggles (caffeine among them, which keeps the screen from dimming,
  locking or sleeping; the night light, with its intensity, and do not disturb, both as you
  left them), segmented sliders, Wi-Fi (with passwords and WPA-Enterprise hand-off),
  Bluetooth, as you left it through restarts and sleep, audio output, notification history,
  session.
- **Preferences.** Your name and password, language, keyboard and time zone, wallpaper
  and desktop widgets, the screens, shortcuts and programs, the computer's name, Nilo,
  the clipboard history, the boot sound, fingerprint and SSH, in one sheet (`SUPER + O`) that the first login opens as a welcome. The wallpaper,
  the widgets and the password change at once; the rest waits until applied, and applying
  rebuilds the system in the background.
- **Generations, from Preferences.** Every rebuild is a whole system NixOS keeps. Each one
  says when it was made, its NixOS, kernel and NIHIL, and which packages it changed;
  one click goes back to it, now and at boot, or boots it just once. How long they stay,
  and cleaning now, with what it frees.
- **Devices.** With [NIHIL for Android](https://github.com/poligle/Nihil-Launcher), a phone or a tablet paired with a QR
  from Preferences opens the computer's apps and web pages, plays and skips
  its music, turns its volume, locks it and is its trackpad, with this desktop's gestures;
  the dashboard's kanban stays in sync with it, and Vector carries things either way.
  Over HTTPS pinned to this computer. See
  [Devices](devices.md).
- **An installer.** An ISO that installs NIHIL on a whole disk, or next to Windows or
  another Linux in room it makes by shrinking it safely. See [Install](install.md).
- **Launcher.** Monochrome app grid that regains colour on the selection, `>` for
  actions, `=` for a calculator, `?` for Nilo. Preferences, Apps hides those you don't want
  there, from the phone's deck too; they're kept in `~/.local/state/nihil/apps.json`, with no
  rebuild.
- **Copy, paste and the clipboard history.** One modifier for both, as on a Mac: `SUPER + C`
  copies and `SUPER + V` pastes, in kitty too. Held a moment longer, `SUPER + V`
  brings out the last copies, text and pictures, from the top of the frame: `V` again goes
  to the next one, and letting go of `SUPER` pastes it where you were (`Esc`: none). The
  window keeps the keyboard all along, so what was open in it stays open. The one chosen
  is lit, its picture in colour. What a password manager copies is never kept, and the
  history is kept in memory only: it goes with the session.
- **Nilo.** An optional assistant with a local model (Qwen 3.5 on Ollama): two white eyes
  that wake up while you type. Three levels of what it may do: talk (and search the web if
  you let it); work in a repository of yours, its files, git and the terminal, each step
  confirmed; or use the whole desktop as you would: see what is open and the screen, click
  through any program, type in Writer, put on a song, open Zen on a video, move windows,
  turn the volume, the night light, Wi-Fi or Bluetooth, send things to the phone, asking
  only before what carries a risk. Close the launcher mid-answer and it
  tells you when it's done, from the bar. See [Nilo](nilo.md).
- **Light on the edge.** In the spirit of Nothing's Glyph Interface, every notification
  sends a segment of light around the frame; critical ones run twice, in red, like the
  battery warnings at 15, 10 and 5 %. Plugging in the charger sends two lights up both
  sides from the bottom, which meet at the top, like the launcher on the phone. Work
  that takes a while stays on it: a rebuild (Preferences, updating, a generation) keeps
  the two lights as far up as it has got and rises when it is done; a download in Zen,
  Firefox or Chromium sends a faint stretch round until it ends. Anything else can use
  it too: `nihil-ipc glyph progress <id> <0..1>`, then `done <id>`.
- **Wallpapers as LED matrices.** Every picture in `wallpapers/`, and in a machine's
  `/etc/nixos/wallpapers` (PNG, JPEG, GIF or WebP, with any name; one named as one of
  NIHIL's takes its place), is rendered at build time as dots, once per output at its native size, so each dot lands on exact pixels. A
  GIF moves on the desktop. Each picture on each screen is drawn once and kept: a rebuild
  only draws the new ones. The [studio](https://nihilshell.com/studio/) does the same in
  the browser with any picture, moving ones too (`docs/studio/`, the same numbers as
  `theme/dotmatrix.py`).
- **Desktop widgets.** The clock and what plays; and, if you want them, the month with a dot
  under each day that has something and what comes next, the network's rates,
  how the computer is (processor, memory, temperature and the system's disk, in rows of dots),
  the weather where you say (now, today's highest and lowest and the three days after, from
  [Open-Meteo](https://open-meteo.com), with no key; the place goes in Preferences, Appearance),
  photos of yours in dots, as many as you like (drop a picture on one to change it, or on the
  desktop for a new one where it falls, or open one with Photo widget from Files, which puts
  it in one with none or in a new one: PNG, JPEG, GIF, BMP or WebP, of which it keeps a copy;
  Add, by Photos in Preferences, Appearance, makes an empty one), notes, as many as you like,
  in Markdown (headings, bold, italics, strikethrough, lists, tasks ticked with a click,
  quotes, code and links; the pencil writes in one and + puts another beside it), and a year
  of GitHub contributions, a dot a day, brighter the more there were (the username goes in
  Preferences, Appearance; it reads the page GitHub draws its own calendar from, every hour,
  and keeps the last one for when there's no network).
  A long press on one, or Arrange in Preferences, Appearance, lets you drag each where you
  want it, on a grid and clear of the others; its corner makes photos, notes, the network and
  the calendar any shape (the calendar lists as much of what comes next as fits), and the
  rest from three quarters to two and a half times as big, as a whole. Dropped on the cross,
  one is turned off or, a photo or a note, gone. Enter keeps it all and Esc puts back what
  was there; each keeps its place and its size, with no rebuild.
- **Boot, login, lock.** The NixOS snowflake switching on LED by LED (Plymouth, played
  whole at least once on the way up and on the way down) with the power-off notes going
  up, unless the session was left muted, a greeter with the lock screen's face (its
  own, in Quickshell: the time in dots, the password as dots, a finger or the password) and
  a lock screen with what is playing in a corner, on a panel of its own: the cover in dots,
  the progress in LEDs and buttons you can click (hyprlock).
- **Pictures, videos and PDFs.** imv, mpv and Zathura open them, from Thunar or from
  Vector, in the same black and greys, and stay out of the launcher. A picture opens with
  the rest of its folder an arrow away; mpv plays music files too.
- **fastfetch in dots.** The same snowflake, drawn with `●` and `·`, monochrome keys in
  NIHIL's own greys and the palette as a row of LEDs.
- **Spanish or English.** One option switches every string of the shell, the lock screen,
  the greeter and the scripts, and the language of their dates.
- **Its own sound.** A set of short digital blips, synthesised for NIHIL; the previous
  sounds are one option away.
