# locale.nix by poligle

{ config, lib, pkgs, ... }:
{
    console =
    {
        font = lib.mkDefault "Lat2-Terminus16";
        useXkbConfig = lib.mkDefault true;
    };

    # The check X's own module makes, which only runs with X on: a layout or variant that doesn't
    # exist stops the build, rather than leaving the greeter, under cage, with no keyboard.
    system.checks = lib.optional (!config.services.xserver.enable) (pkgs.runCommand "xkb-validated"
    {
        inherit (config.services.xserver.xkb) dir model layout variant options;
        nativeBuildInputs = [ pkgs.buildPackages.xkbvalidate ];
        preferLocalBuild = true;
    } ''
        XKB_CONFIG_ROOT="$dir" xkbvalidate "$model" "$layout" "$variant" "$options"
        touch "$out"
    '');
}
