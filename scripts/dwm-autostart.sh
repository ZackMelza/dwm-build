#!/usr/bin/env bash
set -euo pipefail

export PATH="$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"

run_once() {
  local name="$1"
  shift
  if command -v "$1" >/dev/null 2>&1; then
    if ! pgrep -u "$USER" -x "$name" >/dev/null 2>&1; then
      "$@" >/dev/null 2>&1 &
    fi
  fi
}

enabled() {
  local var_name="$1"
  local val="${!var_name:-1}"
  [[ "$val" == "1" || "$val" == "true" || "$val" == "yes" ]]
}

source_if_exists() {
  local file="$1"
  if [[ -f "$file" ]]; then
    # shellcheck disable=SC1090
    source "$file"
  fi
}

source_if_exists "$HOME/.config/environment.d/99-dwm.conf"
source_if_exists "$HOME/.config/dwm/host.conf"

script_path="${BASH_SOURCE[0]}"
if command -v readlink >/dev/null 2>&1; then
  resolved="$(readlink -f -- "$script_path" 2>/dev/null || true)"
  [[ -n "$resolved" ]] && script_path="$resolved"
fi
script_dir="$(cd -- "$(dirname -- "$script_path")" && pwd)"

"$script_dir/initial-boot.sh" || true

if command -v setxkbmap >/dev/null 2>&1; then
  setxkbmap -layout us,gr -variant , -option grp:alt_shift_toggle >/dev/null 2>&1 || true
fi

if [[ -x "$script_dir/set-random-wallpaper.sh" ]]; then
  "$script_dir/set-random-wallpaper.sh" >/dev/null 2>&1 || true
fi

if enabled DWM_AUTOSTART_WALLPAPER_ROTATION; then
  run_once wallpaper-rotator "$script_dir/wallpaper-rotator.sh"
fi

if enabled DWM_AUTOSTART_DUNST; then
  if command -v systemctl >/dev/null 2>&1; then
    if systemctl --user status dwm-dunst.service >/dev/null 2>&1; then
      systemctl --user start dwm-dunst.service >/dev/null 2>&1 || true
    fi
  fi
  run_once dunst dunst
fi

if enabled DWM_AUTOSTART_PICOM; then
  if [[ -x "$script_dir/start-picom.sh" ]]; then
    run_once picom "$script_dir/start-picom.sh"
  else
    run_once picom picom
  fi
fi

if enabled DWM_AUTOSTART_NM_APPLET; then
  run_once nm-applet nm-applet
fi

if enabled DWM_AUTOSTART_BLUEMAN; then
  run_once blueman-applet blueman-applet
fi

if enabled DWM_AUTOSTART_PASYSTRAY; then
  run_once pasystray pasystray
fi

if enabled DWM_AUTOSTART_DWMBLOCKS; then
  if command -v dwmblocks >/dev/null 2>&1; then
    run_once dwmblocks dwmblocks
  elif [[ -x /usr/local/bin/dwmblocks ]]; then
    run_once dwmblocks /usr/local/bin/dwmblocks
  elif [[ -x /usr/bin/dwmblocks ]]; then
    run_once dwmblocks /usr/bin/dwmblocks
  fi
fi

if enabled DWM_AUTOSTART_IDLE_MANAGER; then
  run_once idle-manager "$script_dir/idle-manager.sh"
fi

if ! pgrep -u "$USER" -f "polkit.*authentication-agent" >/dev/null 2>&1; then
  "$script_dir/start-polkit-agent.sh" >/dev/null 2>&1 & disown || true
fi
