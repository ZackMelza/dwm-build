#!/usr/bin/env bash
set -euo pipefail

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/dwm"
last_wallpaper_file="$cache_dir/last-wallpaper"
fallback_image=""

mkdir -p "$cache_dir"

script_path="${BASH_SOURCE[0]}"
if command -v readlink >/dev/null 2>&1; then
  resolved="$(readlink -f -- "$script_path" 2>/dev/null || true)"
  [[ -n "$resolved" ]] && script_path="$resolved"
fi
script_dir="$(cd -- "$(dirname -- "$script_path")" && pwd)"
repo_root="$(cd -- "$script_dir/.." && pwd)"

if [[ -f "$repo_root/dwm.png" ]]; then
  fallback_image="$repo_root/dwm.png"
fi

collect_wallpaper_dirs() {
  local -a dirs=()
  local custom_dirs="${WALLPAPER_DIRS:-}"

  if [[ -n "${WALLPAPER_DIR:-}" ]]; then
    dirs+=("$WALLPAPER_DIR")
  fi

  if [[ -n "$custom_dirs" ]]; then
    IFS=':' read -r -a extra_dirs <<< "$custom_dirs"
    dirs+=("${extra_dirs[@]}")
  fi

  dirs+=(
    "$HOME/Pictures/wallpapers"
    "$HOME/Pictures/backgrounds"
    "$HOME/Hyprland-Dots/wallpapers"
    "$HOME/Arch-Hyprland/Hyprland-Dots/wallpapers"
    "/usr/share/backgrounds"
    "/usr/share/wallpapers"
  )

  printf '%s\n' "${dirs[@]}" | awk 'NF && !seen[$0]++'
}

pick_wallpaper() {
  local -a images=()
  local last_wallpaper=""
  local dir=""

  if [[ -f "$last_wallpaper_file" ]]; then
    last_wallpaper="$(sed -n '1p' "$last_wallpaper_file")"
  fi

  while IFS= read -r dir; do
    [[ -d "$dir" ]] || continue
    while IFS= read -r img; do
      [[ -n "$img" ]] && images+=("$img")
    done < <(find -L "$dir" -type f \( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' -o -iname '*.webp' \))
  done < <(collect_wallpaper_dirs)

  if [[ ${#images[@]} -eq 0 ]]; then
    [[ -n "$fallback_image" ]] && printf '%s\n' "$fallback_image"
    return 0
  fi

  if [[ ${#images[@]} -gt 1 && -n "$last_wallpaper" ]]; then
    mapfile -t images < <(printf '%s\n' "${images[@]}" | awk -v last="$last_wallpaper" '$0 != last')
  fi

  if [[ ${#images[@]} -eq 0 ]]; then
    printf '%s\n' "$last_wallpaper"
    return 0
  fi

  printf '%s\n' "${images[@]}" | shuf -n 1
}

set_wallpaper() {
  local img="$1"

  if command -v feh >/dev/null 2>&1; then
    feh --no-fehbg --bg-fill "$img"
    return 0
  fi

  if command -v xwallpaper >/dev/null 2>&1; then
    xwallpaper --zoom "$img"
    return 0
  fi

  if command -v nitrogen >/dev/null 2>&1; then
    nitrogen --set-zoom-fill "$img"
    return 0
  fi

  echo "No wallpaper setter found (feh/xwallpaper/nitrogen)." >&2
  return 1
}

img="$(pick_wallpaper)"

if [[ -z "$img" || ! -f "$img" ]]; then
  echo "No wallpaper image found." >&2
  exit 0
fi

if set_wallpaper "$img"; then
  printf '%s\n' "$img" > "$last_wallpaper_file"
  printf '%s: %s\n' "$(date '+%F %T')" "$img" >> "$HOME/.feh-wallpaper-log"
fi
