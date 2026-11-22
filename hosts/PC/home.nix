# This machine's Home Manager config, on top of NIHIL's own home.
{ config, lib, pkgs, theme, machineInputs, ... }:
{
	imports = [
		./user-modules/neovim/neovim.nix
		./user-modules/fastfetch/fastfetch.nix
	];

	home.packages = with pkgs; [
		# desktop apps
		calibre
		foliate
		libreoffice-qt
		obsidian
		telegram-desktop
		vesktop

		# arduino development
		arduino-ide
		arduino-cli

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
		machineInputs.freesm-launcher.packages.${pkgs.stdenv.hostPlatform.system}.default

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
		pulseaudio # pactl and friends; the server itself is PipeWire
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
	];

	xdg.userDirs = {
		enable = true;
		setSessionVariables = true;
	};

	home.file.".config/mpv".source = ./materials/mpv;
}
