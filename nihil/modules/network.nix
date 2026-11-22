# network.nix by poligle

{ config, lib, pkgs, ... }:
{
    networking.networkmanager.enable = true;
    hardware.bluetooth.enable = true;
    # Bluetooth is off while rfkill blocks it, which is how the shell turns it off, and
    # systemd-rfkill keeps that block through restarts, sleep and the adapter coming back.
    hardware.bluetooth.powerOnBoot = lib.mkDefault true;
    services.blueman.enable = true;
    networking.networkmanager.wifi.powersave = lib.mkDefault false;
}
