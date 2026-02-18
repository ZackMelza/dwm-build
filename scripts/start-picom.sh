#!/usr/bin/env bash
set -euo pipefail

config_file="$HOME/.config/picom/picom.conf"

if [[ -f "$config_file" ]]; then
  exec picom --config "$config_file"
fi

# Fallback low-latency profile if no config file is present.
exec picom --backend xrender --vsync=false --shadow=false --fading=false --unredir-if-possible
