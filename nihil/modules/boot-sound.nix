# boot-sound.nix by poligle

{ config, lib, pkgs, ... }:
let
    user = config.nihil.user.name;
    silent = "${config.home-manager.users.${user}.xdg.stateHome}/nihil/silent";

    play = pkgs.writeShellScript "nihil-boot-sound" ''
        export PATH=${lib.makeBinPath [ pkgs.alsa-utils pkgs.gnugrep pkgs.coreutils ]}
        open() {
            mkdir -p /run/nihil
            read -r up _ < /proc/uptime
            echo "$up" > /run/nihil/splash-open
            ${config.boot.plymouth.package}/bin/plymouth update --status=nihil-open 2> /dev/null || true
        }
        if [ -e ${lib.escapeShellArg silent} ]; then
            open
            exit 0
        fi
        for pcm in /proc/asound/card*/pcm*p; do
            [ -d "$pcm" ] || continue
            grep -qiE 'hdmi|displayport' "$pcm/info" 2> /dev/null && continue
            card=''${pcm#/proc/asound/card}
            card=''${card%%/*}
            device=''${pcm##*/pcm}
            device=''${device%p}
            amixer -q -M -c "$card" sset Master 55% unmute 2> /dev/null || true
            for control in PCM Speaker Headphone; do
                amixer -q -M -c "$card" sset "$control" 100% unmute 2> /dev/null || true
            done
            aplay -q -D "plughw:$card,$device" ${../sounds/nihil/boot.wav} &
            sleep 0.05
            open
            wait
            exit 0
        done
        open
    '';
in
{
    options.nihil.bootSound = lib.mkOption
    {
        type = lib.types.bool;
        default = true;
        description = "A sound with the boot splash (modules/boot-sound.nix).";
    };

    config.systemd.services.nihil-boot-sound = lib.mkIf config.nihil.bootSound
    {
        description = "NIHIL: the sound of the boot splash";
        wantedBy = [ "sound.target" ];
        after = [ "sound.target" ];
        before = [ "plymouth-quit.service" ];
        unitConfig.ConditionPathExists = "/run/plymouth/pid";
        restartIfChanged = false;
        serviceConfig =
        {
            Type = "oneshot";
            ExecStart = play;
            TimeoutStartSec = 10;
        };
    };
}
