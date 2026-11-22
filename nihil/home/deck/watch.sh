# nihil-watch by poligle (home/deck/watch.nix): NIHIL for Wear OS on a watch,

repo=poligle/Nihil-Wear
package=com.nihilshell.wear
face=com.nihilshell.wear.watchface
provider=content://com.nihilshell.wear.shell
replaced=""

# The words are theme/i18n.nix's, in the machine's language: t key [value…], each value in for
# %1, %2…, as they come.
t() {
    local text i=1 value
    text=$(jq -r --arg k "$1" '.[$k] // $k' "$NIHIL_WATCH_STRINGS")
    shift
    for value in "$@"; do
        text=${text//"%$i"/"$value"}
        i=$((i + 1))
    done
    printf '%s' "$text"
}

say() { printf '\n%s\n' "$*"; }
fail() { printf '%s\n' "$*" >&2; exit 1; }

watches() {
    local serial state
    while read -r serial state _; do
        [ "$state" = device ] || continue
        case $(adb -s "$serial" shell getprop ro.build.characteristics 2> /dev/null) in
            *watch*) echo "$serial" ;;
        esac
    done < <(adb devices | tail -n +2)
}

watch() {
    local found
    mapfile -t found < <(watches)
    case ${#found[@]} in
        0) return 1 ;;
        1) echo "${found[0]}" ;;
        *) fail "$(t watchMany "${found[*]}")" ;;
    esac
}

service() {
    local type=$1 host=${2:-} found
    found=$(avahi-browse -rtp "$type" 2> /dev/null | awk -F';' '$1 == "=" && $3 == "IPv4" { print $8 ":" $9 }') || true
    if [ -z "$found" ]; then
        found=$(adb mdns services 2> /dev/null | awk -v type="$type." '$2 == type { print $3 }') || true
    fi
    if [ -n "$host" ]; then
        found=$(grep "^$host:" <<< "$found" || true)
    fi
    head -n 1 <<< "$found"
}

wait_for() {
    local type=$1 host=${2:-} seconds=$3 found=""
    for _ in $(seq "$seconds"); do
        found=$(service "$type" "$host")
        [ -n "$found" ] && break
        sleep 1
    done
    echo "$found"
}

pair() {
    local pairing code host connect
    say "$(t watchPairSteps)"
    t watchLooking; echo
    pairing=$(wait_for _adb-tls-pairing._tcp "" 90)
    if [ -z "$pairing" ]; then
        read -rp "$(t watchAskPairing)" pairing
    else
        t watchFound "$pairing"; echo
    fi
    read -rp "$(t watchAskCode)" code
    adb pair "$pairing" "$code" || fail "$(t watchPairFailed)"
    host=${pairing%:*}
    connect=$(wait_for _adb-tls-connect._tcp "$host" 20)
    if [ -z "$connect" ]; then
        read -rp "$(t watchAskConnect)" connect
    fi
    adb connect "$connect" > /dev/null || fail "$(t watchConnectFailed "$connect")"
    for _ in $(seq 10); do
        watch > /dev/null && return 0
        sleep 1
    done
    fail "$(t watchNotWatch "$connect")"
}

