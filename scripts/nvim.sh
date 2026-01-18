#!/usr/bin/env bash

terminal=$(command -v kitty)

pkexec env \
    PATH="$PATH" \
    DISPLAY="$DISPLAY" \
    WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
    XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
    HOME="$HOME" \
    XDG_CONFIG_HOME="$HOME/.config" \
    "$terminal" -e nvim /etc/nixos/flake.nix

