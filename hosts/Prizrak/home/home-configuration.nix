{config, pkgs, inputs, ...}:
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
    # tui
    ../../../modules/tui/neovim
    ../../../modules/tui/kitty
    ../../../modules/tui/zsh
    ../../../modules/tui/nh
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
      obs-vaapi #optional AMD hardware acceleration
      obs-gstreamer
      obs-vkcapture
    ];
    };

  home = {
    username = "Prizrak";
    homeDirectory = "/home/Prizrak";
    stateVersion = "25.11";

    file.".config/mpv".source = ../../../materials/mpv;
 #   file."Pictures/Wallpapers".source = ../../../materials/Wallpapers;

   
    packages = with pkgs; [
      # Apps
    	pomodoro-gtk
    	blanket
    	obsidian
    	telegram-desktop
    	lutris
    	bottles
    	mpv
      steam
    	mate.mate-polkit
      matugen
      gpu-screen-recorder
      prismlauncher
      calibre
      rnnoise-plugin
    
    	#themes 
    	gnome-themes-extra
      materia-theme
      arc-theme
    	
    	# icons
    	papirus-icon-theme
      hicolor-icon-theme
    
    	# Dev
    	nodejs
    	python313Packages.pip
      (python3.withPackages (python-pkgs: with python-pkgs; [
          # select Python packages here
          lxml
          requests
          beautifulsoup4
          rich
          pytest-subprocess
          pyqt5
          empy
          virtualenv
          click
      ]))
    	
    	# Utils
    	zip 
    	unzip
    	git
    	btop
    	neofetch
    	gdu
    	dysk 
      networkmanager_dmenu
      pavucontrol
      protontricks
      lact
    	
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
    	inputs.zen-browser.packages.${system}.default
    	inputs.anicli-ru.packages.${system}.default

    ];
  };
}
