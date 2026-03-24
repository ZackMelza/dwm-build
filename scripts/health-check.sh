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
check_cmd xautolock

for c in rofi-beats.sh rofi-search.sh rofi-calc.sh rofi-zsh-theme.sh rofi-kitty-theme.sh dwm-autostart.sh dwm-power-menu.sh show-keybinds.sh start-tray.sh; do
  check_cmd "$c"
done

check_file "$HOME/.config/environment.d/99-dwm.conf"
check_file "$HOME/.config/dwm/host.conf"
if [[ -e "$HOME/.config/rofi" ]]; then
  echo "[OK] file: $HOME/.config/rofi"
else
  echo "[WARN] file: $HOME/.config/rofi missing (run setup-rofi-suite.sh for themed rofi menus)"
fi
if [[ -e "$HOME/.config/kitty" ]]; then
  echo "[OK] file: $HOME/.config/kitty"
else
  echo "[WARN] file: $HOME/.config/kitty missing (shell suite not deployed)"
fi
check_file "$HOME/.zshrc"
check_file "$HOME/.xinitrc"
check_file "$HOME/.config/dwmblocks"

if command -v dwm-health-check.sh >/dev/null 2>&1; then
  echo "[OK] command: dwm-health-check.sh"
else
  echo "[WARN] command: dwm-health-check.sh alias missing"
fi

if pgrep -x dwmblocks >/dev/null 2>&1; then
  echo "[OK] process: dwmblocks running"
else
  echo "[WARN] process: dwmblocks not running"
fi

if pgrep -x dunst >/dev/null 2>&1; then
  echo "[OK] process: dunst running"
else
  echo "[WARN] process: dunst not running"
fi

if pgrep -f "wallpaper-rotator.sh" >/dev/null 2>&1; then
  echo "[OK] process: wallpaper rotation running"
else
  echo "[WARN] process: wallpaper rotation not running"
fi

if pgrep -f "idle-manager.sh|xautolock" >/dev/null 2>&1; then
  echo "[OK] process: idle manager running"
else
  echo "[WARN] process: idle manager not running"
fi

if [[ $missing -ne 0 ]]; then
  echo "Health check failed."
  exit 1
fi

echo "Health check passed."
