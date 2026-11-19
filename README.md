<img width="100%" src="assets/banner.svg" alt="NixOS"/>

<div align="center">

<img src="https://img.shields.io/badge/NixOS-flakes-D71921?style=flat-square&labelColor=000000" alt="NixOS flakes">
<img src="https://img.shields.io/badge/WM-Hyprland-ffffff?style=flat-square&labelColor=000000" alt="Hyprland">
<img src="https://img.shields.io/badge/shell-zsh-8A8A8A?style=flat-square&labelColor=000000" alt="zsh">
<img src="https://img.shields.io/badge/editor-Neovim-8A8A8A?style=flat-square&labelColor=000000" alt="Neovim">

</div>

<img width="100%" src="assets/divider.svg" alt=""/>

### ABOUT

My personal NixOS setup, written as a flake.
The whole system (desktop, terminal, editor and tools) is described in code, so it can be rebuilt on any machine with one command.

| | |
|:--|:--|
| **OS** | NixOS (flakes) |
| **WM** | Hyprland |
| **Shell / bar** | Quickshell with [nothing-panel](https://github.com/yurei07/nothing-panel) (Nothing OS style) |
| **Terminal** | kitty |
| **Shell** | zsh |
| **Editor** | Neovim |
| **Media** | mpv |

<img width="100%" src="assets/divider.svg" alt=""/>

### GALLERY

<p align="center">
  <img width="49%" src="assets/nixos/2026-05-06-215723_hyprshot.png" alt="Desktop 1"/>
  <img width="49%" src="assets/nixos/2026-05-06-215839_hyprshot.png" alt="Desktop 2"/>
</p>

<img width="100%" src="assets/divider.svg" alt=""/>

### STRUCTURE

```text
.
├── flake.nix            # entry point
├── flake.lock           # pinned inputs
├── hosts/
│   └── Prizrak/         # machine config: configuration.nix, hardware, home, nix-modules
├── modules/
│   ├── gui/             # graphical apps (incl. Quickshell / Noctalia)
│   ├── tui/             # terminal: kitty, zsh and CLI tools
│   └── wm/              # Hyprland configuration
├── materials/           # wallpapers, theme, mpv config
├── scripts/             # helper scripts (e.g. nvim.sh)
└── assets/              # screenshots and README graphics
```

### INSTALLATION

> Review the config before using it. Replace the hardware configuration with your own.

```bash
git clone https://github.com/yurei07/nixos.git
cd nixos

# generate hardware config for your machine
sudo nixos-generate-config --show-hardware-config > hosts/Prizrak/hardware-configuration.nix

# build and switch
sudo nixos-rebuild switch --flake .#Prizrak
```

### CREDITS

- [Noctalia](https://github.com/noctalia-dev/noctalia) for the Quickshell setup
- [Hyprland](https://hyprland.org) and the NixOS community

<img width="100%" src="assets/divider.svg" alt=""/>
