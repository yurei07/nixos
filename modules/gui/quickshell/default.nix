{ config, lib, pkgs, inputs, ... }:

let
  homeDir = "/home/Prizrak";
  quickshellDir = "/etc/nixos/modules/gui/quickshell/quickshell";
  quickshellTarget = "${homeDir}/.config/";
  faceIconSource = "${homeDir}/nixos/assets/profile.gif";
  faceIconTarget = "${homeDir}/.face.icon";
in {
  home.activation.symlinkQuickshellAndFaceIcon = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ln -sfn "${quickshellDir}" "${quickshellTarget}"
    ln -sfn "${faceIconSource}" "${faceIconTarget}"
  '';
  
  programs.quickshell = {
    enable = true;
    package = (inputs.quickshell.packages.${pkgs.system}.default);
    systemd.enable = true;
  };

}
