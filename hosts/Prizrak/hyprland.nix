# The machine's own Hyprland config: a plain hyprland.conf.
# Action keys (launcher, close, clipboard...) come from settings.json's binds,
# everything else is written right here. Edit, then `nihil rebuild`.

{ config, osConfig, pkgs, lib, ... }:
let
	# settings.json keys: "SUPER + Q" -> { mods = "SUPER"; key = "Q"; }
	combo = text:
		let parts = lib.filter (p: p != "") (map lib.trim (lib.splitString "+" text));
		in { mods = lib.concatStringsSep " " (lib.init parts); key = lib.last parts; };
	keys = osConfig.nihil.binds;
	bind = action: dispatcher: param: let c = combo keys.${action}; in
		"${c.mods}, ${c.key}, ${dispatcher}${lib.optionalString (param != "") ", ${param}"}";

	# The screen's theme, for borders and the background.
	t = osConfig.nihil.tokens;
	rgb = hex: "rgb(${hex})";

	# Closing the lid: docked, the panel goes dark; alone, the session locks.
	nihil-lid = pkgs.writeShellScriptBin "nihil-lid" ''
		external=$(${pkgs.jq}/bin/jq '[.[] | select(.name != "eDP-1")] | length' <(${osConfig.programs.hyprland.package}/bin/hyprctl -j monitors))
		case "$1" in
			close)
				if [ "$external" -gt 0 ]; then
					${osConfig.programs.hyprland.package}/bin/hyprctl keyword monitor "eDP-1,disable"
				else
					loginctl lock-session
					${osConfig.programs.hyprland.package}/bin/hyprctl dispatch dpms off
				fi
				;;
			open)
				${osConfig.programs.hyprland.package}/bin/hyprctl keyword monitor "eDP-1,preferred,auto,1"
				${osConfig.programs.hyprland.package}/bin/hyprctl dispatch dpms on
				;;
		esac
	'';
