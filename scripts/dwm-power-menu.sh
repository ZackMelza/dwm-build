#!/usr/bin/env bash
set -euo pipefail

choose() {
  local options="Lock\nSuspend\nReboot\nPoweroff\nLogout"

  if command -v rofi >/dev/null 2>&1; then
    printf '%b\n' "$options" | rofi -dmenu -i -p "Power"
    return
  fi

  if command -v dmenu >/dev/null 2>&1; then
    printf '%b\n' "$options" | dmenu -i -p "Power"
    return
  fi

  printf '%b\n' "$options" | head -n1
}

selection="$(choose || true)"

case "$selection" in
  Lock)
    if command -v loginctl >/dev/null 2>&1; then
      loginctl lock-session
    elif command -v xdg-screensaver >/dev/null 2>&1; then
      xdg-screensaver lock
    fi
    ;;
  Suspend)
    systemctl suspend
    ;;
  Reboot)
    systemctl reboot
    ;;
  Poweroff)
    systemctl poweroff
    ;;
  Logout)
    pkill -x dwm
    ;;
  *)
    exit 0
    ;;
esac
