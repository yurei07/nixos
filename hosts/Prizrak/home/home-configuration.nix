{
  pkgs,
  inputs,
  username,
  lib,
  ...
}:
{
  imports = [
    ../../../modules/wm
    ../../../modules/gui
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

    packages =
      with pkgs;
      [
        # desktop apps
        calibre
        foliate
        libreoffice-qt
        obsidian
        telegram-desktop
        vesktop

        # shell runtime / auth
        quickshell
        mate-polkit

        # media
        mpv
        mpvpaper
        imv
        feh
        imagemagick

        # gaming
        bottles
        protontricks
        steam
        gpu-screen-recorder
        scrcpy

        # system / cli utils
        nano
        wget
        zip
        unzip
        unrar
        git
        opencode
        gh
        btop
        gdu
        dysk
        networkmanager_dmenu
        pavucontrol
        pulseaudio
        usbutils
        stress-ng
        killall
        libnotify
        hicolor-icon-theme
        brightnessctl
        easyeffects
        rnnoise-plugin
        lsp-plugins

        # fun / misc
        peaclock
        mufetch
        fastfetch
        cbonsai
        pipes
        cava
        tree
        cmatrix
        yazi
        matugen
        drawio
        zola
        pomodoro-gtk
        blanket

        # from flakes
        inputs.freesm-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default
        inputs.zen-browser.packages.${pkgs.stdenv.hostPlatform.system}.default
      ];

    sessionVariables = {
      XCURSOR_THEME = "Bibata-Modern-Ice";
      XCURSOR_SIZE = "24";
    };
  };
}
