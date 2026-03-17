#!/usr/bin/env bash
set -euo pipefail

if ! command -v stalonetray >/dev/null 2>&1; then
  exit 0
fi

# Minimal tray tuned for DWM's top bar.
exec stalonetray \
  --dockapp-mode simple \
  --geometry 5x1-8+6 \
  --icon-size 16 \
  --background "#10151b" \
  --kludges force_icons_size \
  --grow-gravity E \
  --skip-taskbar \
  --sticky \
  --transparent false
