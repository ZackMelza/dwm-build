#!/usr/bin/env bash
set -euo pipefail

button="${BLOCK_BUTTON:-${BUTTON:-0}}"

if ! command -v pactl >/dev/null 2>&1; then
  echo "n/a"
  exit 0
fi

case "$button" in
  1)
    pactl set-sink-mute @DEFAULT_SINK@ toggle >/dev/null 2>&1 || true
    ;;
  3)
    if command -v pavucontrol >/dev/null 2>&1; then
      pavucontrol >/dev/null 2>&1 &
    fi
    ;;
  4)
    pactl set-sink-volume @DEFAULT_SINK@ +5% >/dev/null 2>&1 || true
    ;;
  5)
    pactl set-sink-volume @DEFAULT_SINK@ -5% >/dev/null 2>&1 || true
    ;;
esac

mute="$(pactl get-sink-mute @DEFAULT_SINK@ 2>/dev/null | awk '{print $2}' || true)"
vol="$(pactl get-sink-volume @DEFAULT_SINK@ 2>/dev/null | awk '{print $5; exit}' || true)"

if [[ -z "$vol" ]]; then
  echo "n/a"
  exit 0
fi

if [[ "$mute" == "yes" ]]; then
  echo "MUT"
else
  echo "$vol"
fi
