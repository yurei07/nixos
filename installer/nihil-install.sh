# nihil-install by poligle (installer/iso.nix)

template=/etc/nihil/template
source=$(cat /etc/nihil/source)
rev=$(cat /etc/nihil/rev)
lang=en
gui=no
log=/tmp/nihil-install.log

least=20000000000
bootBytes=1073741824
headroom=10000000000

strings=/etc/nihil/strings.json

# The words are theme/i18n.nix's, as the window's and the shell's: t key [value…], each value in
# for %1, %2…, as they come.
t() {
    local text i=1 value
    text=$(jq -r --arg l "$lang" --arg k "$1" '.[$l][$k] // .en[$k] // $k' "$strings")
    shift
    for value in "$@"; do
        text=${text//"%$i"/"$value"}
        i=$((i + 1))
    done
    printf '%s' "$text"
}
# If the window is gone, what it would have shown is lost, not the installation.
emit() { jq -cn --arg kind "$1" --arg text "$2" '{ kind: $kind, text: $text }' >&3 2> /dev/null || true; }
say() { if [ "$gui" = yes ]; then emit step "$*"; else gum style --foreground 15 "$@"; fi; }
dim() { if [ "$gui" = yes ]; then printf '%s\n' "$*"; else gum style --foreground 7 "$@"; fi; }
# Says why, and ends with 3, which the EXIT trap leaves alone: called in a $(…), the shell around
# it ends with 3 too, without the general «stopped here» on top of the reason.
fail() {
    if [ "$gui" = yes ]; then emit error "$*"; else gum style --foreground 1 "$@" >&2; fi
    trap - EXIT
    exit 3
}

# One installation at a time: the window's, a text one started after it, and finish.
lock() {
    exec 9> /run/nihil-install.lock
    flock -n 9 || fail "$(t insBusy)"
}

# What a plan holds, empty: each try starts from nothing, not from the one before.
reset_plan() {
    esp="" efi="" boot="" root="" windows=no room="" roomPart="" roomFs="" bootType=""
    roomBytes=0 roomFirst=0 roomLast=0
}

# Nothing on what is about to change may be in use: swap goes off, LVM and RAID on it stop, and
# what still holds it stops the installation before anything is erased, saying what it is.
free_disk() {
    local devices=() dev vg holder held=""
    mapfile -t devices < <(lsblk -lnpo NAME "$@" 2> /dev/null)
    for dev in "${devices[@]}"; do
        swapoff "$dev" 2> /dev/null || true
        umount "$dev" 2> /dev/null || true
    done
    while read -r vg; do
        if [ -n "$vg" ]; then
            vgchange -an "$vg" > /dev/null 2>&1 || true
        fi
    done < <(pvs --noheadings -o vg_name "${devices[@]}" 2> /dev/null | sort -u)
    while read -r dev; do
        mdadm --stop "$dev" > /dev/null 2>&1 || true
    done < <(lsblk -lnpo NAME,TYPE "$@" 2> /dev/null | awk '$2 ~ /^raid/ { print $1 }' | sort -u)
    for dev in "${devices[@]}"; do
        for holder in "/sys/class/block/${dev##*/}/holders/"*; do
            if [ -e "$holder" ]; then
                held="$held ${holder##*/}"
            fi
        done
    done
    held=${held# }
    [ -z "$held" ] || fail "$(t insInUse "$held")"
}

if [ "$(id -u)" != 0 ]; then
    exec sudo "$0" "$@"
fi

exec 3>&1
trap 'status=$?; if [ "$status" != 0 ] && [ "$status" != 3 ]; then
    if [ "$gui" = yes ]; then
        emit error "$(t insStoppedHere)"
    else
        gum style --foreground 1 "$(t insStoppedAgain)" >&2
    fi
fi' EXIT

reserved() {
    case $1 in
        root | nobody | nixbld* | systemd-* | messagebus | polkituser | sshd | nscd | dhcpcd | uuidd | tss \
            | greeter | avahi | rtkit | ollama | geoclue | colord | fwupd-refresh | nm-openvpn | nm-iodine) return 0 ;;
    esac
    return 1
}
valid_user() { [[ $1 =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] && ! reserved "$1"; }
valid_host() { [[ $1 =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]]; }

keymap_of() {
    case $1 in
        gb) echo uk ;;
        pt) echo pt-latin1 ;;
        latam) echo la-latin1 ;;
        br) echo br-abnt2 ;;
        *) echo "$1" ;;
    esac
}

