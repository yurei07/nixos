{config, pkgs, inputs, ...}:
{
  imports = [
    # windows manager
    ../../../modules/wm/hyprland
    # gui
    ../../../modules/gui/spicetify
    ../../../modules/gui/discord
    ../../../modules/gui/gtk
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

  home = {
    username = "Prizrak";
    homeDirectory = "/home/Prizrak";
    stateVersion = "25.11";

    file.".config/mpv".source = ../../../materials/mpv;
    #file."Pictures/Wallpapers".source = ../../../materials/Wallpapers;
   
    packages = with pkgs; [
      # Apps
    	pomodoro-gtk
    	blanket
    	obsidian
    	telegram-desktop
    	obs-studio
    	lutris
    	bottles
    	steam
    	mpv
    	mate.mate-polkit
      orchis-theme
    
    
    	#themes 
    	gnome-themes-extra
      materia-theme
      arc-theme
    	
    	# icons
    	papirus-icon-theme
      hicolor-icon-theme
    
    	# Dev
    	nodejs
    	python3
    	python313Packages.pip
    	
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
    	xdg-desktop-portal
    	
    	# Just cool
    	peaclock
    	cbonsai
    	pipes
    	cava
    	cmatrix
    	yazi
    
    	# inputs
    	inputs.hyprland.packages.${system}.hyprland
    	inputs.quickshell-custom.packages.${system}.default
    	inputs.app2unit.packages.${system}.default
    	inputs.caelestia-cli.packages.${system}.default
    	inputs.zen-browser.packages.${system}.default
    	inputs.anicli-ru.packages.${system}.default
    ];
  };
}
