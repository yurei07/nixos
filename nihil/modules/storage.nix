# storage.nix by poligle

{ config, lib, pkgs, ... }:
{
    # udisks2's own rules: removable drives mount without asking, the disk's own partitions (another
    # system's, Windows') with the password.
    services.udisks2.enable = true;
}
