# default.nix by poligle (home/nilo)

{ pkgs, lib, osConfig, terminal ? "kitty" }:
let
    nihil = osConfig.nihil;
    ollama = osConfig.services.ollama;
    # Where Ollama answers: an address it listens on everywhere is reached on this computer, and an
    # IPv6 one goes in brackets, or the port would read as part of it.
    host = { "0.0.0.0" = "127.0.0.1"; "::" = "::1"; }.${ollama.host} or ollama.host;
    address = if lib.hasInfix ":" host then "[${host}]" else host;

    config = pkgs.writeText "nilo.json" (builtins.toJSON
    {
        ollama = "http://${address}:${toString ollama.port}";
        inherit (nihil) language;
        inherit (nihil.nilo) models contextLength searxng coauthor;
        ddgr = "${pkgs.ddgr}/bin/ddgr";
        git = "${pkgs.git}/bin/git";
        bash = "${pkgs.bash}/bin/bash";
        bwrap = "${pkgs.bubblewrap}/bin/bwrap";
        hyprctl = "${osConfig.programs.hyprland.package}/bin/hyprctl";
        wtype = "${pkgs.wtype}/bin/wtype";
        playerctl = "${pkgs.playerctl}/bin/playerctl";
        grim = "${pkgs.grim}/bin/grim";
        wlrctl = "${pkgs.wlrctl}/bin/wlrctl";
        inherit terminal;
        host = osConfig.networking.hostName;
        flake = osConfig.nihil.flake;
        context = "${./nilo.md}";
        systemctl = "${osConfig.systemd.package}/bin/systemctl";
        journalctl = "${osConfig.systemd.package}/bin/journalctl";
        ollamaUnit = "ollama.service";
    });
in
pkgs.writeShellScriptBin "nilo-agent" ''
    exec ${pkgs.python3}/bin/python3 -I ${./agent.py} --config ${config} "$@"
''
