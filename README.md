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
| **WM** | Hyprland 0.57 (Lua config) |
| **Shell / bar** | Quickshell with [nothing-panel](https://github.com/yurei07/nothing-panel) (Nothing OS style) |
| **Terminal** | kitty |
| **Shell** | zsh |
| **Editor** | Neovim |
| **Media** | mpv |

<img width="100%" src="assets/divider.svg" alt=""/>

### GALLERY

<p align="center">
  <img width="100%" src="assets/nixos/desktop-1.png" alt="Desktop 1"/>
</p>

<img width="100%" src="assets/divider.svg" alt=""/>

### STRUCTURE

```text
.
├── flake.nix            # entry point, inputs and nixosConfigurations
├── hosts/
│   ├── Prizrak/         # main machine: system config + home config
│   │   ├── modules/     # host-specific system modules (audio, gpu, laptop, ...)
│   │   └── home/        # Home Manager entry point
│   ├── pc/              # generic install target used by the live ISO installer
│   ├── live/            # live ISO: Hyprland + nothing-shell demo + installer
│   └── server/          # optional second machine
├── modules/
│   ├── wm/              # window manager (hyprland, polkit)
│   ├── gui/             # user-level graphical apps (nothing-shell, nautilus)
│   └── tui/             # terminal apps (kitty, zsh, neovim, fastfetch)
├── materials/           # per-application assets (mpv)
├── scripts/             # helper scripts (nvim.sh, update.sh, nixinstall)
├── themes/              # local theme stubs (chiaroscuro)
└── .github/             # CI + docs
```

<img width="100%" src="assets/divider.svg" alt=""/>

### INSTALLATION

> Review the config before using it. Replace the hardware configuration with your own.

```bash
git clone https://github.com/yurei07/nixos.git
cd nixos

# generate hardware config for your machine
sudo nixos-generate-config --show-hardware-config > hosts/Prizrak/hardware-configuration.nix

# build and switch
sudo nixos-rebuild switch --flake .#nixos
```

### LIVE ISO

A bootable ISO that drops you straight into Hyprland with the full Nothing rice — try everything, then install with one command.

Build it:

```bash
nix build .#nixosConfigurations.live.config.system.build.isoImage
# → result/iso/nixos-nothing.iso
```

Write it to a USB drive:

```bash
sudo dd if=result/iso/nixos-nothing.iso of=/dev/sdX bs=4M status=progress oflag=sync
```

Boot it (USB in the boot menu) and the desktop starts by itself: wallpaper, panel, dock, kitty. `SUPER + ENTER` opens a terminal — run:

```bash
sudo nixinstall
```

The installer asks for the target disk, GPU vendor (AMD / Intel / NVIDIA), hostname, timezone, swap and the user password, partitions the disk, generates hardware configuration for that machine and installs the `pc` host from this same flake. Reboot straight into Hyprland.

### UPDATING

```bash
cd /etc/nixos
./scripts/update.sh
```

<img width="100%" src="assets/divider.svg" alt=""/>

### CREDITS

- [Hyprland](https://hyprland.org)
- [nothing-panel](https://github.com/yurei07/nothing-panel)
- NixOS and Home Manager communities

<img width="100%" src="assets/divider.svg" alt=""/>
