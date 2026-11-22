# plymouth.nix by poligle

{ config, lib, pkgs, ... }:
let
  splashSeconds = "4.5";
  waitForSound = config.nihil.bootSound;
  litSeconds = "1.5";

  splashWait = pkgs.writeShellScript "nihil-splash-wait" ''
    read -r pid 2>/dev/null < /run/plymouth/pid || exit 0
    [ -r "/proc/$pid/stat" ] || exit 0
    read -r -a stat < "/proc/$pid/stat"
    read -r now _ < /proc/uptime
    opened=0
    if ${lib.boolToString waitForSound}; then
      read -r opened _ 2>/dev/null < /run/nihil/splash-open || opened=""
      if [ -z "$opened" ]; then
        ${config.boot.plymouth.package}/bin/plymouth update --status=nihil-open 2>/dev/null || true
        opened=$now
      fi
    fi
    wall=$(${pkgs.coreutils}/bin/date +%s.%N)
    card=$(${pkgs.coreutils}/bin/stat -c %.3Z /dev/dri/card* 2>/dev/null | ${pkgs.coreutils}/bin/sort -n | ${pkgs.coreutils}/bin/tail -n 1)
    left=$(${pkgs.gawk}/bin/awk -v started="''${stat[21]}" -v now="$now" -v wall="$wall" -v card="''${card:-0}" \
      -v want=${splashSeconds} -v opened="$opened" -v lit=${litSeconds} 'BEGIN {
        shown = started / 100
        if (card > 0 && now - (wall - card) > shown) shown = now - (wall - card)
        w = want - (now - shown); if (w > want) w = want
        if (opened > 0 && opened + lit - now > w) w = opened + lit - now
        printf "%.2f", (w > 0 ? w : 0) }')
    exec ${pkgs.coreutils}/bin/sleep "$left"
  '';
in
{
  boot = 
  {
    plymouth =
    {
      enable = lib.mkDefault true;

      theme = lib.mkDefault "nihil";
      themePackages = [ (import ../theme/plymouth.nix { inherit pkgs waitForSound; passphrase = config.nihil.strings.diskPassphrase; }) ];
    };

    consoleLogLevel = lib.mkDefault 3;
    initrd.verbose = lib.mkDefault false;
    kernelParams = 
    [
      "quiet"
      "splash"
      "udev.log_level=3"
      "systemd.show_status=auto"
      "rd.udev.log_level=3"
    ];
  };

  stylix.targets.plymouth.enable = lib.mkDefault false;

  systemd.services = lib.genAttrs [ "plymouth-poweroff" "plymouth-reboot" "plymouth-halt" "plymouth-kexec" ] (_:
  {
    serviceConfig.ExecStartPost = [ "-${pkgs.coreutils}/bin/sleep ${splashSeconds}" ];
  })
  //
  {
    plymouth-quit.serviceConfig.ExecStartPre = [ "${splashWait}" ];
  };
}
