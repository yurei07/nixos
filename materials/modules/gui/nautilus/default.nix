{pkgs, config, ... }:
{
  home = {
    packages = with pkgs; [
      nautilus
      nautilus-open-any-terminal
      gnome-epub-thumbnailer
      totem

      dconf-editor
    ];

  };

  xdg.userDirs = {
    enable = true;
    createDirectories = true;
    extraConfig = {
      XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/Pictures";
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
