{ pkgs, ... }:
{

  systemd.user.services.polkit_mate = {
    Install = {
      WantedBy = [ "hyprland-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.mate.mate-polkit}/libexec/polkit-mate-authentication-agent-1";
      Restart = "always";
      StartLimitInterval = 0;
    };
  };
}
