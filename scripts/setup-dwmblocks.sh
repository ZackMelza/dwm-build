#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: setup-dwmblocks.sh [options]

Deploys the dwmblocks config package from this repo into ~/.config/dwmblocks.
Optionally installs blocks.h into a dwmblocks source tree and builds it.

Options:
  --mode symlink|copy         Deploy mode (default: symlink)
  --dwmblocks-src PATH        Path to dwmblocks source repo
  --build                     Build dwmblocks in --dwmblocks-src after copying blocks.h
  --force                     Replace existing files
  --dry-run                   Print actions only
  -h, --help                  Show this help
USAGE
}

mode="symlink"
dwmblocks_src=""
do_build=0
force=0
dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --mode)
      mode="${2:-}"
      shift 2
      ;;
    --dwmblocks-src)
      dwmblocks_src="${2:-}"
      shift 2
      ;;
    --build)
      do_build=1
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

if [[ $do_build -eq 1 && -z "$dwmblocks_src" ]]; then
  echo "--build requires --dwmblocks-src" >&2
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
    run_cmd "cp -r '$src' '$dst'"
  fi
}

script_path="${BASH_SOURCE[0]}"
if command -v readlink >/dev/null 2>&1; then
  resolved="$(readlink -f -- "$script_path" 2>/dev/null || true)"
  [[ -n "$resolved" ]] && script_path="$resolved"
fi
repo_root="$(cd -- "$(dirname -- "$script_path")/.." && pwd)"
src_dir="$repo_root/dwmblocks"
dst_dir="$HOME/.config/dwmblocks"

run_cmd "mkdir -p '$HOME/.config'"
link_or_copy "$src_dir" "$dst_dir"
if [[ -d "$dst_dir/scripts" ]]; then
  for script in "$dst_dir"/scripts/*.sh; do
    [[ -e "$script" ]] || continue
    run_cmd "chmod +x '$script'"
  done
fi

# Backward-compat path for older helper scripts that referenced ~/.local/dwmblocks.
run_cmd "mkdir -p '$HOME/.local'"
if [[ ! -e "$HOME/.local/dwmblocks" ]]; then
  run_cmd "ln -s '$dst_dir' '$HOME/.local/dwmblocks'"
fi

if [[ -n "$dwmblocks_src" ]]; then
  if [[ ! -d "$dwmblocks_src" ]]; then
    echo "dwmblocks source path not found: $dwmblocks_src" >&2
    exit 1
  fi

  if [[ -f "$dwmblocks_src/blocks.h" && $force -eq 1 ]]; then
    run_cmd "cp '$dwmblocks_src/blocks.h' '$dwmblocks_src/blocks.h.bak.$(date +%Y%m%d%H%M%S)'"
  fi

  run_cmd "cp '$dst_dir/blocks.def.h' '$dwmblocks_src/blocks.h'"

  if [[ $do_build -eq 1 ]]; then
    run_cmd "make -C '$dwmblocks_src' clean"
    run_cmd "make -C '$dwmblocks_src'"
    if [[ $dry_run -eq 1 ]]; then
      run_cmd "sudo make -C '$dwmblocks_src' install"
    else
      if [[ $EUID -eq 0 ]]; then
        make -C "$dwmblocks_src" install
      elif command -v sudo >/dev/null 2>&1; then
        sudo make -C "$dwmblocks_src" install
      else
        echo "Need root or sudo to install dwmblocks." >&2
        exit 1
      fi
    fi
  fi
fi

echo "dwmblocks package deployed to $dst_dir"
