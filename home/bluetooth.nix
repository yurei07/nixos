# bluetooth.nix by poligle
{ ... }:
{
    dconf.settings."org/blueman/general".plugin-list = [ "!PowerManager" "!KillSwitch" ];
}