download() {
    local dir=$1 release sums name url
    release=$(curl -fsSL "https://api.github.com/repos/$repo/releases?per_page=20" |
        jq -c '[.[] | select(.draft | not)] | (map(select(.prerelease | not))[0] // .[0]) // empty') ||
        fail "$(t watchNoGithub)"
    [ -n "$release" ] || fail "$(t watchNoRelease "$repo")"
    say "$(jq -r '.name // .tag_name' <<< "$release")"
    sums=$(jq -r '.assets[] | select(.name == "SHA256SUMS") | .browser_download_url' <<< "$release")
    [ -n "$sums" ] || fail "$(t watchNoSums)"
    curl -fsSL -o "$dir/SHA256SUMS" "$sums" || fail "$(t watchDownloadFailed SHA256SUMS)"
    while read -r _ name; do
        name=${name#\*}
        case $name in
            *.apk) ;;
            *) fail "$(t watchNotApk "$name")" ;;
        esac
        case $name in */*) fail "$(t watchBadName "$name")" ;; esac
        url=$(jq -r --arg name "$name" '.assets[] | select(.name == $name) | .browser_download_url' <<< "$release")
        [ -n "$url" ] || fail "$(t watchMissingApk "$name")"
        curl -fsSL -o "$dir/$name" "$url" || fail "$(t watchDownloadFailed "$name")"
    done < "$dir/SHA256SUMS"
    (cd "$dir" && sha256sum --quiet --strict -c SHA256SUMS) || fail "$(t watchSumsWrong)"
}

install_one() {
    local serial=$1 apk=$2 id=$3 out answer
    t watchInstalling "$(basename "$apk")"; echo
    out=$(adb -s "$serial" install -r "$apk" 2>&1) && return 0
    case $out in
        *INSTALL_FAILED_UPDATE_INCOMPATIBLE*) ;;
        *) fail "$(t watchRefused "$(basename "$apk")" "$out")" ;;
    esac
    t watchOtherKey "$id"; echo
    read -rp "$(t watchAskReplace)" answer
    case $answer in
        [yYsS]*) ;;
        *) fail "$(t watchNothingReplaced)" ;;
    esac
    adb -s "$serial" uninstall "$id" > /dev/null || fail "$(t watchKept "$id")"
    adb -s "$serial" install "$apk" > /dev/null || fail "$(t watchRefusedShort "$(basename "$apk")")"
    replaced=1
}

install_latest() {
    local serial=$1 dir apk
    dir=$(mktemp -d)
    download "$dir"
    for apk in "$dir"/*.apk; do
        case $apk in *-face-*) ;; *) install_one "$serial" "$apk" "$package" ;; esac
    done
    for apk in "$dir"/*.apk; do
        case $apk in *-face-*) install_one "$serial" "$apk" "$face" ;; esac
    done
    rm -rf "$dir"
}

# What it hands the watch goes through adb's stdin, not a command line: an invitation, code and
# all, is in no one's ps, here or on the watch, while it waits to be used.
call() {
    local serial=$1 method=$2 arg=${3:-} out
    # shellcheck disable=SC2016 # $arg is the watch's, from the line it reads
    out=$(printf '%s\n' "$arg" | adb -s "$serial" shell \
        "read -r arg; content call --uri $provider --method $method"' ${arg:+--arg "$arg"}')
    out=${out%$'\r'}
    case $out in
        "Result: Bundle[{"*"}]") ;;
        *) fail "$(t watchSaid "$out")" ;;
    esac
    out=${out#"Result: Bundle[{"}
    out=${out%"}]"}
    echo "${out#*=}"
}

invite() {
    local serial=$1 uri name
    uri=$(nihil-deck pair --json | jq -r '.uri // empty') || true
    [ -n "$uri" ] || fail "$(t watchNoInvite "$(t cfgTitle), $(t cfgDevices), $(t deckUse)")"
    name=$(call "$serial" invite "$uri")
    adb -s "$serial" shell input keyevent KEYCODE_WAKEUP
    adb -s "$serial" shell am start -n "$package/.ProbeActivity" > /dev/null
    t watchInvited "$name"; echo
}

halo() {
    local serial=$1 service="$package/$package.system.HaloService" enabled
    t watchHalo; echo
    adb -s "$serial" shell cmd notification allow_listener "$package/$package.system.GlyphListener"
    enabled=$(adb -s "$serial" shell settings get secure enabled_accessibility_services | tr -d '\r')
    case ":$enabled:" in
        *":$service:"*) ;;
        ":null:" | "::") adb -s "$serial" shell settings put secure enabled_accessibility_services "$service" ;;
        *) adb -s "$serial" shell settings put secure enabled_accessibility_services "$enabled:$service" ;;
    esac
    adb -s "$serial" shell settings put secure accessibility_enabled 1
}

# Wireless debugging lets whatever paired with the watch install anything on it: off, if wanted.
unplug() {
    local serial=$1 answer
    case $serial in *:* | *._adb-tls-connect.*) ;; *) return 0 ;; esac
    read -rp "$(t watchAskDebugOff)" answer
    case $answer in
        [yYsS]*) adb -s "$serial" shell settings put global adb_wifi_enabled 0 > /dev/null 2>&1 || true ;;
    esac
}

case ${1:-install} in
    install)
        serial=$(watch) || { pair; serial=$(watch); }
        install_latest "$serial"
        invite "$serial"
        halo "$serial" || { t watchNoHalo; echo; }
        say "$(t watchDone)"
        unplug "$serial"
        ;;
    update)
        serial=$(watch) || fail "$(t watchNoWatch)"
        install_latest "$serial"
        if [ -n "$replaced" ]; then
            invite "$serial"
        fi
        say "$(t watchUpdated)"
        unplug "$serial"
        ;;
    forget)
        serial=$(watch) || fail "$(t watchNoWatch)"
        device=$(call "$serial" forget)
        if [ -n "$device" ] && nihil-deck forget "$device" > /dev/null; then
            t watchForgotBoth; echo
        else
            t watchForgot; echo
        fi
        ;;
    *)
        echo "Usage: nihil-watch [install | update | forget]" >&2
        exit 2
        ;;
esac
