#!/usr/bin/env bash
    terminal=$(command -v kitty)
    pkexec env \
      PATH="$PATH" \
      HOME="$HOME" \
      DISPLAY="$DISPLAY" \
      WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
      XDG_SESSION_TYPE="$XDG_SESSION_TYPE" \
      XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
      "$terminal" -e nvim /etc/nixos/flake.nix 
