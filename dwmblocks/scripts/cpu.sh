#!/usr/bin/env bash
set -euo pipefail

button="${BLOCK_BUTTON:-${BUTTON:-0}}"

open_monitor() {
  if command -v alacritty >/dev/null 2>&1; then
    if command -v btop >/dev/null 2>&1; then
      alacritty -e btop >/dev/null 2>&1 &
      return
    fi
    if command -v htop >/dev/null 2>&1; then
      alacritty -e htop >/dev/null 2>&1 &
      return
    fi
    alacritty -e top >/dev/null 2>&1 &
    return
  fi

  if command -v xterm >/dev/null 2>&1; then
    if command -v htop >/dev/null 2>&1; then
      xterm -e htop >/dev/null 2>&1 &
      return
    fi
    xterm -e top >/dev/null 2>&1 &
  fi
}

case "$button" in
  1)
    open_monitor
    ;;
  3)
    if command -v gnome-system-monitor >/dev/null 2>&1; then
      gnome-system-monitor >/dev/null 2>&1 &
    fi
    ;;
esac

if [[ ! -r /proc/loadavg ]]; then
  echo "n/a"
  exit 0
fi

load1="$(awk '{print $1}' /proc/loadavg)"
echo "$load1"
