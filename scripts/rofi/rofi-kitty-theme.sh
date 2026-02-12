#!/usr/bin/env bash
set -euo pipefail

themes_dir="$HOME/.config/kitty/kitty-themes"
kitty_conf="$HOME/.config/kitty/kitty.conf"
rofi_theme="${ROFI_CONF_DIR:-$HOME/.config/rofi}/config-kitty-theme.rasi"

if [[ ! -d "$themes_dir" ]]; then
  command -v notify-send >/dev/null 2>&1 && notify-send "Rofi Kitty Theme" "kitty themes directory missing"
  exit 1
fi

mapfile -t themes < <(find "$themes_dir" -maxdepth 1 -type f -name '*.conf' -printf '%f\n' | sed 's/\.conf$//' | sort)
if [[ ${#themes[@]} -eq 0 ]]; then
  command -v notify-send >/dev/null 2>&1 && notify-send "Rofi Kitty Theme" "No kitty themes found"
  exit 1
fi

choice="$(printf '%s\n' "${themes[@]}" | rofi -i -dmenu -p "Kitty Theme" -config "$rofi_theme")"
[[ -n "$choice" ]] || exit 0

if [[ ! -f "$kitty_conf" ]]; then
  mkdir -p "$(dirname "$kitty_conf")"
  : >"$kitty_conf"
fi

if grep -q -E '^[#[:space:]]*include[[:space:]]+\./kitty-themes/.*\.conf' "$kitty_conf"; then
  sed -i -E "s|^[#[:space:]]*include[[:space:]]+\./kitty-themes/.*\.conf|include ./kitty-themes/$choice.conf|" "$kitty_conf"
else
  printf '\ninclude ./kitty-themes/%s.conf\n' "$choice" >>"$kitty_conf"
fi

if pgrep -x kitty >/dev/null 2>&1; then
  pkill -USR1 -x kitty >/dev/null 2>&1 || true
fi

command -v notify-send >/dev/null 2>&1 && notify-send "Rofi Kitty Theme" "Set theme: $choice"
