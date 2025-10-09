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


      # inputs
      inputs.hyprland.packages.${system}.hyprland
      inputs.anicli-ru.packages.${system}.default
    ];
  };
}
