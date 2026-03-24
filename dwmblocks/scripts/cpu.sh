#!/usr/bin/env bash
set -euo pipefail

button="${BLOCK_BUTTON:-${BUTTON:-0}}"

open_monitor() {
  if command -v launch-terminal.sh >/dev/null 2>&1; then
    if command -v btop >/dev/null 2>&1; then
      launch-terminal.sh btop >/dev/null 2>&1 &
      return
    fi
    if command -v htop >/dev/null 2>&1; then
      launch-terminal.sh htop >/dev/null 2>&1 &
      return
    fi
    launch-terminal.sh top >/dev/null 2>&1 &
    return
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
