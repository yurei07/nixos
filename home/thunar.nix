# thunar.nix by poligle

{ config, pkgs, ... }:
{
    xdg.dataFile."xfce4/helpers/kitty.desktop".text = ''
        [Desktop Entry]
        Version=1.0
        Type=X-XFCE-Helper
        Encoding=UTF-8
        NoDisplay=true
        Name=Kitty
        Icon=kitty
        X-XFCE-Category=TerminalEmulator
        X-XFCE-Binaries=kitty;
        X-XFCE-Commands=kitty;
        X-XFCE-CommandsWithParameter=kitty -e %s;
    '';

    xdg.configFile."xfce4/helpers.rc".text = ''
        TerminalEmulator=kitty
    '';
}