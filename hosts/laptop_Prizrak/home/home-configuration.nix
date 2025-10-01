{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    # windows manager
    ../../../modules/wm/hyprland
    # gui
    ../../../modules/gui/spicetify
    ../../../modules/gui/discord
    ../../../modules/gui/gtk
    ../../../modules/gui/quickshell
    ../../../modules/gui/rofi
    ../../../modules/gui/syncthing
    ../../../modules/gui/firefox
    # tui
    ../../../modules/tui/neovim
    ../../../modules/tui/kitty
    ../../../modules/tui/zsh
    ../../../modules/tui/nh
    ../../../modules/tui/neofetch
  ];

  systemd.user.services.polkit_mate = {
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.mate.mate-polkit}/libexec/polkit-mate-authentication-agent-1";
      Restart = "always";
      StartLimitInterval = 0;
    };
  };

  home = {
    username = "laptop_Prizrak";
    homeDirectory = "/home/laptop_Prizrak";
    stateVersion = "25.11";

    file.".config/mpv".source = ../../../materials/mpv;

    packages = with pkgs; [
      # Apps
      pomodoro-gtk
      blanket
      obsidian
      telegram-desktop
      lutris
      bottles
      xfce.thunar
      nautilus
      mpv
      steam
      mate.mate-polkit
      matugen
      gpu-screen-recorder
      prismlauncher
      foliate
      airtame
      libreoffice-qt
      pdfsam-basic

      #themes
      gnome-themes-extra
      materia-theme
      arc-theme

      # icons
      papirus-icon-theme
      hicolor-icon-theme

      # Utils
      zip
      unzip
      git
      btop
      gdu
      dysk
      networkmanager_dmenu
      pavucontrol
      protontricks
      lact
      gh
      bash
      bluez
      brightnessctl
      cava
      cliphist
      coreutils
      ddcutil
      file
      findutils
      gpu-screen-recorder
      libnotify
      matugen
      networkmanager
      wl-clipboard

      # Just cool
      peaclock
      mufetch
      neofetch
      cbonsai
      pipes
      cava
      tree
      cmatrix
      yazi

      # inputs
      inputs.hyprland.packages.${system}.hyprland
      inputs.anicli-ru.packages.${system}.default
    ];
  };
}