guess_zone() { curl -fs --max-time 6 https://ipapi.co/timezone || true; }

# Never the disk NIHIL started from: up from /iso to its disk, and any disk with an iso9660 on it,
# which is still the USB when the ISO was copied to RAM and /iso is a tmpfs.
list_disks() {
    local source live="" candidate
    source=$(findmnt -no SOURCE /iso 2> /dev/null || true)
    if [ -n "$source" ]; then
        live=$(lsblk -lnspo NAME,TYPE "$source" 2> /dev/null | awk '$2 == "disk" { print $1; exit }' || true)
    fi
    lsblk -dbnpo NAME,SIZE,RO,TYPE | awk -v live="$live" -v least="$least" '
        $4 == "disk" && $3 == 0 && $2 >= least && $1 != live &&
        $1 !~ /^\/dev\/(fd|zram|ram|loop)[0-9]/ && $1 !~ /(boot[0-9]+|rpmb)$/ { print $1 }' |
    while read -r candidate; do
        lsblk -no FSTYPE "$candidate" 2> /dev/null | grep -qx iso9660 || printf '%s\n' "$candidate"
    done
}

set_disk() {
    disk=$1
    sector=$(blockdev --getss "$disk")
    align=$(( 1048576 / sector ))
}

# 25 GB, as the window writes it.
size() {
    local n
    n=$(numfmt --to=si --suffix=B "$1")
    printf '%s %s\n' "${n%%[A-Z]*}" "${n##*[0-9.,]}"
}

part() {
    if [[ $disk =~ [0-9]$ ]]; then echo "${disk}p$1"; else echo "${disk}$1"; fi
}

gpt() { [ "$(blkid -o value -s PTTYPE "$disk" 2>/dev/null)" = gpt ]; }

number_of() { cat "/sys/class/block/${1##*/}/partition"; }
fstype_of() { blkid -p -o value -s TYPE "$1" 2>/dev/null || true; }
label_of() { blkid -p -o value -s LABEL "$1" 2>/dev/null || true; }

partitions() {
    lsblk -pbnro NAME,SIZE,TYPE "$disk" | awk -v least="$1" -v skip="$2" '$3 == "part" && $2 >= least && index(" " skip " ", " " $1 " ") == 0 { print $1 }'
}

describe() {
    local part
    for part in "$@"; do
        printf '%s   %s   %s\n' "$part" "$(lsblk -no SIZE "$part" | tr -d ' ')" "$(lsblk -no FSTYPE,LABEL "$part" | xargs)"
    done
}

esp_of() {
    local part
    while read -r part; do
        if [ "$(blkid -p -o value -s PART_ENTRY_TYPE "$part" 2>/dev/null | tr '[:upper:]' '[:lower:]')" = c12a7328-f81f-11d2-ba4b-00a0c93ec93b ]; then
            echo "$part"
            return
        fi
    done < <(partitions 0 "")
}

has_windows() {
    local present=1
    [ -n "$1" ] || return 1
    mkdir -p /tmp/esp
    mount -o ro "$1" /tmp/esp 2>/dev/null || return 1
    if [ -d /tmp/esp/EFI/Microsoft ]; then
        present=0
    fi
    umount /tmp/esp
    return "$present"
}

windows_elsewhere() {
    local other part
    while read -r other; do
        [ "$other" != "$disk" ] || continue
        while read -r part; do
            if [ "$(blkid -p -o value -s PART_ENTRY_TYPE "$part" 2>/dev/null | tr '[:upper:]' '[:lower:]')" = c12a7328-f81f-11d2-ba4b-00a0c93ec93b ] \
                    && has_windows "$part"; then
                echo "$other"
                return 0
            fi
        done < <(lsblk -pnro NAME,TYPE "$other" | awk '$2 == "part" { print $1 }')
    done < <(lsblk -dpnro NAME,TYPE | awk '$2 == "disk" { print $1 }')
    return 0
}

free_stretches() {
    parted -m -s "$disk" unit s print free 2>/dev/null | awk -F: -v least="$1" -v align="$align" -v sector="$sector" '
        $5 == "free;" {
            first = int(($2 + align - 1) / align) * align
            last = int(($3 + 1) / align) * align - 1
            if (last > first && (last - first + 1) * sector >= least) print first, last
        }'
}

smallest() {
    local report magic blocks block
    case $2 in
        ntfs)
            magic=$( { ntfscat "$1" hiberfil.sys 2>/dev/null || true; } | head -c 4 | tr '[:upper:]' '[:lower:]')
            if [ "$magic" = hibr ]; then
                dim "$(t insHibernated "$1")" >&2
                return 1
            fi
            if ! report=$(ntfsresize --info --no-progress-bar "$1" 2>&1); then
                dim "$(t insNtfsCheck "$1")" >&2
                return 1
            fi
            sed -n 's/.*resize at \([0-9][0-9]*\) bytes.*/\1/p' <<< "$report"
            ;;
        ext4)
            if ! report=$(resize2fs -P "$1" 2>/dev/null); then
                dim "$(t insExt4Check "$1")" >&2
                return 1
            fi
            blocks=$(sed -n 's/^Estimated minimum size of the filesystem: \([0-9][0-9]*\)$/\1/p' <<< "$report")
            block=$(dumpe2fs -h "$1" 2>/dev/null | awk -F: '/^Block size:/ { print $2 + 0 }')
            if [ -z "$blocks" ] || [ -z "$block" ]; then
                return 1
            fi
            echo $(( blocks * block ))
            ;;
        btrfs)
            mkdir -p /tmp/shrink
            if ! mount -o ro "$1" /tmp/shrink 2>/dev/null; then
                dim "$(t insBtrfsMount "$1")" >&2
                return 1
            fi
            report=$(btrfs inspect-internal min-dev-size /tmp/shrink 2>/dev/null) || report=""
            if [ "$(btrfs filesystem show /tmp/shrink 2>/dev/null | grep -c devid)" != 1 ]; then
                report=""
            fi
            umount /tmp/shrink
            if [ -z "$report" ]; then
                return 1
            fi
            echo "${report%% *}"
            ;;
        *)
            return 1
            ;;
    esac
}

givers() {
    local part bytes fstype small give
    while read -r part bytes; do
        fstype=$(fstype_of "$part")
        [ "$bytes" -gt $(( $1 + headroom )) ] || continue
        case $fstype in
            ntfs|ext4|btrfs) ;;
            crypto_LUKS|LVM2_member)
                dim "$(t insEncryptedPart "$part")" >&2
                continue
                ;;
            xfs|zfs_member|f2fs)
                dim "$(t insNoShrink "$part" "$fstype")" >&2
                continue
                ;;
            *) continue ;;
        esac
        small=$(smallest "$part" "$fstype") || continue
        [ -n "$small" ] || continue
        give=$(( (bytes - small - headroom) / 1048576 * 1048576 ))
        if [ "$give" -ge "$1" ]; then
            printf '%s %s %s\n' "$part" "$fstype" "$give"
        else
            dim "$(t insTooFull "$part" "$(size "$1")")" >&2
        fi
    done < <(lsblk -pbnro NAME,SIZE,TYPE "$disk" | awk '$3 == "part" { print $1, $2 }')
}

