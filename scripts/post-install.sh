#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: post-install.sh [options]

Deploys reproducible user/session config after packages + dwm are installed.

Options:
  --mode symlink|copy       How to deploy files (default: symlink)
  --profile laptop|desktop  Force profile before writing host config
  --install-session         Install sessions/dwm.desktop to /usr/share/xsessions (sudo)
  --setup-rofi              Install Hypr-like rofi scripts/config
  --setup-shell             Install kitty + zsh config/theme helpers
  --dm-theme breeze|hyprlike Apply login theme to selected --display-manager
  --display-manager NAME    For --dm-theme: lightdm|sddm
  --rebuild-dwm             Rebuild/install dwm after profile deployment
  --backup                  Backup target files before overwrite where supported
  --force                   Overwrite existing files/links
  --dry-run                 Print changes without writing
  -h, --help                Show this help
USAGE
}

mode="symlink"
profile=""
install_session=0
setup_rofi=0
setup_shell=0
dm_theme="none"
display_manager="none"
rebuild_dwm=0
backup=0
force=0
dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      mode="${2:-}"
      shift 2
      ;;
    --profile)
      profile="${2:-}"
      shift 2
      ;;
    --install-session)
      install_session=1
      shift
      ;;
    --setup-rofi)
      setup_rofi=1
      shift
      ;;
    --setup-shell)
      setup_shell=1
      shift
      ;;
    --dm-theme)
      dm_theme="${2:-}"
      shift 2
      ;;
    --display-manager)
      display_manager="${2:-}"
      shift 2
      ;;
    --rebuild-dwm)
      rebuild_dwm=1
      shift
      ;;
    --backup)
      backup=1
      shift
      ;;
    --force)
      force=1
      shift
      ;;
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

if [[ "$mode" != "symlink" && "$mode" != "copy" ]]; then
  echo "Invalid mode: $mode" >&2
  exit 1
fi

if [[ "$dm_theme" != "none" && "$dm_theme" != "hyprlike" && "$dm_theme" != "breeze" ]]; then
  echo "Invalid dm theme: $dm_theme" >&2
  exit 1
fi

if [[ "$display_manager" != "none" && "$display_manager" != "lightdm" && "$display_manager" != "sddm" ]]; then
  echo "Invalid display manager for post-install theming: $display_manager" >&2
  exit 1
fi

run_cmd() {
  if [[ $dry_run -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    eval "$*"
  fi
}

link_or_copy() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" && ! -L "$src" ]]; then
    echo "Missing source path: $src" >&2
    exit 1
  fi

  run_cmd "mkdir -p '$(dirname "$dst")'"

  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ $force -eq 1 ]]; then
      if [[ $backup -eq 1 ]]; then
        run_cmd "mv '$dst' '${dst}.bak.$(date +%Y%m%d%H%M%S)'"
      else
        run_cmd "rm -rf '$dst'"
      fi
    else
      echo "Skipping existing path (use --force): $dst"
      return 0
    fi
  fi

  if [[ "$mode" == "symlink" ]]; then
    run_cmd "ln -s '$src' '$dst'"
  else
    run_cmd "cp '$src' '$dst'"
  fi
}

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

run_cmd "mkdir -p '$HOME/.local/bin'"
run_cmd "mkdir -p '$HOME/.config/dwm'"
run_cmd "printf '%s\n' '$repo_root' > '$HOME/.config/dwm/repo_root'"

scripts=(
  dwm-autostart.sh
  initial-boot.sh
  start-polkit-agent.sh
  start-picom.sh
  set-random-wallpaper.sh
  wallpaper-rotator.sh
  idle-manager.sh
  set-dwm-profile.sh
  set-dwm-keybind-profile.sh
  rebuild-dwm-profile.sh
  dwm-power-menu.sh
  setup-dwmblocks.sh
  setup-rofi-suite.sh
  setup-shell-suite.sh
  setup-notification-service.sh
  setup-display-manager-theme.sh
  health-check.sh
  uninstall-dwm-stack.sh
  generate-keybind-cheatsheet.sh
  show-keybinds.sh
  bootstrap.sh
)

