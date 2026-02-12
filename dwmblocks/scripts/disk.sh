#!/usr/bin/env bash
set -euo pipefail

button="${BLOCK_BUTTON:-${BUTTON:-0}}"

if [[ "$button" == "1" ]]; then
  if command -v alacritty >/dev/null 2>&1; then
    alacritty -e /bin/sh -lc "df -h; echo; read -r -p 'Press enter to close' _" >/dev/null 2>&1 &
  elif command -v xterm >/dev/null 2>&1; then
    xterm -e /bin/sh -lc "df -h; echo; read -r -p 'Press enter to close' _" >/dev/null 2>&1 &
  fi
elif [[ "$button" == "3" ]]; then
  if command -v nemo >/dev/null 2>&1; then
    nemo / >/dev/null 2>&1 &
  elif command -v thunar >/dev/null 2>&1; then
    thunar / >/dev/null 2>&1 &
  elif command -v pcmanfm >/dev/null 2>&1; then
    pcmanfm / >/dev/null 2>&1 &
  fi
fi

df -h / 2>/dev/null | awk 'NR==2 {print $3 "/" $2}'
