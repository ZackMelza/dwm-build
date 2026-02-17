#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: setup-notification-service.sh [options]

Installs and enables a user-level notification service for DWM.

Options:
  --dry-run   Print actions without writing
  -h, --help  Show this help
USAGE
}

dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dry-run)
      dry_run=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
done

run_cmd() {
  if [[ $dry_run -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    eval "$*"
  fi
}

unit_dir="$HOME/.config/systemd/user"
unit_name="dwm-dunst.service"
unit_path="$unit_dir/$unit_name"

run_cmd "mkdir -p '$unit_dir'"

if [[ $dry_run -eq 1 ]]; then
  echo "[dry-run] write $unit_path"
else
  cat >"$unit_path" <<'UNIT'
[Unit]
Description=DWM notifications (dunst)
After=graphical-session-pre.target
PartOf=graphical-session.target

[Service]
Type=simple
ExecStart=/usr/bin/env dunst
Restart=on-failure
RestartSec=1

[Install]
WantedBy=default.target
UNIT
fi

if command -v systemctl >/dev/null 2>&1; then
  if [[ $dry_run -eq 1 ]]; then
    run_cmd "systemctl --user daemon-reload"
    run_cmd "systemctl --user enable --now '$unit_name'"
  else
    if systemctl --user daemon-reload >/dev/null 2>&1; then
      if ! systemctl --user enable --now "$unit_name" >/dev/null 2>&1; then
        echo "Could not enable/start $unit_name automatically; enable it later with: systemctl --user enable --now $unit_name" >&2
      fi
    else
      echo "No active systemd user session; unit installed but not enabled yet." >&2
    fi
  fi
else
  echo "systemctl not found; notification service installed but not enabled." >&2
fi

echo "Notification service ready: $unit_name"
