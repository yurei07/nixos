# fastfetch.nix by poligle

{ config, osConfig, pkgs, lib, ... }:
let
	grid = lib.filter (row: lib.any (cell: cell != "0") (lib.stringToCharacters row))
		(lib.splitString "\n" (lib.removeSuffix "\n" (builtins.readFile ../theme/art/snowflake-19.txt)));

	led = cell:
		let v = lib.toInt cell; in
		if v >= 5 then "$1● " else if v >= 2 then "$2· " else "  ";

	logo = pkgs.writeText "nihil-fastfetch-logo" (lib.concatMapStringsSep "\n" (row: lib.concatMapStrings led (lib.stringToCharacters row)) grid);

	p = osConfig.nihil.tokens.palette;
	digit = c: lib.toInt c;
	hex = { a = 10; b = 11; c = 12; d = 13; e = 14; f = 15; };
	nibble = c: let l = lib.toLower c; in hex.${l} or (digit l);
	byte = s: toString (16 * nibble (builtins.substring 0 1 s) + nibble (builtins.substring 1 1 s));
	ansi = colour: "38;2;${byte (builtins.substring 0 2 colour)};${byte (builtins.substring 2 2 colour)};${byte (builtins.substring 4 2 colour)}";

	esc = builtins.fromJSON ''"\u001b"'';
	leds = lib.concatMapStrings (colour: "${esc}[${ansi colour}m● ") [ p.muted p.dim p.ink p.ink p.ink p.dim p.muted p.signal ] + "${esc}[0m";
in
{
	programs.fastfetch =
	{
		enable = true;
		settings =
		{
			logo =
			{
				type = "file";
				source = "${logo}";
				color = { "1" = ansi p.ink; "2" = ansi p.muted; };
				padding = { top = 1; left = 2; right = 4; };
			};

			display =
			{
				separator = "  ";
				color = { keys = ansi p.dim; title = ansi p.ink; separator = ansi p.muted; };
				key.width = 11;
			};

			modules =
			[
				{ type = "title"; format = "{user-name}@{host-name}"; }
				{ type = "custom"; format = osConfig.nihil.tokens.motto; outputColor = "3;${ansi p.muted}"; }   # 3: italics
				"break"
				{ type = "os"; key = "OS"; }
				{ type = "kernel"; key = "Kernel"; }
				{ type = "uptime"; key = "Uptime"; }
				{ type = "packages"; key = "Packages"; }
				{ type = "wm"; key = "WM"; }
				{ type = "shell"; key = "Shell"; }
				{ type = "terminal"; key = "Terminal"; }
				{ type = "cpu"; key = "CPU"; }
				{ type = "memory"; key = "Memory"; }
				{ type = "disk"; key = "Disk"; folders = "/"; }
				{ type = "battery"; key = "Battery"; }
				"break"
				{ type = "custom"; format = leds; }
			];
		};
	};
}
