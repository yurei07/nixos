{
  config,
  lib,
  pkgs,
  inputs,
  username,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix

    # host-specific system modules
    ./modules/gpu.nix
    ./modules/laptop.nix
    ./modules/fingerprint.nix
    ./modules/bluetooth.nix
    ./modules/arduino.nix
    ./modules/users.nix
    ./modules/fonts.nix
    ./modules/audio.nix
    ./modules/lightdm.nix
    ./modules/replays.nix

    # system-level graphical apps
    ./modules/obs.nix
  ];

  # patool is only needed for bottles; the upstream test suite fails in the Nix
  # build environment, so skip it.
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
    upower.enable = true; # battery info for the nothing-shell bar

    hardware.openrgb = {
      enable = true;
      package = pkgs.openrgb-with-all-plugins;
      motherboard = "amd";
      server.port = 6742;
    };
  };

  users.users.${username}.extraGroups = [ "adbusers" ];

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    loader.systemd-boot.configurationLimit = 10;
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
    config.common.default = "*";
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };
  nix.optimise.automatic = true;

  environment.systemPackages = with pkgs; [
    xwayland-satellite
  ];

  home-manager = {
    users.${username} = import ./home/home-configuration.nix;
    backupFileExtension = "backup";
  };

  system.stateVersion = "25.05";
}
