#!/usr/bin/env bash
# NOTHING-SHELL: screenshots through hyprshot. --area selects a region, --now takes the screen.
case "${1:---area}" in
  --now) exec hyprshot -m output ;;
  *) exec hyprshot -m region ;;
esac
