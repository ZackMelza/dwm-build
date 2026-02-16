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
  --build                     Build/install dwmblocks (auto-clones source to /tmp if --dwmblocks-src is not set)
  --repo-url URL              dwmblocks git URL for auto-clone (default: https://github.com/torrinfail/dwmblocks.git)
  --force                     Replace existing files
  --dry-run                   Print actions only
  -h, --help                  Show this help
USAGE
}

mode="symlink"
dwmblocks_src=""
do_build=0
repo_url="https://github.com/torrinfail/dwmblocks.git"
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
    --repo-url)
      repo_url="${2:-}"
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

patch_dwmblocks_source_if_needed() {
  local src="$1"
  local cfile="$src/dwmblocks.c"
  if [[ ! -f "$cfile" ]]; then
    return 0
  fi

  if grep -q 'void termhandler()' "$cfile"; then
    run_cmd "sed -i \"s/void termhandler();/void termhandler(int signum);/g\" '$cfile'"
    run_cmd "sed -i \"s/void termhandler()/void termhandler(int signum)/g\" '$cfile'"
    # Avoid unused-parameter warnings if toolchain treats warnings as errors.
    run_cmd "sed -i '/void termhandler(int signum)/,/^}/ s/statusContinue = 0;/(void)signum;\\n\tstatusContinue = 0;/' '$cfile'"
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
if [[ $dry_run -ne 1 && ! -e "$dst_dir" && ! -L "$dst_dir" ]]; then
  echo "Expected dwmblocks target missing: $dst_dir" >&2
  exit 1
fi
if [[ ! -e "$HOME/.local/dwmblocks" ]]; then
  run_cmd "ln -s '$dst_dir' '$HOME/.local/dwmblocks'"
fi

auto_tmp_src=""
if [[ $do_build -eq 1 && -z "$dwmblocks_src" ]]; then
  auto_tmp_src="$(mktemp -d /tmp/dwmblocks-src.XXXXXX)"
  dwmblocks_src="$auto_tmp_src/dwmblocks"
  run_cmd "git clone '$repo_url' '$dwmblocks_src'"
fi

if [[ -n "$dwmblocks_src" ]]; then
  if [[ $dry_run -ne 1 && ! -d "$dwmblocks_src" ]]; then
    echo "dwmblocks source path not found: $dwmblocks_src" >&2
    exit 1
  fi

  if [[ -f "$dwmblocks_src/blocks.h" && $force -eq 1 ]]; then
    run_cmd "cp '$dwmblocks_src/blocks.h' '$dwmblocks_src/blocks.h.bak.$(date +%Y%m%d%H%M%S)'"
  fi

  run_cmd "cp '$dst_dir/blocks.def.h' '$dwmblocks_src/blocks.h'"

  if [[ $do_build -eq 1 ]]; then
    patch_dwmblocks_source_if_needed "$dwmblocks_src"
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

if [[ -n "$auto_tmp_src" ]]; then
  run_cmd "rm -rf '$auto_tmp_src'"
fi

echo "dwmblocks package deployed to $dst_dir"