how_much() {
    local fewest=$1 most=$2 amount typed choice labels=() all other
    all=$(t insAllOfIt "$(size "$most")")
    other=$(t insOtherAmount)
    for amount in 30 50 100 200 500; do
        if [ $(( amount * 1000000000 )) -ge "$fewest" ] && [ $(( amount * 1000000000 )) -lt "$most" ]; then
            labels+=("$amount GB")
        fi
    done
    choice=$(gum choose --header "$(t insRoomFor)" "${labels[@]}" "$all" "$other") || return 1
    case $choice in
        "")
            return 1
            ;;
        "$all")
            echo "$most"
            ;;
        "$other")
            typed=""
            until [[ $typed =~ ^[1-9][0-9]*$ ]] && [ $(( typed * 1000000000 )) -ge "$fewest" ] && [ $(( typed * 1000000000 )) -le "$most" ]; do
                typed=$(gum input --placeholder 60 --header "$(t insGbRange "$(( (fewest + 999999999) / 1000000000 ))" "$(( most / 1000000000 ))")") || return 1
            done
            echo $(( typed * 1000000000 ))
            ;;
        *)
            echo $(( ${choice%% *} * 1000000000 ))
            ;;
    esac
}

room_base() {
    if ! gpt; then
        dim "$(t insNoGptNextTo "$disk")"
        return 1
    fi
    esp=$(esp_of)
    boot=$esp
    efi=""
    bootType=""
    if [ -z "$esp" ]; then
        bootType=ef00
    elif [ "$(blockdev --getsize64 "$esp")" -lt 500000000 ]; then
        bootType=ea00
        efi=$esp
    fi
    need=$least
    if [ -n "$bootType" ]; then
        need=$(( least + bootBytes ))
    fi
    windows=no
    if has_windows "$esp"; then
        windows=yes
    fi
}

plan_room() {
    local entries=() labels=() index choice back part fstype give label fstypes=""
    room_base || return 1

    while read -r first last; do
        entries+=("free $first $last")
        labels+=("$(t insFreeSpace): $(size $(( (last - first + 1) * sector )))")
    done < <(free_stretches "$need")
    local unchecked=()
    mapfile -t unchecked < <(partitions $(( need + headroom )) "")
    for part in "${unchecked[@]}"; do
        if [ "$(fstype_of "$part")" = ext4 ] && ! resize2fs -P "$part" > /dev/null 2>&1; then
            if gum confirm "$(t insExt4Ask "$part")" \
                    --affirmative "$(t insCheckIt)" --negative "$(t insLeaveIt)"; then
                say "$(t insCheckingPart "$part")"
                e2fsck -f -p "$part" > /dev/null 2>&1 || true
            fi
        fi
    done

    say "$(t insLookingParts)"
    while read -r part fstype give; do
        label=$(label_of "$part")
        entries+=("shrink $part $fstype $give")
        labels+=("$(t insRoomIn "$part") ($fstype${label:+, $label}, $(size "$(blockdev --getsize64 "$part")")): $(t insUpTo "$(size "$give")")")
    done < <(givers "$need")
    while read -r part; do
        fstypes+="$(fstype_of "$part") "
    done < <(partitions 0 "")
    if [[ " $fstypes " == *" BitLocker "* ]]; then
        dim "$(t insBitLockerShrink)"
    fi
    if [ "${#entries[@]}" -eq 0 ]; then
        dim "$(t insNoRoom "$disk" "$(size "$need")")"
        return 1
    fi

    back=$(t insBack)
    choice=$(gum choose --header "$(t insWhereGoes)" "${labels[@]}" "$back") || return 1
    if [ -z "$choice" ] || [ "$choice" = "$back" ]; then
        return 1
    fi
    for index in "${!labels[@]}"; do
        if [ "${labels[$index]}" = "$choice" ]; then
            break
        fi
    done
    read -r room _ <<< "${entries[$index]}"
    if [ "$room" = free ]; then
        read -r room first last <<< "${entries[$index]}"
        roomBytes=$(how_much "$need" $(( (last - first + 1) * sector ))) || return 1
        roomBytes=$(( roomBytes / 1048576 * 1048576 ))
        roomFirst=$first
        roomLast=$(( first + roomBytes / sector - 1 ))
    else
        read -r room roomPart roomFs give <<< "${entries[$index]}"
        roomBytes=$(how_much "$need" "$give") || return 1
        roomBytes=$(( roomBytes / 1048576 * 1048576 ))
    fi
}

part_base() {
    if ! gpt; then
        dim "$(t insNoGptMake "$disk")"
        return 1
    fi
    esp=$(esp_of)
    mapfile -t roots < <(partitions "$least" "$esp")
    if [ "${#roots[@]}" -eq 0 ]; then
        dim "$(t insNoPartition)"
        return 1
    fi
}

boot_needed() { [ -z "$esp" ] || [ "$(blockdev --getsize64 "$esp")" -lt 500000000 ]; }

plan_partition() {
    local boots=() choices=()
    roots=()
    part_base || return 1
    mapfile -t choices < <(describe "${roots[@]}")
    root=$(gum choose --header "$(t insGoesOn)" "${choices[@]}") || return 1
    root=${root%% *}
    boot=$esp
    efi=""
    if [ -z "$esp" ] || [ "$(blockdev --getsize64 "$esp")" -lt 500000000 ]; then
        mapfile -t boots < <(partitions 500000000 "$esp $root")
        if [ "${#boots[@]}" -eq 0 ]; then
            dim "$(t insNeedsBoot)"
            return 1
        fi
        mapfile -t choices < <(describe "${boots[@]}")
        boot=$(gum choose --header "$(t insBootPartition)" "${choices[@]}") || return 1
        boot=${boot%% *}
        efi=$esp
    fi
    windows=no
    if has_windows "$esp"; then
        windows=yes
    fi
}

shrink_filesystem() {
    local status=0
    case $2 in
        ntfs)
            printf 'y\n' | ntfsresize --no-progress-bar --size "$3" "$1" >/dev/null
            ;;
        ext4)
            e2fsck -f -p "$1" >/dev/null || status=$?
            [ "$status" -lt 4 ] || return 1
            resize2fs "$1" "$(( $3 / 1024 ))K" >/dev/null 2>&1
            ;;
        btrfs)
            mkdir -p /tmp/shrink
            mount "$1" /tmp/shrink
            btrfs filesystem resize "1:$3" /tmp/shrink >/dev/null
            umount /tmp/shrink
            ;;
    esac
}

