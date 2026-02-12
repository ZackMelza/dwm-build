#!/usr/bin/env bash
set -euo pipefail

button="${BLOCK_BUTTON:-${BUTTON:-0}}"

notify_text() {
  local msg="$1"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Battery" "$msg"
  elif command -v xmessage >/dev/null 2>&1; then
    xmessage -center "$msg" >/dev/null 2>&1 &
  fi
}

show_battery_info() {
  if command -v acpi >/dev/null 2>&1; then
    notify_text "$(acpi -b 2>/dev/null || true)"
  elif command -v upower >/dev/null 2>&1; then
    bat_dev="$(upower -e 2>/dev/null | grep battery | head -n1 || true)"
    if [[ -n "$bat_dev" ]]; then
      notify_text "$(upower -i "$bat_dev" 2>/dev/null | awk -F: '/state|percentage|time to/{gsub(/^[ \t]+/,"",$2); print $1": "$2}')"
    fi
  fi
}

cycle_power_profile() {
  if ! command -v powerprofilesctl >/dev/null 2>&1; then
    return
  fi

  current="$(powerprofilesctl get 2>/dev/null || true)"
  next="balanced"
  case "$current" in
    power-saver) next="balanced" ;;
    balanced) next="performance" ;;
    performance) next="power-saver" ;;
  esac

  powerprofilesctl set "$next" >/dev/null 2>&1 || true
  notify_text "Power profile: $next"
}

case "$button" in
  1)
    show_battery_info
    ;;
  3)
    cycle_power_profile
    ;;
esac

bat=""
for p in /sys/class/power_supply/BAT*; do
  if [[ -e "$p" ]]; then
    bat="$(basename "$p")"
    break
  fi
done
if [[ -z "$bat" ]]; then
  echo "AC"
  exit 0
fi

cap_file="/sys/class/power_supply/$bat/capacity"
status_file="/sys/class/power_supply/$bat/status"

if [[ ! -r "$cap_file" || ! -r "$status_file" ]]; then
  echo "n/a"
  exit 0
fi

cap="$(cat "$cap_file")"
status="$(cat "$status_file")"

case "$status" in
  Charging) echo "+${cap}%" ;;
  Discharging) echo "-${cap}%" ;;
  Full) echo "=${cap}%" ;;
  *) echo "${cap}%" ;;
esac
