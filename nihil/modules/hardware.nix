# hardware.nix by poligle

{ config, lib, pkgs, ... }:
let
    greeter = config.services.greetd.settings.default_session.user;
    # Says 1 to skip the fingerprint, 0 not to: pam_exec logs every exit but 0 as an error, and
    # not skipping is what happens nearly always. If it fails itself, the password is asked for.
    skipReader = pkgs.writeShellScript "skip-fingerprint" ''
        for state in /proc/acpi/button/lid/*/state; do
            [ -r "$state" ] || continue
            ${pkgs.gnugrep}/bin/grep -q closed "$state" && exit 1
        done
        # A regular file, and no more of it than a PID: a FIFO or a link to /dev/zero, the user's
        # own to make, would hang sudo or read forever.
        if [ "''${PAM_SERVICE:-}" = sudo ] && uid=$(${pkgs.coreutils}/bin/id -u -- "''${PAM_USER:-}" 2> /dev/null); then
            flag="/run/user/$uid/nihil-sudo-password"
            if [ -f "$flag" ] && [ ! -L "$flag" ] && [ "$(${pkgs.coreutils}/bin/head -c 16 -- "$flag")" = "$PPID" ]; then
                exit 1
            fi
        fi
        # Once: after a password typed in the greeter, the next login offers the finger again.
        if [ "''${PAM_SERVICE:-}" = greetd ] && uid=$(${pkgs.coreutils}/bin/id -u -- ${greeter} 2> /dev/null) \
            && [ -e "/run/user/$uid/nihil-greeter-password" ]; then
            ${pkgs.coreutils}/bin/rm -f "/run/user/$uid/nihil-greeter-password"
            exit 1
        fi
        exit 0
    '';

    skipFingerprint = service:
    {
        rules.auth.skipFingerprint =
        {
            enable = config.security.pam.services.${service}.fprintAuth;
            order = config.security.pam.services.${service}.rules.auth.fprintd.order - 1;
            # pam_exec answers setcred with PAM_IGNORE, which a jump would make the whole stack's
            # answer: greetd starts its greeter without authenticating, and it would never show.
            control = "[success=ignore ignore=ignore default=1]";
            modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
            args = [ "quiet" "${skipReader}" ];
        };
    };
in
{
    services.libinput.enable = lib.mkDefault true;

    services.logind.settings.Login =
    {
        HandleLidSwitch = lib.mkDefault "suspend";
        HandleLidSwitchExternalPower = lib.mkDefault "suspend";
        HandleLidSwitchDocked = lib.mkDefault "ignore";
    };
    services.fprintd.enable = lib.mkDefault config.nihil.fingerprint;

    hardware.enableRedistributableFirmware = lib.mkDefault true;
    boot.kernelPackages = lib.mkDefault pkgs.linuxPackages_latest;
    security.pam.services = lib.genAttrs [ "sudo" "su" "login" "polkit-1" "greetd" ] skipFingerprint //
    {
        hyprlock.fprintAuth = false;
    };
    zramSwap.enable = lib.mkDefault true;
    
    services.udev.extraRules = ''
        ACTION=="add", SUBSYSTEM=="leds", KERNEL=="platform::micmute", RUN+="${pkgs.coreutils}/bin/chgrp nihil-leds /sys/class/leds/%k/brightness", RUN+="${pkgs.coreutils}/bin/chmod g+w /sys/class/leds/%k/brightness"
    '';
}
