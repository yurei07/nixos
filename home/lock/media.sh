# media.sh by poligle

set -u
export LC_ALL=C.UTF-8

if [[ -n ${XDG_RUNTIME_DIR:-} ]]; then dir="$XDG_RUNTIME_DIR/nihil-lock"; else dir="/tmp/nihil-lock-$UID"; fi
state="$dir/state"
sep=$'\x1f'
format="{{status}}$sep{{playerInstance}}$sep{{playerName}}$sep{{title}}$sep{{artist}}$sep{{position}}$sep{{mpris:length}}$sep{{mpris:artUrl}}"

glyph_prev=$'\xf3\xb0\x92\xae'
glyph_play=$'\xf3\xb0\x90\x8a'
glyph_pause=$'\xf3\xb0\x8f\xa4'
glyph_next=$'\xf3\xb0\x92\xad'

refresh() {
	local stamp=0 shown="" out line st inst playing="" paused="" own_playing="" own_paused="" t
	(umask 077 && mkdir -p "$dir") 2>/dev/null || return 0
	exec 9>"$dir/lock" || return 0
	if ! flock -w 3 9; then
		exec 9>&-
		return 0
	fi
	t=${EPOCHREALTIME//[!0-9]/}
	if [[ -s $state ]]; then
		IFS=$sep read -r stamp _ shown _ < "$state" || true
		[[ $stamp =~ ^[0-9]+$ ]] || stamp=0
		if [[ ${1:-} != now ]] && (( t - stamp < 900000 )); then
			exec 9>&-
			return 0
		fi
	fi
	out=$(timeout 2 playerctl --all-players metadata --format "$format" 2>/dev/null) || true
	while IFS= read -r line; do
		IFS=$sep read -r st inst _ <<< "$line"
		case $st in
			Playing)
				[[ -n $playing ]] || playing=$line
				[[ -n $shown && $inst == "$shown" ]] && own_playing=$line
				;;
			Paused)
				[[ -n $paused ]] || paused=$line
				[[ -n $shown && $inst == "$shown" ]] && own_paused=$line
				;;
		esac
	done <<< "$out"
	line=${own_playing:-${playing:-${own_paused:-$paused}}}
	printf '%s%s%s\n' "$t" "$sep" "$line" > "$state.tmp" && mv -f "$state.tmp" "$state"
	exec 9>&-
}

