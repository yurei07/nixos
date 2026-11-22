# desktop-entries.nix by poligle

{ config, osConfig, pkgs, lib, ... }:
let
    hidden = name:
    {
        text = ''
            [Desktop Entry]
            Type=Application
            Name=${name}
            NoDisplay=true
        '';
    };
in
{
    xdg.desktopEntries.nihil-settings =
    {
        name = osConfig.nihil.strings.cfgTitle;
        comment = osConfig.nihil.strings.cfgComment;
        exec = "nihil-ipc settings open";
        icon = "preferences-system";
        terminal = false;
        categories = [ "Settings" ];
    };

    # Files' Open with, for the kinds the photo widget shows; out of the launcher, and no
    # picture's default (viewers.nix keeps imv for each of them).
    xdg.desktopEntries.nihil-photo =
    {
        name = osConfig.nihil.strings.widgetPhotoApp;
        exec = "nihil-ipc widgets photo %f";
        icon = "image-x-generic";
        terminal = false;
        noDisplay = true;
        mimeType = [ "image/png" "image/jpeg" "image/gif" "image/bmp" "image/webp" ];
    };

    xdg.dataFile =
    {
        "applications/kitty-open.desktop"                       = hidden "kitty URL Launcher";
        "applications/org.freedesktop.Xwayland.desktop"         = hidden "Xwayland";
        "applications/xdg-desktop-portal-gtk.desktop"           = hidden "Portal";
        "applications/nixos-manual.desktop"                     = hidden "NixOS Manual";
        "applications/uuctl.desktop"                            = hidden "uuctl";
        "applications/kitty.desktop"                            = hidden "kitty";
        "applications/nvim.desktop"                             = hidden "Neovim wrapper";
        "applications/nm-applet.desktop"                        = hidden "NetworkManager Applet";
        "applications/nm-connection-editor.desktop"             = hidden "Advanced Network Configuration";
        "applications/blueman-adapters.desktop"                 = hidden "Bluetooth Adapters";
        "applications/blueman-manager.desktop"                  = hidden "Bluetooth Manager";
        "applications/org.pulseaudio.pavucontrol.desktop"       = hidden "Volume Control";
        "applications/thunar-bulk-rename.desktop"               = hidden "Bulk Rename";
        "applications/thunar-settings.desktop"                  = hidden "Thunar Preferences";
        "applications/thunar-volman-settings.desktop"           = hidden "Removable Drives and Media";

        "applications/kvantummanager.desktop"                   = hidden "Kvantum Manager";
        "applications/qt5ct.desktop"                            = hidden "Qt5 Settings";
        "applications/qt6ct.desktop"                            = hidden "Qt6 Settings";
    };
}