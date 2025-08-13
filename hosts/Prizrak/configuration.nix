{ config, lib, pkgs, nixpkgs, inputs, ... }:
{
  imports =
    [
      ./hardware-configuration.nix

      # nixos modules
      ./nix-modules/nvidia.nix
      ./nix-modules/bluetooth.nix
      ./nix-modules/users.nix
      ./nix-modules/fonts.nix
      ./nix-modules/audio.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.common.default = "*";

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = ["nix-command" "flakes"]; 

  programs.dconf.enable = true;

  security.polkit.enable = true;

  environment = {
    variables = {
      GTK_THEME = "catppuccin-mocha-lavender-compact";
    };
    systemPackages = with pkgs; [
      #...
    ];
  };

  # home-manager
  home-manager.users.Prizrak = import ./home/home-configuration.nix;

  system.stateVersion = "25.05"; # Did you read the comment?

}

