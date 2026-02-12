#!/usr/bin/env bash
set -euo pipefail

missing=0

check_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "[MISS] command: $cmd"
    missing=1
  else
    echo "[OK] command: $cmd"
  fi
}

check_file() {
  local file="$1"
  if [[ ! -e "$file" ]]; then
    echo "[MISS] file: $file"
    missing=1
  else
    echo "[OK] file: $file"
  fi
}

echo "DWM stack health check"

for c in dwm rofi dmenu kitty zsh picom dunst feh playerctl brightnessctl; do
  check_cmd "$c"
done

for c in rofi-beats.sh rofi-search.sh rofi-calc.sh rofi-zsh-theme.sh rofi-kitty-theme.sh dwm-autostart.sh dwm-power-menu.sh show-keybinds.sh; do
  check_cmd "$c"
done

check_file "$HOME/.config/environment.d/99-dwm.conf"
check_file "$HOME/.config/dwm/host.conf"
check_file "$HOME/.config/rofi"
check_file "$HOME/.config/kitty"
check_file "$HOME/.zshrc"
check_file "$HOME/.xinitrc"
check_file "$HOME/.config/dwmblocks"

if pgrep -x dwmblocks >/dev/null 2>&1; then
  echo "[OK] process: dwmblocks running"
else
  echo "[WARN] process: dwmblocks not running"
fi

if [[ $missing -ne 0 ]]; then
  echo "Health check failed."
  exit 1
fi

echo "Health check passed."
