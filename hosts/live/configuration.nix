# Live ISO: boots straight into Hyprland with the full Nothing shell so you can
# try the setup before installing. The whole repo is available at /etc/nixos and
# `nixinstall` (in any terminal) performs the guided installation.
{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:
{
  imports = [
    "${inputs.nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix"
    ../Prizrak/modules/audio.nix
    ../Prizrak/modules/fonts.nix
    ../Prizrak/modules/bluetooth.nix
  ];

  # ISO branding
  image.fileName = "nixos-nothing.iso";
  isoImage.volumeID = "NOTHING_NIXOS";

  # silence the 26.11 zfs default warning; the ISO has no zfs anyway
  boot.zfs.forceImportRoot = true;

  nixpkgs.config.allowUnfree = true;

  # flakes must be enabled in the installer's own nix.conf for nixos-install --flake
  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  # the repo itself, ready to install: rsync it to /mnt/etc/nixos
  environment.etc."nixos".source = ../..;

  # welcome card shown by Hyprland on the live desktop
  environment.etc."nixos-live/welcome".source = ./welcome.sh;
  environment.etc."nixos-live/flag".text = "";

  # autologin on tty1, which immediately starts Hyprland (environment.extraInit below)
  services.getty.autologinUser = "nixos";

  environment.extraInit = ''
    # live ISO: tty1 autologin drops straight into Hyprland
    if [ "$(tty)" = "/dev/tty1" ] && [ -z "$HYPRLAND_STARTED" ]; then
      export HYPRLAND_STARTED=1
      exec ${inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland}/bin/Hyprland
    fi
  '';

  users.users.nixos.extraGroups = [
    "wheel"
    "video"
    "audio"
    "input"
    "networkmanager"
  ];

  networking.networkmanager.enable = true;

  # compressed RAM swap keeps the live session comfortable
  zramSwap.enable = true;

  # portals for Wayland apps in the live session
  xdg.portal = {
    enable = true;
    extraPortals = [
      pkgs.xdg-desktop-portal-gnome
      pkgs.xdg-desktop-portal-gtk
    ];
    config.common.default = "*";
  };

  services.gvfs.enable = true;

  # installer tooling
  environment.systemPackages = with pkgs; [
    rsync
    nano
    curl
    wget
    pciutils
    usbutils
    # /usr/bin/env nixinstall -> the script shipped inside the repo
    (pkgs.runCommand "nixinstall-bin" { } ''
      mkdir -p $out/bin
      ln -s /etc/nixos/scripts/nixinstall $out/bin/nixinstall
    '')
  ];

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = {
      inherit inputs;
    };
    users.nixos = {
      imports = [ ./home ];
    };
  };

  system.stateVersion = "25.11";
}
