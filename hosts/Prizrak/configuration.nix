{
  config,
  lib,
  pkgs,
  nixpkgs,
  inputs,
  ...
}:
let
  creamlinux = import (pkgs.fetchFromGitHub {
    owner = "Novattz";
    repo = "creamlinux-installer";
    rev = "main"; # replace with a commit hash to pin the version
    hash = "sha256-sV23mp0XnJHf4oSqqvFLFfvSkssHzxafqYMNw3HGEdg="; # paste the value returned by the error your rebuild will output
  }) { inherit pkgs; };
in
{
  imports = [
    ./../../materials/themes/prizrak.nix

    ./hardware-configuration.nix

    # nixos modules
    ./nix-modules/nvidia.nix
    ./nix-modules/bluetooth.nix
    ./nix-modules/users.nix
    ./nix-modules/fonts.nix

    ./nix-modules/audio.nix
    ./nix-modules/lightdm.nix
    ./nix-modules/replays.nix

    ../../modules/gui/obs/obs.nix

  ];

  replays.enable = true;

  virtualisation.docker.enable = true;

  nixpkgs.config.allowUnfree = true;

  services = {
    gvfs.enable = true;
    usbmuxd.enable = true;
    gnome.gnome-browser-connector.enable = true;
    gnome.gnome-keyring.enable = true;
    dbus.packages = with pkgs; [ dconf ];
    zerotierone.enable = true;
    flatpak.enable = true;

    hardware.openrgb = {
      enable = true;
      package = pkgs.openrgb-with-all-plugins;
      motherboard = "amd";
      server = {
        port = 6742;
      };
    };
  };

  users.users.Prizrak.extraGroups = [ "adbusers" ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  programs = {
    gpu-screen-recorder.enable = true;
    ssh.askPassword = ""; 
    dconf.enable = true;
  };

  xdg.portal = {
    enable = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-gnome 
      pkgs.xdg-desktop-portal-gtk
    ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];



  environment = {
    systemPackages = with pkgs; [
      xwayland-satellite
      creamlinux 
    ];
  };

  # home-manager
  home-manager.users.Prizrak = import ./home/home-configuration.nix;
  system.stateVersion = "25.05"; # Did you read the comment?
}
