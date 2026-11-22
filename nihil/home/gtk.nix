# gtk.nix by poligle

{ config, pkgs, lib, ... }:
let
    colors = config.lib.stylix.colors.withHashtag;
in
{
    gtk =
    {
        enable = true; 

        theme.name = lib.mkForce "adw-gtk3-dark";

        iconTheme =
        {
            name = "Colloid-Grey-Dark";
            package = pkgs.colloid-icon-theme.override { colorVariants = [ "grey" ]; };
        };

        gtk3.extraConfig = 
        {
            gtk-toolbar-style = "GTK_TOOLBAR_ICONS";
            gtk-toolbar-icon-size = "GTK_ICON_SIZE_LARGE_TOOLBAR";
            gtk-button-images = 0;
            gtk-menu-images = 0;
            gtk-enable-event-sounds = 1;
            gtk-enable-input-feedback-sounds = 0;
            gtk-xft-antialias = 1;
            gtk-xft-hinting = 1;
            gtk-xft-hintstyle = "hintslight";
            gtk-xft-rgba = "rgb";
        };

        # GTK 4 has no toolbar style or button and menu images: it warns of each key it doesn't know.
        gtk4.extraConfig = 
        {
            gtk-enable-event-sounds = 1;
            gtk-enable-input-feedback-sounds = 0;
            gtk-xft-antialias = 1;
            gtk-xft-hinting = 1;
            gtk-xft-hintstyle = "hintslight";
            gtk-xft-rgba = "rgb";
        };
    };

    stylix.targets.gtk.extraCss = ''
        @define-color destructive_fg_color ${colors.base06};
        @define-color error_fg_color ${colors.base06};
        @define-color theme_selected_bg_color alpha(${colors.base06}, 0.25);
        @define-color theme_selected_fg_color ${colors.base06};

        .view:selected, .view:selected:focus, iconview:selected, iconview:selected:focus,
        treeview.view:selected, treeview.view:selected:focus, flowbox flowboxchild:selected,
        .view text:selected, iconview text:selected, textview text:selected,
        .view text selection, iconview text selection, textview text selection,
        entry selection, label selection, .cell:selected
        {
            background-color: alpha(${colors.base06}, 0.25);
            color: ${colors.base06};
        }
    '';

    home.packages = 
    [
        pkgs.noto-fonts-cjk-sans
    ];
}