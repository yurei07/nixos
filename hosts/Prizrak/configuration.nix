{
  config,
  lib,
  pkgs,
  nixpkgs,
  inputs,
  ...
}:
let
  Theme = import ../../modules/gui/gtk/packages_theme.nix { inherit pkgs; };
in
{
  imports = [
    ./hardware-configuration.nix

    # nixos modules
    ./nix-modules/nvidia.nix
    ./nix-modules/bluetooth.nix
    ./nix-modules/users.nix
    ./nix-modules/fonts.nix
    ./nix-modules/audio.nix
    ./nix-modules/lightdm.nix

    ../../modules/gui/obs/obs.nix
  ];
  services.gvfs.enable = true;
  services.usbmuxd.enable = true;
  programs.adb.enable = true;
  users.users.Prizrak.extraGroups = [ "adbusers" ];
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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
  
  # services.premid.enable = true;
  services.flatpak.enable = true;

  environment = {
    variables = {
      GTK_THEME = "Goth_theme-2025-04-17-grey-Dark";
    };
    systemPackages = with pkgs; [
      Theme
      ifuse
      libimobiledevice
      usbmuxd
    ];
  };

  # home-manager
  home-manager.users.Prizrak = import ./home/home-configuration.nix;

  system.stateVersion = "25.05"; # Did you read the comment?

}