for script in "${scripts[@]}"; do
  src="$repo_root/scripts/$script"
  dst="$HOME/.local/bin/$script"
  link_or_copy "$src" "$dst"
  run_cmd "chmod +x '$dst'"
done

link_or_copy "$repo_root/xinitrc" "$HOME/.xinitrc"
link_or_copy "$repo_root/picom" "$HOME/.config/picom"

profile_args="--force"
if [[ -n "$profile" ]]; then
  profile_args="--profile '$profile' --force"
fi
run_cmd "DWM_REPO_ROOT='$repo_root' '$HOME/.local/bin/set-dwm-profile.sh' $profile_args"
keybind_args=""
if [[ -n "$profile" ]]; then
  keybind_args="--profile '$profile'"
fi
notif_args=""
if [[ $dry_run -eq 1 ]]; then
  notif_args="--dry-run"
fi
run_cmd "DWM_REPO_ROOT='$repo_root' '$HOME/.local/bin/set-dwm-keybind-profile.sh' $keybind_args"
run_cmd "DWM_REPO_ROOT='$repo_root' '$HOME/.local/bin/setup-dwmblocks.sh' --mode '$mode' --force"
run_cmd "'$HOME/.local/bin/setup-notification-service.sh' $notif_args"

if [[ $setup_rofi -eq 1 ]]; then
  if [[ $backup -eq 1 ]]; then
    run_cmd "DWM_REPO_ROOT='$repo_root' '$HOME/.local/bin/setup-rofi-suite.sh' --mode '$mode' --force --backup"
  else
    run_cmd "DWM_REPO_ROOT='$repo_root' '$HOME/.local/bin/setup-rofi-suite.sh' --mode '$mode' --force"
  fi
fi

if [[ $setup_shell -eq 1 ]]; then
  if [[ $backup -eq 1 ]]; then
    run_cmd "DWM_REPO_ROOT='$repo_root' '$HOME/.local/bin/setup-shell-suite.sh' --mode '$mode' --force --backup"
  else
    run_cmd "DWM_REPO_ROOT='$repo_root' '$HOME/.local/bin/setup-shell-suite.sh' --mode '$mode' --force"
  fi
fi

if [[ "$dm_theme" != "none" ]]; then
  if [[ "$display_manager" == "none" ]]; then
    echo "--dm-theme requires --display-manager lightdm|sddm" >&2
    exit 1
  fi
  if [[ $backup -eq 1 ]]; then
    run_cmd "DWM_REPO_ROOT='$repo_root' '$HOME/.local/bin/setup-display-manager-theme.sh' --dm '$display_manager' --theme '$dm_theme' --backup"
  else
    run_cmd "DWM_REPO_ROOT='$repo_root' '$HOME/.local/bin/setup-display-manager-theme.sh' --dm '$display_manager' --theme '$dm_theme'"
  fi
fi

if [[ $rebuild_dwm -eq 1 ]]; then
  rebuild_args=""
  if [[ -n "$profile" ]]; then
    rebuild_args="--profile '$profile'"
  fi
  run_cmd "DWM_REPO_ROOT='$repo_root' '$HOME/.local/bin/rebuild-dwm-profile.sh' $rebuild_args"
fi

if [[ $install_session -eq 1 ]]; then
  if [[ ! -f "$repo_root/sessions/dwm.desktop" ]]; then
    echo "Missing source path: $repo_root/sessions/dwm.desktop" >&2
    exit 1
  fi
  if [[ $dry_run -eq 1 ]]; then
    run_cmd "sudo install -Dm644 '$repo_root/sessions/dwm.desktop' /usr/share/xsessions/dwm.desktop"
  else
    if [[ $EUID -eq 0 ]]; then
      install -Dm644 "$repo_root/sessions/dwm.desktop" /usr/share/xsessions/dwm.desktop
    elif command -v sudo >/dev/null 2>&1; then
      sudo install -Dm644 "$repo_root/sessions/dwm.desktop" /usr/share/xsessions/dwm.desktop
    else
      echo "Skipping --install-session: need root or sudo." >&2
    fi
  fi
fi

echo "Post-install finished (mode: $mode)."
