{
  config,
  lib,
  pkgs,
  nixpkgs,
  inputs,
  username,
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
    ./hardware-configuration.nix

    # nixos modules
    ./nix-modules/gpu.nix
    ./nix-modules/laptop.nix
    ./nix-modules/fingerprint.nix
    ./nix-modules/bluetooth.nix
    ./nix-modules/users.nix
    ./nix-modules/fonts.nix

    ./nix-modules/audio.nix
    ./nix-modules/lightdm.nix
    ./nix-modules/replays.nix

    ../../modules/gui/obs/obs.nix

  ];

  nixpkgs.overlays = [
    (final: prev: {
      pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
        (pyFinal: pyPrev: {
          patool = pyPrev.patool.overridePythonAttrs (old: {
            doCheck = false;
          });
        })
      ];
    })
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
    tailscale.enable = true;
    upower.enable = true; # battery info for the Nothing shell bar

    hardware.openrgb = {
      enable = true;
      package = pkgs.openrgb-with-all-plugins;
      motherboard = "amd";
      server = {
        port = 6742;
      };
    };
  };

  users.users.${username}.extraGroups = [ "adbusers" ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
  };

  programs = {
    gpu-screen-recorder.enable = true;
    ssh.askPassword = ""; 
    dconf.enable = true;
  };

  xdg = {
    portal = {
      enable = true;
      extraPortals = [ 
        pkgs.xdg-desktop-portal-gnome 
        pkgs.xdg-desktop-portal-gtk
      ];
      config.common.default = "*";
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # Keep the Nix store in check (this laptop has one shared root/nix partition).
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;
  boot.loader.systemd-boot.configurationLimit = 10;

  environment = {
    systemPackages = with pkgs; [
      xwayland-satellite 
    ];
  };

  # home-manager
  home-manager = {
    users.${username}= import ./home/home-configuration.nix;
    backupFileExtension = "backup";
  };
  system.stateVersion = "25.05"; # Did you read the comment?
}
