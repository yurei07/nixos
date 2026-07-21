{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.user.services.replays = {
    Unit.After = [ "graphical-session.target" ];
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      Type = "simple"; 
      Restart = "always";
      ExecStart = ''
        export PATH=/run/wrappers/bin:$PATH
        exec gpu-screen-recorder -w DP-1 -q ultra -a default_output -a default_input -f 60 -r 300 -c mp4 -o ~/Games/Replays
      '';
    };
  };
}
