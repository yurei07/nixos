# Nothing OS skins for the TUI apps: btop and yazi themes vendored from
# uzayr-iqbal-hamid/nothing-os-dots-hyprland (MIT), pointing the apps at them.
{
  config,
  lib,
  pkgs,
  ...
}:
{
  # btop: monochrome Nothing palette, set as the active colour theme.
  home.file.".config/btop/themes/nothing.theme".source = ../tui/nothing-themes/btop-nothing.theme;
  home.file.".config/btop/btop.conf".text = ''
    color_theme = "nothing"
    theme_background = false
    force_tty = 0
  '';

  # yazi: the Nothing flavor for the file manager.
  home.file.".config/yazi/theme.toml".source = ../tui/nothing-themes/yazi/theme.toml;
  home.file.".config/yazi/flavors/nothing.yazi".source = ../tui/nothing-themes/yazi/flavors/nothing.yazi;
}
