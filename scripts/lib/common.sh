#!/usr/bin/env bash

resolve_repo_root() {
  local script_path="${1:-${BASH_SOURCE[1]:-${BASH_SOURCE[0]}}}"

  if [[ -n "${DWM_REPO_ROOT:-}" && -d "${DWM_REPO_ROOT}/scripts" ]]; then
    printf '%s\n' "$DWM_REPO_ROOT"
    return 0
  fi

  if [[ -f "$HOME/.config/dwm/repo_root" ]]; then
    sed -n '1p' "$HOME/.config/dwm/repo_root"
    return 0
  fi

  if command -v readlink >/dev/null 2>&1; then
    local resolved=""
    resolved="$(readlink -f -- "$script_path" 2>/dev/null || true)"
    [[ -n "$resolved" ]] && script_path="$resolved"
  fi

  cd -- "$(dirname -- "$script_path")/../.." && pwd
}

resolve_zsh_shell() {
  local shell_path=""

  for shell_path in /usr/bin/zsh /bin/zsh "$(command -v zsh 2>/dev/null || true)"; do
    [[ -n "$shell_path" ]] || continue
    if [[ -x "$shell_path" ]]; then
      printf '%s\n' "$shell_path"
      return 0
    fi
  done

  return 1
}
