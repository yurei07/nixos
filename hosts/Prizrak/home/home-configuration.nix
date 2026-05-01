{
  config,
  pkgs,
  inputs,
  ...
}:
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
      nautilus
      wget
      mpv
      steam
      mate-polkit
      matugen
      gpu-screen-recorder
      foliate
      scrcpy
      usbutils
      stress-ng
      libreoffice-qt
      quickshell
      vesktop

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
      pulseaudio

      # Just cool
      peaclock
      mufetch
      # neofetch
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
      # inputs.niri.packages.${stdenv.hostPlatform.system}.niri
      inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
      inputs.prismlauncher.packages.${stdenv.hostPlatform.system}.default
      inputs.noctalia.packages.${stdenv.hostPlatform.system}.default
    ];
  };
}