shrink_partition() {
    local number info code guid first last name attributes bit end flags=()
    number=$(number_of "$1")
    info=$(sgdisk -i "$number" "$disk")
    code=$(awk '/^Partition GUID code:/ { print $4 }' <<< "$info")
    guid=$(awk '/^Partition unique GUID:/ { print $4 }' <<< "$info")
    first=$(awk '/^First sector:/ { print $3 }' <<< "$info")
    last=$(awk '/^Last sector:/ { print $3 }' <<< "$info")
    attributes=$(awk '/^Attribute flags:/ { print $3 }' <<< "$info")
    name=$(sed -n "s/^Partition name: '\(.*\)'$/\1/p" <<< "$info")
    if [ -z "$code" ] || [ -z "$guid" ] || [ -z "$first" ] || [ -z "$last" ] || [[ ! $attributes =~ ^[0-9A-Fa-f]{16}$ ]]; then
        fail "$(t insEntryUnread "$1")"
    fi
    end=$(( first + $2 / sector - 1 ))
    for (( bit = 0; bit < 64; bit++ )); do
        if (( (16#$attributes >> bit) & 1 )); then
            flags+=(-A "$number:set:$bit")
        fi
    done
    if ! sgdisk -a 1 -d "$number" -n "$number:$first:$end" -t "$number:$code" -u "$number:$guid" -c "$number:$name" "${flags[@]}" "$disk" >/dev/null; then
        fail "$(t insEntryShrink "$1" "$disk")"
    fi
    partprobe "$disk" || true
    udevadm settle
    echo "$(( (end + align) / align * align )) $last"
}

free_number() {
    sgdisk -p "$disk" | awk '$1 ~ /^[0-9]+$/ { used[$1] = 1 } END { n = 1; while (n in used) n++; print n }'
}

make_partitions() {
    local first=$1 number
    if [ -n "$bootType" ]; then
        number=$(free_number)
        sgdisk -n "$number:$first:$(( first + bootBytes / sector - 1 ))" -t "$number:$bootType" -c "$number:NIHIL" "$disk" >/dev/null
        boot=$(part "$number")
        first=$(( first + bootBytes / sector ))
    fi
    number=$(free_number)
    sgdisk -n "$number:$first:$2" -t "$number:8300" -c "$number:nixos" "$disk" >/dev/null
    root=$(part "$number")
    partprobe "$disk" || true
    udevadm settle
}

logged() {
    local shown=-1
    if [ "$gui" = yes ]; then
        "$@" 2>&1 | while IFS= read -r line; do
            printf '%s\n' "$line"
            if [ "$SECONDS" != "$shown" ]; then
                shown=$SECONDS
                emit log "$line"
            fi
        done
    else
        "$@"
    fi
}

apply_plan() {
    say "$(t insPreparing)"
    # What gets installed answers before the disk is touched: an image built from a revision that
    # isn't on GitHub would otherwise fail after formatting.
    nix flake metadata "$source${rev:+/$rev}" > /dev/null 2>&1 || fail "$(t insNoSource "$source${rev:+/$rev}")"
    umount -R /mnt 2>/dev/null || true
    cryptsetup close cryptroot 2>/dev/null || true
    if [ "$mode" = whole ]; then
        esp="" efi="" windows=no
        free_disk "$disk"
        wipefs -af "$disk" >/dev/null
        sgdisk --zap-all "$disk" >/dev/null
        sgdisk -n1:0:+1G -t1:ef00 -c1:BOOT -n2:0:0 -t2:8300 -c2:nixos "$disk" >/dev/null
        partprobe "$disk" || fail "$(t insNewPartitions "$disk")"
        udevadm settle
        boot=$(part 1)
        root=$(part 2)
        mkfs.fat -F 32 -n BOOT "$boot" >/dev/null
    else
        if [ "$mode" = part ] && [ -n "$boot" ] && [ "$boot" != "$esp" ]; then
            free_disk "$root" "$boot"
        elif [ "$mode" = part ]; then
            free_disk "$root"
        elif [ "$room" = shrink ]; then
            free_disk "$roomPart"
        fi
        if [ "$mode" = room ]; then
            if [ "$room" = shrink ]; then
                say "$(t insShrinking "$roomPart")"
                partBytes=$(blockdev --getsize64 "$roomPart")
                keep=$(( (partBytes - roomBytes) / 1048576 * 1048576 ))
                shrink_filesystem "$roomPart" "$roomFs" "$keep"
                stretch=$(shrink_partition "$roomPart" "$keep")
                read -r roomFirst roomLast <<< "$stretch"
            fi
            make_partitions "$roomFirst" "$roomLast"
        fi
        types=(-t "$(number_of "$root"):8300")
        if [ "$boot" != "$esp" ]; then
            if [ -n "$esp" ]; then type=ea00; else type=ef00; fi
            types+=(-t "$(number_of "$boot"):$type")
        fi
        sgdisk "${types[@]}" "$disk" >/dev/null
        partprobe "$disk" || true
        udevadm settle
        if [ "$boot" != "$esp" ]; then
            mkfs.fat -F 32 -n NIHIL "$boot" >/dev/null
        fi
        wipefs -af "$root" >/dev/null
    fi
    if [ "$encrypt" = yes ]; then
        printf '%s' "$passphrase" | cryptsetup luksFormat --type luks2 --batch-mode --key-file=- "$root"
        printf '%s' "$passphrase" | cryptsetup open --key-file=- "$root" cryptroot
        root=/dev/mapper/cryptroot
    fi
    mkfs.btrfs -f -L nixos "$root" >/dev/null

    mount "$root" /mnt
    for volume in @ @home @nix @log; do
        btrfs subvolume create "/mnt/$volume" >/dev/null
    done
    umount /mnt

    options=compress=zstd,noatime
    mount -o "subvol=@,$options" "$root" /mnt
    mkdir -p /mnt/home /mnt/nix /mnt/var/log /mnt/boot
    mount -o "subvol=@home,$options" "$root" /mnt/home
    mount -o "subvol=@nix,$options" "$root" /mnt/nix
    mount -o "subvol=@log,$options" "$root" /mnt/var/log
    mount -o umask=0077 "$boot" /mnt/boot
    if [ -n "$efi" ]; then
        mkdir -p /mnt/efi
        mount -o umask=0077 "$efi" /mnt/efi
    fi

    say "$(t insWriting)"
    nixos-generate-config --root /mnt >/dev/null
    etc=/mnt/etc/nixos
    rm -f "$etc/configuration.nix"
    cp -r "$template/." "$etc/"
    chmod -R u+w "$etc"

    outputs='{}'
    for connector in /sys/class/drm/card*-*; do
        [ "$(cat "$connector/status" 2>/dev/null)" = connected ] || continue
        name=${connector##*/}
        name=${name#card*-}
        resolution=$(head -n 1 "$connector/modes" 2>/dev/null || true)
        [[ $resolution =~ ^([0-9]+)x([0-9]+) ]] || continue
        outputs=$(jq --arg name "$name" --argjson width "${BASH_REMATCH[1]}" --argjson height "${BASH_REMATCH[2]}" \
            '. + { ($name): { width: $width, height: $height } }' <<< "$outputs")
    done
    [ "$outputs" != '{}' ] || outputs='{ "Virtual-1": { "width": 1920, "height": 1080 } }'

    model=""
    if grep -qi thinkpad /sys/class/dmi/id/product_version 2>/dev/null; then
        model=thinkpad
    fi
    fingerprint=false
    if lsusb 2>/dev/null | grep -qiE 'fingerprint|synaptics.*(fp|finger)|goodix|elan.*fp|validity'; then
        fingerprint=true
    fi

    jq -n \
        --arg name "$username" --arg fullName "$fullname" --arg host "$hostname" \
        --arg language "$lang" --arg locale "$locale" --arg zone "$zone" \
        --arg layout "$layout" --arg model "$model" \
        --argjson outputs "$outputs" --argjson fingerprint "$fingerprint" \
        '{
            version: 1,
            user: { name: $name, fullName: $fullName },
            host: { name: $host },
            language: $language,
            locale: $locale,
            timeZone: $zone,
            keyboard: { layout: $layout, variant: "", model: $model },
            outputs: $outputs,
            wallpaper: "night",
            nilo: { enable: false, acceleration: "cpu", integratedGpu: false },
            fingerprint: $fingerprint,
            ssh: false
        }' > "$etc/settings.json"

    # The graphics the firmware showed the boot on, by the driver this live system gave it: early
    # KMS for that one only. Names matched nothing reliable ("compatible", "Corporation" read as ATI).
    gpu="" booted=no
    for device in /sys/bus/pci/devices/*; do
        [ "$(cat "$device/boot_vga" 2> /dev/null)" = 1 ] || continue
        booted=yes
        driver=$(basename "$(readlink -f "$device/driver" 2> /dev/null)")
        case $driver in
            amdgpu) gpu="hardware.amdgpu.initrd.enable = true;" ;;
            i915|xe) gpu="boot.initrd.kernelModules = [ \"$driver\" ];" ;;
        esac
        break
    done
    if [ "$booted" = no ]; then
        # Or, with no boot display known, by vendor among display controllers (class 03xx): 1002 is
        # AMD, 8086 Intel.
        vga=$(lspci -nn | grep -E '\[03(00|02|80)\]' || true)
        if grep -q '\[1002:' <<< "$vga"; then
            gpu="hardware.amdgpu.initrd.enable = true;"
        elif grep -q '\[8086:' <<< "$vga"; then
            gpu="boot.initrd.kernelModules = [ \"i915\" ];"
        fi
    fi

    loader=""
    if [ -n "$efi" ]; then
        loader+=$'\n\t# The EFI partition is small: systemd-boot there, the kernels on /boot (XBOOTLDR).'
        loader+=$'\n\tboot.loader.efi.efiSysMountPoint = lib.mkForce "/efi";'
        loader+=$'\n\tboot.loader.systemd-boot.xbootldrMountPoint = "/boot";\n'
    fi
    # On this disk or another: either way it shares the clock, and keeps it in local time.
    if [ "$windows" = yes ] || [ -n "$(windows_elsewhere)" ]; then
        loader+=$'\n\t# Windows keeps the hardware clock in local time.'
        loader+=$'\n\ttime.hardwareClockInLocalTime = true;\n'
    fi

    if [ "$mode" != whole ] && [ -n "$esp" ] && [ "$boot" = "$esp" ]; then
        for dir in /mnt/boot/EFI/*/; do
            [ -d "$dir" ] || continue
            name=$(basename "$dir")
            case ${name,,} in
                boot|microsoft|systemd|linux|nixos) continue ;;
            esac
            # Written into a Nix string: a name FAT allows, with $ { } or ', would break it.
            case $name in
                *[!A-Za-z0-9._-]*) continue ;;
            esac
            for file in shimx64.efi grubx64.efi; do
                if [ -f "$dir$file" ]; then
                    loader+=$(printf "\n\t# %s, on the EFI partition before NIHIL.\n\tboot.loader.systemd-boot.extraEntries.\"%s.conf\" = ''\n\t\ttitle %s\n\t\tefi /EFI/%s/%s\n\t'';" \
                        "${name^}" "${name,,}" "${name^}" "$name" "$file")
                    loader+=$'\n'
                    break
                fi
            done
        done
    fi

    release=$(nixos-version | cut -d . -f 1,2)
    cat > "$etc/local.nix" << EOF

{ config, lib, pkgs, ... }:
{
	system.stateVersion = "$release";

	nihil.extraWallpapers = lib.optional (builtins.pathExists ./wallpapers) ./wallpapers;

	fileSystems = lib.genAttrs [ "/" "/home" "/nix" "/var/log" ] (_: { options = [ "compress=zstd" "noatime" ]; });
	services.btrfs.autoScrub = { enable = true; fileSystems = [ "/" ]; };

	${gpu}
${loader}
}
EOF

    if [ -n "$rev" ]; then
        nix flake lock "$etc" --override-input nihil "$source/$rev"
    else
        nix flake lock "$etc"
    fi

    say "$(t insInstallingLong)"
    if ! logged nixos-install --flake "$etc#$hostname" --no-root-passwd --no-channel-copy; then
        say "$(t insRetrying)"
        logged nixos-install --flake "$etc#$hostname" --no-root-passwd --no-channel-copy
    fi

    printf '%s:%s\n' "$username" "$password" | nixos-enter --root /mnt -c chpasswd

    # The Wi-Fi joined to install is there at the first boot too: NetworkManager's own files,
    # root's alone, as it keeps them.
    local profile
    for profile in /etc/NetworkManager/system-connections/*.nmconnection; do
        if [ -f "$profile" ] && grep -qx 'type=wifi' "$profile"; then
            install -d -m 700 /mnt/etc/NetworkManager/system-connections
            install -m 600 "$profile" "/mnt/etc/NetworkManager/system-connections/${profile##*/}"
        fi
    done
    : > /run/nihil-install.done

    if [ "$gui" = no ]; then
        gum style --foreground 15 --margin "1 0" "$(t insInstalled)"
    fi
}

finish() {
    umount -R /mnt 2>/dev/null || true
    cryptsetup close cryptroot 2>/dev/null || true
    reboot
}

json_lines() { jq -R . | jq -sc '[ .[] | select(length > 0) ]'; }

describe_json() {
    local part out='[]'
    for part in "$@"; do
        out=$(jq --arg path "$part" --argjson size "$(blockdev --getsize64 "$part")" --arg fstype "$(fstype_of "$part")" \
            --arg label "$(label_of "$part")" '. + [ { path: $path, size: $size, fstype: $fstype, label: $label } ]' <<< "$out")
    done
    printf '%s\n' "$out"
}

probe_disk() {
    local notes free='[]' shrink='[]' unchecked_json='[]' parts roots_json='[]' boots_json='[]' part first last fstype give
    local gptOk=false windowsHere=false needed=false espPath="" model elsewhere partition_list=()
    set_disk "$1"
    notes=$(mktemp)
    if gpt; then gptOk=true; fi
    mapfile -t partition_list < <(partitions 0 "")
    parts=$(describe_json "${partition_list[@]}")
    if room_base >> "$notes" 2>&1; then
        while read -r first last; do
            free=$(jq --argjson first "$first" --argjson last "$last" --argjson bytes $(( (last - first + 1) * sector )) \
                '. + [ { first: $first, last: $last, bytes: $bytes } ]' <<< "$free")
        done < <(free_stretches "$need")
        while read -r part; do
            if [ "$(fstype_of "$part")" = ext4 ] && ! resize2fs -P "$part" > /dev/null 2>&1; then
                unchecked_json=$(jq --arg path "$part" '. + [ $path ]' <<< "$unchecked_json")
            fi
        done < <(partitions $(( need + headroom )) "")
        while read -r part fstype give; do
            shrink=$(jq --arg part "$part" --arg fstype "$fstype" --arg label "$(label_of "$part")" \
                --argjson size "$(blockdev --getsize64 "$part")" --argjson give "$give" \
                '. + [ { part: $part, fstype: $fstype, label: $label, size: $size, give: $give } ]' <<< "$shrink")
        done < <(givers "$need" 2>> "$notes")
        if jq -e 'any(.[]; .fstype == "BitLocker")' <<< "$parts" > /dev/null; then
            dim "$(t insBitLockerShrink)" >> "$notes"
        fi
    else
        need=$least
    fi
    if [ "$gptOk" = true ]; then
        espPath=$(esp_of)
        esp=$espPath
        if has_windows "$espPath"; then windowsHere=true; fi
        if boot_needed; then needed=true; fi
        mapfile -t partition_list < <(partitions "$least" "$espPath")
        roots_json=$(describe_json "${partition_list[@]}")
        mapfile -t partition_list < <(partitions 500000000 "$espPath")
        boots_json=$(describe_json "${partition_list[@]}")
    fi
    model=$(lsblk -dno MODEL "$disk" | sed 's/ *$//')
    elsewhere=$(windows_elsewhere)
    jq -n --arg path "$disk" --argjson size "$(blockdev --getsize64 "$disk")" --arg model "$model" --arg elsewhere "$elsewhere" \
        --argjson gpt "$gptOk" --argjson windows "$windowsHere" --arg esp "$espPath" --argjson need "$need" \
        --argjson free "$free" --argjson shrink "$shrink" --argjson unchecked "$unchecked_json" \
        --argjson roots "$roots_json" --argjson boots "$boots_json" --argjson bootNeeded "$needed" \
        --argjson parts "$parts" --argjson notes "$(json_lines < "$notes")" \
        '{ path: $path, size: $size, model: $model, gpt: $gpt, windows: $windows, elsewhere: $elsewhere, esp: $esp, need: $need,
           room: { free: $free, shrink: $shrink, unchecked: $unchecked },
           part: { roots: $roots, boots: $boots, bootNeeded: $bootNeeded },
           partitions: $parts, notes: $notes }'
    rm -f "$notes"
}

