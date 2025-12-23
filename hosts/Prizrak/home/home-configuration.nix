{
  config,
  pkgs,
  inputs,
  ...
}:
let
  caelestiaConfigDir = ./.;
in
{
  imports = [
    # windows manager
    ../../../modules/wm
    # gui
    ../../../modules/gui
    # tui
    ../../../modules/tui
  ];


  home = {
    username = "Prizrak";
    homeDirectory = "/home/Prizrak";
    stateVersion = "25.11";

    file.".config/mpv".source = ../../../materials/mpv;

    packages = with pkgs; [
      # Apps
      calibre
      pomodoro-gtk
      blanket
      obsidian
      telegram-desktop
      lutris
      bottles
      xfce.thunar
      nautilus
      wget
      mpv
      steam
      mate.mate-polkit
      matugen
      gpu-screen-recorder
      prismlauncher
      foliate
      scrcpy
      android-tools
      usbutils
      stress-ng
      libreoffice-qt
      quickshell
      (discord.override {
              withOpenASAR = true;
              withVencord = true;
            })
      #themes
      gnome-themes-extra
      materia-theme
      arc-theme
      killall
      libnotify

      # icons
      papirus-icon-theme
      hicolor-icon-theme

      # Utils
      zip
      unzip
      git
      btop
      bash
      gdu
      dysk
      networkmanager_dmenu
      pavucontrol
      protontricks
      lact
      gh

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
      brightnessctl
      easyeffects
      rnnoise-plugin
      lsp-plugins

      # inputs
      inputs.hyprland.packages.${stdenv.hostPlatform.system}.hyprland
      inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
      inputs.anicli-ru.packages.${stdenv.hostPlatform.system}.default
      inputs.noctalia.packages.${stdenv.hostPlatform.system}.default
      # caelestia-shell
      # caelestia-cli
    ];

  };

  # xdg.configFile."caelestia/shell.json".source = caelestiaConfigDir + "/shell.json";
  # xdg.configFile.".local/state/caelestia/scheme.json".source = caelestiaConfigDir + "/scheme.json";
}
