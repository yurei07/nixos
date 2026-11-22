# regreet.nix by poligle

{ config, lib, pkgs, ... }:
let
    p = config.nihil.tokens.palette;
    f = config.nihil.tokens.fonts;
in
{
    programs.regreet =
    {
        enable = true;
        cageArgs = [ "-s" "-d" "-m" "last" ];

        settings =
        {
            background.path = lib.mkForce "/var/lib/nihil/greeter/wallpaper.png";
            appearance.greeting_msg = if config.nihil.user.greeting != ""
                then lib.replaceStrings [ "%1" ] [ config.nihil.user.greeting ] config.nihil.strings.welHello
                else config.nihil.strings.welHelloAnon;

            widget.clock =
            {
                format = "%H:%M";
                resolution = "500ms";
                label_width = 150;
            };
        };
    };

    stylix.targets.regreet.extraCss = ''
        frame.background {
            background-color: alpha(#${p.void}, 0.86);
            border: 1px solid #${p.line};
            border-radius: 24px;
        }

        frame.widget-clock {
            margin-top: 56px;
            padding: 6px 22px;
        }

        frame.widget-clock label {
            font-family: "${f.dot}";
            font-weight: 800;
            font-size: 44px;
            color: #${p.ink};
        }

        entry,
        dropdown > button {
            min-height: 40px;
            border-radius: 999px;
            background-color: #${p.surface};
            border: 1px solid #${p.line};
            box-shadow: none;
        }

        entry:focus-within {
            border-color: #${p.muted};
            outline: none;
        }

        button {
            border-radius: 999px;
            padding: 6px 18px;
            font-family: "${f.mono}";
        }

        button.suggested-action {
            background-color: #${p.ink};
            color: #${p.void};
        }

        button.destructive-action {
            background-color: transparent;
            color: #${p.signal};
            border: 1px solid #${p.signal};
        }
    '';

    environment.sessionVariables =
        let xkb = config.services.xserver.xkb; in
        { XKB_DEFAULT_LAYOUT = xkb.layout; }
        // lib.optionalAttrs (xkb.variant != "") { XKB_DEFAULT_VARIANT = xkb.variant; }
        // lib.optionalAttrs (xkb.model != "") { XKB_DEFAULT_MODEL = xkb.model; };

    # Through /etc, which follows the generation that runs: a link straight into the store would
    # point at nothing once a collection took it, until the next login copies the user's.
    environment.etc."nihil/wallpapers".source = config.nihil.wallpapers;

    systemd.tmpfiles.rules =
    [
        "d /var/lib/nihil/greeter 0755 ${config.nihil.user.name} users -"
        "L /var/lib/nihil/greeter/wallpaper.png - - - - /etc/nihil/wallpapers/${config.nihil.wallpaper}/${config.nihil.primaryOutput}.png"
    ];
}
