{ config, lib, pkgs, ... }:

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
}
