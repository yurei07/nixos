# default.nix by poligle (home/deck)

{ pkgs, lib, osConfig, profile, iconTheme }:
let
    nihil = osConfig.nihil;
    # jeepney speaks D-Bus to BlueZ, to announce the deck over Bluetooth.
    python = pkgs.python3.withPackages (ps: [ ps.jeepney ]);

    config = pkgs.writeText "nihil-deck.json" (builtins.toJSON
    {
        inherit (nihil.deck) port bluetooth;
        inherit iconTheme;
        name = osConfig.networking.hostName;
        strings = { inherit (nihil.strings) deckPaired deckPairedBody; };
        ipc = "${profile}/nihil-ipc";
        volume = "${profile}/osd-volume";
        notify = lib.getExe' pkgs.libnotify "notify-send";
        openssl = lib.getExe' pkgs.openssl "openssl";
        qrencode = lib.getExe' pkgs.qrencode "qrencode";
        rsvg = lib.getExe' pkgs.librsvg "rsvg-convert";
        ip = lib.getExe' pkgs.iproute2 "ip";
        wpctl = lib.getExe' pkgs.wireplumber "wpctl";
        wlCopy = lib.getExe' pkgs.wl-clipboard "wl-copy";
        wlPaste = lib.getExe' pkgs.wl-clipboard "wl-paste";
        open = lib.getExe' pkgs.xdg-utils "xdg-open";
    });
in
pkgs.writeShellScriptBin "nihil-deck" ''
    exec ${python}/bin/python3 -I ${./deck.py} --config ${config} "$@"
''
