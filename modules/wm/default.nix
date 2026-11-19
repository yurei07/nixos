# Window manager module entry point.
{ ... }:
{
  imports = [
    ./hyprland/hyprland.nix
    ./polkit/polkit.nix
  ];
}
