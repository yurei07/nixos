# binds.nix by poligle

{ config, lib, ... }:
let
    keys =
    {
        launcher = "SUPER + Space";
        dashboard = "SUPER + D";
        panel = "SUPER + P";
        colourPicker = "SUPER + H";
        lock = "SUPER + K";
        nilo = "SUPER + I";
        settings = "SUPER + O";
        wallpapers = "SUPER + W";
        copy = "SUPER + C";
        clipboard = "SUPER + V";
        close = "SUPER + Q";
        float = "SUPER + SHIFT + Space";
        maximize = "SUPER + F";
        fullscreen = "SUPER + SHIFT + F";
        special = "SUPER + Escape";
        # Not a modifier as the key: SUPER + Control_L fired as CTRL went down, before any
        # SUPER + CTRL + key, and took the window along.
        toSpecial = "SUPER + SHIFT + Escape";
        nextWorkspace = "SUPER + Tab";
        overview = "SUPER + A";
        screenshot = "PRINT";
        snip = "XF86SelectiveScreenshot";
    };

    programs =
    [
        { name = "Terminal"; exec = "kitty"; keys = "SUPER + Super_L"; }
        { name = config.nihil.strings.bindFiles; exec = "thunar"; keys = "SUPER + E"; }
        { name = "Zen"; exec = "zen-beta"; keys = "SUPER + X"; }
    ];

    former = [ "terminal" "files" "browser" "notes" "code" "music" "pixels" ];

    # The directions each gesture takes.
    ways = { workspaces = [ "left" "right" ]; close = [ "down" ]; launcher = [ "up" ]; maximize = [ "pinchin" "pinchout" ]; special = [ "up" "down" ]; };

    trim = text: let m = builtins.match "[[:space:]]*(.*[^[:space:]])[[:space:]]*" text; in if m == null then "" else lib.head m;
    modifiers = [ "SUPER" "SHIFT" "CTRL" "CONTROL" "ALT" "WIN" "LOGO" "MOD4" "META" "MOD1" ];
    heldKeys = [ "control_l" "control_r" "shift_l" "shift_r" "alt_l" "alt_r" ];
    split = combo: lib.filter (part: part != "") (map trim (lib.splitString "+" combo));
    valid = combo: let p = split combo; in p != [ ] && lib.all (part: lib.elem (lib.toUpper part) modifiers) (lib.init p);
    # A modifier as the key fires as it goes down, ahead of every combination with it.
    held = combo: let p = split combo; in p != [ ] && lib.elem (lib.toLower (lib.last p)) heldKeys;
    # An action's text in theme/i18n.nix: launcher's is bindLauncher.
    label = name: "bind" + lib.toUpper (lib.substring 0 1 name) + lib.substring 1 (lib.stringLength name) name;
    unlabelled = lib.filter (name: !(config.nihil.strings ? ${label name})) (builtins.attrNames keys);

    combos = lib.filter (combo: combo != null)
        (builtins.attrValues config.nihil.binds ++ map (program: program.keys) config.nihil.programs);

    gestures =
    {
        workspaces = 3;     # sideways: the next or previous workspace
        close = 3;          # down: close the window
        launcher = 3;       # up: the launcher
        maximize = 3;       # spread: the window maximised; brought together, back
        special = 4;        # up or down: the special workspace
    };
in
{
    options.nihil =
    {
        binds = lib.mkOption
        {
            type = lib.types.attrsOf (lib.types.nullOr lib.types.str);
            default = { };
            apply = changed: keys // removeAttrs changed former;
            example = { launcher = "SUPER + R"; screenshot = null; };
            description = "Keys for NIHIL's actions, over the defaults in modules/binds.nix; null for none.";
        };

        bindDefaults = lib.mkOption
        {
            type = lib.types.attrs;
            default = { inherit keys gestures programs; };
            readOnly = true;
            description = "NIHIL's own keys and fingers, before a machine changes them (Preferences shows both).";
        };

        programs = lib.mkOption
        {
            type = lib.types.listOf (lib.types.submodule
            {
                options =
                {
                    name = lib.mkOption { type = lib.types.str; };
                    exec = lib.mkOption { type = lib.types.str; };
                    keys = lib.mkOption { type = lib.types.nullOr lib.types.str; default = null; };
                };
            });
            default = programs;
            description = "Programs with a key: a name, the command that opens it and its keys (Preferences, Shortcuts).";
        };

        gestures = lib.mkOption
        {
            type = lib.types.attrsOf (lib.types.nullOr (lib.types.ints.between 2 5));
            default = { };
            apply = changed: gestures // changed;
            example = { close = null; launcher = null; special = 3; };
            description = "Fingers for each touchpad gesture, over the defaults in modules/binds.nix; null for none.";
        };
    };

    config.warnings = map (combo: "nihil.binds: ${combo} ends in a modifier, which fires as it goes down, before any combination with it: give it another key.")
        (lib.filter held combos);

    config.assertions =
    [
        {
            assertion = lib.all valid combos;
            message = "nihil.binds, nihil.programs: a key is its modifiers (SUPER, SHIFT, CTRL, ALT), then the key; ${lib.concatStringsSep ", " (lib.filter (combo: !(valid combo)) combos)} isn't.";
        }
        {
            assertion = lib.all (program: builtins.match "[^[:cntrl:]]*" program.exec != null) config.nihil.programs;
            message = "nihil.programs: a command can't have line breaks or other control characters.";
        }
        {
            assertion = let used = lib.concatLists (lib.mapAttrsToList (name: fingers: map (way: "${toString fingers}:${way}") ways.${name})
                (lib.filterAttrs (_: fingers: fingers != null) config.nihil.gestures)); in
                lib.length used == lib.length (lib.unique used);
            message = "nihil.gestures: two gestures with the same fingers and direction (special is up and down; launcher up, close down).";
        }
        {
            assertion = lib.all (name: keys ? ${name}) (builtins.attrNames config.nihil.binds);
            message = "nihil.binds: unknown action; the actions are ${lib.concatStringsSep ", " (builtins.attrNames keys)}.";
        }
        {
            assertion = lib.all (name: gestures ? ${name}) (builtins.attrNames config.nihil.gestures);
            message = "nihil.gestures: unknown gesture; the gestures are ${lib.concatStringsSep ", " (builtins.attrNames gestures)}.";
        }
        # Preferences shows each action by its text; one without would show its name.
        {
            assertion = unlabelled == [ ];
            message = "theme/i18n.nix: every action in modules/binds.nix needs its text; ${lib.concatStringsSep ", " (map label unlabelled)} isn't there.";
        }
    ];
}
