# zen.nix by poligle

{ config, osConfig, lib, pkgs, inputs, ... }:
let
    colors = config.lib.stylix.colors.withHashtag;
    palette = lib.mapAttrs (_: hex: "#${hex}") osConfig.nihil.tokens.palette;
in
{
    imports = [ inputs.zen-browser.homeModules.beta ];

    programs.zen-browser =
    {
        enable = true;
        setAsDefaultBrowser = true;
        profiles =
        {
            default =
            {
                settings =
                {
                    "ui.highlight" = colors.base03;
                    "ui.highlighttext" = colors.base06;
                };

                # Stylix's theme leaves the find bar (Ctrl + F) in Zen's light colours.
                userChrome = ''
                    findbar
                    {
                        --toolbar-field-background-color: ${palette.raised} !important;
                        --toolbar-field-background-color-focus: ${palette.raised} !important;
                        --toolbar-field-text-color: ${palette.ink} !important;
                        --toolbar-field-text-color-focus: ${palette.ink} !important;
                        --input-background-color: ${palette.raised} !important;
                        --input-text-color: ${palette.ink} !important;
                        background-color: ${colors.base00} !important;
                        color: ${colors.base05} !important;
                        border-color: ${colors.base02} !important;
                        box-shadow: none !important;
                    }

                    findbar .findbar-textbox
                    {
                        appearance: none !important;
                        background: ${palette.raised} !important;
                        color: ${palette.ink} !important;
                        border: 1px solid ${palette.line} !important;
                        border-radius: 8px !important;
                        outline: none !important;
                        box-shadow: none !important;
                    }

                    findbar .findbar-textbox:focus { border-color: ${palette.muted} !important; }
                    findbar .findbar-textbox[status="notfound"] { border-color: ${palette.signal} !important; }
                    findbar .findbar-textbox::placeholder { color: ${palette.muted} !important; }

                    findbar :is(label, description, .findbar-label, .found-matches, .findbar-find-status)
                    {
                        color: ${colors.base04} !important;
                    }

                    findbar :is(toolbarbutton, checkbox)
                    {
                        color: ${colors.base05} !important;
                        fill: ${colors.base05} !important;
                        background-color: transparent !important;
                    }

                    findbar :is(toolbarbutton, checkbox):hover { background-color: ${colors.base02} !important; }

                    findbar checkbox .checkbox-check
                    {
                        background-color: ${colors.base01} !important;
                        border: 1px solid ${colors.base03} !important;
                    }

                    findbar checkbox[checked] .checkbox-check
                    {
                        background-color: ${colors.base06} !important;
                        fill: ${colors.base00} !important;
                    }
                '';
            };
        };
    };

    stylix.targets.zen-browser.profileNames = [ "default" ];
}
