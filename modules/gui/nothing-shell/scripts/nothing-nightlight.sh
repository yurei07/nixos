#!/usr/bin/env bash
# NOTHING-SHELL: night light through hyprsunset. `status` prints the JSON the
# control center button expects; `toggle` starts/stops the filter.
case "${1:-toggle}" in
  status)
    if pgrep -x hyprsunset >/dev/null 2>&1; then
      echo '{"class":"on"}'
    else
      echo '{"class":"off"}'
    fi
    ;;
  *)
    if pgrep -x hyprsunset >/dev/null 2>&1; then
      pkill -x hyprsunset
    else
      setsid hyprsunset -t 3500 >/dev/null 2>&1 < /dev/null &
    fi
    ;;
esac
