#!/usr/bin/env bash
set -euo pipefail

button="${BLOCK_BUTTON:-${BUTTON:-}}"
power_menu="${HOME}/.local/bin/dwm-power-menu.sh"

run_power_menu() {
  if [[ -x "$power_menu" ]]; then
    "$power_menu" >/dev/null 2>&1 || true
  elif command -v dwm-power-menu.sh >/dev/null 2>&1; then
    dwm-power-menu.sh >/dev/null 2>&1 || true
  fi
}

case "$button" in
  1|2|3|4|5)
    run_power_menu
    ;;
esac

printf 'PWR'
