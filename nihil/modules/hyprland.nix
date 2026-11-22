# hyprland.nix by poligle

{ config, lib, pkgs, ... }:
{
    programs.hyprland.enable = true;
    programs.hyprland.withUWSM = true;
}
