#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bootstrap.sh [options]

One-shot bootstrap for fresh systems.

Options:
  --profile auto|laptop|desktop
  --display-manager lightdm|sddm|greetd|ly|none
  --dm-theme none|breeze|hyprlike
  --mode symlink|copy
  --enable-services
  --disable-services
  --non-interactive
  --dry-run
USAGE
}

profile=""
dm=""
dm_theme=""
mode=""
enable_services=""
interactive=1
dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile) profile="${2:-}"; shift 2 ;;
    --display-manager) dm="${2:-}"; shift 2 ;;
    --dm-theme) dm_theme="${2:-}"; shift 2 ;;
    --mode) mode="${2:-}"; shift 2 ;;
    --enable-services) enable_services=1; shift ;;
    --disable-services) enable_services=0; shift ;;
    --non-interactive) interactive=0; shift ;;
    --dry-run) dry_run=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown arg: $1" >&2; exit 1 ;;
  esac
done

script_path="${BASH_SOURCE[0]}"
if command -v readlink >/dev/null 2>&1; then
  resolved="$(readlink -f -- "$script_path" 2>/dev/null || true)"
  [[ -n "$resolved" ]] && script_path="$resolved"
fi
repo_root="$(cd -- "$(dirname -- "$script_path")/.." && pwd)"

if [[ -t 1 ]]; then
  C_RESET=$'\033[0m'
  C_BOLD=$'\033[1m'
  C_BLUE=$'\033[34m'
  C_GREEN=$'\033[32m'
  C_YELLOW=$'\033[33m'
else
  C_RESET=""
  C_BOLD=""
  C_BLUE=""
  C_GREEN=""
  C_YELLOW=""
fi

print_banner() {
  printf '%s%sDWM Bootstrap (Xorg-first)%s\n' "$C_BOLD" "$C_BLUE" "$C_RESET"
  printf '%sRepository:%s %s\n' "$C_BOLD" "$C_RESET" "$repo_root"
}

print_step() {
  printf '%s[%s]%s %s\n' "$C_BLUE" "$1" "$C_RESET" "$2"
}

print_ok() {
  printf '%s%s%s\n' "$C_GREEN" "$1" "$C_RESET"
}

print_warn() {
  printf '%s%s%s\n' "$C_YELLOW" "$1" "$C_RESET" >&2
}

run_cmd() {
  if [[ $dry_run -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    eval "$*"
  fi
}

run_root() {
  if [[ $dry_run -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
    return 0
  fi
  if [[ $EUID -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    print_warn "Need root or sudo: $*"
    return 1
  fi
}

is_arch_like() {
  if [[ ! -f /etc/os-release ]]; then
    return 1
  fi
  # shellcheck disable=SC1091
  source /etc/os-release
  case "${ID:-}" in
    arch|endeavouros|manjaro) return 0 ;;
  esac
  [[ "${ID_LIKE:-}" == *"arch"* ]]
}

ensure_paru_arch() {
  if ! is_arch_like; then
    return 0
  fi
  if command -v paru >/dev/null 2>&1; then
    return 0
  fi

  if [[ $EUID -eq 0 ]]; then
    print_warn "Run bootstrap as a regular user (not root) so paru can be built."
    exit 1
  fi

  print_step "paru" "paru not found; installing paru (AUR helper)"
  run_root pacman -S --needed --noconfirm base-devel git

  local build_dir
  build_dir="$(mktemp -d /tmp/paru-build.XXXXXX)"

  if [[ $dry_run -eq 1 ]]; then
    echo "[dry-run] git clone https://aur.archlinux.org/paru.git '$build_dir/paru'"
    echo "[dry-run] (cd '$build_dir/paru' && makepkg -si --noconfirm)"
    echo "[dry-run] rm -rf '$build_dir'"
    return 0
  fi

  git clone https://aur.archlinux.org/paru.git "$build_dir/paru"
  (
    cd "$build_dir/paru"
    makepkg -si --noconfirm
  )
  rm -rf "$build_dir"
  print_ok "paru installed."
}

menu_select() {
  local title="$1"
  local default_index="$2"
  shift 2
  local options=("$@")
  local answer

  printf '%s%s%s\n' "$C_BOLD" "$title" "$C_RESET" >&2
  for i in "${!options[@]}"; do
    printf '  %d) %s\n' "$((i + 1))" "${options[$i]}" >&2
  done

  while true; do
    read -r -p "Choose [${default_index}]: " answer
    if [[ -z "$answer" ]]; then
      answer="$default_index"
    fi
    if [[ "$answer" =~ ^[0-9]+$ ]] && (( answer >= 1 && answer <= ${#options[@]} )); then
      printf '%s' "${options[$((answer - 1))]}"
      return 0
    fi
    print_warn "Invalid choice. Enter a number between 1 and ${#options[@]}." >&2
  done
}

if [[ $interactive -eq 1 && -t 0 ]]; then
  [[ -z "$profile" ]] && profile="$(menu_select "Profile" 1 auto laptop desktop)"
  [[ -z "$dm" ]] && dm="$(menu_select "Display Manager" 1 sddm lightdm greetd ly none)"
  [[ -z "$dm_theme" ]] && dm_theme="$(menu_select "DM Theme" 2 none breeze hyprlike)"
  [[ -z "$mode" ]] && mode="$(menu_select "Deploy Mode" 1 symlink copy)"
  if [[ -z "$enable_services" ]]; then
    ans="$(menu_select "Enable Services" 1 yes no)"
    [[ "$ans" == "yes" ]] && enable_services=1 || enable_services=0
  fi
else
  [[ -z "$profile" ]] && profile="auto"
  [[ -z "$dm" ]] && dm="sddm"
  [[ -z "$dm_theme" ]] && dm_theme="breeze"
  [[ -z "$mode" ]] && mode="symlink"
  [[ -z "$enable_services" ]] && enable_services=1
fi

case "$profile" in
  auto|laptop|desktop) ;;
  *) echo "Invalid profile: $profile" >&2; exit 1 ;;
esac
case "$dm" in
  sddm|lightdm|greetd|ly|none) ;;
  *) echo "Invalid display manager: $dm" >&2; exit 1 ;;
esac
case "$dm_theme" in
  none|breeze|hyprlike) ;;
  *) echo "Invalid dm theme: $dm_theme" >&2; exit 1 ;;
esac
case "$mode" in
  symlink|copy) ;;
  *) echo "Invalid mode: $mode" >&2; exit 1 ;;
