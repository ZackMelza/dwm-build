#!/usr/bin/env bash
set -euo pipefail

script_path="${BASH_SOURCE[0]}"
if command -v readlink >/dev/null 2>&1; then
  resolved="$(readlink -f -- "$script_path" 2>/dev/null || true)"
  [[ -n "$resolved" ]] && script_path="$resolved"
fi
script_dir="$(cd -- "$(dirname -- "$script_path")" && pwd)"
out_file="${XDG_CACHE_HOME:-$HOME/.cache}/dwm-keybinds.txt"
mkdir -p "$(dirname "$out_file")"

"$script_dir/generate-keybind-cheatsheet.sh" > "$out_file"

if command -v rofi >/dev/null 2>&1; then
  rofi -dmenu -i -no-custom -p "DWM Keys" < "$out_file" >/dev/null 2>&1 || true
  exit 0
fi

if command -v xmessage >/dev/null 2>&1; then
  xmessage -file "$out_file" -center >/dev/null 2>&1 &
  exit 0
fi

cat "$out_file"
