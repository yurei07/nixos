# Install

Two ways in, to the same system: the installer, on any computer, or the NixOS you already
have, from a clone of this repository. Either way the machine keeps what is its own in
`/etc/nixos`, and NIHIL comes from here.

To see it first, a NixOS runs it in a window, as it comes: `nix run
github:poligle/Nihil-Shell#vm` logs in by itself (user `nihil`, password `nihil`) on a disk of
its own in `~/.cache/nihil-vm`; `--fresh` starts it on a new one. The folder it's run from is
at `/mnt/nihil` in it.

### With the installer

[Releases](https://github.com/poligle/Nihil-Shell/releases) has the ISO: `latest`, built
from every push, or a tagged version; it installs the NIHIL of the commit it was built from.
Check it against `SHA256SUMS`, next to it, write it to a USB stick, boot it (UEFI, with
Secure Boot off in the firmware: NixOS isn't signed for it) and the installer starts on
its own, in a window of its own like the login screen; should that not start, its text
version takes its place (`sudo nihil-install`, from any console):

```bash
sha256sum -c SHA256SUMS --ignore-missing
gh attestation verify nihil-*.iso -R poligle/Nihil-Shell    # built by this repository's CI, from its commit
sudo dd if=nihil-*.iso of=/dev/sdX bs=4M status=progress oflag=sync    # sdX: the stick
```

1. Language and keyboard, a network if there is no cable (a Wi-Fi joined here is joined
   again at the first boot), and the time zone. Meanwhile it reads the whole stick: one
   that cannot be read stops it before installing, saying so.
2. Your name, user name, password and the computer's name.
3. The disk, and where on it: next to what is there, in its free space or in room a
   partition gives up (Windows' NTFS, an ext4 or a btrfs, shrunk keeping what it holds;
   a Windows with BitLocker is shrunk from Windows itself); on one of its partitions,
   formatted; or the whole disk, erased. Next to another system the rest of the disk
   stays as it is, and the boot menu goes on the disk's EFI partition, offering Windows
   or the other system too; if there is none, or it is small (Windows' is 100 MB),
   NIHIL adds 1 GB for the kernels (XBOOTLDR). A Linux booted by GRUB gets its own entry
   (systemd-boot finds Windows by itself). To partition by hand, another console
   (`Ctrl+Alt+F2`) has cfdisk and parted; then "Look again" and "On one of its partitions".
   NIHIL is btrfs with subvolumes for `/`, `/home`, `/nix` and `/var/log`, compressed,
   inside LUKS if you choose to encrypt.
4. The first login opens the welcome: what NIHIL is and how its frame works, then your
   name, language, keyboard, time zone, wallpaper and system. **Preferences** changes
   all of it later, and the shortcuts too: `SUPER + O`, the cog in quick settings or
   the launcher. Changes wait until applied; applying asks once, for a finger if there is
   a reader or for your password, never both, and rebuilds the system on its own
   (`nihil apply`), which keeps going if the shell restarts and puts the old settings
   back if the build fails.

Next to Windows, three things to know. NIHIL's menu, the first thing that starts, shows
for 5 seconds what is on its own disk: Windows on another disk stays in the computer's own
boot menu (the key it shows as it starts: F12, F11, Esc…), and the installer says so. A
Windows update can put Windows first again: choose Linux Boot Manager first in the
firmware. And a Windows with BitLocker asks for its recovery key when Secure Boot changes,
or the first time it starts from another menu: have it at hand before you begin.

It finds the screens and the GPU on its own and installs over the network (almost all of
NIHIL comes from cache.nixos.org; its wallpapers, splash and fonts are made on the spot).
A stick that gives read errors: write it again, or try another stick or port; **Copy ISO
Files to RAM**, among the boot menu's options, loads it all into memory before starting.

### On a NixOS you already have

The classic way: clone NIHIL and rebuild from it. Any NixOS on UEFI will do: the switch
brings it to the NixOS release NIHIL pins, and it boots with systemd-boot.

```bash
# NIHIL, cloned: your own copy, to read, change and pull
git clone https://github.com/poligle/Nihil-Shell ~/Nihil-Shell

# The machine's flake, next to the hardware-configuration.nix /etc/nixos already has
sudo cp -a /etc/nixos /etc/nixos.before-nihil
sudo cp ~/Nihil-Shell/templates/machine/{flake.nix,settings.json,local.nix,home.nix} /etc/nixos/

# The screens, for settings.json: each one's name and size
for c in /sys/class/drm/card*-*; do [ "$(cat "$c/status")" = connected ] && echo "${c##*/card?-} $(head -n 1 "$c/modes")"; done

sudoedit /etc/nixos/settings.json /etc/nixos/local.nix
```

In `settings.json`: `user.name` is the user you already have (a new one would come without
a password: `sudo passwd` it before rebooting), `host.name` the computer's name, then
language, keyboard and time zone, and `outputs` the screens above, as
`"eDP-1": { "width": 1920, "height": 1200 }`. In `local.nix`: the `system.stateVersion` of
your old `configuration.nix`, and whatever this machine needed there, such as
`boot.loader.efi.efiSysMountPoint = "/boot/efi";` if its EFI partition is mounted there, or
`hardware.amdgpu.initrd.enable = true;` with an AMD GPU, so the boot splash comes up early
(the installer adds the GPU's by itself).

A screen connected later, on any machine, goes into `outputs` from Preferences, Screens:
the screens drawn as they sit on the desk, to be dragged beside each other, and for the one
picked its resolution, refresh rate, scale, rotation, bar and whether it is the main one.
Or the same by hand (`nihil settings`), with a `position` like `"2560x0"` in logical pixels. One that is not there works anyway, with Hyprland's own
mode, no bar and the primary screen's wallpaper.

Then point the flake at the clone and switch (flakes are turned on for this first time;
NIHIL keeps them on). `HOST` is `host.name`:

```bash
sudo sed -i "s|github:poligle/Nihil-Shell|path:$HOME/Nihil-Shell|" /etc/nixos/flake.nix
sudo NIX_CONFIG="experimental-features = nix-command flakes" \
    nixos-rebuild switch --flake /etc/nixos#HOST
```

With the clone, updating is `git -C ~/Nihil-Shell pull`, then `nihil update`. Leave the
`sed` out to follow GitHub instead, as the installer does: `nihil update` then pulls from here.

**This machine's configuration** stays in `/etc/nixos`, separate from NIHIL:

| File | What it holds |
|------|---------------|
| `flake.nix` | NIHIL as an input (`github:poligle/Nihil-Shell`, or `path:` to a clone), through `nihil.lib.mkSystem` |
| `settings.json` | User, computer name, language, locale, keyboard, time zone, screens, Nilo, fingerprint, SSH and its keys (`sshKeys`), how long generations stay, the deck |
| `hardware-configuration.nix` | Disks and drivers, from `nixos-generate-config` |
| `local.nix` | Anything else for this machine: drivers, services, packages |
| `home.nix` | Its apps (NIHIL installs little beyond Zen) and anything else for its user, through Home Manager |

**Updates** come from the repository: `nihil update` moves the machine's flake to the
latest NIHIL (and the NixOS it pins) and rebuilds. Nothing of yours is in the repository,
so updating never touches it. The quick settings have it too: a dot on their update button
when GitHub has something newer, how many commits with the pointer on it, and which ones
with a click, next to the password that updates.

```bash
nihil update      # the latest NIHIL, then rebuild
nihil check       # whether GitHub has a newer NIHIL, and which commits
nihil rebuild     # apply changes to /etc/nixos
nihil settings    # edit a copy of settings.json, then rebuild with it once it's valid
nihil version     # the NIHIL this machine runs, and the one pinned
nihil dev [path]  # NIHIL from a checkout instead, until nihil dev off or nihil update
nihil apply FILE  # FILE as settings.json, rebuilt in the background (/run/nihil)
nihil generations # the system's generations: NixOS, kernel, NIHIL, which one runs
nihil generations changes N   # the packages generation N changed
nihil generations switch N    # back to N, now and at boot
nihil generations boot N      # N the next boot only
nihil generations clean DAYS  # those older than DAYS days go, and what nothing needs
nihil welcome     # the welcome, again
nihil watch       # NIHIL for Wear OS on a watch (Devices)
nihil passwd      # Preferences' own: the password it was given, for whoever runs it through sudo
```

One change at a time: while one is being made, from a terminal or from Preferences, any
other stops and says so. Switching and cleaning run in `nihil-apply.service`, as Preferences'
do, and the terminal follows them: closing it, or Ctrl+C, stops following, not the change
(`--unit` starts it without following). A change that fails with the system as it was leaves
`settings.json`, `flake.lock` and `nihil dev` as they were too, so the next rebuild builds
what runs. `nihil apply` and `nihil settings` take settings for this machine's own account
only (a different `user.name` would leave it out of the system), with `host.name`, and
with each key of the type NIHIL reads.

---

## Daily usage

```bash
nihil rebuild                  # apply /etc/nixos (alias nrebuild)
nihil update                   # the latest NIHIL, then rebuild (alias nupdate)
sudo nixos-rebuild build --flake /etc/nixos          # build without switching
nihil generations clean 7      # older than 7 days go, from the boot menu too (alias ngc)
```

`nh os switch` does the same as `nihil rebuild` and prints the package diff between
generations. Garbage collection also runs weekly on its own (`modules/nix.nix`), keeping
the generations of the last `generations.days` days and taking the rest out of the boot
menu; Preferences, Generations cleans now too, and says what it freed.

To try changes to NIHIL before pushing them: `nihil dev ~/Nihil-Shell` rebuilds with that
checkout and keeps it, so `nihil rebuild` and Preferences use it too, until `nihil dev off`
or `nihil update`; `nihil version` says which NIHIL runs. Each rebuild takes a copy of the
checkout as it is, new files included, without `.git` (`/var/lib/nihil/dev-tree`): the
history stays out of the store. The copy is read as whoever turned `nihil dev` on and
built as root, so Preferences says so where it asks for the password. To build on a clone for good, point the machine's flake
at it (On a NixOS you already have, above).

### Keeping NIHIL current

NIHIL's `flake.lock` is the NixOS every machine runs: `nihil update` takes it from here.
Every Monday, [`.github/workflows/update.yml`](../.github/workflows/update.yml) brings the
inputs up to date in a pull request, once a machine as the installer leaves it still
evaluates and the `nihil` command still builds (GitHub has to let Actions create pull
requests: Settings, Actions, General,
Workflow permissions, "Allow GitHub Actions to create and approve pull requests").
Nothing merges by itself: try its branch, `inputs`, with `nihil dev` on a checkout, then
merge it; that makes a new ISO, and `nihil update` takes it to each machine.
`nix flake update` does the same by hand.

A new NixOS release, every May and November, means moving `nixpkgs`, `home-manager` and
`stylix` in `flake.nix` to its branches together, before the one NIHIL follows reaches
its end of life. `home.stateVersion` in `home.nix` stays at `26.05`, the release NIHIL's
home started on, for every machine; `system.stateVersion` is each machine's own, in its
`local.nix`.

---

## Recovery

- **System won't boot:** pick an earlier generation from the boot menu (systemd-boot).
  It's a system-level restore point.
- **Something broke after applying or updating:** Preferences, Generations (or
  `nihil generations switch N`) goes back to an earlier generation without restarting,
  and "Boot it once" tries one at the next boot only, for what needs a restart (a kernel,
  a driver). Your settings stay as they are: the next apply builds from them again.
- **An update broke something:** an update that fails to build leaves `flake.lock` as it
  was on its own. One that built and broke something: boot the previous generation, then
  go back to the NIHIL you had: `/etc/nixos/flake.lock` holds the revision, so `git` on
  `/etc/nixos` (or a copy of the old lock) and `nihil rebuild` return to it.
