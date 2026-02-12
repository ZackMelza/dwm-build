#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: uninstall-dwm-stack.sh [options]

Removes deployed user-side DWM stack files and optionally restores backups.

Options:
  --restore-backups      Restore latest *.bak.* files when available
  --remove-session       Remove /usr/share/xsessions/dwm.desktop
  --dm sddm|lightdm|none Remove DM theme config for selected DM
  --dry-run              Print actions only
USAGE
}

restore=0
remove_session=0
dm="none"
dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --restore-backups) restore=1; shift ;;
    --remove-session) remove_session=1; shift ;;
    --dm) dm="${2:-}"; shift 2 ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

run_cmd() {
  if [[ $dry_run -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    eval "$*"
  fi
}

restore_latest() {
  local target="$1"
  local latest
  latest="$(find "$(dirname "$target")" -maxdepth 1 -name "$(basename "$target").bak.*" -printf '%T@ %p\n' 2>/dev/null | sort -nr | head -n1 | cut -d' ' -f2- || true)"
  if [[ -n "$latest" ]]; then
    run_cmd "rm -rf '$target'"
    run_cmd "mv '$latest' '$target'"
  fi
}

for f in dwm-autostart.sh initial-boot.sh start-polkit-agent.sh set-random-wallpaper.sh set-dwm-profile.sh set-dwm-keybind-profile.sh rebuild-dwm-profile.sh dwm-power-menu.sh setup-dwmblocks.sh setup-rofi-suite.sh setup-display-manager-theme.sh rofi-beats.sh rofi-search.sh rofi-calc.sh show-keybinds.sh generate-keybind-cheatsheet.sh health-check.sh bootstrap.sh dwm-bootstrap.sh dwm-health-check.sh dwm-uninstall.sh; do
  run_cmd "rm -f '$HOME/.local/bin/$f'"
done

if [[ -L "$HOME/.xinitrc" ]]; then
  run_cmd "rm -f '$HOME/.xinitrc'"
fi

if [[ $restore -eq 1 ]]; then
  restore_latest "$HOME/.xinitrc"
  restore_latest "$HOME/.config/rofi"
fi

if [[ -L "$HOME/.config/rofi" ]]; then
  run_cmd "rm -f '$HOME/.config/rofi'"
fi

if [[ -L "$HOME/.config/dwmblocks" ]]; then
  run_cmd "rm -f '$HOME/.config/dwmblocks'"
fi

if [[ $remove_session -eq 1 ]]; then
  run_cmd "sudo rm -f /usr/share/xsessions/dwm.desktop"
fi

if [[ "$dm" == "sddm" ]]; then
  run_cmd "sudo rm -f /etc/sddm.conf.d/10-dwm-hyprlike-theme.conf"
  run_cmd "sudo rm -rf /usr/share/sddm/themes/dwm-hyprlike"
elif [[ "$dm" == "lightdm" ]]; then
  run_cmd "sudo rm -f /etc/lightdm/lightdm-gtk-greeter.conf.d/10-dwm-hyprlike.conf"
fi

echo "Uninstall complete."
