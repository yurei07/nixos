# Repository structure
 
```
.
├── flake.nix                    # entry point, all inputs and nixosConfigurations
├── flake.lock
├── hosts/
│   └── Prizrak/                 # config for a specific machine
│       ├── configuration.nix    # system NixOS config (services, boot, etc)
│       ├── hardware-configuration.nix
│       ├── nix-modules/         # system modules split by topic
│       │   ├── nvidia.nix
│       │   ├── bluetooth.nix
│       │   ├── users.nix
│       │   ├── fonts.nix
│       │   ├── audio.nix
│       │   ├── lightdm.nix
│       │   └── replays.nix
│       └── home/
│           └── home-configuration.nix   # Home Manager entry point for the user
├── modules/                     # reusable modules (not tied to a specific host)
│   ├── wm/                      # window manager (hyprland/)
│   ├── gui/                     # graphical apps (obs, nautilus, ...)
│   └── tui/                     # terminal apps
├── materials/
│   ├── themes/                  # stylix + color schemes
│   └── mpv/                     # per-application configs
├── scripts/                     # shell scripts invoked from the config (nvim.sh, etc)
├── docs/                        # this documentation
└── .github/workflows/           # CI build check
```
 
## Rule for adding a new module
 
- If the module is **specific to one machine** (e.g. a particular GPU) — put it in `hosts/<host>/nix-modules/`
- If the module is **reusable** (an app that could run on any machine) — put it in `modules/{wm,gui,tui}/`
- Home Manager-specific settings (per-application dotfiles) live inside `modules/`, imported through `home-configuration.nix`
## Multi-host (for the future)
 
If a second machine is added — copy the `hosts/Prizrak/` structure into `hosts/<new-name>/`, duplicate `configuration.nix`/`home-configuration.nix` with the needed differences, and add a new `nixosConfigurations.<new-name>` entry in `flake.nix`. Shared modules (`modules/`) are reused as-is.
 

