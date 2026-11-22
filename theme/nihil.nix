# nihil.nix by poligle

let
	palette =
	{
		void    = "000000";   # frame, bar, drawers (OLED black)
		surface = "0E0E0E";   # cards inside drawers           1.09:1
		raised  = "1A1A1A";   # hover, slider tracks            1.21:1
		line    = "2A2A2A";   # 1 px lines                      1.46:1
		off     = "333333";   # LEDs that are switched off      1.66:1
		muted   = "7A7A7A";   # metadata, inactive icons        4.89:1
		dim     = "A3A3A3";   # secondary text                  8.33:1
		ink     = "F2F2F2";   # primary text, lit LEDs         18.76:1
		signal  = "D71921";   # interrupts only (never small text, 4.05:1)
	};
in
{
	name = "NIHIL";
	motto = "ex nihilo";

	inherit palette;

	base16 =
	{
		scheme = "NIHIL";
		author = "poligle";

		base00 = palette.void;
		base01 = palette.surface;
		base02 = palette.raised;
		base03 = "5E5E5E";
		base04 = palette.muted;
		base05 = "E6E6E6";
		base06 = palette.ink;
		base07 = "FFFFFF";
		base08 = palette.signal;
		base09 = "CFCFCF";
		base0A = "FFFFFF";
		base0B = "9E9E9E";
		base0C = "8A8A8A";
		base0D = palette.ink;
		base0E = "B5B5B5";
		base0F = "6E6E6E";
	};

	fonts =
	{
		dot   = "Doto";                     # dot matrix: clocks, big numbers
		sans  = "Space Grotesk";            # interface text
		mono  = "Space Mono";               # labels and metadata
		code  = "JetBrainsMono Nerd Font";  # terminal and editors
		icons = "JetBrainsMono Nerd Font";  # Material Design glyphs (nf-md)
	};

	frame =
	{
		thickness    = 8;
		bar          = 44;
		radius       = 20;   # inner corners of the frame
		fillet       = 14;   # concave joint between frame and drawers
		drawerRadius = 22;   # convex corners of the drawers
	};

	windows =
	{
		rounding = 12;
		gapsIn   = 4;
		gapsOut  = 8;
		border   = 1;
	};

	motion =
	{
		fast   = 140;
		normal = 240;
		drawer = 320;
		slow   = 480;
	};
}
