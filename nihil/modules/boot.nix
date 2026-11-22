# boot.nix by poligle

{ config, lib, pkgs, ... }:
{
    boot.loader.systemd-boot.enable = lib.mkDefault true;
    # The boot menu's editor lets anyone at the keyboard boot with init=/bin/sh, as root.
    boot.loader.systemd-boot.editor = lib.mkDefault false;
    boot.loader.efi.canTouchEfiVariables = lib.mkDefault true;
    boot.loader.systemd-boot.configurationLimit = lib.mkDefault 10;
    boot.supportedFilesystems = [ "exfat" "ext4" "vfat" ];
}
