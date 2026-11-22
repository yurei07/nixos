# desktop.nix by poligle

{ config, lib, pkgs, ... }:
let
    # The plugin only looks for an archive manager's wrapper in its own folder.
    archives = pkgs.thunar-archive-plugin.overrideAttrs (old:
    {
        postInstall = (old.postInstall or "") + ''
            ln -s ${pkgs.xarchiver}/libexec/thunar-archive-plugin/xarchiver.tap $out/libexec/thunar-archive-plugin/
        '';
    });

    # Out of the launcher in its own entry. A copy among the user's applications hid it from the
    # archives too: that folder has no cache of which app opens what.
    xarchiver = pkgs.symlinkJoin
    {
        name = "xarchiver-${pkgs.xarchiver.version}";
        paths = [ pkgs.xarchiver ];
        postBuild = ''
            rm $out/share/applications/xarchiver.desktop
            sed '/^\[Desktop Entry\]$/a NoDisplay=true' ${pkgs.xarchiver}/share/applications/xarchiver.desktop \
                > $out/share/applications/xarchiver.desktop
        '';
    };
in
{
    programs.thunar = 
    {
        enable = lib.mkDefault true;
        plugins = with pkgs; 
        [
            archives
            thunar-volman
        ];
    };

    environment.systemPackages = lib.mkIf config.programs.thunar.enable [ xarchiver ];
    
    services.gvfs.enable = lib.mkDefault true;
    services.tumbler.enable = lib.mkDefault true;
}