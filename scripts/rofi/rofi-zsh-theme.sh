#!/usr/bin/env bash
set -euo pipefail

themes_dir="$HOME/.oh-my-zsh/themes"
zshrc="$HOME/.zshrc"
rofi_theme="${ROFI_CONF_DIR:-$HOME/.config/rofi}/config-zsh-theme.rasi"

if [[ ! -d "$themes_dir" ]]; then
  command -v notify-send >/dev/null 2>&1 && notify-send "Rofi Zsh Theme" "~/.oh-my-zsh/themes not found"
  exit 1
fi

mapfile -t themes < <(find "$themes_dir" -maxdepth 1 -type f -name '*.zsh-theme' -printf '%f\n' | sed 's/\.zsh-theme$//' | sort)
if [[ ${#themes[@]} -eq 0 ]]; then
  command -v notify-send >/dev/null 2>&1 && notify-send "Rofi Zsh Theme" "No themes found"
  exit 1
fi

choice="$(printf '%s\n' "Random" "${themes[@]}" | rofi -i -dmenu -p "Zsh Theme" -config "$rofi_theme")"
[[ -n "$choice" ]] || exit 0

if [[ "$choice" == "Random" ]]; then
  choice="${themes[$((RANDOM % ${#themes[@]}))]}"
fi

if [[ ! -f "$zshrc" ]]; then
  printf 'export ZSH="$HOME/.oh-my-zsh"\nZSH_THEME="%s"\nsource "$ZSH/oh-my-zsh.sh"\n' "$choice" >"$zshrc"
else
  if grep -q '^ZSH_THEME=' "$zshrc"; then
    sed -i "s/^ZSH_THEME=.*/ZSH_THEME=\"$choice\"/" "$zshrc"
  else
    printf '\nZSH_THEME="%s"\n' "$choice" >>"$zshrc"
  fi
fi

command -v notify-send >/dev/null 2>&1 && notify-send "Rofi Zsh Theme" "Set theme: $choice"
