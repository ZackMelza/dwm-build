#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: setup-rofi-suite.sh [--mode symlink|copy] [--force] [--dry-run]

Installs the full Hypr-like rofi suite for DWM.
USAGE
}

mode="symlink"
force=0
dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      mode="${2:-}"
      shift 2
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
      echo "Unknown arg: $1" >&2
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

link_or_copy() {
  local src="$1" dst="$2" is_dir="${3:-0}"
  if [[ -e "$dst" || -L "$dst" ]]; then
    if [[ $force -eq 1 ]]; then
      run_cmd "rm -rf '$dst'"
    else
      return
    fi
  fi

  if [[ "$mode" == "symlink" ]]; then
    run_cmd "ln -s '$src' '$dst'"
  else
    if [[ "$is_dir" == "1" ]]; then
      run_cmd "cp -r '$src' '$dst'"
    else
      run_cmd "cp '$src' '$dst'"
    fi
  fi
}

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"

run_cmd "mkdir -p '$HOME/.local/bin' '$HOME/.config'"

for s in rofi-beats.sh rofi-search.sh rofi-calc.sh; do
  link_or_copy "$repo_root/scripts/rofi/$s" "$HOME/.local/bin/$s"
  run_cmd "chmod +x '$HOME/.local/bin/$s'"
done

link_or_copy "$repo_root/rofi" "$HOME/.config/rofi" 1

echo "Rofi suite installed (full config + themes)."
