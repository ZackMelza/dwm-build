#!/usr/bin/env bash
set -euo pipefail

wallpaper_dir="${WALLPAPER_DIR:-$HOME/Pictures/wallpapers}"

if [[ ! -d "$wallpaper_dir" ]]; then
  wallpaper_dir="/usr/share/wallpapers"
fi

if [[ ! -d "$wallpaper_dir" ]]; then
  echo "No wallpaper directory found." >&2
  exit 0
fi

img="$(find "$wallpaper_dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \) | shuf -n 1)"

if [[ -z "$img" ]]; then
  echo "No image files found in $wallpaper_dir" >&2
  exit 0
fi

if command -v feh >/dev/null 2>&1; then
  feh --bg-scale "$img"
fi

printf '%s: %s\n' "$(date '+%F %T')" "$img" >> "$HOME/.feh-wallpaper-log"
