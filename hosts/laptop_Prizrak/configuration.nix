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
    ./nix-modules/intel.nix
    ./nix-modules/bluetooth.nix
    ./nix-modules/users.nix
    ./nix-modules/fonts.nix
    ./nix-modules/audio.nix
    ./nix-modules/lightdm.nix
  ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.common.default = "*";

  # Battery
  services.thermald.enable = true;

  services.tlp = {
    enable = true;

    settings = {
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";
      CPU_SCALING_GOVERNOR_ON_AC = "performance";

      CPU_BOOST_ON_BAT = 0;
      CPU_BOOST_ON_AC = 1;

      RUNTIME_PM_ON_AC = "auto";
      RUNTIME_PM_ON_BAT = "auto";

      START_CHARGE_THRESH_BAT0 = 95;
      STOP_CHARGE_THRESH_BAT0 = 100;
      START_CHARGE_THRESH_BAT1 = 95;
      STOP_CHARGE_THRESH_BAT1 = 100;
    };
  };

  # boot.kernelParams = ["acpi_backlight=vendor"];
  programs.light.enable = true;


  services.upower.enable = true;
  nixpkgs.config.allowUnfree = true;

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  services.dbus.packages = with pkgs; [ dconf ];
  services.gnome.gnome-keyring.enable = true;
  programs.dconf.enable = true;

  #boot.kernelModules = [ "v4l2loopback" ];
  #boot.extraModulePackages = with config.boot.kernelPackages; [ v4l2loopback ];

  security.polkit.enable = true;

  services.flatpak.enable = true;

  environment = {
    variables = {
      GTK_THEME = "Goth_theme-2025-04-17-grey-Dark";
    };
    systemPackages = with pkgs; [
      Theme
    ];
  };

  # home-manager
  home-manager.users.laptop_Prizrak = import ./home/home-configuration.nix;

  system.stateVersion = "25.05"; # Did you read the comment?

}
