# Repository structure

```text
.
├── flake.nix                    # entry point, all inputs and nixosConfigurations
├── flake.lock
├── hosts/
│   ├── Prizrak/                 # main machine
│   │   ├── configuration.nix    # system NixOS config (services, boot, etc)
│   │   ├── hardware-configuration.nix
│   │   ├── modules/             # system modules split by topic
│   │   │   ├── audio.nix
│   │   │   ├── bluetooth.nix
│   │   │   ├── fingerprint.nix
│   │   │   ├── fonts.nix
│   │   │   ├── gpu.nix
│   │   │   ├── laptop.nix
│   │   │   ├── lightdm.nix
│   │   │   ├── obs.nix
│   │   │   ├── replays.nix
│   │   │   └── users.nix
│   │   └── home/
│   │       └── home-configuration.nix  # Home Manager entry point for the user
│   └── server/                  # optional second machine
├── modules/                     # reusable modules (not tied to a specific host)
│   ├── wm/                      # window manager (hyprland/, polkit/)
│   ├── gui/                     # graphical user-level apps (nautilus, nothing-shell)
│   └── tui/                     # terminal apps
├── materials/                   # per-application assets (mpv)
├── scripts/                     # helper scripts (nvim.sh, update.sh)
├── themes/                      # local theme stubs (chiaroscuro)
└── .github/                     # CI + docs
```

## Rule for adding a new module

- If the module is **specific to one machine** — put it in `hosts/<host>/modules/`
- If the module is **reusable user-level** (an app or dotfile set) — put it in `modules/{wm,gui,tui}/`
- System-level modules (boot, services, hardware) live under `hosts/<host>/modules/`
- Home Manager-specific settings (per-application dotfiles) live inside `modules/`, imported through `home-configuration.nix`
