#!/usr/bin/env bash
# Welcome card shown on the live ISO desktop (opened by Hyprland autostart).
c_red=$'\e[38;5;196m'
c_dim=$'\e[38;5;245m'
c_txt=$'\e[38;5;15m'
c_acc=$'\e[38;5;203m'
c_end=$'\e[0m'

cat <<EOF

${c_acc}  N O T H I N G  ${c_txt}NixOS — live${c_end}

${c_txt}This is your NixOS, already running.${c_end} Look around:
  • ${c_acc}SUPER + ENTER${c_end}  terminal (kitty)
  • ${c_acc}SUPER + D${c_end}      app launcher (rofi)
  • ${c_acc}SUPER + SPACE${c_end}  control center (click the clock)
  • ${c_acc}SUPER + 1..0${c_end}   workspaces

${c_txt}Like it? Install it:${c_end}
  ${c_red}sudo nixinstall${c_end}   ${c_dim}← guided installer: disk, GPU, hostname, password${c_end}

${c_dim}Config lives at /etc/nixos · github.com/yurei07 (Prizrak's flake)${c_end}
EOF
exec bash
