#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: set-dwm-keybind-profile.sh [--profile laptop|desktop] [--dry-run]

Selects compile-time keybind profile by writing profiles/config-profile.h.
USAGE
}

profile=""
dry_run=0

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
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      exit 1
      ;;
  esac
done

detect_profile() {
  local p=""
  if [[ -f "$HOME/.config/environment.d/99-dwm.conf" ]]; then
    p="$(awk -F= '/^DWM_PROFILE=/{print $2; exit}' "$HOME/.config/environment.d/99-dwm.conf" || true)"
  fi

  if [[ "$p" == "laptop" || "$p" == "desktop" ]]; then
    echo "$p"
    return
  fi

  if compgen -G "/sys/class/power_supply/BAT*" >/dev/null; then
    echo "laptop"
  else
    echo "desktop"
  fi
}

if [[ -z "$profile" ]]; then
  profile="$(detect_profile)"
fi

if [[ "$profile" != "laptop" && "$profile" != "desktop" ]]; then
  echo "Invalid profile: $profile" >&2
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
src="$repo_root/profiles/config-profile-$profile.h"
dst="$repo_root/profiles/config-profile.h"

if [[ ! -f "$src" ]]; then
  echo "Missing profile header: $src" >&2
  exit 1
fi

if [[ $dry_run -eq 1 ]]; then
  echo "Would write: $dst"
  echo "#include \"config-profile-$profile.h\""
  exit 0
fi

printf '#include "config-profile-%s.h"\n' "$profile" > "$dst"
echo "Selected keybind profile: $profile"
