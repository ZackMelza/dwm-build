#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: rebuild-dwm-profile.sh [options]

Applies DWM runtime+compile profiles, rebuilds dwm, and installs it.

Options:
  --profile laptop|desktop  Force profile (default: auto detect)
  --dry-run                 Print commands only
  --no-install              Build but skip install step
  -h, --help                Show this help
USAGE
}

profile=""
dry_run=0
no_install=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      profile="${2:-}"
      shift 2
      ;;
    --dry-run)
      dry_run=1
      shift
      ;;
    --no-install)
      no_install=1
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

profile_args=""
if [[ -n "$profile" ]]; then
  profile_args="--profile '$profile'"
fi

run_cmd "'$repo_root/scripts/set-dwm-profile.sh' $profile_args --force"
run_cmd "'$repo_root/scripts/set-dwm-keybind-profile.sh' $profile_args"
run_cmd "make -C '$repo_root' clean"
run_cmd "make -C '$repo_root'"

if [[ $no_install -eq 0 ]]; then
  if [[ $dry_run -eq 1 ]]; then
    run_cmd "sudo make -C '$repo_root' install"
  else
    if [[ $EUID -eq 0 ]]; then
      make -C "$repo_root" install
    elif command -v sudo >/dev/null 2>&1; then
      sudo make -C "$repo_root" install
    else
      echo "Need root or sudo to install dwm." >&2
      exit 1
    fi
  fi
fi

echo "DWM rebuild complete."
