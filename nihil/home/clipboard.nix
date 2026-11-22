# clipboard.nix by poligle

{ config, osConfig, pkgs, lib, ... }:
let
	size = osConfig.nihil.clipboard;

	nihil-clipboard = pkgs.writeShellScriptBin "nihil-clipboard" ''
		set -u
		export PATH="${lib.makeBinPath [ pkgs.cliphist pkgs.wl-clipboard pkgs.wtype pkgs.coreutils pkgs.gnugrep osConfig.programs.hyprland.package ]}:$PATH"
		# Never /tmp, where another user could make the folder first.
		dir="''${XDG_RUNTIME_DIR:?}/nihil-clipboard"
		tab=$(printf '\t')

		# The history is kept in memory, in the runtime folder, and goes with the session: what's
		# copied from somewhere that doesn't mark it secret (a password from a terminal) would
		# otherwise stay on disk, and in its backups.
		# A function, so not with exec, which would run cliphist itself.
		cliphist() {
			command cliphist -db-path "$dir/db" "$@"
		}

		entry() {
			cliphist list | while IFS= read -r found; do
				if [ "''${found%%"$tab"*}" = "$1" ]; then
					printf '%s\n' "$found"
					break
				fi
			done
		}

		copy() {
			local found
			found=$(entry "$1")
			if [ -z "$found" ]; then
				echo "nihil-clipboard: no copy $1" >&2
				exit 1
			fi
			if [ -n "$2" ]; then
				printf '%s\n' "$found" | cliphist decode | wl-copy --type "$2"
			else
				printf '%s\n' "$found" | cliphist decode | wl-copy
			fi
		}

		keys() {
			local mods answer
			case "''${1:-}" in
				paste) mods=SHIFT ;;
				copy) mods=CTRL ;;
				*)
					echo "Usage: nihil-clipboard keys paste|copy" >&2
					return 2
					;;
			esac
			answer=$(hyprctl dispatch "hl.dsp.send_shortcut({ mods = \"$mods\", key = \"Insert\" })" 2>&1)
			if [ "$answer" = ok ]; then
				return 0
			fi
			echo "nihil-clipboard: Hyprland said \"$answer\"; typing $mods + Insert with wtype" >&2
			if ! wtype -M "''${mods,,}" -k Insert -m "''${mods,,}"; then
				echo "nihil-clipboard: $mods + Insert could not be typed" >&2
				return 1
			fi
		}

		case "''${1:-}" in
			store)
				if [ "''${CLIPBOARD_STATE:-data}" != data ]; then
					cat > /dev/null
					exit 0
				fi
				types=$(wl-paste --list-types 2> /dev/null || true)
				picture=""
				if ! printf '%s\n' "$types" | grep -q '^text/plain'; then
					picture=$(printf '%s\n' "$types" | grep -m 1 '^image/' || true)
				fi
				if [ -n "$picture" ]; then
					cat > /dev/null
					wl-paste --no-newline --type "$picture" | cliphist -max-items ${toString size} store
				else
					cliphist -max-items ${toString size} store
				fi
				;;
			list)
				mkdir -p "$dir"
				cliphist -preview-width 300 list | head -n "''${2:-${toString size}}" > "$dir/list.new"
				keep=" "
				while IFS="$tab" read -r id preview; do
					keep="$keep$id "
					if [[ $preview =~ ^\[\[\ binary\ data\ .*\ ([a-z]+)(\ [0-9]+x[0-9]+)?\ \]\]$ ]]; then
						file="$dir/$id.''${BASH_REMATCH[1]}"
						if [ ! -s "$file" ]; then
							printf '%s\t%s\n' "$id" "$preview" | cliphist decode > "$file.part" 2> /dev/null \
								&& mv "$file.part" "$file" || rm -f "$file.part"
						fi
					fi
				done < "$dir/list.new"
				for file in "$dir"/*.*; do
					[ -e "$file" ] || continue
					name=''${file##*/}
					case "$name" in list.new) continue ;; esac
					case "$keep" in *" ''${name%%.*} "*) ;; *) rm -f "$file" ;; esac
				done
				cat "$dir/list.new"
				;;
			copy)
				copy "''${2:?Usage: nihil-clipboard copy ID [TYPE]}" "''${3:-}"
				;;
			paste)
				copy "''${2:?Usage: nihil-clipboard paste ID [TYPE]}" "''${3:-}"
				sleep 0.06
				keys paste || exit 1
				;;
			keys)
				keys "''${2:-}" || exit $?
				;;
			delete)
				entry "''${2:?Usage: nihil-clipboard delete ID}" | cliphist delete
				;;
			wipe)
				cliphist wipe
				rm -rf "$dir"
				;;
			*)
				echo "Usage: nihil-clipboard list [N] | copy ID [TYPE] | paste ID [TYPE] | keys paste|copy | delete ID | wipe" >&2
				exit 2
				;;
		esac
	'';
in
{
	home.packages = [ nihil-clipboard ];

	systemd.user.services.nihil-clipboard = lib.mkIf (size > 0)
	{
		Unit =
		{
			Description = "NIHIL clipboard history";
			After = [ "graphical-session.target" ];
			PartOf = [ "graphical-session.target" ];
		};

		Service =
		{
			ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${nihil-clipboard}/bin/nihil-clipboard store";
			Restart = "on-failure";
			RestartSec = 2;
		};

		Install.WantedBy = [ "graphical-session.target" ];
	};
}
