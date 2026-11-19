#!/usr/bin/env bash
# NOTHING-SHELL: apply the Nothing wallpaper to the laptop panel and wire up
# the path rofi expects. Usage: nothing-wallpaper.sh [dark|light] (default: dark).
# Waits for swww-daemon (started together with Hyprland).
mode="${1:-dark}"
dir="$HOME/Pictures/wallpapers/nothing"
img="$dir/nothing-02-glyph-$mode-1920x1080.png"
ww=$(command -v awww || command -v swww)

for _ in $(seq 1 40); do
  "$ww" query >/dev/null 2>&1 && break
  sleep 0.25
done

"$ww" img -o eDP-1 "$img" --transition-type fade --transition-duration 0.6
ln -sfn "$img" "$HOME/.config/rofi/.current_wallpaper"
