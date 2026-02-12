#!/usr/bin/env bash
set -euo pipefail

button="${BLOCK_BUTTON:-${BUTTON:-0}}"

if [[ "$button" == "1" ]]; then
  cal_out="$(cal -3 2>/dev/null || date '+%B %Y')"
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "Calendar" "$cal_out"
  elif command -v xmessage >/dev/null 2>&1; then
    xmessage -center "$cal_out" >/dev/null 2>&1 &
  fi
fi

date '+%a %b %d %H:%M'