probe() {
    local online=false wifi=false uefi=false zone="" disks_json='[]' candidate
    if [ -d /sys/firmware/efi ]; then uefi=true; fi
    if curl -fsI --max-time 6 https://cache.nixos.org > /dev/null 2>&1; then
        online=true
        zone=$(guess_zone)
    fi
    if nmcli -t -f TYPE device 2>/dev/null | grep -qx wifi; then wifi=true; fi
    while read -r candidate; do
        [ -n "$candidate" ] || continue
        disks_json=$(jq --argjson disk "$(probe_disk "$candidate")" '. + [ $disk ]' <<< "$disks_json")
    done < <(list_disks)
    jq -n --argjson uefi "$uefi" --argjson online "$online" \
        --argjson wifi "$wifi" --arg zone "$zone" --argjson disks "$disks_json" \
        '{ uefi: $uefi, online: $online, wifi: $wifi, zone: $zone, disks: $disks }'
}

apply_answers() {
    local answers="" kind first bytes found part fstype give entry candidate
    IFS= read -r answers || [ -n "$answers" ] || fail "$(t insNoAnswers)"
    exec < /dev/null
    get() { jq -r "$1 // empty" <<< "$answers"; }
    lang=$(get .language)
    [ "$lang" = es ] || lang=en
    # If the window dies halfway, the disk work goes on to the end rather than stopping mid-step.
    trap '' PIPE HUP
    lock
    exec >> "$log" 2>&1
    if [ "$lang" = es ]; then locale=es_ES.UTF-8; else locale=en_US.UTF-8; fi
    [ -d /sys/firmware/efi ] || fail "$(t insNeedsUefi)"
    layout=$(get .layout)
    [[ $layout =~ ^[a-z][a-z0-9_-]*$ ]] || layout=us
    zone=$(get .zone)
    timedatectl list-timezones | grep -qxF "$zone" || fail "$(t insUnknownZone "$zone")"
    fullname=$(get .fullName)
    fullname=${fullname//[:$'\r\n']/}
    username=$(get .user)
    valid_user "$username" || fail "$(t insBadUser)"
    password=$(get .password)
    [ -n "$password" ] || fail "$(t insEmptyPassword)"
    # chpasswd takes a line: a control character in it would end up as another.
    [[ $password != *[[:cntrl:]]* ]] || fail "$(t insBadPassword)"
    hostname=$(get .host)
    valid_host "$hostname" || fail "$(t insBadHost)"
    candidate=$(get .disk)
    list_disks | grep -qxF "$candidate" || fail "$(t insBadDisk)"
    set_disk "$candidate"
    encrypt=no
    passphrase=""
    if [ "$(jq -r '.encrypt // false' <<< "$answers")" = true ]; then
        encrypt=yes
        passphrase=$(get .passphrase)
        [ -n "$passphrase" ] || fail "$(t insEmptyPassphrase)"
        [[ $passphrase != *[[:cntrl:]]* ]] || fail "$(t insBadPassword)"
    fi
    mode=$(get .mode)
    reset_plan
    case $mode in
        whole) ;;
        room)
            room_base > /dev/null || fail "$(t insNoGpt "$disk")"
            kind=$(get .room.kind)
            bytes=$(get .room.bytes)
            [[ $bytes =~ ^[0-9]+$ ]] || fail "$(t insNoSize)"
            bytes=$(( bytes / 1048576 * 1048576 ))
            [ "$bytes" -ge "$need" ] || fail "$(t insNeedsAtLeast "$(size "$need")")"
            found=no
            if [ "$kind" = free ]; then
                first=$(get .room.first)
                while read -r entry; do
                    read -r roomFirst roomLast <<< "$entry"
                    if [ "$roomFirst" = "$first" ] && [ "$bytes" -le $(( (roomLast - roomFirst + 1) * sector )) ]; then
                        found=yes
                        break
                    fi
                done < <(free_stretches "$need")
                [ "$found" = yes ] || fail "$(t insFreeGone)"
                room=free
                roomBytes=$bytes
                roomLast=$(( roomFirst + roomBytes / sector - 1 ))
            elif [ "$kind" = shrink ]; then
                part=$(get .room.part)
                while read -r entry; do
                    read -r roomPart fstype give <<< "$entry"
                    if [ "$roomPart" = "$part" ] && [ "$bytes" -le "$give" ]; then
                        found=yes
                        roomFs=$fstype
                        break
                    fi
                done < <(givers "$need" 2> /dev/null)
                [ "$found" = yes ] || fail "$(t insGivesLess "$part")"
                room=shrink
                roomBytes=$bytes
            else
                fail "$(t insNoWhere)"
            fi
            ;;
        part)
            roots=()
            part_base > /dev/null || fail "$(t insNoRoot "$disk")"
            root=$(get .root)
            printf '%s\n' "${roots[@]}" | grep -qxF "$root" || fail "$(t insBadRoot "$root")"
            boot=$esp
            efi=""
            if boot_needed; then
                boot=$(get .boot)
                if [ "$boot" = "$root" ] || ! partitions 500000000 "$esp $root" | grep -qxF "$boot"; then
                    fail "$(t insNeedsBootShort)"
                fi
                efi=$esp
            fi
            if has_windows "$esp"; then
                windows=yes
            fi
            ;;
        *) fail "$(t insNoWhere)" ;;
    esac
    apply_plan
    emit "done" "$(t insInstalled)"
}

