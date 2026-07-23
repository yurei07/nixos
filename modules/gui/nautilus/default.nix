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

  xdg.configFile."noctalia/config.toml".text = ''
  [shell]
  corner_radius_scale = 0.0

  [shell.panel]
  borders = false
  shadow = true

  [bar.main]
  radius = 0
  capsule = false
'';
}
