# nihil-cli.nix by poligle

{ config, lib, options, pkgs, ... }:
let
    flake = config.nihil.flake;
    xkb = config.services.xserver.xkb;

    loader = config.boot.loader.systemd-boot;
    menu = if !loader.enable then 0 else if loader.configurationLimit == null then 100000 else loader.configurationLimit;

    # The values settings.json may give these, as their options declare them.
    languages = options.nihil.language.type.functor.payload.values or [ "es" "en" ];
    accelerations = options.nihil.nilo.acceleration.type.functor.payload.values or [ "cpu" "vulkan" "rocm" "cuda" ];

    # What apply and settings take: the account stays the one settings.json names (another
    # name would leave it out of the system, password and all), host.name is there, and each
    # key NIHIL reads has its type. It prints why not, or nothing.
    check = pkgs.writeText "nihil-settings.jq" ''
        def text: type == "string";
        def flag: type == "boolean";
        def whole($low; $high): type == "number" and . == floor and . >= $low and . <= $high;
        def either(f): . == null or f;
        if type != "object" then "it's not an object"
        elif (.user | either(type == "object")) | not then "user is not an object"
        elif (.user.name // "nihil") != $user then "user.name stays \($user), or that account would be left out of the system"
        elif (.user.fullName | either(text)) | not then "user.fullName is not text"
        elif (.host | type == "object" and (.name | text and test("^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$"))) | not
            then "host.name takes lowercase letters, digits and hyphens, with no hyphen at either end"
        elif (.language | either(IN($languages[]))) | not then "language is \($languages | join(" or "))"
        elif (.locale | either(text and test("^[A-Za-z0-9_.@-]+$"))) | not then "locale is not the name of a locale"
        elif (.timeZone | either(text and test("^[A-Za-z0-9_+-]+(/[A-Za-z0-9_+-]+)*$"))) | not
            then "timeZone is not the name of a time zone"
        elif (.keyboard | either(type == "object" and all(.layout, .variant, .model; either(text)))) | not
            then "keyboard's layout, variant and model are text"
        elif (.outputs | either(type == "object" and all(.[]; type == "object"))) | not then "outputs has an object for each screen"
        elif all(.primaryOutput, .wallpaper; either(text)) | not then "primaryOutput and wallpaper are text"
        elif (.nilo | either(type == "object" and all(.enable, .integratedGpu; either(flag))
                and (.acceleration | either(IN($accelerations[]))))) | not
            then "nilo's enable and integratedGpu are true or false, and its acceleration \($accelerations | join(", "))"
        elif all(.binds, .gestures; either(type == "object" and all(.[]; either(text)))) | not
            then "binds and gestures give each action the text of a key, or null"
        elif (.programs | either(type == "array")) | not then "programs is a list"
        elif all(.fingerprint, .ssh, .bootSound; either(flag)) | not then "fingerprint, ssh and bootSound are true or false"
        elif (.sshKeys | either(type == "array" and all(.[]; text))) | not then "sshKeys is a list of public keys"
        elif (.generations | either(type == "object" and (.days | either(whole(1; 3650))))) | not
            then "generations.days goes from 1 to 3650"
        elif (.clipboard | either(whole(0; 100))) | not then "clipboard goes from 0 to 100"
        elif (.deck | either(type == "object" and (.enable | either(flag)) and (.bluetooth | either(flag))
                and (.interfaces | either(type == "array" and all(.[]; text and test("^[A-Za-z0-9_.:@-]{1,15}$")))))) | not
            then "deck.enable and deck.bluetooth are true or false, and deck.interfaces a list of network interfaces"
        else empty end
    '';

    nihil = pkgs.writeShellApplication
    {
        name = "nihil";
        runtimeInputs = [ pkgs.jq pkgs.coreutils pkgs.diffutils pkgs.gawk pkgs.gnused pkgs.gnutar pkgs.curl pkgs.shadow
            pkgs.util-linux pkgs.openssh pkgs.xkbvalidate config.systemd.package config.nix.package ];
        text = ''
            flake=''${NIHIL_FLAKE:-${flake}}
            # The machine's settings.json: the one whose host.name is this running system's
            # (stamped at /etc/nihil/settings.json when it was built), else one matching the
            # hostname, else the flake root's. A machine's flake keeps it in hosts/<name>/.
            run_host=$(jq -r '.host.name // empty' /etc/nihil/settings.json 2>/dev/null || true)
            settings_json=""
            for candidate in "$flake"/hosts/*/settings.json "$flake"/settings.json; do
                [ -f "$candidate" ] || continue
                if [ -n "$run_host" ] && [ "$(jq -r '.host.name // empty' "$candidate" 2>/dev/null)" = "$run_host" ]; then
                    settings_json="$candidate"
                    break
                fi
            done
            if [ -z "$settings_json" ]; then
                for candidate in "$flake"/hosts/*/settings.json "$flake"/settings.json; do
                    [ -f "$candidate" ] || continue
                    if [ "$(jq -r '.host.name // empty' "$candidate" 2>/dev/null)" = "$(hostname)" ]; then
                        settings_json="$candidate"
                        break
                    fi
                done
            fi
            if [ -z "$settings_json" ]; then
                for candidate in "$flake"/hosts/*/settings.json "$flake"/settings.json; do
                    [ -f "$candidate" ] || continue
                    settings_json="$candidate"
                    break
                done
            fi
            run=/run/nihil
            aside=$run/aside
            dev=/var/lib/nihil/dev
            tree=/var/lib/nihil/dev-tree
            profile=''${NIHIL_PROFILE:-/nix/var/nix/profiles/system}
            menu=${toString menu}
            oneshot=''${NIHIL_ONESHOT:-/sys/firmware/efi/efivars/LoaderEntryOneShot-4a67b082-0a4c-41cf-b6c7-440b29bb8c4f}
            unit=""
            before=""
            kept=""
            temporary=()

            # What changes the system runs as root, all of it, so that it holds the lock throughout.
            become_root() {
                local keep_flake=()
                if [ "$(id -u)" != 0 ]; then
                    if [ -n "''${NIHIL_FLAKE:-}" ]; then
                        keep_flake=(--preserve-env=NIHIL_FLAKE)
                    fi
                    exec sudo "''${keep_flake[@]}" "$(readlink -f "$0")" "$@"
                fi
            }

            # One change to the system at a time, whoever makes it: a terminal, Preferences (in
            # nihil-apply.service) or Nilo. Taken before anything is touched. The commands a change
            # runs don't get its descriptor (9>&-): one left running would keep the lock.
            lock() {
                local mask
                mkdir -p "$run"
                # Opened, and made if it isn't there, in one step: two commands starting at once
                # can't each lock a file of their own.
                mask=$(umask)
                umask 077
                exec 9>> "$run/lock"
                umask "$mask"
                if ! flock -n 9 || systemctl is-active --quiet nihil-apply.service; then
                    echo "Something is being applied already." >&2
                    exit 3
                fi
            }

            # In nihil-apply.service, the same lock: what started the unit held it until then.
            hold() {
                exec 9>> "$run/lock"
                flock 9
            }

            # A change begins. What it replaces is kept (keep), and on any way out, a failure,
            # Ctrl+C or systemctl stop, goes back if the system is still the one from before.
            begin() {
                before=$(readlink -f /run/current-system)
                rm -rf "$aside"
                mkdir -p "$aside"
                trap 'exit 130' INT
                trap 'exit 143' TERM HUP
            }

            keep() {
                kept=1
                if [ -e "$1" ]; then
                    cp -p "$1" "$aside/$2"
                else
                    : > "$aside/$2.none"
                fi
            }

            put_back() {
                if [ -e "$aside/$2" ]; then
                    cp -p "$aside/$2" "$1" || true
                elif [ -e "$aside/$2.none" ]; then
                    rm -f "$1"
                fi
            }

            finish() {
                if [ "$1" = 0 ]; then
                    # Quoted: a bare done is the shell's keyword to shellcheck
                    echo "done" > "$run/apply.status"
                elif [ "$(readlink -f /run/current-system)" != "$before" ]; then
                    echo warning > "$run/apply.status"
                else
                    echo failed > "$run/apply.status"
                fi
            }

            # However it ends: the unit's status never stays at running (Preferences would wait
            # for it until a restart), and a failed change leaves no file of the system changed.
            ended() {
                local status=$?
                if [ -n "$before" ]; then
                    if [ "$status" != 0 ] && [ -n "$kept" ] && [ "$(readlink -f /run/current-system)" = "$before" ]; then
                        put_back "$settings_json" settings.json
                        put_back "$flake/flake.lock" flake.lock
                        put_back "$dev" dev
                        echo "Nothing was applied: the system and its files are as they were."
                    fi
                    rm -rf "$aside"
                fi
                if [ "''${#temporary[@]}" != 0 ]; then
                    rm -f "''${temporary[@]}"
                fi
                if [ -n "$unit" ] && [ "$(cat "$run/apply.status" 2> /dev/null)" = running ]; then
                    finish "$status"
                fi
            }
            trap ended EXIT

            # Starts a change in nihil-apply.service, where Preferences follows it ($run/apply.*).
            in_unit() {
                local kind=$1
                shift
                echo running > "$run/apply.status"
                echo "$kind" > "$run/apply.kind"
                : > "$run/apply.log"
                chmod 0644 "$run/apply.status" "$run/apply.kind" "$run/apply.log"
                if ! systemd-run --unit nihil-apply --collect --quiet -E HOME=/root -- "$(readlink -f "$0")" "$@" 9>&-; then
                    echo failed > "$run/apply.status"
                    echo "nihil-apply.service didn't start." >&2
                    exit 4
                fi
            }

            # A terminal follows the change it started, to its end: closed or interrupted halfway, it
            # stops following, and the unit goes on. It answers as the change ended.
            follow() {
                local pid
                exec 9>&-
                pid=$(systemctl show -p MainPID --value nihil-apply.service 2> /dev/null || true)
                if [ -n "$pid" ] && [ "$pid" != 0 ]; then
                    tail -n +1 -f --pid="$pid" "$run/apply.log" || true
                fi
                while [ "$(cat "$run/apply.status" 2> /dev/null)" = running ]; do
                    sleep 0.2
                done
                if [ -z "$pid" ] || [ "$pid" = 0 ]; then
                    cat "$run/apply.log"
                fi
                [ "$(cat "$run/apply.status" 2> /dev/null)" = "done" ]
            }

            # The change itself, in the unit: its output goes to the log Preferences reads, and it
            # takes the lock over.
            unit_start() {
                unit=1
                export PATH="/run/wrappers/bin:/run/current-system/sw/bin:$PATH"
                exec >> "$run/apply.log" 2>&1
                hold
                begin
            }

            checkout() {
                local from
                from=$(head -n 1 "$dev" 2> /dev/null || true)
                if [ -n "$from" ] && [ -f "$from/flake.nix" ]; then
                    echo "$from"
                fi
            }

            # Who turned nihil dev on: the checkout is read as them, never as root.
            dev_owner() {
                local who
                who=$(sed -n 2p "$dev" 2> /dev/null || true)
                echo "''${who:-${config.nihil.user.name}}"
            }

            # A copy of the checkout, read as its owner and written as root's: a link in it can't
            # bring root's files into the store, and nobody else edits the copy while it's built.
            snapshot() {
                rm -rf "$tree.new" &&
                    mkdir -p "$tree.new" &&
                    runuser -u "$(dev_owner)" -- tar -C "$1" --exclude=.git --exclude=./.direnv --exclude=./result \
                        --exclude='./result-*' --exclude=__pycache__ -cf - . |
                        tar -C "$tree.new" --no-same-owner --no-same-permissions -xf - &&
                    chown -R root:root "$tree.new" &&
                    rm -rf "$tree" &&
                    mv "$tree.new" "$tree"
            }

            rebuild() {
                local host from override=()
                host=$(jq -r '.host.name // empty' "$settings_json")
                from=$(checkout)
                if [ -n "$from" ]; then
                    echo "NIHIL from $from (nihil dev off goes back to the one pinned)."
                    if ! snapshot "$from"; then
                        echo "Could not copy $from to $tree: nothing built." >&2
                        return 1
                    fi
                    override=(--override-input nihil "path:$tree" --no-write-lock-file)
                fi
                nixos-rebuild switch --flake "$flake#''${host:-$(hostname)}" "''${override[@]}" "$@" 9>&-
            }

            # FILE as whoever asked through sudo: root doesn't follow their links to its own files.
            usage() {
                echo "Usage: nihil rebuild | update [--unit] | check [--json] | settings | version | dev [path|off] | apply FILE | welcome | watch"
                echo "       nihil generations [--json] | changes N | boot N | switch N [--unit] | clean DAYS [--unit]"
                echo "The machine's flake: $flake"
            }

            read_as_caller() {
                if [ -n "''${SUDO_USER:-}" ]; then
                    runuser -u "$SUDO_USER" -- cat -- "$1"
                else
                    cat -- "$1"
                fi
            }

            # Whether FILE is settings this machine takes; why not, on stderr.
            valid() {
                local current problem key n=0
                local -a keys
                current=$(jq -r '.user.name // "nihil"' "$settings_json" 2> /dev/null || echo ${lib.escapeShellArg config.nihil.user.name})
                if ! jq empty "$1" 2> /dev/null; then
                    echo "Those settings are not valid: it's not JSON." >&2
                    return 1
                fi
                if ! problem=$(jq -r --arg user "$current" --argjson languages ${lib.escapeShellArg (builtins.toJSON languages)} \
                    --argjson accelerations ${lib.escapeShellArg (builtins.toJSON accelerations)} -f ${check} "$1"); then
                    echo "Those settings are not valid." >&2
                    return 1
                fi
                if [ -n "$problem" ]; then
                    echo "Those settings are not valid: $problem." >&2
                    return 1
                fi
                if ! XKB_CONFIG_ROOT=${xkb.dir} xkbvalidate "$(jq -r '.keyboard.model // ""' "$1")" \
                    "$(jq -r '.keyboard.layout // "us"' "$1")" "$(jq -r '.keyboard.variant // ""' "$1")" \
                    ${lib.escapeShellArg xkb.options} > /dev/null 2>&1; then
                    echo "Those settings are not valid: that keyboard layout, variant or model doesn't exist." >&2
                    return 1
                fi
                if [ ! -f "${pkgs.tzdata}/share/zoneinfo/$(jq -r '.timeZone // "UTC"' "$1")" ]; then
                    echo "Those settings are not valid: that time zone doesn't exist." >&2
                    return 1
                fi
                mapfile -t keys < <(jq -r '.sshKeys // [] | .[]' "$1")
                for key in "''${keys[@]}"; do
                    n=$((n + 1))
                    if ! printf '%s\n' "$key" | ssh-keygen -l -f - > /dev/null 2>&1; then
                        echo "Those settings are not valid: key $n in sshKeys is not a public key." >&2
                        return 1
                    fi
                done
            }

            # The latest NIHIL, leaving nihil dev for it. If it fails and the system stays as it
            # was, flake.lock and nihil dev go back: the next apply builds what runs, not this.
            update_nihil() {
                local old new
                keep "$flake/flake.lock" flake.lock
                keep "$dev" dev
                if [ -f "$dev" ]; then
                    echo "Leaving nihil dev ($(head -n 1 "$dev")) for the NIHIL on GitHub."
                    rm -f "$dev"
                fi
                old=$(jq -r '.nodes.nihil.locked.rev // "?"' "$flake/flake.lock" 2> /dev/null || echo "?")
                if ! nix flake update --refresh --flake "$flake" 9>&-; then
                    return 1
                fi
                new=$(jq -r '.nodes.nihil.locked.rev // "?"' "$flake/flake.lock" 2> /dev/null || echo "?")
                if [ "$old" = "$new" ]; then
                    echo "NIHIL is up to date (''${new:0:7})."
                else
                    echo "NIHIL ''${old:0:7} -> ''${new:0:7}"
                fi
                if ! rebuild "$@"; then
                    return 1
                fi
                rm -rf "$tree" "$tree.new"
            }

            check() {
                local node rev owner repo ref api compare from
                node=$(jq -c '.nodes.nihil // {}' "$flake/flake.lock" 2> /dev/null || echo '{}')
                rev=$(jq -r 'if .locked.type == "github" then .locked.rev // "" else "" end' <<< "$node")
                owner=$(jq -r '.locked.owner // ""' <<< "$node")
                repo=$(jq -r '.locked.repo // ""' <<< "$node")
                ref=$(jq -r '.original.ref // ""' <<< "$node")
                from=$(checkout)
                if [ -z "$rev" ]; then
                    jq -n --arg dev "$from" '{ state: "unknown", dev: $dev }'
                    return
                fi
                api="https://api.github.com/repos/$owner/$repo"
                if [ -z "$ref" ]; then
                    ref=$(curl -fsSL --max-time 10 "$api" | jq -r '.default_branch // ""') || ref=""
                fi
                if [ -n "$ref" ] && compare=$(curl -fsSL --max-time 15 "$api/compare/$rev...$ref"); then
                    jq --arg dev "$from" --arg rev "$rev" --arg ref "$ref" '{
                        state: (if .ahead_by > 0 then "behind" else "current" end),
                        behind: .ahead_by,
                        pinned: $rev[0:7],
                        branch: $ref,
                        commits: [.commits | reverse | .[:20][] | { sha: .sha[0:7], subject: (.commit.message | split("\n")[0]) }],
                        dev: $dev
                    }' <<< "$compare"
                else
                    jq -n --arg dev "$from" --arg rev "$rev" '{ state: "offline", pinned: $rev[0:7], dev: $dev }'
                fi
            }

            numbers() {
                local link n
                for link in "$profile"-*-link; do
                    n=''${link#"$profile"-}
                    n=''${n%-link}
                    case $n in
                        "" | *[!0-9]*) continue ;;
                    esac
                    echo "$n"
                done | sort -n
            }

            number_of() {
                local name
                name=$(basename "$1")
                name=''${name#"$(basename "$profile")"-}
                echo "''${name%-link}"
            }

            is_generation() {
                case ''${1:-} in
                    "" | *[!0-9]*) return 1 ;;
                esac
                [ -L "$profile-$1-link" ]
            }

            generations() {
                local current default next n link path date version kernel revision dir free size
                current=$(readlink -f /run/current-system 2> /dev/null || true)
                default=$(number_of "$(readlink "$profile" 2> /dev/null || echo none)")
                next=""
                if [ -r "$oneshot" ]; then
                    next=$(tail -c +5 "$oneshot" | tr -d '\0' | sed -n 's/^nixos-generation-\([0-9]*\)\(\.conf\)\{0,1\}$/\1/p')
                fi
                read -r free size < <(df -B1 --output=avail,size /nix/store | tail -n 1) || true
                for n in $(numbers | sort -rn); do
                    link="$profile-$n-link"
                    path=$(readlink -f "$link")
                    date=$(stat -c %Y "$link")
                    version=$(cat "$path/nixos-version" 2> /dev/null || true)
                    kernel=""
                    for dir in "$path"/kernel-modules/lib/modules/*; do
                        if [ -d "$dir" ]; then
                            kernel=$(basename "$dir")
                            break
                        fi
                    done
                    revision=$(cat "$path/etc/nihil/revision" 2> /dev/null || true)
                    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$n" "$date" "$version" "$kernel" "$revision" "$path"
                done | jq -R -s --arg current "$current" --arg default "$default" --arg next "$next" \
                    --argjson menu "$menu" --argjson free "''${free:-0}" --argjson size "''${size:-0}" '
                    split("\n") | map(select(length > 0) | split("\t")) | to_entries | map(.key as $i | .value | {
                        number: (.[0] | tonumber),
                        date: (.[1] | tonumber),
                        nixos: .[2],
                        kernel: .[3],
                        nihil: (.[4] | split(" ")[0] // ""),
                        current: (.[5] == $current),
                        default: (.[0] == $default),
                        next: (.[0] == $next),
                        menu: ($i < $menu)
                    }) | { generations: ., bootMenu: ($menu > 0), free: $free, size: $size }'
            }

            changes() {
                local before="" n
                for n in $(numbers); do
                    if [ "$n" -lt "$1" ]; then
                        before=$n
                    fi
                done
                if [ -z "$before" ]; then
                    jq -n --argjson n "$1" '{ number: $n, before: null, lines: [] }'
                    return
                fi
                nix --extra-experimental-features nix-command store diff-closures "$profile-$before-link" "$profile-$1-link" \
                    | sed 's/\x1b\[[0-9;]*m//g' \
                    | jq -R -s --argjson n "$1" --argjson before "$before" '{ number: $n, before: $before, lines: (split("\n") | map(select(length > 0))) }'
            }

            boot_once() {
                local id
                id=$({ bootctl list --json=short 2> /dev/null || echo '[]'; } | jq -r --arg want "nixos-generation-$1" '
                    [ (if type == "array" then .[] else empty end) | .id // empty | select(ascii_downcase == $want or ascii_downcase == $want + ".conf") ][0] // empty')
                if [ -z "$id" ]; then
                    echo "The boot menu has no generation $1." >&2
                    exit 5
                fi
                bootctl set-oneshot "$id"
                echo "The next boot only, generation $1."
            }

            switch_to() {
                local previous running status=0
                previous=$(number_of "$(readlink "$profile")")
                running=$(readlink -f /run/current-system)
                echo "Generation $1, in place of $previous."
                if ! nix-env --profile "$profile" --switch-generation "$1"; then
                    return 1
                fi
                "$profile/bin/switch-to-configuration" switch 9>&- || status=$?
                if [ "$status" != 0 ] && [ "$(readlink -f /run/current-system)" = "$running" ]; then
                    nix-env --profile "$profile" --switch-generation "$previous" || true
                fi
                return "$status"
            }

            clean() {
                local free_before free_after status=0
                free_before=$(df -B1 --output=avail /nix/store | tail -n 1 | tr -d ' ')
                if ! nix-collect-garbage --delete-older-than "$1"d 9>&-; then
                    return 1
                fi
                "$profile/bin/switch-to-configuration" boot 9>&- || status=$?
                sync -f /nix/store || true
                free_after=$(df -B1 --output=avail /nix/store | tail -n 1 | tr -d ' ')
                echo "nihil: freed $(( free_after > free_before ? free_after - free_before : 0 ))"
                return "$status"
            }

            case "''${1:-help}" in
                rebuild)
                    shift
                    become_root rebuild "$@"
                    lock
                    begin
                    rebuild "$@"
                    ;;
                check)
                    shift
                    result=$(check)
                    if [ "''${1:-}" = --json ]; then
                        echo "$result"
                        exit 0
                    fi
                    case $(jq -r .state <<< "$result") in
                        behind)
                            jq -r '"GitHub has \(.behind) commit\(if .behind == 1 then "" else "s" end) past the NIHIL pinned (\(.pinned)):",
                                (.commits[] | "  \(.sha)  \(.subject)"),
                                "nihil update brings \(if .behind == 1 then "it" else "them" end)."' <<< "$result"
                            ;;
                        current) echo "NIHIL is up to date ($(jq -r .pinned <<< "$result"))." ;;
                        offline) echo "GitHub can't be reached: no way to know." ;;
                        *) echo "This NIHIL doesn't come from GitHub: nothing to compare." ;;
                    esac
                    if [ -n "$(checkout)" ]; then
                        echo "The system runs $(checkout) (nihil dev) meanwhile."
                    fi
                    ;;
                update)
                    shift
                    become_root update "$@"
                    if [ "''${1:-}" = --unit ]; then
                        trap 'exit 4' ERR
                        lock
                        in_unit update update-run
                        echo "Updating in nihil-apply.service: $run/apply.log tells how it goes."
                        exit 0
                    fi
                    lock
                    begin
                    update_nihil "$@"
                    ;;
                settings)
                    shift
                    if [ "$#" = 0 ]; then
                        # Edited in a copy, as whoever runs it: settings.json changes once the copy
                        # is valid, and goes back if the rebuild that applies it fails.
                        draft=$(mktemp --suffix=.json)
                        temporary+=("$draft")
                        cp "$settings_json" "$draft"
                        read -r -a editor <<< "''${VISUAL:-''${EDITOR:-nano}}"
                        while true; do
                            "''${editor[@]}" "$draft"
                            if cmp -s "$draft" "$settings_json"; then
                                echo "settings.json is as it was: nothing to apply."
                                exit 0
                            fi
                            if valid "$draft"; then
                                break
                            fi
                            read -r -p "Edit it again? [Y/n] " again || again=n
                            case $again in
                                [nN]*)
                                    echo "Nothing applied." >&2
                                    exit 1
                                    ;;
                            esac
                        done
                        if [ "$(id -u)" != 0 ]; then
                            sudo "$(readlink -f "$0")" settings "$draft"
                            exit
                        fi
                        set -- "$draft"
                    fi
                    become_root settings "$@"
                    lock
                    staged=$(mktemp)
                    temporary+=("$staged")
                    if ! read_as_caller "$1" > "$staged"; then
                        echo "$1 can't be read." >&2
                        exit 2
                    fi
                    if ! valid "$staged"; then
                        exit 2
                    fi
                    begin
                    keep "$settings_json" settings.json
                    install -m 0644 "$staged" "$settings_json"
                    rebuild
                    ;;
                dev)
                    shift
                    become_root dev "$@"
                    if [ "''${1:-}" = off ]; then
                        shift
                        lock
                        begin
                        keep "$dev" dev
                        rm -rf "$dev" "$tree" "$tree.new"
                        echo "NIHIL as pinned in $flake/flake.lock again."
                        rebuild "$@"
                        exit 0
                    fi
                    from=$(realpath "''${1:-.}")
                    if [ "$#" -gt 0 ]; then
                        shift
                    fi
                    if [ ! -f "$from/flake.nix" ]; then
                        echo "There is no NIHIL checkout in $from." >&2
                        exit 1
                    fi
                    lock
                    begin
                    keep "$dev" dev
                    mkdir -p "$(dirname "$dev")"
                    # The checkout, and who turned it on: rebuilds read it as them.
                    printf '%s\n%s\n' "$from" "''${SUDO_USER:-root}" > "$dev"
                    chmod 0644 "$dev"
                    rebuild "$@"
                    ;;
                generations)
                    shift
                    what=''${1:-list}
                    n=''${2:-}
                    case $what in
                        list | --json)
                            if [ "$what" = --json ] || [ "$n" = --json ]; then
                                generations
                                exit 0
                            fi
                            generations | jq -r '.generations[] | [
                                    "\(.number)",
                                    (.date | strflocaltime("%Y-%m-%d %H:%M")),
                                    (if .nixos != "" then "NixOS \(.nixos)" else empty end),
                                    (if .kernel != "" then "Linux \(.kernel)" else empty end),
                                    (if .nihil != "" then "NIHIL \(.nihil)" else empty end),
                                    ([ (if .current then "running" else empty end), (if .default then "boots" else empty end),
                                        (if .next then "the next boot" else empty end) ] | join(", "))
                                ] | map(select(. != "")) | join("  ")'
                            ;;
                        changes)
                            if ! is_generation "$n"; then
                                echo "There is no generation $n." >&2
                                exit 2
                            fi
                            changes "$n"
                            ;;
                        boot | switch | clean)
                            become_root generations "$@"
                            set -o errtrace
                            trap 'exit 4' ERR
                            if [ "$what" = clean ]; then
                                case $n in
                                    "" | *[!0-9]*) n=0 ;;
                                esac
                                if [ "$n" -lt 1 ] || [ "$n" -gt 3650 ]; then
                                    echo "Days, from 1 to 3650." >&2
                                    exit 2
                                fi
                            elif ! is_generation "$n"; then
                                echo "There is no generation $n." >&2
                                exit 2
                            fi
                            case $what:''${3:-} in
                                boot:*)
                                    boot_once "$n"
                                    ;;
                                switch:--unit)
                                    lock
                                    in_unit generation generations switch-run "$n"
                                    echo "In nihil-apply.service: $run/apply.log tells how it goes."
                                    ;;
                                switch:*)
                                    lock
                                    in_unit generation generations switch-run "$n"
                                    follow
                                    ;;
                                clean:--unit)
                                    lock
                                    in_unit clean generations clean-run "$n"
                                    echo "In nihil-apply.service: $run/apply.log tells how it goes."
                                    ;;
                                clean:*)
                                    lock
                                    in_unit clean generations clean-run "$n"
                                    follow
                                    ;;
                            esac
                            ;;
                        switch-run | clean-run)
                            unit_start
                            status=0
                            if [ "$what" = switch-run ]; then
                                switch_to "$n" || status=$?
                                echo "nihil: generation $(number_of "$(readlink "$profile")")"
                            else
                                clean "$n" || status=$?
                            fi
                            exit "$status"
                            ;;
                        *)
                            echo "Usage: nihil generations [--json] | changes N | boot N | switch N [--unit] | clean DAYS [--unit]" >&2
                            exit 2
                            ;;
                    esac
                    ;;
                apply)
                    shift
                    become_root apply "$@"
                    trap 'exit 4' ERR
                    lock
                    staged=$(mktemp)
                    temporary+=("$staged")
                    if [ "''${1:--}" = - ]; then
                        awk 'started || /^[{]/ { started = 1; print }' > "$staged"
                    elif ! read_as_caller "$1" > "$staged"; then
                        echo "$1 can't be read." >&2
                        exit 2
                    fi
                    if ! valid "$staged"; then
                        exit 2
                    fi
                    install -m 0644 "$staged" "$run/settings.json"
                    in_unit settings apply-run
                    echo "Applying in nihil-apply.service: $run/apply.log tells how it goes."
                    ;;
                apply-run)
                    unit_start
                    keep "$settings_json" settings.json
                    install -m 0644 "$run/settings.json" "$settings_json"
                    rebuild
                    ;;
                update-run)
                    unit_start
                    update_nihil
                    ;;
                passwd)
                    # Preferences' own: the password of the user who ran sudo, and of nobody else. The
                    # new one comes in a file of that user's, which goes once read; on stdin, after
                    # the current one, sudo would take it for a second try.
                    if [ "$(id -u)" != 0 ]; then
                        exec sudo "$(readlink -f "$0")" passwd
                    fi
                    if [ -z "''${SUDO_USER:-}" ] || [ "$SUDO_USER" = root ]; then
                        echo "nihil passwd: only for the user who runs it, through sudo" >&2
                        exit 3
                    fi
                    file="/run/user/$(id -u -- "$SUDO_USER")/nihil-new-password"
                    password=$(read_as_caller "$file") || exit 4
                    runuser -u "$SUDO_USER" -- rm -f -- "$file"
                    case "$password" in
                        "" | *$'\n'* | *$'\r'*) exit 3 ;;
                    esac
                    printf '%s:%s\n' "$SUDO_USER" "$password" | chpasswd || exit 4
                    ;;
                welcome)
                    exec nihil-ipc settings welcome
                    ;;
                watch)
                    shift
                    if ! command -v nihil-watch > /dev/null; then
                        # The way there as Preferences names it, in the system's language.
                        echo ${lib.escapeShellArg "The deck is off: ${config.nihil.strings.cfgTitle}, ${config.nihil.strings.cfgDevices}, ${config.nihil.strings.deckUse} (nihil.deck.enable)."} >&2
                        exit 1
                    fi
                    exec nihil-watch "$@"
                    ;;
                version)
                    running=$(cat /etc/nihil/revision 2>/dev/null || echo "?")
                    pinned=$(jq -r '.nodes.nihil.locked | "\(.rev[0:7] // "local") (\(.lastModified // 0 | strftime("%Y-%m-%d %H:%M")))"' "$flake/flake.lock" 2>/dev/null || echo "?")
                    echo "NIHIL $running"
                    if [ -n "$(checkout)" ]; then
                        echo "  From $(checkout) (nihil dev; nihil dev off goes back to $pinned)"
                    elif [ "$pinned" != "$running" ]; then
                        echo "  $flake/flake.lock pins $pinned: nihil rebuild applies it"
                    fi
                    ;;
                help | -h | --help)
                    usage
                    ;;
                *)
                    usage >&2
                    exit 2
                    ;;
            esac
        '';
    };
in
{
    options.nihil.revision = lib.mkOption
    {
        type = lib.types.str;
        default = "unknown";
        description = "The NIHIL this machine was built from, as nihil version says it (set by nihil.lib.mkSystem).";
    };

    options.nihil.cli = lib.mkOption
    {
        type = lib.types.package;
        readOnly = true;
        description = "The nihil command, as built.";
    };

    config =
    {
        nihil.cli = nihil;
        environment.systemPackages = [ nihil ];
        environment.etc."nihil/revision".text = config.nihil.revision + "\n";
        # The machine's own settings, stamped at build time: nihil finds the machine's
        # settings.json in its flake by the host.name this system was built with.
        environment.etc."nihil/settings.json".text = builtins.toJSON config.nihil.settings;
    };
}
