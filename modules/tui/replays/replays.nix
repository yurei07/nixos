{
  config,
  lib,
  pkgs,
  ...
}:
{
  systemd.user.services.replays = {
    # enable = true;
    Unit.After = [ "graphical-session.target" ];
    Install.WantedBy = [ "graphical-session.target" ];
    Service = {
      Type = "simple"; 
      Restart = "always";
      ExecStart = ''
        export PATH=/run/wrappers/bin:$PATH
        exec gpu-screen-recorder -w screen -q ultra -a default_output -a default_input -f 60 -r 300 -c mp4 -o ~/Games/Replays
      '';
    };
  };
}
