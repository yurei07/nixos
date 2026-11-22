# Nautilus file manager and desktop integration.
{
  pkgs,
  config,
  lib,
  ...
}:
{
  home.packages = with pkgs; [
    nautilus
    nautilus-open-any-terminal
    gnome-epub-thumbnailer
    totem
    dconf-editor
  ];

  xdg.userDirs = {
    enable = true;
    setSessionVariables = lib.mkDefault false;
    createDirectories = true;
    extraConfig = {
      SCREENSHOTS = "${config.home.homeDirectory}/Pictures/Screenshots";
    };
  };

  dconf.settings = {
    "org/gnome/nautilus/preferences" = {
      recursive-search = "always";
      sort-directories-first = true;
      show-hidden-files = true;
    };

    "org/gnome/Nautilus/Extension/OpenAnyTerminal" = {
      terminal = "kitty";
    };
  };
}
