{
  pkgs,
  inputs,
  username,
  lib,
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
  xdg.userDirs = {
    enable = true;
    setSessionVariables = true;
  };

  home = {
    homeDirectory = "/home/${username}";
    stateVersion = "25.11";

    file.".config/mpv".source = ../../../materials/mpv;

    packages = with pkgs; [
      # Apps
      nano 
      bottles
      calibre
      pomodoro-gtk
      blanket
      telegram-desktop
      wget
      mpv
      mpvpaper
      imv
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
      feh
      imagemagick     
      drawio
      zola
      obsidian

      #themes
      gnome-themes-extra
      materia-theme
      arc-theme
      killall
      libnotify
      numix-cursor-theme
      # icons
      papirus-icon-theme
      hicolor-icon-theme
      # Utils
      zip
      unzip
      unrar
      git
      opencode
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
      fastfetch
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
      inputs.freesm-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default
    ];

    sessionVariables = {
      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "24";
    };
  };
}
