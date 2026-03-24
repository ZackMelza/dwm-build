#!/usr/bin/env bash
set -euo pipefail

find_terminal() {
  local candidate=""

  for candidate in \
    "${TERMINAL:-}" \
    kitty \
    /usr/bin/kitty \
    /usr/local/bin/kitty \
    /usr/sbin/kitty \
    /opt/kitty/bin/kitty \
    alacritty \
    /usr/bin/alacritty \
    st \
    /usr/bin/st \
    xterm \
    /usr/bin/xterm
  do
    [[ -n "$candidate" ]] || continue
    if command -v "$candidate" >/dev/null 2>&1; then
      printf '%s\n' "$candidate"
      return 0
    fi
    if [[ -x "$candidate" ]]; then
      printf '%s\n' "$candidate"
      return 0
    fi
  done

  return 1
}

if term="$(find_terminal)"; then
  :
elif command -v alacritty >/dev/null 2>&1; then
  term="alacritty"
elif command -v st >/dev/null 2>&1; then
  term="st"
elif command -v xterm >/dev/null 2>&1; then
  term="xterm"
else
  exit 1
fi

if [[ $# -eq 0 ]]; then
  exec "$term"
fi

exec "$term" -e "$@"
