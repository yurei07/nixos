# stylix.nix by poligle

{ config, lib, pkgs, ... }:
let
    nihil = config.nihil;
    tokens = nihil.tokens;
in
{
    stylix = 
    {
        enable = true;
        image = "${nihil.wallpapers}/${nihil.wallpaper}/${nihil.primaryOutput}.png";
        base16Scheme = tokens.base16;
        polarity = lib.mkDefault "dark";

        cursor = 
        {
            package = lib.mkDefault pkgs.bibata-cursors;
            name = lib.mkDefault "Bibata-Modern-Classic";
            size = lib.mkDefault 15;
        };

        fonts = 
        {
            monospace = 
            {
                package = lib.mkDefault pkgs.nerd-fonts.jetbrains-mono;
                name = lib.mkDefault tokens.fonts.code;
            };
            sansSerif = 
            {
                package = lib.mkDefault nihil.fonts;
                name = lib.mkDefault tokens.fonts.sans;
            };
            emoji = 
            {
                package = lib.mkDefault pkgs.noto-fonts-color-emoji;
                name = lib.mkDefault "Noto Color Emoji";
            };
            sizes = 
            {
                terminal = lib.mkDefault 11;
                applications = lib.mkDefault 11;
                desktop = lib.mkDefault 10;
                popups = lib.mkDefault 10;
            };
        };

        opacity = 
        {
            terminal = lib.mkDefault 0.9;
            popups = lib.mkDefault 0.8;
        };
    };
}
