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
  --rebuild-dwm             Rebuild/install dwm after profile deployment
  --force                   Overwrite existing files/links
  --dry-run                 Print changes without writing
  -h, --help                Show this help
USAGE
}

mode="symlink"
profile=""
install_session=0
rebuild_dwm=0
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
    --rebuild-dwm)
      rebuild_dwm=1
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

  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ $force -eq 1 ]]; then
      run_cmd "rm -rf '$dst'"
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

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

run_cmd "mkdir -p '$HOME/.local/bin'"
run_cmd "mkdir -p '$HOME/.config/dwm'"

scripts=(
  dwm-autostart.sh
  initial-boot.sh
  start-polkit-agent.sh
  set-random-wallpaper.sh
  set-dwm-profile.sh
  set-dwm-keybind-profile.sh
  rebuild-dwm-profile.sh
  dwm-power-menu.sh
  setup-dwmblocks.sh
)

for script in "${scripts[@]}"; do
  src="$repo_root/scripts/$script"
  dst="$HOME/.local/bin/$script"
  link_or_copy "$src" "$dst"
  run_cmd "chmod +x '$dst'"
done

link_or_copy "$repo_root/xinitrc" "$HOME/.xinitrc"

profile_args="--force"
if [[ -n "$profile" ]]; then
  profile_args="--profile '$profile' --force"
fi
run_cmd "'$HOME/.local/bin/set-dwm-profile.sh' $profile_args"
run_cmd "'$HOME/.local/bin/set-dwm-keybind-profile.sh' ${profile:+--profile '$profile'}"
run_cmd "'$HOME/.local/bin/setup-dwmblocks.sh' --mode '$mode' --force"

if [[ $rebuild_dwm -eq 1 ]]; then
  rebuild_args=""
  if [[ -n "$profile" ]]; then
    rebuild_args="--profile '$profile'"
  fi
  run_cmd "'$HOME/.local/bin/rebuild-dwm-profile.sh' $rebuild_args"
fi

if [[ $install_session -eq 1 ]]; then
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
