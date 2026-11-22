# default.nix by poligle (home/calendar)

{ pkgs }:
let
    python = pkgs.python3.withPackages (ps: [ ps.icalendar ps.recurring-ical-events ]);
in
pkgs.writeShellScriptBin "nihil-calendar" ''
    exec ${python}/bin/python3 -I ${./calendars.py} "$@"
''
