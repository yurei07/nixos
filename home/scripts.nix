# scripts.nix by poligle

{ config, osConfig, pkgs, lib, ... }:
let
	ipc = "${config.home.profileDirectory}/bin/nihil-ipc";
	wpctl = "${pkgs.wireplumber}/bin/wpctl";
	grep = "${pkgs.gnugrep}/bin/grep";
	awk = "${pkgs.gawk}/bin/awk";
	brightnessctl = "${pkgs.brightnessctl}/bin/brightnessctl";
	hyprctl = "${osConfig.programs.hyprland.package}/bin/hyprctl";
	jq = "${pkgs.jq}/bin/jq";
	notify = "${pkgs.libnotify}/bin/notify-send";
	fileUri = ''${jq} -rn --arg path "$1" '"file://" + ($path | split("/") | map(@uri) | join("/"))' '';
	strings = osConfig.nihil.strings;
	sound = osConfig.nihil.sounds;
	volumeSound = sound.volume;

	nihil-shot = pkgs.writeShellScriptBin "nihil-shot" ''
		set -euo pipefail
		pictures=$(${pkgs.xdg-user-dirs}/bin/xdg-user-dir PICTURES 2> /dev/null || true)
		if [ -z "$pictures" ] || [ "$pictures" = "$HOME" ]; then
			pictures="$HOME/Pictures"
		fi
		dir="$pictures/${strings.screenshotsDir}"
		mkdir -p "$dir"
		# Two in the same second keep both: the second gets a number.
		file="$dir/NIHIL_$(date '+%Y-%m-%d_%H.%M.%S')"
		name="$file.png"
		n=1
		while [ -e "$name" ]; do
			n=$((n + 1))
			name="$file-$n.png"
		done
		file=$name
		case "''${1:-region}" in
			screen)
				output=$(${hyprctl} -j monitors | ${jq} -r '.[] | select(.focused) | .name')
				${pkgs.grim}/bin/grim -o "$output" "$file"
				;;
			region)
				area=$(${pkgs.slurp}/bin/slurp) || exit 0
				${pkgs.grim}/bin/grim -g "$area" "$file"
				;;
			*) echo "Usage: nihil-shot screen | region" >&2; exit 2 ;;
		esac
		${pkgs.wl-clipboard}/bin/wl-copy --type image/png < "$file"
		set -- "$file"
		${notify} -a NIHIL -h "string:image-path:$(${fileUri})" "${strings.screenshotSaved}" "''${file/#$HOME/\~}"
	'';

	mic-led-sync = pkgs.writeShellScriptBin "mic-led-sync" ''
		set -euo pipefail
		LED="/sys/class/leds/platform::micmute/brightness"
		[ -e "$LED" ] || exit 0
		out="$(${wpctl} get-volume @DEFAULT_AUDIO_SOURCE@ 2>&1 || true)"
		echo 0 > "$LED"
		if [[ "$out" == *"Could not connect to PipeWire"* ]]; then
			echo "mic-led-sync: PipeWire not reachable in this session." >&2
			exit 1
		fi
		if [[ "$out" == *"No such"* ]] || [[ "$out" == *"Unknown"* ]]; then
			echo "mic-led-sync: no valid DEFAULT_AUDIO_SOURCE. Output: $out" >&2
			exit 1
		fi
		if echo "$out" | ${grep} -q "MUTED"; then
			echo 1 > "$LED"
		else
			echo 0 > "$LED"
		fi
	'';

	nihil-record = pkgs.writeShellScriptBin "nihil-record" ''
		set -uo pipefail
		run="''${XDG_RUNTIME_DIR:?}/nihil-record"
		mkdir -p "$run"
		# One at a time: two starts at once would leave two recorders on one file.
		exec 9> "$run/lock"
		${pkgs.util-linux}/bin/flock 9

		# Still the recorder: a PID that died and came back as another process isn't stopped.
		recording() {
			[ -f "$run/pid" ] && kill -0 "$(cat "$run/pid")" 2>/dev/null \
				&& [ "$(cat "/proc/$(cat "$run/pid")/comm" 2>/dev/null)" = wf-recorder ]
		}

		videos() {
			local dir
			dir="$(${pkgs.xdg-user-dirs}/bin/xdg-user-dir VIDEOS 2>/dev/null)"
			if [ -z "$dir" ] || [ "$dir" = "$HOME" ]; then dir="$HOME/Videos"; fi
			mkdir -p "$dir" && printf '%s\n' "$dir"
		}

		start() {
			recording && return 0
			local dir where
			dir="$(videos)" || exit 1
			if [ "''${1:-region}" = screen ]; then
				where=(-o "$(${hyprctl} -j monitors | ${jq} -r '.[] | select(.focused) | .name')")
			else
				where=(-g "$(${pkgs.slurp}/bin/slurp)") || return 0
			fi
			local base name n=1
			base="$dir/NIHIL_$(date '+%Y-%m-%d_%H.%M.%S')"
			name="$base.mp4"
			while [ -e "$name" ]; do
				n=$((n + 1))
				name="$base-$n.mp4"
			done
			printf '%s\n' "$name" > "$run/file"
			printf '%s\n' "$dir/.nihil-record.mp4" > "$run/raw"
			${pkgs.wf-recorder}/bin/wf-recorder "''${where[@]}" -x yuv420p -c libx264 \
				-p crf=20 -p preset=veryfast -f "$(cat "$run/raw")" > "$run/log" 2>&1 &
			echo $! > "$run/pid"
			sleep 0.5
			if recording; then
				${ipc} recorder started
			else
				rm -f "$run/pid"
				failed
			fi
		}

		# What wf-recorder said stays in its log, in its own words; the notice says where.
		failed() {
			local where="${strings.recordLog}"
			${notify} -a NIHIL -- "${strings.recordFailed}" "''${where//%1/$run/log}" || true
		}

		stop() {
			[ -f "$run/pid" ] || { ${ipc} recorder stopped; return 0; }
			local pid raw file uri died=1
			pid="$(cat "$run/pid")"
			if recording; then
				died=0
				kill -INT "$pid"
				for _ in $(seq 100); do kill -0 "$pid" 2>/dev/null || break; sleep 0.1; done
			fi
			rm -f "$run/pid"
			${ipc} recorder stopped
			raw="$(cat "$run/raw")"; file="$(cat "$run/file")"
			if [ ! -s "$raw" ]; then
				rm -f "$raw"
				failed
				return 0
			fi
			if ${pkgs.ffmpeg-headless}/bin/ffmpeg -v error -y -i "$raw" -c copy \
				-bsf:v h264_metadata=video_full_range_flag=0 -movflags +faststart "$file"; then
				rm -f "$raw"
			else
				mv -f "$raw" "$file"
				[ "$died" = 0 ] || { failed; return 0; }
			fi
			uri=$(set -- "$file"; ${fileUri})
			${pkgs.wl-clipboard}/bin/wl-copy --type text/uri-list "$uri" || true
			picture=()
			if ${pkgs.ffmpeg-headless}/bin/ffmpeg -v error -y -i "$file" -frames:v 1 -vf scale=480:-2 "$run/frame.png" \
				&& [ -s "$run/frame.png" ]; then
				picture=(-h "string:image-path:$(set -- "$run/frame.png"; ${fileUri})")
			fi
			${notify} -a NIHIL "''${picture[@]}" "${strings.recordSaved}" "''${file/#$HOME/\~}" || true
		}

		case "''${1:-toggle}" in
			toggle) if [ -f "$run/pid" ]; then stop; else start "''${2:-region}"; fi ;;
			start) start "''${2:-region}" ;;
			stop) stop ;;
			status) if recording; then echo on; else echo off; fi ;;
			*) echo "Usage: nihil-record toggle|start [region|screen] | stop | status" >&2; exit 2 ;;
		esac
	'';

	osd-brightness = pkgs.writeShellScriptBin "osd-brightness" ''
		step="5%"
		case "$1" in
			up)
				${brightnessctl} set +"$step" >/dev/null
				;;
			down)
				${brightnessctl} set "$step"- >/dev/null
				;;
		esac
		br="$(${brightnessctl} -m | ${awk} -F, '{gsub("%","",$4); print $4}')"
		exec ${ipc} osd brightness "$br" >/dev/null 2>&1
	'';

	osd-volume = pkgs.writeShellScriptBin "osd-volume" ''
		sink="@DEFAULT_AUDIO_SINK@"
		step="5%"
		case "$1" in
			up)
				${wpctl} set-mute "$sink" 0
				${wpctl} set-volume -l 1 "$sink" "$step+"
				${pkgs.pipewire}/bin/pw-play --volume 0.4 ${volumeSound} &
				;;
			down)
				${wpctl} set-mute "$sink" 0
				${wpctl} set-volume "$sink" "$step-"
				${pkgs.pipewire}/bin/pw-play --volume 0.4 ${volumeSound} &
				;;
			mute)
				${wpctl} set-mute "$sink" toggle
				;;
		esac
		state="$(${wpctl} get-volume "$sink")"
		vol="$(${awk} '{printf "%d", $2 * 100 + 0.5}' <<< "$state")"
		muted=false
		if ${grep} -q MUTED <<< "$state"; then
			muted=true
		fi
		exec ${ipc} osd volume "$vol" "$muted" >/dev/null 2>&1
	'';

	osd-mic = pkgs.writeShellScriptBin "osd-mic" ''
		${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle
		${mic-led-sync}/bin/mic-led-sync || true
		muted=false
		if ${wpctl} get-volume @DEFAULT_AUDIO_SOURCE@ | ${grep} -q MUTED; then
			muted=true
		fi
		exec ${ipc} osd mic "$muted" >/dev/null 2>&1
	'';

	lock-screen = pkgs.writeShellScriptBin "lock-screen" ''
		${pkgs.procps}/bin/pidof hyprlock >/dev/null && exit 0
		${pkgs.pipewire}/bin/pw-play --volume 0.4 ${sound.lock} &
		exec ${pkgs.systemd}/bin/systemd-run --user --scope --collect --quiet ${config.programs.hyprlock.package}/bin/hyprlock
	'';

	power-off = pkgs.writeShellScriptBin "power-off" ''
		${pkgs.pipewire}/bin/pw-play --volume 0.5 ${sound.power}
		exec ${pkgs.systemd}/bin/systemctl poweroff
	'';
in
{
	home.packages =
	[
		mic-led-sync
		osd-brightness
		osd-volume
		osd-mic
		lock-screen
		power-off
		nihil-shot
		nihil-record
	];

}
