# kitty.nix by poligle

{ config, pkgs, lib, ... }:
let
	glass = pkgs.writeShellScript "kitty-glass" ''
		if [ "$(cat "${config.xdg.stateHome}/nihil/glass" 2> /dev/null)" = on ]; then
			echo "background_opacity 0.8"
		fi
	'';
in
{
	programs.kitty = 
	{
		enable = true;

		settings = 
		{
			confirm_os_window_close = 0;
			window_padding_width = 12;
			cursor_shape = "block";
			cursor_blink_interval = 0;
			tab_bar_style = "fade";
			tab_fade = 1;
			active_tab_font_style = "bold";
			inactive_tab_font_style = "bold";
			dynamic_background_opacity = true;
		};

		extraConfig = "geninclude ${glass}";

		keybindings =
		{
			"shift+insert" = "paste_from_clipboard";
			"ctrl+insert" = "copy_to_clipboard";
		};
	};
}