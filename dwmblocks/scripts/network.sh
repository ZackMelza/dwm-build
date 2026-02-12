#!/usr/bin/env bash
set -euo pipefail

button="${BLOCK_BUTTON:-${BUTTON:-0}}"

case "$button" in
  1)
    if command -v nm-connection-editor >/dev/null 2>&1; then
      nm-connection-editor >/dev/null 2>&1 &
    fi
    ;;
  3)
    if command -v alacritty >/dev/null 2>&1 && command -v nmtui >/dev/null 2>&1; then
      alacritty -e nmtui >/dev/null 2>&1 &
    elif command -v xterm >/dev/null 2>&1 && command -v nmtui >/dev/null 2>&1; then
      xterm -e nmtui >/dev/null 2>&1 &
    fi
    ;;
esac

if command -v nmcli >/dev/null 2>&1; then
  state="$(nmcli -t -f STATE g 2>/dev/null | head -n1 || true)"
  if [[ "$state" == "connected" ]]; then
    active="$(nmcli -t -f NAME,TYPE connection show --active 2>/dev/null | head -n1 || true)"
    name="${active%%:*}"
    [[ -n "$name" ]] && echo "$name" && exit 0
    echo "up"
    exit 0
  fi
  echo "down"
  exit 0
fi

echo "n/a"
