# Home for the live ISO user: the Nothing rice (Hyprland, quickshell panel,
# wallpapers, rofi, swaync) without the heavy host applications.
{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    ../../../modules/wm
    ../../../modules/gui
    ../../../modules/tui/kitty/kitty.nix
  ];

  home.packages = with pkgs; [
    quickshell
  ];

  home.stateVersion = "25.11";
}
