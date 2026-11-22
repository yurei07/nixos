# Generic install target used by scripts/nixinstall (see /etc/nixos/scripts).
# Hardware-specific parts (disk layout, GPU vendor) are generated at install
# time; everything else is the full Prizrak desktop.
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
    ./modules/gpu.nix
    ./modules/users.nix
    # shared, machine-independent modules reused from the Prizrak laptop host
    ../Prizrak/modules/audio.nix
    ../Prizrak/modules/fonts.nix
    ../Prizrak/modules/bluetooth.nix
    ../Prizrak/modules/arduino.nix
    ../Prizrak/modules/lightdm.nix
  ];

  time.timeZone = "Europe/Berlin"; # nixinstall rewrites this
  i18n.defaultLocale = "en_US.UTF-8";

  nixpkgs.config.allowUnfree = true;

  # patool tests fail in the Nix build env; needed by bottles
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

  # works on any machine: firmware + microcode for both CPU vendors
  hardware.enableRedistributableFirmware = true;
  hardware.cpu.amd.updateMicrocode = true;
  hardware.cpu.intel.updateMicrocode = true;

  # maintenance
  services.fwupd.enable = true;
  services.power-profiles-daemon.enable = true;
  services.fstrim.enable = true;

  # compressed RAM swap, independent of any swap partition
  zramSwap.enable = true;

  # portals for Wayland apps
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

  boot = {
    loader.systemd-boot.enable = true;
    loader.efi.canTouchEfiVariables = true;
    loader.systemd-boot.configurationLimit = 10;
  };

  home-manager = {
    users.${username} = import ./home/home-configuration.nix;
    backupFileExtension = "backup";
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs username;
      theme = inputs.chiaroscuro.themes.kanso-zen;
    };
  };

  system.stateVersion = "25.11";
}
