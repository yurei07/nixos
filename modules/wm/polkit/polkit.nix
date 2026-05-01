{ pkgs, ... }:
{

systemd.user.services.polkit_mate = {
  Unit = {
    Description = "Polkit MATE Authentication Agent";
    After = [ "graphical-session-pre.target" ];
    PartOf = [ "graphical-session.target" ];
  };
  Service = {
    ExecStart = "${pkgs.mate.mate-polkit}/libexec/polkit-mate-authentication-agent-1";
    Restart = "always";
    RestartSec = 1;
  };
  Install = {
    WantedBy = [ "hyprland-session.target" "graphical-session.target" ];
  };
};
}
