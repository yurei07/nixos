# wallpaper.nix by poligle

{ config, osConfig, pkgs, lib, ... }:
let
	nihil = osConfig.nihil;
	hyprctl = "${osConfig.programs.hyprland.package}/bin/hyprctl";

	nihil-wallpaper = pkgs.writeShellScriptBin "nihil-wallpaper" ''
		set -euo pipefail
		export PATH="${lib.makeBinPath [ pkgs.awww pkgs.jq pkgs.coreutils pkgs.diffutils pkgs.procps ]}:${config.home.profileDirectory}/bin:$PATH"

		# Through Home Manager's link, always this generation's: a link left in the state straight
		# into the store would outlive it, and a collection would empty it.
		dir="${config.xdg.dataHome}/nihil/wallpapers"
		state="${config.xdg.stateHome}/nihil/wallpaper"
		glass="${config.xdg.stateHome}/nihil/glass"
		names=( ${lib.escapeShellArgs nihil.wallpapers.names} )

		current() {
			if [ -r "$state" ] && [ -d "$dir/$(cat "$state")" ]; then
				cat "$state"
			else
				echo "${nihil.wallpaper}"
			fi
		}

		apply() {
			local name="$1" output file
			[ -d "$dir/$name" ] || { echo "nihil-wallpaper: unknown wallpaper '$name'" >&2; exit 1; }
			mkdir -p "$(dirname "$state")"
			echo "$name" > "$state"
			ln -sfn "$dir/$name" "$state-current"
			# A copy for the login screen, which can't read the home.
			if [ -w /var/lib/nihil/greeter ]; then
				shown=/var/lib/nihil/greeter/wallpaper.png
				if [ -L "$shown" ] || ! cmp -s "$dir/$name/${nihil.primaryOutput}.png" "$shown"; then
					cp -f "$dir/$name/${nihil.primaryOutput}.png" "$shown.tmp" && mv -f "$shown.tmp" "$shown"
				fi
				look > /var/lib/nihil/greeter/glass
			fi
			# Started with the daemon, the socket may not be there yet; and one screen awww doesn't
			# know yet is no reason to leave the others bare.
			for _ in $(seq 50); do
				awww query > /dev/null 2>&1 && break
				sleep 0.1
			done
			for output in $(${hyprctl} -j monitors | jq -r '.[].name'); do
				file="$dir/$name/$output.gif"
				[ -r "$file" ] || file="$dir/$name/$output.png"
				[ -r "$file" ] || file="$dir/$name/${nihil.primaryOutput}.png"
				awww img --outputs "$output" "$file" || echo "nihil-wallpaper: $output: awww img failed" >&2
			done
			if command -v nihil-lock-glass > /dev/null; then
				nihil-lock-glass > /dev/null 2>&1 &
			fi
		}

		look() {
			if [ "$(cat "$glass" 2> /dev/null)" = on ]; then echo on; else echo off; fi
		}

		step() {
			local now i count=''${#names[@]}
			now="$(current)"
			for i in "''${!names[@]}"; do
				if [ "''${names[$i]}" = "$now" ]; then
					apply "''${names[$(( (i + $1 + count) % count ))]}"
					return
				fi
			done
			apply "''${names[0]}"
		}

		case "''${1:-restore}" in
			restore) apply "$(current)" ;;
			next)    step 1 ;;
			prev)    step -1 ;;
			set)     apply "''${2:?Usage: nihil-wallpaper set <name>}" ;;
			list)    printf '%s\n' "''${names[@]}" ;;
			current) current ;;
			glass)
				case "''${2:-}" in
					"") look ;;
					on | off)
						mkdir -p "$(dirname "$glass")"
						echo "$2" > "$glass"
						apply "$(current)"
						pkill -USR1 -x 'kitty|\.kitty-wrapped' || true
						;;
					*) echo "Usage: nihil-wallpaper glass [on|off]" >&2; exit 2 ;;
				esac
				;;
			*)       echo "Usage: nihil-wallpaper [restore|next|prev|set <name>|list|current|glass [on|off]]" >&2; exit 2 ;;
		esac
	'';
in
{
	home.packages = [ nihil-wallpaper ];

	xdg.dataFile."nihil/wallpapers".source = nihil.wallpapers;

	systemd.user.services.awww-daemon =
	{
		Unit =
		{
			Description = "Wayland Wallpaper Daemon";
			After = [ "graphical-session.target" ];
			PartOf = [ "graphical-session.target" ];
		};

		Service =
		{
			ExecStart = "${pkgs.awww}/bin/awww-daemon";
			# A failure here would take the daemon down with it.
			ExecStartPost = "-${nihil-wallpaper}/bin/nihil-wallpaper restore";
			Restart = "on-failure";
		};

		Install =
		{
			WantedBy = [ "graphical-session.target" ];
		};
	};
}
