# default.nix by poligle (modules)

{ ... }:
{
    imports =
    [
        ./boot.nix
        ./network.nix
        ./locale.nix
        ./audio.nix
        ./hardware.nix
        ./users.nix
        ./packages.nix
        ./hyprland.nix
        ./regreet.nix
        ./greeter.nix
        ./desktop.nix
        ./storage.nix
        ./nix.nix
        ./plymouth.nix
        ./boot-sound.nix
        ./stylix.nix
        ./direnv.nix
        ./nihil.nix
        ./nihil-cli.nix
        ./binds.nix
        ./deck.nix
    ];
}
