#!/usr/bin/env bash
# NOTHING-SHELL: lock the session with hyprlock (Nothing Ndot clock, see
# ~/.config/hypr/hyprlock.conf). Closes the shell's popovers first.
qs ipc -c nothing call controlcenter close >/dev/null 2>&1
qs ipc -c nothing call powermenu close >/dev/null 2>&1
exec hyprlock
