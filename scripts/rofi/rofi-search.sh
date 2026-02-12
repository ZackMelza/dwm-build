#!/usr/bin/env bash
set -euo pipefail

conf_dir="${ROFI_CONF_DIR:-$HOME/.config/rofi}"
rofi_theme="$conf_dir/config-search.rasi"
search_engine="${ROFI_SEARCH_ENGINE:-https://duckduckgo.com/?q=}"

query="$(printf '' | rofi -dmenu -p 'Search Web' -config "$rofi_theme")"
[[ -n "$query" ]] || exit 0

xdg-open "${search_engine}${query}" >/dev/null 2>&1 &
