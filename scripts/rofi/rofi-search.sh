#!/usr/bin/env bash
set -euo pipefail

conf_dir="${ROFI_CONF_DIR:-$HOME/.config/rofi}"
rofi_theme="$conf_dir/config-search.rasi"
search_engine="${ROFI_SEARCH_ENGINE:-https://duckduckgo.com/?q=}"
rofi_args=(-dmenu -p "Search Web")

if [[ -f "$rofi_theme" ]]; then
  rofi_args+=(-config "$rofi_theme")
fi

query="$(printf '' | rofi "${rofi_args[@]}")"
[[ -n "$query" ]] || exit 0

xdg-open "${search_engine}${query}" >/dev/null 2>&1 &
