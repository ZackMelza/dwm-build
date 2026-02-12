#!/usr/bin/env bash
set -euo pipefail

button="${BLOCK_BUTTON:-${BUTTON:-0}}"

open_update_terminal() {
  local cmd="$1"
  if command -v alacritty >/dev/null 2>&1; then
    alacritty -e /bin/sh -lc "$cmd" >/dev/null 2>&1 &
  elif command -v xterm >/dev/null 2>&1; then
    xterm -e /bin/sh -lc "$cmd" >/dev/null 2>&1 &
  fi
}

if [[ "$button" == "1" ]]; then
  if command -v pacman >/dev/null 2>&1; then
    open_update_terminal "sudo pacman -Syu; echo; read -r -p 'Press enter to close' _"
  elif command -v apt >/dev/null 2>&1; then
    open_update_terminal "sudo apt update && sudo apt upgrade -y; echo; read -r -p 'Press enter to close' _"
  elif command -v dnf >/dev/null 2>&1; then
    open_update_terminal "sudo dnf upgrade --refresh -y; echo; read -r -p 'Press enter to close' _"
  elif command -v zypper >/dev/null 2>&1; then
    open_update_terminal "sudo zypper dup -y; echo; read -r -p 'Press enter to close' _"
  fi
fi

count="?"

if command -v checkupdates >/dev/null 2>&1; then
  count="$(checkupdates 2>/dev/null | wc -l || true)"
elif command -v apt >/dev/null 2>&1; then
  count="$(apt list --upgradable 2>/dev/null | awk 'NR>1' | wc -l || true)"
elif command -v dnf >/dev/null 2>&1; then
  count="$(dnf check-update -q 2>/dev/null | awk 'NF && $1 !~ /^(Last|Obsoleting|Security)/' | wc -l || true)"
elif command -v zypper >/dev/null 2>&1; then
  count="$(zypper -q list-updates 2>/dev/null | awk 'NR>2 && $1 !~ /^Repository/' | wc -l || true)"
fi

echo "$count"