load() {
	stamp=0 status="" instance="" name="" title="" artist="" position="" length="" art=""
	[[ -s $state ]] || return 0
	IFS=$sep read -r stamp status instance name title artist position length art < "$state" || true
	[[ $stamp =~ ^[0-9]+$ ]] || stamp=0
	[[ $position =~ ^[0-9]+$ ]] || position=0
	[[ $length =~ ^[0-9]+$ ]] || length=0
	if (( ${EPOCHREALTIME//[!0-9]/} - stamp > 5000000 )); then status=""; fi
}

decode() {
	local s=${1#file://}
	s=${s//'%'/'\x'}
	printf -v REPLY '%b' "$s"
}

clean() {
	local s=$1 n=$2
	s=${s//[[:cntrl:]]/}
	if (( ${#s} > n )); then s="${s:0:n-1}…"; fi
	s=${s//'&'/'&amp;'}
	s=${s//'<'/'&lt;'}
	s=${s//'>'/'&gt;'}
	REPLY=$s
}

span() {
	printf "<span font_family='%s' size='%d' foreground='#%s' letter_spacing='%d'>%s</span>" \
		"$1" "$(( $2 * 1024 ))" "$3" "${5:-0}" "$4"
}

duration() {
	local s=$(( $1 / 1000000 ))
	if (( s >= 3600 )); then
		printf -v REPLY '%d:%02d:%02d' $(( s / 3600 )) $(( s % 3600 / 60 )) $(( s % 60 ))
	else
		printf -v REPLY '%d:%02d' $(( s / 60 )) $(( s % 60 ))
	fi
}

info() {
	load
	[[ -n $status ]] || return 0
	local head=${name^}
	[[ -n $head ]] || head=MPRIS
	[[ $status == Paused ]] && head="$head, ${PAUSED,}"
	clean "$head" 40
	span "$MONO" 8 "$DIM" "$REPLY" 1536
	clean "${title:-$name}" 30
	printf '\n'
	span "$SANS" 16 "$INK" "$REPLY"
	if [[ -n $artist ]]; then
		clean "$artist" 40
		printf '\n'
		span "$SANS" 11 "$DIM" "$REPLY"
	fi
}

progress() {
	refresh
	load
	[[ -n $status ]] || return 0
	local pos=$position elapsed total cells lit i on="" off=""
	if [[ $status == Playing && $stamp -gt 0 ]]; then
		pos=$(( pos + ${EPOCHREALTIME//[!0-9]/} - stamp ))
	fi
	if (( length > 0 && pos > length )); then pos=$length; fi
	duration "$pos"
	elapsed=$REPLY
	if (( length <= 0 )); then
		span "$MONO" 9 "$DIM" "$elapsed"
		return 0
	fi
	duration "$length"
	total=$REPLY
	cells=$(( 46 - 4 - ${#elapsed} - ${#total} ))
	lit=$(( (pos * cells + length / 2) / length ))
	for (( i = 0; i < cells; i++ )); do
		if (( i < lit )); then on+="•"; else off+="•"; fi
	done
	span "$MONO" 9 "$DIM" "$elapsed  "
	span "$ICONS" 9 "$INK" "$on"
	span "$ICONS" 9 "$MUTED" "$off"
	span "$MONO" 9 "$DIM" "  $total"
}

button() {
	load
	[[ -n $status ]] || return 0
	case ${1:-} in
		prev) span "$ICONS" 15 "$DIM" " $glyph_prev " ;;
		next) span "$ICONS" 15 "$DIM" " $glyph_next " ;;
		toggle)
			if [[ $status == Playing ]]; then
				span "$ICONS" 21 "$INK" " $glyph_pause "
			else
				span "$ICONS" 21 "$INK" " $glyph_play "
			fi
			;;
	esac
}

cover() {
	load
	if [[ -z $status ]]; then
		printf '%s\n' "$BLANK"
		return 0
	fi
	local src="" key png started=0 t
	case $art in
		file://*) decode "$art"; src=$REPLY ;;
		http://* | https://*) ;;
		*) printf '%s\n' "$NOART"; return 0 ;;
	esac
	key=${art//[!A-Za-z0-9._-]/_}
	if (( ${#key} > 120 )); then key=${key: -120}; fi
	png="$dir/cover-$key.png"
	if [[ -s $png && ( -z $src || ! $src -nt $png ) ]]; then
		printf '%s\n' "$png"
		return 0
	fi
	if [[ -e $png.fail && ( -z $src || ! $src -nt $png.fail ) ]]; then
		printf '%s\n' "$NOART"
		return 0
	fi
	t=${EPOCHREALTIME//[!0-9]/}
	if [[ -d $png.job ]]; then
		read -r started < "$png.job/started" 2>/dev/null || true
		[[ $started =~ ^[0-9]+$ ]] || started=0
		if (( t - started > 60000000 )); then rm -rf "$png.job"; fi
	fi
	if mkdir "$png.job" 2>/dev/null; then
		printf '%s\n' "$t" > "$png.job/started"
		{ timeout 30 "$0" render "$art" "$png"; rm -rf "$png.job"; } < /dev/null > /dev/null 2>&1 &
	fi
	printf '%s\n' "$NOART"
}

render() {
	local art=$1 png=$2 src tmp ok=0
	tmp=$(mktemp "$dir/fetch.XXXXXX") || return 1
	case $art in
		file://*)
			decode "$art"
			src=$REPLY
			;;
		http://* | https://*)
			local ca=()
			[[ -r /etc/ssl/certs/ca-certificates.crt ]] && ca=(--cacert /etc/ssl/certs/ca-certificates.crt)
			if curl --silent --fail --location --max-time 15 --max-filesize 10485760 \
				--proto '=http,https' --proto-redir '=http,https' "${ca[@]}" --output "$tmp" "$art"; then
				src=$tmp
			fi
			;;
	esac
	if [[ -n ${src:-} && -f $src ]] && "$RENDER" "$src" "$png"; then ok=1; fi
	rm -f "$tmp"
	if (( ok )); then
		rm -f "$png.fail"
		ls -1t "$dir"/cover-*.png 2>/dev/null | tail -n +41 | while IFS= read -r old; do rm -f "$old"; done
	else
		: > "$png.fail"
	fi
}

act() {
	load
	[[ -n $instance ]] || return 0
	case $1 in
		prev) timeout 2 playerctl --player="$instance" previous ;;
		next) timeout 2 playerctl --player="$instance" next ;;
		toggle) timeout 2 playerctl --player="$instance" play-pause ;;
	esac > /dev/null 2>&1 || true
	sleep 0.25
	refresh now
	sleep 0.75
	refresh now
}

backdrop() {
	load
	local plain="$LOCK/$1.png" lit="$LOCK/$1-media.png"
	if [[ -n $status && -e $lit ]]; then
		printf '%s\n' "$lit"
	else
		printf '%s\n' "$plain"
	fi
}

case ${1:-} in
	info) info ;;
	progress) progress ;;
	button) button "${2:-}" ;;
	cover) cover ;;
	render) render "${2:-}" "${3:-}" ;;
	backdrop) backdrop "${2:-}" ;;
	prev | toggle | next) act "$1" ;;
	*) echo "Usage: nihil-lock-media info|progress|button prev|toggle|next|cover|backdrop OUTPUT|prev|toggle|next" >&2; exit 2 ;;
esac