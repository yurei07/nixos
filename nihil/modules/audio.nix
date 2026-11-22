# audio.nix by poligle

{ config, lib, pkgs, ... }:
{
    services.pulseaudio.enable = lib.mkDefault false;
    security.rtkit.enable = lib.mkDefault true;
    services.pipewire = 
    {
        enable = lib.mkDefault true;
        alsa.enable = lib.mkDefault true;
        alsa.support32Bit = lib.mkDefault true;
        pulse.enable = lib.mkDefault true;
    };
}