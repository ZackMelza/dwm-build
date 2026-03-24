#!/usr/bin/env bash
set -euo pipefail

button="${BLOCK_BUTTON:-${BUTTON:-0}}"

if [[ "$button" == "1" ]]; then
  if command -v launch-terminal.sh >/dev/null 2>&1; then
    launch-terminal.sh /bin/sh -lc "free -h; echo; read -r -p 'Press enter to close' _" >/dev/null 2>&1 &
  fi
fi

if ! command -v free >/dev/null 2>&1; then
  echo "n/a"
  exit 0
fi

free -h | awk '/^Mem:/ {print $3 "/" $2}'
