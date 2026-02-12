#!/usr/bin/env bash
set -euo pipefail

button="${BLOCK_BUTTON:-${BUTTON:-0}}"

if [[ "$button" == "1" ]]; then
  if command -v alacritty >/dev/null 2>&1; then
    alacritty -e /bin/sh -lc "free -h; echo; read -r -p 'Press enter to close' _" >/dev/null 2>&1 &
  elif command -v xterm >/dev/null 2>&1; then
    xterm -e /bin/sh -lc "free -h; echo; read -r -p 'Press enter to close' _" >/dev/null 2>&1 &
  fi
fi

if ! command -v free >/dev/null 2>&1; then
  echo "n/a"
  exit 0
fi

free -h | awk '/^Mem:/ {print $3 "/" $2}'
