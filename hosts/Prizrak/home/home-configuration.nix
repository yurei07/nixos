{
  config,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    ./development
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
  programs.obs-studio = {
    enable = true;

    package = (
      pkgs.obs-studio.override {
        cudaSupport = true;
      }
    );

    plugins = with pkgs.obs-studio-plugins; [
      wlrobs
      obs-backgroundremoval
      obs-pipewire-audio-capture
      obs-vaapi # optional AMD hardware acceleration
      obs-gstreamer
      obs-vkcapture
    ];
  };

  home = {
    username = "Prizrak";
    homeDirectory = "/home/Prizrak";
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
      wget
      mpv
      steam
      mate.mate-polkit
      matugen
      gpu-screen-recorder
      prismlauncher
      foliate

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

      # inputs
      inputs.hyprland.packages.${system}.hyprland
      inputs.anicli-ru.packages.${system}.default
    ];
  };
}
