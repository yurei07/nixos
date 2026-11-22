# nix.nix by poligle
{ config, lib, pkgs, ... }:
{
    options.nihil.generations.days = lib.mkOption
    {
        type = lib.types.ints.between 1 3650;
        default = 7;
        description = "How many days generations stay before the weekly clean removes them (settings.json's generations.days).";
    };

    config =
    {
        nix =
        {
            settings.experimental-features = [ "nix-command" "flakes" ];
            settings.auto-optimise-store = lib.mkDefault true;
            gc =
            {
                automatic = lib.mkDefault true;
                dates = lib.mkDefault "weekly";
                options = lib.mkDefault "--delete-older-than ${toString config.nihil.generations.days}d";
            };
        };

        # Collecting removes generations but not their boot entries: the menu kept offering ones
        # that no longer exist. Writing the entries again after it is what nihil generations clean does.
        systemd.services.nix-gc.serviceConfig.ExecStartPost =
            [ "/nix/var/nix/profiles/system/bin/switch-to-configuration boot" ];

        programs.nh =
        {
            enable = true;
            flake = config.nihil.flake;
        };
    };
}