check_media() {
    if [ -f /iso/nix-store.squashfs ] && ! cat /iso/nix-store.squashfs > /dev/null; then
        exit 1
    fi
}

check_filesystem() {
    if [ ! -b "$1" ] || [ "$(lsblk -dno TYPE "$1")" != part ] || [ "$(fstype_of "$1")" != ext4 ] \
            || findmnt -rno TARGET -S "$1" > /dev/null; then
        exit 1
    fi
    e2fsck -f -p "$1" > /dev/null 2>&1 || true
}

main_tui() {
    local disk_candidates=() disk_options=()
    clear
    gum style --foreground 15 --bold --margin "1 2" "N I H I L" "$(gum style --foreground 7 --italic 'ex nihilo')"

    [ -d /sys/firmware/efi ] || fail "NIHIL boots with systemd-boot, which needs UEFI: this machine started in legacy BIOS mode."

    language=$(gum choose --header "Language / Idioma" "English" "Español")
    if [ "$language" = "Español" ]; then
        lang=es
        locale=es_ES.UTF-8
    else
        locale=en_US.UTF-8
    fi
    lock
    if [ -e /run/nihil-install.done ]; then
        if gum confirm "$(t insAlreadyInstalled)" \
                --affirmative "$(t insRestart)" --negative "$(t insInstallAgain)"; then
            finish
        fi
        rm -f /run/nihil-install.done
    fi

    if [ -f /iso/nix-store.squashfs ]; then
        if ! gum spin --title "$(t insCheckingUsb)" -- cat /iso/nix-store.squashfs > /dev/null; then
            fail "$(t insUsbBad)"
        fi
    fi

    until curl -fsI --max-time 6 https://cache.nixos.org >/dev/null; do
        if ! nmcli -t -f TYPE device 2>/dev/null | grep -qx wifi; then
            dim "$(t insNoWifi)"
        fi
        wifi=$(t insChooseWifi)
        retry=$(t insTryAgain)
        leave=$(t insLeave)
        case $(gum choose --header "$(t insOffline)" "$wifi" "$retry" "$leave") in
            "$wifi") nmtui-connect || true ;;
            "$leave")
                dim "$(t insOfflineHelp)"
                exit 0
                ;;
            *) sleep 2 ;;
        esac
    done

    layout=$(gum choose --header "$(t insKeyboard)" us es gb de fr it pt latam other)
    if [ "$layout" = other ]; then
        layout=""
        until [ -n "$layout" ] && grep -q "^ *$layout " "$(find -L "$NIHIL_XKB" -name base.lst -print -quit)"; do
            layout=$(gum input --header "$(t insXkbLayout)" --placeholder "br")
        done
    fi
    keymap=$(keymap_of "$layout")
    if ! loadkeys "$keymap" >/dev/null 2>&1; then
        dim "$(t insNoKeymap "$keymap")"
    fi

    zone=$(guess_zone)
    if [ -n "$zone" ] && ! timedatectl list-timezones | grep -qxF "$zone"; then
        zone=""
    fi
    if [ -z "$zone" ] || ! gum confirm "$(t insZoneAsk "$zone")" \
            --affirmative "$(t insYes)" --negative "$(t insAnother)"; then
        zone=$(timedatectl list-timezones | gum filter --header "$(t insZone)")
    fi

    fullname=$(gum input --header "$(t insYourName)" --placeholder "Ada Lovelace")
    fullname=${fullname//[:$'\r\n']/}
    suggested=$(printf '%s' "${fullname%% *}" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_-')
    until valid_user "${username:-}"; do
        username=$(gum input --header "$(t insUserHint)" \
            --value "${suggested:-nihil}")
    done
    while true; do
        password=$(gum input --password --header "$(t insPassword)")
        again=$(gum input --password --header "$(t insPasswordAgain)")
        if [ -n "$password" ] && [ "$password" = "$again" ]; then
            break
        fi
        dim "$(t insMismatch)"
    done
    until [[ ${hostname:-} =~ ^[a-z0-9]([a-z0-9-]{0,61}[a-z0-9])?$ ]]; do
        hostname=$(gum input --header "$(t cfgHost)" --value "nihil")
    done

    mapfile -t disk_candidates < <(list_disks)
    [ "${#disk_candidates[@]}" -gt 0 ] || fail "$(t insNoDisk)"
    disk_options=()
    for candidate in "${disk_candidates[@]}"; do
        disk_options+=("$candidate   $(lsblk -dno SIZE "$candidate" | tr -d ' ')   $(lsblk -dno MODEL "$candidate" | sed 's/ *$//')")
    done
    disk=$(gum choose --header "$(t insInstallOn)" "${disk_options[@]}")
    set_disk "${disk%% *}"

    mode=whole
    reset_plan
    nextTo=$(t insNextTo)
    all=$(t insWhole)
    pick=$(t insOnPartition)
    while true; do
        lsblk -o NAME,SIZE,FSTYPE,LABEL "$disk"
        choice=$(gum choose --header "$(t insWhereOn "$disk")" "$nextTo" "$all" "$pick")
        reset_plan
        case $choice in
            "$nextTo")
                if plan_room; then
                    mode=room
                    break
                fi
                ;;
            "$all")
                mode=whole
                break
                ;;
            "$pick")
                if plan_partition; then
                    mode=part
                    break
                fi
                ;;
        esac
    done

    encrypt=no
    if gum confirm "$(t insEncryptAsk)" \
            --affirmative "$(t insEncrypt)" --negative "$(t insNo)" --default=false; then
        encrypt=yes
        while true; do
            passphrase=$(gum input --password --header "$(t insPassphrase)")
            again=$(gum input --password --header "$(t insPassphraseAgain)")
            if [ -n "$passphrase" ] && [ "$passphrase" = "$again" ]; then
                break
            fi
            dim "$(t insMismatch)"
        done
    fi

    if [ "$mode" = whole ]; then
        gum style --foreground 1 --margin "1 0" "$(t insErased "$disk")"
    elif [ "$mode" = room ] && [ "$room" = shrink ]; then
        gum style --foreground 1 --margin "1 0" \
            "$(t insShrinkGives "$roomPart" "$(size "$roomBytes")" "$disk")" \
            "$(t insShrinkSafe)"
        if [ "$roomFs" = ntfs ]; then
            dim "$(t insWindowsCheck)"
        fi
    elif [ "$mode" = room ]; then
        gum style --foreground 1 --margin "1 0" "$(t insFreeGoes "$(size "$roomBytes")" "$disk")"
    else
        gum style --foreground 1 --margin "1 0" "$(t insFormatted "$root$( [ "$boot" = "$esp" ] || printf ', %s' "$boot")" "$disk")"
    fi
    if [ "$mode" != whole ] && [ "$windows" = yes ]; then
        dim "$(t insBitLocker)"
    else
        elsewhere=$(windows_elsewhere)
        if [ -n "$elsewhere" ]; then
            dim "$(t insWindowsElsewhere "$elsewhere")"
        fi
    fi
    if ! gum confirm "$(t insInstallAsk)" --affirmative "$(t insInstall)" --negative "$(t insCancel)" \
            --default=false; then
        trap - EXIT
        exit 1
    fi

    apply_plan

    if gum confirm "$(t insRestartAsk)" --affirmative "$(t insRestart)" --negative "$(t insLater)"; then
        finish
    fi
}

case ${1:-} in
    probe)
        gui=yes
        if [ "${2:-}" = es ]; then
            lang=es
        fi
        exec 3>&2
        probe
        ;;
    apply)
        gui=yes
        apply_answers
        ;;
    check-media)
        gui=yes
        trap - EXIT
        check_media
        ;;
    check-filesystem)
        gui=yes
        trap - EXIT
        check_filesystem "${2:?}"
        ;;
    finish)
        lock
        finish
        ;;
    "")
        main_tui
        ;;
    *)
        echo "nihil-install [probe [es] | apply | check-media | check-filesystem PARTITION | finish]" >&2
        trap - EXIT
        exit 2
        ;;
esac
