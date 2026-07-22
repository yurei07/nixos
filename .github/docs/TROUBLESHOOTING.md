# Troubleshooting

Real errors encountered while working on this config, and how they were fixed.

## `home-manager-*.service` fails on rebuild — "Existing file ... would be clobbered"

Home Manager refuses to overwrite a file it doesn't manage (e.g. `gtk.css`, created by some third-party theming tool).

**Fix** — allow automatic backup on conflict:
```nix
home-manager.backupFileExtension = "backup";
```
The old file gets renamed to `<name>.backup` instead of blocking activation.

## `error: The option 'X' does not exist. Did you mean 'Y'?`

Usually a typo, or an option renamed in a newer nixpkgs release. Nix almost always suggests the correct name in the error itself ("Did you mean..."). Cases we've hit:
- `xdg.usersDirs` → `xdg.userDirs` (typo, extra `s`)
- `stylix.iconTheme.*` → `stylix.icons.*` (renamed upstream)
- `pkgs.mate.mate-polkit` → `pkgs.mate-polkit` (package moved to top-level)

## `error: The option 'X' has conflicting definition values`

The same option is set in two different places with different values. Nix will show both source files in the conflict.
**Fix** — keep the value in only one place (usually wherever it's meaningfully correct), remove the duplicate from the other file.

## Option declared at the wrong level (system vs home-manager)

Example: `xdg.userDirs` is a **Home Manager** option, not a system-level NixOS option. Declaring it in `configuration.nix` (system level) gives "option does not exist". It needs to live inside `home-manager.users.<user>` / `home-configuration.nix`.

Similarly: `xdg.*` inside home-configuration must be a **sibling** of `home = { ... }`, not nested inside it — they're separate namespaces at the same file level.

## Package build fails during its test suite (`doCheck` failures) — e.g. `patool`

Sometimes a package in nixpkgs-unstable breaks because of a bug in its own test suite (an upstream bug, not something in your config). Temporary fix — an overlay disabling tests for that specific package:

```nix
nixpkgs.overlays = [
  (final: prev: {
    pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
      (pyFinal: pyPrev: {
        patool = pyPrev.patool.overridePythonAttrs (old: { doCheck = false; });
      })
    ];
  })
];
```
Remove the overlay once upstream fixes the bug (check the relevant nixpkgs issue periodically).

## `git add` → `Permission denied` on `/etc/nixos/.git`

`/etc/nixos` is owned by root or another user. Fixes:
```bash
sudo git add -A
```
or change ownership (without specifying a non-existent group):
```bash
sudo chown -R $USER /etc/nixos
```
Check your own group beforehand with `id`.

## `warning: Git tree '/etc/nixos' is dirty`

Not an error, just an informational warning — there are uncommitted changes. Stage/commit before rebuilding:
```bash
git add -A && git commit -m "wip"
```
