#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: setup-shell-suite.sh [--mode symlink|copy] [--force] [--backup] [--dry-run]

Installs kitty + zsh shell defaults close to the Hyprland setup.
USAGE
}

mode="symlink"
force=0
backup=0
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
    --backup)
      backup=1
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
  local src="$1" dst="$2" is_dir="${3:-0}"

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
      return 0
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

script_path="${BASH_SOURCE[0]}"
if command -v readlink >/dev/null 2>&1; then
  resolved="$(readlink -f -- "$script_path" 2>/dev/null || true)"
  [[ -n "$resolved" ]] && script_path="$resolved"
fi
repo_root="$(cd -- "$(dirname -- "$script_path")/.." && pwd)"

run_cmd "mkdir -p '$HOME/.config'"
link_or_copy "$repo_root/kitty" "$HOME/.config/kitty" 1
link_or_copy "$repo_root/shell/zshrc" "$HOME/.zshrc"

if [[ ! -d "$HOME/.oh-my-zsh" ]] && command -v git >/dev/null 2>&1; then
  run_cmd "git clone --depth=1 https://github.com/ohmyzsh/ohmyzsh.git '$HOME/.oh-my-zsh'"
fi

if [[ -d "$HOME/.oh-my-zsh" ]]; then
  run_cmd "mkdir -p '$HOME/.oh-my-zsh/custom/plugins'"
  if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions" ]] && command -v git >/dev/null 2>&1; then
    run_cmd "git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions '$HOME/.oh-my-zsh/custom/plugins/zsh-autosuggestions'"
  fi
  if [[ ! -d "$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting" ]] && command -v git >/dev/null 2>&1; then
    run_cmd "git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting '$HOME/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting'"
  fi

  if [[ -f "$repo_root/shell/themes/agnosterzak.zsh-theme" ]]; then
    run_cmd "install -Dm644 '$repo_root/shell/themes/agnosterzak.zsh-theme' '$HOME/.oh-my-zsh/themes/agnosterzak.zsh-theme'"
  fi
fi

echo "Shell suite installed (kitty + zsh)."
