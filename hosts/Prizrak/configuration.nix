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

  services.gvfs.enable = true;
  services.usbmuxd.enable = true;
  # programs.adb.enable = true;
  users.users.Prizrak.extraGroups = [ "adbusers" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  programs.gpu-screen-recorder.enable = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.common.default = "*";

  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  services.dbus.packages = with pkgs; [ dconf ];
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;

  services.zerotierone.enable = true;

  # services.premid.enable = true;
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
      alacritty
      fuzzel
      swaylock
      xwayland-satellite

      xdg-desktop-portal
      xdg-desktop-portal-gnome
      xdg-desktop-portal-wlr
      xorg.xhost
    ];
  };

  # home-manager
  home-manager.users.Prizrak = import ./home/home-configuration.nix;

  system.stateVersion = "25.05"; # Did you read the comment?

}
