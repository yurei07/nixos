# settings.nix by poligle

{ config, lib, ... }:
let
    s = config.nihil.settings;
    get = path: default: lib.attrByPath path default s;

    firstWord = text: lib.head (lib.splitString " " text);
    outputs = get [ "outputs" ] { };
    sshKeys = get [ "sshKeys" ] [ ];
    known = [ "version" "user" "host" "language" "locale" "timeZone" "keyboard" "outputs" "primaryOutput"
        "wallpaper" "nilo" "binds" "gestures" "programs" "fingerprint" "ssh" "sshKeys" "generations" "deck"
        "clipboard" "bootSound" ];
    unknown = lib.subtractLists known (builtins.attrNames s);
in
{
    options.nihil =
    {
        settings = lib.mkOption
        {
            type = lib.types.attrs;
            default = { };
            description = "The machine's settings.json, as read by nihil.lib.mkSystem.";
        };

        home = lib.mkOption
        {
            type = lib.types.listOf lib.types.deferredModule;
            default = [ ];
            description = "Home Manager modules of this machine, added to NIHIL's for its user.";
        };

        flake = lib.mkOption
        {
            type = lib.types.str;
            default = "/etc/nixos";
            description = "Where the machine's flake is: nihil rebuild and nihil update use it.";
        };

        machineDir = lib.mkOption
        {
            type = lib.types.str;
            default = "";
            description = "Where the machine's files live in its flake, relative to nihil.flake (empty for the flake root).";
        };

        user =
        {
            name = lib.mkOption
            {
                type = lib.types.strMatching "[A-Za-z_][A-Za-z0-9_-]*";
                default = get [ "user" "name" ] "nihil";
                description = "The account of the person using this machine.";
            };

            fullName = lib.mkOption
            {
                type = lib.types.str;
                default = get [ "user" "fullName" ] "";
                description = "Their name, as the greeter and the welcome say it.";
            };

            greeting = lib.mkOption
            {
                type = lib.types.str;
                default = if config.nihil.user.fullName != "" then firstWord config.nihil.user.fullName else "";
                description = "The name the greeter uses (the first word of fullName).";
            };
        };

        fingerprint = lib.mkOption
        {
            type = lib.types.bool;
            default = get [ "fingerprint" ] false;
            description = "Fingerprint reader for sudo, polkit and the greeter (fprintd).";
        };
    };

    config =
    {
        # A key written by hand that nothing reads would otherwise change nothing, silently.
        warnings = lib.optional (unknown != [ ]) "settings.json: keys NIHIL doesn't read: ${lib.concatStringsSep ", " unknown}.";
        assertions =
        [
            {
                assertion = get [ "version" ] 1 == 1;
                message = "settings.json: version ${toString (get [ "version" ] 1)} is newer than this NIHIL knows (1).";
            }
        ];

        networking.hostName = lib.mkDefault (get [ "host" "name" ] "nihil");
        time.timeZone = lib.mkDefault (get [ "timeZone" ] "UTC");
        i18n.defaultLocale = lib.mkDefault (get [ "locale" ] "en_US.UTF-8");

        services.xserver.xkb =
        {
            layout = lib.mkDefault (get [ "keyboard" "layout" ] "us");
            variant = lib.mkDefault (get [ "keyboard" "variant" ] "");
            model = lib.mkIf (get [ "keyboard" "model" ] "" != "") (lib.mkDefault (get [ "keyboard" "model" ] ""));
        };

        services.openssh = lib.mkIf (get [ "ssh" ] false)
        {
            enable = lib.mkDefault true;
            settings =
            {
                PermitRootLogin = lib.mkDefault "no";
                AllowUsers = lib.mkDefault [ config.nihil.user.name ];
                PasswordAuthentication = lib.mkDefault (sshKeys == [ ]);
                KbdInteractiveAuthentication = lib.mkDefault false;
            };
        };
        # With the password still accepted, repeated failures from an address block it for a while.
        services.sshguard.enable = lib.mkDefault (get [ "ssh" ] false && sshKeys == [ ]);
        users.users.${config.nihil.user.name}.openssh.authorizedKeys.keys = sshKeys;
        nihil.generations.days = lib.mkDefault (get [ "generations" "days" ] 7);
        nihil.deck.enable = lib.mkDefault (get [ "deck" "enable" ] false);
        nihil.deck.interfaces = lib.mkDefault (get [ "deck" "interfaces" ] [ ]);
        nihil.deck.bluetooth = lib.mkDefault (get [ "deck" "bluetooth" ] true);

        # Each at the lowest priority, key by key: local.nix changes one key, a screen or the list of
        # programs without a conflict, and adds to them without losing settings.json's.
        nihil.binds = lib.mapAttrs (_: lib.mkDefault) (get [ "binds" ] { });
        nihil.gestures = lib.mapAttrs (_: lib.mkDefault) (get [ "gestures" ] { });
        nihil.programs = lib.mkIf (get [ "programs" ] null != null) (lib.mkDefault (get [ "programs" ] [ ]));

        nihil =
        {
            language = lib.mkDefault (get [ "language" ] "en");
            clipboard = lib.mkDefault (get [ "clipboard" ] 8);
            bootSound = lib.mkDefault (get [ "bootSound" ] true);
            wallpaper = lib.mkDefault (get [ "wallpaper" ] "night");
            outputs = lib.mapAttrs (_: lib.mapAttrs (_: lib.mkDefault)) outputs;
            # Among the screens in the end, local.nix's too: a laptop's panel, else one of settings.json's.
            primaryOutput = lib.mkDefault (get [ "primaryOutput" ]
                (let
                    names = builtins.attrNames config.nihil.outputs;
                    order = lib.filter (lib.hasPrefix "eDP") names
                        ++ lib.filter (name: outputs ? ${name}) names ++ names;
                in
                    if order != [ ] then lib.head order else ""));

            nilo =
            {
                enable = lib.mkDefault (get [ "nilo" "enable" ] false);
                acceleration = lib.mkDefault (get [ "nilo" "acceleration" ] "cpu");
                integratedGpu = lib.mkDefault (get [ "nilo" "integratedGpu" ] false);
            };
        };
    };
}
