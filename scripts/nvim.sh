#!/usr/bin/env bash

# 1. Даем разрешение локальному root подключаться к нашему Wayland/XWayland
# Это решит ошибку "Authorization required"
xhost +si:localuser:root > /dev/null

terminal=$(command -v kitty)

# 2. Используем pkexec, но ПРАВИЛЬНО прокидываем окружение
pkexec env \
    PATH="$PATH" \
    DISPLAY="$DISPLAY" \
    WAYLAND_DISPLAY="$WAYLAND_DISPLAY" \
    XDG_RUNTIME_DIR="$XDG_RUNTIME_DIR" \
    HOME="$HOME" \
    XDG_CONFIG_HOME="$HOME/.config" \
    "$terminal" -e nvim /etc/nixos/flake.nix

# 3. После закрытия терминала закрываем доступ для безопасности
xhost -si:localuser:root > /dev/null
