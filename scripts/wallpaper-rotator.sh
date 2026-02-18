#!/usr/bin/env bash
set -euo pipefail

interval="${DWM_WALLPAPER_ROTATION_SECONDS:-1800}"
script_path="${HOME}/.local/bin/set-random-wallpaper.sh"

if [[ ! "$interval" =~ ^[0-9]+$ ]] || (( interval < 60 )); then
  interval=1800
fi

run_setter() {
  if [[ -x "$script_path" ]]; then
    "$script_path" >/dev/null 2>&1 || true
  elif command -v set-random-wallpaper.sh >/dev/null 2>&1; then
    set-random-wallpaper.sh >/dev/null 2>&1 || true
  fi
}

while true; do
  sleep "$interval"
  run_setter
done