in
{
	# NIHIL's own generator is off: this file writes the config instead.
	nihil.hyprland.enable = false;

	home.packages = [ nihil-lid ];

	wayland.windowManager.hyprland =
	{
		enable = true;
		package = null;
		portalPackage = null;
		# A plain hyprland.conf, not the Lua config (HM 26.05 would pick Lua by default).
		configType = "hyprlang";
		# UWSM starts the session's targets: Home Manager's own would run alongside it.
		systemd.enable = false;

		settings =
		{
			monitor = [ "eDP-1, preferred, auto, 1" ];

			env =
			[
				"QT_QPA_PLATFORM,wayland;xcb"
				"QT_QPA_PLATFORMTHEME,qt6ct"
				"QT_STYLE_OVERRIDE,Fusion"
				"_JAVA_AWT_WM_NONREPARENTING,1"
			];

			# Keyboard: driven by settings.json (layout us,ru, switch on Alt+Shift).
			input = with osConfig.services.xserver.xkb;
			{
				kb_layout = layout;
				kb_variant = variant;
				kb_model = model;
				kb_options = options;
				follow_mouse = 1;
				sensitivity = 0;
				touchpad.natural_scroll = false;
			};

			general =
			{
				gaps_in = t.windows.gapsIn;
				gaps_out = t.windows.gapsOut;
				border_size = t.windows.border;
				col = { active_border = rgb t.palette.muted; inactive_border = rgb t.palette.line; };
				resize_on_border = true;
				allow_tearing = false;
				layout = "master";
			};

			decoration =
			{
				rounding = t.windows.rounding;
				active_opacity = 1.0;
				inactive_opacity = 0.85;
				fullscreen_opacity = 1.0;
				shadow.enabled = false;
				blur =
				{
					enabled = true;
					size = 4;
					passes = 2;
					brightness = 0.5;
					contrast = 1.0;
					noise = 0;
					xray = false;
					popups = false;
				};
			};

			master.new_status = "master";

			misc =
			{
				force_default_wallpaper = 0;
				disable_hyprland_logo = true;
				disable_splash_rendering = true;
				background_color = rgb t.palette.void;
				# If the lock screen ever dies, the lock key brings a new one instead of a dead end.
				allow_session_lock_restore = true;
			};

			ecosystem = { no_update_news = true; no_donation_nag = true; };

			animation =
			[
				"windows, 1, 2.6, nihilOut, popin 94%"
				"windowsMove, 1, 2.4, nihilOut, slide"
				"border, 1, 4, linear"
				"fade, 1, 2, nihilOut"
				"workspaces, 1, 3, nihilInOut, slide"
			];
			bezier =
			[
				"linear, 0, 0, 1, 1"
				"nihilOut, 0.05, 0.7, 0.1, 1.0"
				"nihilInOut, 0.4, 0.0, 0.2, 1.0"
			];

			gesture =
			[
				"3, horizontal, workspace"
				"3, down, close"
				"3, up, exec, nihil-ipc drawers toggle launcher"
				"3, pinchin, exec, hyprctl dispatch fullscreen 1"
				"3, pinchout, exec, hyprctl dispatch fullscreen 1"
				"4, vertical, exec, hyprctl dispatch togglespecialworkspace"
			];

			windowrulev2 =
			[
				"suppress_event maximize, class:^(.*)$"
				"float, class:^(kitty)$"
				"size 800 500, class:^(kitty)$"
				"center, class:^(kitty)$"
				"float, class:^(thunar)$"
				"center, class:^(thunar)$"
				"size 1000 700, class:^(thunar)$, title:^(.+ - Thunar)$"
				"float, class:^(nm-connection-editor)$"
				"size 640 400, class:^(nm-connection-editor)$"
				"center, class:^(nm-connection-editor)$"
				"float, class:.*blueman-manager.*"
				"size 640 400, class:.*blueman-manager.*"
				"center, class:.*blueman-manager.*"
				"float, class:^(org.pulseaudio.pavucontrol)$"
				"size 640 400, class:^(org.pulseaudio.pavucontrol)$"
				"center, class:^(org.pulseaudio.pavucontrol)$"
			];
			layerrule = [ "noanim, namespace:^(nihil-.*)$" ];

			# The panel's drawers: hold the key, navigate, Enter chooses, Escape cancels.
			bind = (map (key: "SUPER, ${key}, workspace, ${key}") (map toString (lib.range 1 9)))
			++ [ "SUPER, 0, workspace, 10" ]
			++ (map (key: "SUPER SHIFT, ${key}, movetoworkspace, ${key}") (map toString (lib.range 1 9)))
			++ [ "SUPER SHIFT, 0, movetoworkspace, 10" ]

			# focus and drag
			++ [
				"SUPER, left, movefocus, l"
				"SUPER, right, movefocus, r"
				"SUPER, up, movefocus, u"
				"SUPER, down, movefocus, d"
				", mouse:275, workspace, e-1"
				", mouse:276, workspace, e+1"
			]

			# Actions from settings.json
			++ [
				(bind "close" "killactive" "")
				(bind "float" "togglefloating" "")
				(bind "maximize" "fullscreen" "1")
				(bind "fullscreen" "fullscreen" "0")
				(bind "special" "togglespecialworkspace" "")
				(bind "toSpecial" "movetoworkspacesilent" "special")
				(bind "nextWorkspace" "workspace" "e+1")
				(bind "launcher" "exec" "nihil-ipc drawers toggle launcher")
				(bind "dashboard" "exec" "nihil-ipc drawers toggle dashboard")
				(bind "panel" "exec" "nihil-ipc drawers toggle panel")
				(bind "settings" "exec" "nihil-ipc settings toggle")
				(bind "colourPicker" "exec" "hyprpicker -a")
				(bind "copy" "exec" "hyprctl dispatch sendshortcut CTRL, Insert,")
				(bind "clipboard" "global" "quickshell:nihil-clipboard")
				(bind "overview" "global" "quickshell:nihil-overview")
				(bind "wallpapers" "global" "quickshell:nihil-wallpapers")

				# Open a drawer, then walk in it with its submap.
				(bind "clipboard" "submap" "clipboard")
				(bind "overview" "submap" "overview")
				(bind "wallpapers" "submap" "wallpapers")
			];
			bindm = [
				"SUPER, mouse:272, movewindow"
				", mouse:274, movewindow"
			];

			# Media and brightness: work on the lock screen too (bindl), repeat while held (binde).
			binde =
			[
				", XF86AudioRaiseVolume, exec, osd-volume up"
				", XF86AudioLowerVolume, exec, osd-volume down"
				", XF86MonBrightnessUp, exec, osd-brightness up"
				", XF86MonBrightnessDown, exec, osd-brightness down"
			];
			bindl =
			[
				", XF86AudioMute, exec, osd-volume mute"
				", XF86AudioMicMute, exec, osd-mic"
				", XF86AudioNext, exec, playerctl next"
				", XF86AudioPause, exec, playerctl play-pause"
				", XF86AudioPlay, exec, playerctl play-pause"
				", XF86AudioPrev, exec, playerctl previous"
				"SHIFT, PRINT, exec, nihil-record toggle screen"
				"SHIFT, XF86SelectiveScreenshot, exec, nihil-record toggle region"
				", switch:on:Lid Switch, exec, nihil-lid close"
				", switch:off:Lid Switch, exec, nihil-lid open"

				# Actions that answer on the lock screen too
				(bind "lock" "exec" "lock-screen")
				(bind "screenshot" "exec" "nihil-shot screen")
				(bind "snip" "exec" "nihil-shot region")
			];

			# SUPER+V: the clipboard. Navigate with Tab/Arrows, Enter pastes, Escape cancels.
			extraConfig = ''
				submap = clipboard
				bind = SUPER, V, global, quickshell:nihil-clipboard-next
				bind = SUPER, Tab, global, quickshell:nihil-clipboard-next
				bind = SUPER, Down, global, quickshell:nihil-clipboard-next
				bind = SUPER, Right, global, quickshell:nihil-clipboard-next
				bind = SUPER SHIFT, V, global, quickshell:nihil-clipboard-back
				bind = SUPER SHIFT, Tab, global, quickshell:nihil-clipboard-back
				bind = SUPER, Up, global, quickshell:nihil-clipboard-back
				bind = SUPER, Left, global, quickshell:nihil-clipboard-back
				bind = SUPER, Delete, global, quickshell:nihil-clipboard-forget
				bind = SUPER, BackSpace, global, quickshell:nihil-clipboard-forget
				bind = SUPER, Return, global, quickshell:nihil-clipboard-paste
				bind = SUPER, Return, submap, reset
				bind = SUPER, KP_Enter, global, quickshell:nihil-clipboard-paste
				bind = SUPER, KP_Enter, submap, reset
				bind = SUPER, Escape, global, quickshell:nihil-clipboard-cancel
				bind = SUPER, Escape, submap, reset
				bindit = SUPER, Super_L, submap, reset
				bindit = SUPER, Super_R, submap, reset
				submap = reset

				# SUPER+A: the overview. Enter goes to the chosen workspace.
				submap = overview
				bind = SUPER, A, global, quickshell:nihil-overview-next
				bind = SUPER, Tab, global, quickshell:nihil-overview-next
				bind = SUPER, Right, global, quickshell:nihil-overview-next
				bind = SUPER SHIFT, A, global, quickshell:nihil-overview-back
				bind = SUPER SHIFT, Tab, global, quickshell:nihil-overview-back
				bind = SUPER, Left, global, quickshell:nihil-overview-back
				bind = SUPER, Return, global, quickshell:nihil-overview-go
				bind = SUPER, Return, submap, reset
				bind = SUPER, KP_Enter, global, quickshell:nihil-overview-go
				bind = SUPER, KP_Enter, submap, reset
				bind = SUPER, Escape, global, quickshell:nihil-overview-cancel
				bind = SUPER, Escape, submap, reset
				bindit = SUPER, Super_L, submap, reset
				bindit = SUPER, Super_R, submap, reset
				submap = reset

				# SUPER+W: the wallpapers. Enter sets the chosen one.
				submap = wallpapers
				bind = SUPER, W, global, quickshell:nihil-wallpapers-next
				bind = SUPER, Tab, global, quickshell:nihil-wallpapers-next
				bind = SUPER, Right, global, quickshell:nihil-wallpapers-next
				bind = SUPER SHIFT, W, global, quickshell:nihil-wallpapers-back
				bind = SUPER SHIFT, Tab, global, quickshell:nihil-wallpapers-back
				bind = SUPER, Left, global, quickshell:nihil-wallpapers-back
				bind = SUPER, Return, global, quickshell:nihil-wallpapers-go
				bind = SUPER, Return, submap, reset
				bind = SUPER, KP_Enter, global, quickshell:nihil-wallpapers-go
				bind = SUPER, KP_Enter, submap, reset
				bind = SUPER, Escape, global, quickshell:nihil-wallpapers-cancel
				bind = SUPER, Escape, submap, reset
				bindit = SUPER, Super_L, submap, reset
				bindit = SUPER, Super_R, submap, reset
				submap = reset
			'';

			exec-once =
			[
				"mic-led-sync"
				"nihil-wallpaper restore"
			];
		};
	};
}
