<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="assets/brand/nihil-logo-dark.svg">
    <img alt="NIHIL" src="assets/brand/nihil-logo-light.svg" width="420">
  </picture>
</p>

<p align="center"><i>ex nihilo</i></p>

<p align="center">A monochrome, dot-matrix desktop for NixOS</p>

<p align="center">
  <a href="https://nihilshell.com/">Website</a> &nbsp;&nbsp;&nbsp;
  <a href="docs/install.md">Install</a> &nbsp;&nbsp;&nbsp;
  <a href="https://github.com/poligle/Nihil-Launcher">NIHIL for Android</a> &nbsp;&nbsp;&nbsp;
  <a href="https://github.com/poligle/Nihil-Wear">NIHIL for Wear OS</a>
</p>

![NIHIL desktop](docs/assets/screens/desktop.png)

NIHIL is a personal NixOS configuration. It takes the structure of
[Caelestia](https://github.com/caelestia-dots/shell), a frame around the screen with
drawers that grow out of it, and dresses it in the language of Nothing: monochrome,
dot-matrix type, red only to interrupt, and light that runs along the edge. All of it is
declared in Nix, and one file, [`theme/nihil.nix`](theme/nihil.nix), holds the tokens that
GTK, the terminal, the compositor, the lock screen and the shell are made from.

> *Nihil* is Latin for "nothing", the way *caelestia* is Latin for "the heavenly". And
> *ex nihilo*, from nothing, is also what NixOS does: the whole system, rebuilt from a
> declaration.

| | |
|:---:|:---:|
| ![Dashboard](docs/assets/screens/dashboard.png) | ![Quick settings](docs/assets/screens/settings.png) |
| Dashboard <kbd>SUPER</kbd> <kbd>D</kbd> | Quick settings <kbd>SUPER</kbd> <kbd>P</kbd> |
| ![Launcher](docs/assets/screens/launcher.png) | ![Clipboard history](docs/assets/screens/clipboard.png) |
| Launcher <kbd>SUPER</kbd> <kbd>Space</kbd> | Clipboard history, holding <kbd>SUPER</kbd> <kbd>V</kbd> |
| ![Wallpapers](docs/assets/screens/wallpapers.png) | ![Preferences](docs/assets/screens/preferences.png) |
| Wallpapers in dots <kbd>SUPER</kbd> <kbd>W</kbd> | Preferences <kbd>SUPER</kbd> <kbd>O</kbd> |
| ![Every workspace](docs/assets/screens/overview.png) | ![A notification](docs/assets/screens/notification.png) |
| Every workspace, holding <kbd>SUPER</kbd> <kbd>A</kbd> | A notification, its light along the frame |

<p align="center">
  <img src="docs/assets/screens/glass/terminal.png" width="720" alt="kitty with fastfetch in dots, the wallpaper blurred and darkened through it, and the frame and the bar in smoked glass.">
</p>

<p align="center"><sub>The same, in smoked glass: one switch in Preferences.</sub></p>

## What's in it

- **The frame and its drawers.** One black shape around the screen; the bar is its left
  side, and the dashboard, quick settings and the launcher grow out of it.
- **Smoked glass,** if you choose it: the frame and every drawer turn to dark glass over
  what is really behind them.
- **Widgets on the desktop:** the clock, the month with what comes next from your
  calendars, photos and notes as many as you like, the weather, the network, the system,
  what plays and GitHub contributions, each where you put it and as big as you make it.
- **Nilo,** an assistant with a model that runs here, and as much of the system as you
  give it: a chat, a repository, or the whole desktop.
- **Devices as decks,** a phone, a tablet and the watch, with [NIHIL for Android](https://github.com/poligle/Nihil-Launcher)
  and [NIHIL for Wear OS](https://github.com/poligle/Nihil-Wear), over the network or, with
  none in common, Bluetooth, and Vector to carry things between them and this computer.
- **Preferences,** the whole system on one sheet, applied as a rebuild, with every
  generation a click away.
- **Wallpapers in dots,** its own sounds, and the boot splash, greeter and lock screen in
  the same language.
- **An installer** that makes room next to Windows, or takes a whole disk.

## Learn more

- [Everything in it, in detail](docs/features.md)
- [Install, and keep it current](docs/install.md)
- [Keys, commands and options](docs/reference.md)
- [Nilo](docs/nilo.md)
- [Devices](docs/devices.md), and [the deck's protocol](docs/deck.md)
- [Design](docs/design.md)
- [Inside NIHIL](docs/inside.md)

## Credits

- [Caelestia](https://github.com/caelestia-dots/shell) for the frame-and-drawers idea.
- [Nothing](https://nothing.tech) for the design language that inspired the look. NIHIL
  is a personal project and is not affiliated with Nothing Technology.
- [Quickshell](https://quickshell.org), [Hyprland](https://hyprland.org),
  [Stylix](https://github.com/nix-community/stylix) and
  [Home Manager](https://github.com/nix-community/home-manager).
- The NixOS logo, by Simon Frankau, Tim Cuthbertson and Daniel Baker for the NixOS Project
  ([NixOS/branding](https://github.com/NixOS/branding)), is licensed under
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/); NIHIL's mark redraws it as dots.
  NIHIL is not affiliated with or endorsed by the NixOS project.
- The Android robot is reproduced or modified from work created and shared by Google and used
  according to terms described in the Creative Commons 3.0 Attribution License.
  Android is a trademark of Google LLC.
- Fonts: Doto, Space Grotesk and Space Mono (SIL OFL 1.1), JetBrains Mono (SIL OFL 1.1).
  The website ships subsets of the first three, with their licence in `docs/assets/fonts`.
- Icons: [Colloid](https://github.com/vinceliuice/Colloid-icon-theme) by Vince Liuice
  (GPL-3.0), installed from nixpkgs.
- Weather data by [Open-Meteo](https://open-meteo.com), licensed under
  [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/), for the weather widget.

The code and NIHIL's own sounds are MIT licensed (see `LICENSE`); the logos keep the licences
above, and [`sounds/CREDITS.md`](sounds/CREDITS.md) says where each sound comes from.

## Notes

Public repository: contains no secrets or credentials. User passwords are set with
`passwd`, and SSH keys and fingerprint data live outside the repository.
