#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: setup-display-manager-theme.sh [options]

Apply login-manager theming.

Options:
  --dm sddm|lightdm      Target DM (required)
  --theme hyprlike       Theme preset (default: hyprlike)
  --backup               Backup existing DM config/theme before overwrite
  --dry-run              Print actions only
USAGE
}

dm=""
theme="hyprlike"
backup=0
dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --dm)
      dm="${2:-}"
      shift 2
      ;;
    --theme)
      theme="${2:-}"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --backup)
      backup=1
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown arg: $1" >&2
      exit 1
      ;;
  esac
done

if [[ "$dm" != "sddm" && "$dm" != "lightdm" ]]; then
  echo "--dm must be sddm or lightdm" >&2
  exit 1
fi

if [[ "$theme" != "hyprlike" ]]; then
  echo "Unsupported theme: $theme" >&2
  exit 1
fi

run_cmd() {
  if [[ $dry_run -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    eval "$*"
  fi
}

if [[ $EUID -eq 0 ]]; then
  SUDO=""
elif command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
else
  echo "Need root or sudo." >&2
  exit 1
fi

if [[ -n "${DWM_REPO_ROOT:-}" && -d "${DWM_REPO_ROOT}/scripts" ]]; then
  repo_root="$DWM_REPO_ROOT"
elif [[ -f "$HOME/.config/dwm/repo_root" ]]; then
  repo_root="$(sed -n '1p' "$HOME/.config/dwm/repo_root")"
else
  script_path="${BASH_SOURCE[0]}"
  if command -v readlink >/dev/null 2>&1; then
    resolved="$(readlink -f -- "$script_path" 2>/dev/null || true)"
    [[ -n "$resolved" ]] && script_path="$resolved"
  fi
  repo_root="$(cd -- "$(dirname -- "$script_path")/.." && pwd)"
fi

require_path() {
  local path="$1"
  if [[ ! -e "$path" && ! -L "$path" ]]; then
    echo "Missing source path: $path" >&2
    exit 1
  fi
}

if [[ "$dm" == "sddm" ]]; then
  theme_src="$repo_root/themes/sddm/dwm-hyprlike"
  theme_dst="/usr/share/sddm/themes/dwm-hyprlike"
  conf_dir="/etc/sddm.conf.d"
  conf_file="$conf_dir/10-dwm-hyprlike-theme.conf"

  require_path "$theme_src"

  run_cmd "$SUDO install -d '$theme_dst'"
  if [[ $backup -eq 1 ]]; then
    run_cmd "$SUDO test ! -e '$theme_dst' || $SUDO mv '$theme_dst' '${theme_dst}.bak.$(date +%Y%m%d%H%M%S)'"
    run_cmd "$SUDO install -d '$theme_dst'"
  fi
  run_cmd "$SUDO cp -r '$theme_src/'* '$theme_dst/'"
  run_cmd "$SUDO install -d '$conf_dir'"
  if [[ $backup -eq 1 ]]; then
    run_cmd "$SUDO test ! -e '$conf_file' || $SUDO cp '$conf_file' '${conf_file}.bak.$(date +%Y%m%d%H%M%S)'"
  fi

  if [[ $dry_run -eq 1 ]]; then
    echo "[dry-run] write $conf_file"
  else
    $SUDO tee "$conf_file" >/dev/null <<'CONF'
[Theme]
Current=dwm-hyprlike
CursorTheme=Bibata-Modern-Ice
CONF
  fi

  echo "Applied SDDM theme: dwm-hyprlike"
  exit 0
fi

# lightdm
conf_dir="/etc/lightdm/lightdm-gtk-greeter.conf.d"
conf_file="$conf_dir/10-dwm-hyprlike.conf"
run_cmd "$SUDO install -d '$conf_dir'"
if [[ $backup -eq 1 ]]; then
  run_cmd "$SUDO test ! -e '$conf_file' || $SUDO cp '$conf_file' '${conf_file}.bak.$(date +%Y%m%d%H%M%S)'"
fi

if [[ $dry_run -eq 1 ]]; then
  echo "[dry-run] write $conf_file"
else
  $SUDO tee "$conf_file" >/dev/null <<'CONF'
[greeter]
background=#0f111a
theme-name=Adwaita-dark
icon-theme-name=Papirus-Dark
cursor-theme-name=Bibata-Modern-Ice
font-name=Sans 11
clock-format=%a %b %d  %H:%M
position=20%,center 50%,center
CONF
fi

echo "Applied LightDM GTK greeter hyprlike settings"
