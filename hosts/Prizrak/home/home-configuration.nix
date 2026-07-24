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

  # gtk.cursorTheme = {
  #   name = "Numix-Cursor";
  #   package = pkgs.numix-cursor-theme;
  #   size = 24;
  # };
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
      inputs.freesm-launcher.packages.${stdenv.hostPlatform.system}.default
      inputs.zen-browser.packages.${stdenv.hostPlatform.system}.default
      inputs.noctalia.packages.${stdenv.hostPlatform.system}.default
    ];

    sessionVariables = {
      XCURSOR_THEME = "Numix-Cursor";
      XCURSOR_SIZE = "24";
    };
  };
}
