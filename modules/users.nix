# users.nix by poligle

{ config, lib, pkgs, ... }:
let
    user = config.nihil.user;
in
{
    programs.zsh.enable = true;

    users.users.${user.name} =
    {
        isNormalUser = true;
        description = user.fullName;
        # Above nixpkgs' own default for normal users (a mkDefault too), below a plain value in local.nix.
        shell = lib.mkOverride 900 pkgs.zsh;
        extraGroups = [ "wheel" "networkmanager" "video" "nihil-leds" ];
    };

    users.groups.nihil-leds = { };
}
