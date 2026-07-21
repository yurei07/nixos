# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, lib, pkgs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
    ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "server"; # Define your hostname.
  networking.networkmanager.enable = true;

  nix.settings.experimental-features = ["nix-command" "flakes" ];

  # Set your time zone.
  time.timeZone = "Europe/Berlin";
  i18n.defaultLocale = "en_US.UTF-8";

  services.openssh = {
    enable = true; 
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "no";
    };
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
   users.users.server = {
     isNormalUser = true;
     extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
   };

  # List packages installed in system profile.
  # You can use https://search.nixos.org/ to find more packages (and options).
   environment.systemPackages = with pkgs; [
     neovim
     wget
     htop
     fastfetch
   ];

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [ 22 8080 ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;
  
  
  home-manager.users.server = {pkgs, ...}: {
    imports = [
      ../../modules/tui/neovim/neovim.nix
      ../../modules/tui/kitty/kitty.nix
      ../../modules/tui/zsh/zsh.nix
      ../../modules/tui/nh/nh.nix
    ];

    home.stateVersion = "26.11";
  };
  
  # SYSTEMS 
  fileSystems."/srv/storage" = {
    device = "/dev/disk/by-uuid/73e76d85-e7d0-40a6-8224-5962acf3cb9f";
    fsType = "ext4";
    options = ["nofail"  "x-systemd.device-timeout=30" ];
  };

  # SYSTEMD 
  systemd.tmpfiles.rules = [
    "d /srv/storage 0770 server users -"
    "d /srv/filebrowser 0770 server users -"
  ];

  # SERVICES 
  services.filebrowser = {
    enable = true;
    
    user = "server";
    group = "users";

    openFirewall = true;
    
    settings = {
      port = 8080;
      address = "0.0.0.0";

      root = "/srv/storage";

      database = "/srv/filebrowser/filebrowser.db";
    };
  };

  system.stateVersion = "26.11"; # Did you read the comment?

}


