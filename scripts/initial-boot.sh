#!/usr/bin/env bash
set -euo pipefail

marker="$HOME/.config/dwm/.initial_startup_done"

if [[ -f "$marker" ]]; then
  exit 0
fi

mkdir -p "$HOME/.config/dwm"

if command -v xdg-user-dirs-update >/dev/null 2>&1; then
  xdg-user-dirs-update >/dev/null 2>&1 || true
fi

if command -v gsettings >/dev/null 2>&1; then
  gsettings set org.gnome.desktop.interface color-scheme prefer-dark >/dev/null 2>&1 || true
fi

touch "$marker"
