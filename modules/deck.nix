# deck.nix by poligle

{ config, lib, pkgs, ... }:
let
    cfg = config.nihil.deck;
in
{
    options.nihil.deck =
    {
        enable = lib.mkOption
        {
            type = lib.types.bool;
            default = false;
            description = "Devices as decks: NIHIL for Android, paired from Preferences, opens apps and pages here (docs/deck.md).";
        };

        port = lib.mkOption
        {
            type = lib.types.port;
            default = 64445;
            description = "The deck's HTTPS port on the local network.";
        };

        interfaces = lib.mkOption
        {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            example = [ "enp3s0" ];
            description = "The network interfaces where the deck can be reached and is announced; every one when empty.";
        };

        bluetooth = lib.mkOption
        {
            type = lib.types.bool;
            default = true;
            description = "Reached over Bluetooth LE too, when a device shares no network with the computer, which then announces itself while the deck runs (docs/deck.md).";
        };
    };

    config = lib.mkIf cfg.enable
    {
        networking.firewall.allowedTCPPorts = lib.mkIf (cfg.interfaces == [ ]) [ cfg.port ];
        networking.firewall.interfaces = lib.genAttrs cfg.interfaces (_: { allowedTCPPorts = [ cfg.port ]; });

        boot.kernelModules = [ "uinput" ];
        # uaccess gives /dev/uinput to the session at the screen, every program in it and not
        # the deck alone: any can make a keyboard and type into any window (docs/deck.md).
        services.udev.packages =
        [
            (pkgs.writeTextFile
            {
                name = "nihil-deck-udev-rules";
                destination = "/etc/udev/rules.d/72-nihil-deck.rules";
                text = ''
                    KERNEL=="uinput", SUBSYSTEM=="misc", TAG+="uaccess", OPTIONS+="static_node=uinput"
                    SUBSYSTEM=="input", KERNEL=="event*", ATTRS{name}=="NIHIL deck trackpad", ENV{ID_INPUT_TOUCHPAD_INTEGRATION}="external"
                '';
            })
        ];

        # Announced as NIHIL, not by the computer's own name, which goes with it from network to
        # network: the phone finds it by its pin, and has its name from the QR.
        services.avahi =
        {
            enable = true;
            hostName = lib.mkDefault "nihil";
            allowInterfaces = lib.mkIf (cfg.interfaces != [ ]) cfg.interfaces;
            publish =
            {
                enable = true;
                addresses = true;
            };
            extraServiceFiles.nihil-deck = ''
                <?xml version="1.0" standalone="no"?>
                <!DOCTYPE service-group SYSTEM "avahi-service.dtd">
                <service-group>
                  <name>NIHIL</name>
                  <service>
                    <type>_nihil-deck._tcp</type>
                    <port>${toString cfg.port}</port>
                    <txt-record>v=1</txt-record>
                  </service>
                </service-group>
            '';
        };
    };
}