esac

if [[ "$dm" == "none" ]]; then
  dm_theme="none"
fi

print_banner
print_step "config" "Selected profile=$profile dm=$dm dm_theme=$dm_theme mode=$mode enable_services=$enable_services interactive=$interactive"

print_step "preflight" "Checking AUR helper (Arch-like systems)"
ensure_paru_arch

extra_install=""
extra_post=""

if [[ "$profile" != "auto" ]]; then
  extra_install+=" --profile '$profile'"
  extra_post+=" --profile '$profile'"
fi
if [[ "$enable_services" == "1" ]]; then
  extra_install+=" --enable-services"
fi
if [[ $dry_run -eq 1 ]]; then
  extra_install+=" --dry-run"
  extra_post+=" --dry-run"
fi

print_step "install" "Installing packages, building DWM, and deploying base stack"
# shellcheck disable=SC2086
run_cmd "DWM_REPO_ROOT='$repo_root' bash -c '\"$repo_root/scripts/install-dwm-stack.sh\" --display-manager \"$dm\" --dm-theme \"$dm_theme\" --install-xinitrc --install-session $extra_install'"
print_step "post" "Applying user config, rofi/shell setup, and rebuild"
# shellcheck disable=SC2086
run_cmd "DWM_REPO_ROOT='$repo_root' bash -c '\"$repo_root/scripts/post-install.sh\" --mode \"$mode\" --force --setup-rofi --setup-shell --display-manager \"$dm\" --dm-theme \"$dm_theme\" --rebuild-dwm $extra_post'"

ensure_session_entry() {
  local session_file="/usr/share/xsessions/dwm.desktop"
  local wrapper="/usr/local/bin/dwm-session"

  install_wrapper() {
    if [[ $dry_run -eq 1 ]]; then
      echo "[dry-run] install $wrapper"
      return 0
    fi

    local tmpf
    tmpf="$(mktemp)"
    cat >"$tmpf" <<'WRAP'
#!/usr/bin/env sh
set -eu
LOG="${XDG_RUNTIME_DIR:-/tmp}/dwm-session.log"
export PATH="$HOME/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:$PATH"
export XDG_SESSION_TYPE=x11
export GDK_BACKEND=x11
export QT_QPA_PLATFORM=xcb
unset WAYLAND_DISPLAY
unset XDG_SESSION_DESKTOP
{
  echo "== $(date) =="
  echo "USER=$USER HOME=$HOME"
  echo "PATH=$PATH"
} >> "$LOG" 2>&1

if command -v dwm-autostart.sh >/dev/null 2>&1; then
  dwm-autostart.sh >> "$LOG" 2>&1 &
elif [ -x "$HOME/.local/bin/dwm-autostart.sh" ]; then
  "$HOME/.local/bin/dwm-autostart.sh" >> "$LOG" 2>&1 &
fi

DWM_BIN="$(command -v dwm 2>/dev/null || true)"
[ -z "$DWM_BIN" ] && [ -x /usr/local/bin/dwm ] && DWM_BIN=/usr/local/bin/dwm
[ -z "$DWM_BIN" ] && [ -x /usr/bin/dwm ] && DWM_BIN=/usr/bin/dwm

if [ -z "$DWM_BIN" ]; then
  echo "dwm binary not found" >> "$LOG"
  exit 127
fi

exec "$DWM_BIN" >> "$LOG" 2>&1
WRAP
    run_root install -m 755 "$tmpf" "$wrapper" || true
    rm -f "$tmpf"
  }

  if [[ $dry_run -eq 1 ]]; then
    echo "[dry-run] ensure $session_file exists"
    install_wrapper
    return 0
  fi

  install_wrapper

  if [[ ! -f "$session_file" ]]; then
    if ! run_root install -Dm644 "$repo_root/sessions/dwm.desktop" "$session_file"; then
      echo "Warning: missing $session_file and no sudo to install it." >&2
      return 0
    fi
  fi

  run_root sed -i "s|^Exec=.*|Exec=$wrapper|; s|^TryExec=.*|TryExec=$wrapper|" "$session_file" || true

  if [[ "$dm" == "sddm" ]]; then
    run_root install -d /etc/sddm.conf.d || true
    if [[ $dry_run -eq 1 ]]; then
      echo "[dry-run] write /etc/sddm.conf.d/00-displayserver.conf"
    else
      cat <<'CONF' | run_root tee /etc/sddm.conf.d/00-displayserver.conf >/dev/null || true
[General]
DisplayServer=x11
CONF
    fi
  fi
}

if [[ "$dm" != "none" ]]; then
  print_step "session" "Ensuring display-manager session wrapper and X11 settings"
  ensure_session_entry
fi

print_ok "Bootstrap complete."
echo "Next: reboot, select DWM in your display manager, and run ~/.local/bin/dwm-health-check.sh"
