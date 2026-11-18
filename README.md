<img width="100%" src="https://capsule-render.vercel.app/api?type=waving&color=0:0d1117,100:bb9af7&height=160&section=header&text=nixos&fontSize=52&fontColor=ffffff&fontAlignY=40&desc=my%20declarative%20system%20configuration&descSize=16&descAlignY=62&descColor=c0caf5&animation=fadeIn" alt="nixos header"/>

<div align="center">

![NixOS](https://img.shields.io/badge/NixOS-flakes-bb9af7?style=flat-square&logo=nixos&logoColor=0d1117)
![Hyprland](https://img.shields.io/badge/WM-Hyprland-7aa2f7?style=flat-square)
![Shell](https://img.shields.io/badge/shell-zsh-c0caf5?style=flat-square)
![Editor](https://img.shields.io/badge/editor-Neovim-bb9af7?style=flat-square&logo=neovim&logoColor=0d1117)
![License](https://img.shields.io/badge/license-MIT-7aa2f7?style=flat-square)

</div>

## About

My personal NixOS setup, written as a flake.
The whole system (desktop, terminal, editor and tools) is described in code, so it can be rebuilt on any machine with one command.

- **OS:** NixOS (flakes)
- **WM:** Hyprland
- **Shell / bar:** Quickshell with [Noctalia](https://github.com/Ly-sec/Noctalia)
- **Terminal:** kitty
- **Shell:** zsh
- **Editor:** Neovim
- **Media:** mpv

## Gallery

<p align="center">
  <img width="49%" src="assets/nixos/2026-05-06-215723_hyprshot.png" alt="Desktop 1"/>
  <img width="49%" src="assets/nixos/2026-05-06-215839_hyprshot.png" alt="Desktop 2"/>
</p>

## Structure

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
└── assets/              # screenshots for this README
```

## Installation

> Review the config before using it. Replace the hardware configuration with your own.

```bash
git clone https://github.com/yurei07/nixos.git
cd nixos

# generate hardware config for your machine and put it into hosts/Prizrak/
sudo nixos-generate-config --show-hardware-config > hosts/Prizrak/hardware-configuration.nix

# build and switch
sudo nixos-rebuild switch --flake .#Prizrak
```

## Credits

- [Noctalia](https://github.com/Ly-sec/Noctalia) for the Quickshell setup
- [Hyprland](https://hyprland.org) and the NixOS community

## License

MIT
