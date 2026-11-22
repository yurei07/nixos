# packages.nix by poligle

{ config, lib, pkgs, ... }:
{
    environment.systemPackages = with pkgs; 
    [
        wev
        wget
        git
        unzip
        lxqt.lxqt-policykit
        fastfetch
        btop
        brightnessctl
        playerctl
        trash-cli
        sound-theme-freedesktop
    ];

    fonts.packages = with pkgs; 
    [
        nerd-fonts.jetbrains-mono
        nerd-fonts.hack
    ];
}
