#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bootstrap.sh [options]

One-shot bootstrap for fresh systems.

Options:
  --profile laptop|desktop
  --display-manager lightdm|sddm|greetd|ly|none
  --dm-theme none|hyprlike
  --mode symlink|copy
  --enable-services
  --dry-run
USAGE
}

profile=""
dm="sddm"
dm_theme="hyprlike"
mode="symlink"
enable_services=1
dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) profile="${2:-}"; shift 2 ;;
    --display-manager) dm="${2:-}"; shift 2 ;;
    --dm-theme) dm_theme="${2:-}"; shift 2 ;;
    --mode) mode="${2:-}"; shift 2 ;;
    --enable-services) enable_services=1; shift ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

script_path="${BASH_SOURCE[0]}"
if command -v readlink >/dev/null 2>&1; then
  resolved="$(readlink -f -- "$script_path" 2>/dev/null || true)"
  [[ -n "$resolved" ]] && script_path="$resolved"
fi
repo_root="$(cd -- "$(dirname -- "$script_path")/.." && pwd)"
extra_install=""
extra_post=""

[[ -n "$profile" ]] && extra_install+=" --profile '$profile'" && extra_post+=" --profile '$profile'"
[[ $enable_services -eq 1 ]] && extra_install+=" --enable-services"
[[ $dry_run -eq 1 ]] && extra_install+=" --dry-run" && extra_post+=" --dry-run"

# shellcheck disable=SC2086
DWM_REPO_ROOT="$repo_root" bash -c "'$repo_root/scripts/install-dwm-stack.sh' --display-manager '$dm' --dm-theme '$dm_theme' --install-xinitrc --install-session $extra_install"
# shellcheck disable=SC2086
DWM_REPO_ROOT="$repo_root" bash -c "'$repo_root/scripts/post-install.sh' --mode '$mode' --force --setup-rofi --setup-shell --display-manager '$dm' --dm-theme '$dm_theme' --rebuild-dwm $extra_post"

ensure_session_entry() {
  local session_file="/usr/share/xsessions/dwm.desktop"
  local wrapper="/usr/local/bin/dwm-session"

  install_wrapper() {
    if [[ $dry_run -eq 1 ]]; then
      echo "[dry-run] install $wrapper"
      return 0
    fi

    local payload='#!/usr/bin/env sh
set -eu
LOG="${XDG_RUNTIME_DIR:-/tmp}/dwm-session.log"
{
  echo "== $(date) =="
  echo "USER=$USER HOME=$HOME"
  echo "PATH=$PATH"
} >> "$LOG" 2>&1

if command -v dwm-autostart.sh >/dev/null 2>&1; then
  dwm-autostart.sh >> "$LOG" 2>&1 &
elif [ -x "$HOME/.local/bin/dwm-autostart.sh" ]; then
  "$HOME/.local/bin/dwm-autostart.sh" >> "$LOG" 2>&1 &
fi

DWM_BIN="$(command -v dwm 2>/dev/null || true)"
[ -z "$DWM_BIN" ] && [ -x /usr/local/bin/dwm ] && DWM_BIN=/usr/local/bin/dwm
[ -z "$DWM_BIN" ] && [ -x /usr/bin/dwm ] && DWM_BIN=/usr/bin/dwm

if [ -z "$DWM_BIN" ]; then
  echo "dwm binary not found" >> "$LOG"
  exit 127
fi

exec "$DWM_BIN" >> "$LOG" 2>&1
'

    if [[ $EUID -eq 0 ]]; then
      printf '%s\n' "$payload" > "$wrapper"
      chmod 755 "$wrapper"
    elif command -v sudo >/dev/null 2>&1; then
      printf '%s\n' "$payload" | sudo tee "$wrapper" >/dev/null
      sudo chmod 755 "$wrapper"
    else
      echo "Warning: no sudo, cannot install $wrapper" >&2
    fi
  }

  if [[ $dry_run -eq 1 ]]; then
    echo "[dry-run] ensure $session_file exists"
    install_wrapper
    return 0
  fi

  install_wrapper

  if [[ ! -f "$session_file" ]]; then
    if [[ $EUID -eq 0 ]]; then
      install -Dm644 "$repo_root/sessions/dwm.desktop" "$session_file"
    elif command -v sudo >/dev/null 2>&1; then
      sudo install -Dm644 "$repo_root/sessions/dwm.desktop" "$session_file"
    else
      echo "Warning: missing $session_file and no sudo to install it." >&2
      return 0
    fi
  fi

  if [[ $EUID -eq 0 ]]; then
    sed -i "s|^Exec=.*|Exec=$wrapper|; s|^TryExec=.*|TryExec=$wrapper|" "$session_file"
  elif command -v sudo >/dev/null 2>&1; then
    sudo sed -i "s|^Exec=.*|Exec=$wrapper|; s|^TryExec=.*|TryExec=$wrapper|" "$session_file"
  fi
}

if [[ "$dm" != "none" ]]; then
  ensure_session_entry
fi

echo "Bootstrap complete."
