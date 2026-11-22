# home.nix by poligle

{ config, osConfig, pkgs, lib, inputs, ... }:
{
	imports =
	[
		./home/gtk.nix
		./home/nvim.nix
		./home/zsh.nix
		./home/thunar.nix
		./home/hyprland.nix
		./home/kitty.nix
		./home/scripts.nix
		./home/desktop-entries.nix
		./home/default-apps.nix
		./home/viewers.nix
		./home/wallpaper.nix
		./home/hypridle.nix
		./home/hyprlock.nix
		./home/zen.nix
		./home/bluetooth.nix
		./home/cli.nix
		./home/refresh.nix
		./home/shell.nix
		./home/fastfetch.nix
		./home/clipboard.nix
		./home/deck.nix
	];

	home.stateVersion = "26.05";
	programs.home-manager.enable = true;

	home.packages =
	[
		pkgs.pavucontrol
		pkgs.networkmanagerapplet
		pkgs.libnotify
		pkgs.awww
		pkgs.grim
		pkgs.slurp
		pkgs.hyprpicker
	];
}
