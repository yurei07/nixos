{
  config,
  lib,
  pkgs,
  nixpkgs,
  inputs,
  ...
}:
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

  services.gvfs.enable = true;
  services.usbmuxd.enable = true;
  # programs.adb.enable = true;
  users.users.Prizrak.extraGroups = [ "adbusers" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  programs.gpu-screen-recorder.enable = true;
  
  programs.ssh.askPassword = ""; 

  xdg.portal = {
    enable = true;
    extraPortals = [ 
      pkgs.xdg-desktop-portal-gnome 
      pkgs.xdg-desktop-portal-gtk
    ];
    
    config = {
      common = {
        default = [ "gtk" ];
      };
      niri = {
        "org.freedesktop.impl.portal.ScreenCast" = "gnome";
        "org.freedesktop.impl.portal.Screenshot" = "gnome";
      };
    };
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  services.dbus.packages = with pkgs; [ dconf ];
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;

  services.zerotierone.enable = true;

  services.flatpak.enable = true;

  services.hardware.openrgb = {
    enable = true;
    package = pkgs.openrgb-with-all-plugins;
    motherboard = "amd";
    server = {
      port = 6742;
    };
  };

  environment = {
    systemPackages = with pkgs; [
      xwayland-satellite
    ];
  };

  # home-manager
  home-manager.users.Prizrak = import ./home/home-configuration.nix;

  system.stateVersion = "25.05"; # Did you read the comment?

}
