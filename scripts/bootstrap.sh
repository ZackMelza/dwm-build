#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: bootstrap.sh [options]

One-shot bootstrap for fresh systems.

Options:
  --profile auto|laptop|desktop
  --display-manager lightdm|sddm|greetd|ly|none
  --dm-theme none|hyprlike
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
    echo "Need root or sudo: $*" >&2
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
    echo "Run bootstrap as a regular user (not root) so paru can be built." >&2
    exit 1
  fi

  echo "paru not found; installing paru (AUR helper)..."
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
}

prompt_with_default() {
  local label="$1"
  local default="$2"
  local value
  read -r -p "$label [$default]: " value
  if [[ -z "$value" ]]; then
    printf '%s' "$default"
  else
    printf '%s' "$value"
  fi
}

if [[ $interactive -eq 1 && -t 0 ]]; then
  [[ -z "$profile" ]] && profile="$(prompt_with_default "Profile (auto/laptop/desktop)" "auto")"
  [[ -z "$dm" ]] && dm="$(prompt_with_default "Display manager (sddm/lightdm/greetd/ly/none)" "sddm")"
  [[ -z "$dm_theme" ]] && dm_theme="$(prompt_with_default "DM theme (none/hyprlike)" "none")"
  [[ -z "$mode" ]] && mode="$(prompt_with_default "Deploy mode (symlink/copy)" "symlink")"
  if [[ -z "$enable_services" ]]; then
    ans="$(prompt_with_default "Enable services" "yes")"
    case "$ans" in
      y|Y|yes|YES|true|1) enable_services=1 ;;
      *) enable_services=0 ;;
    esac
  fi
else
  [[ -z "$profile" ]] && profile="auto"
  [[ -z "$dm" ]] && dm="sddm"
  [[ -z "$dm_theme" ]] && dm_theme="none"
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
  none|hyprlike) ;;
  *) echo "Invalid dm theme: $dm_theme" >&2; exit 1 ;;
esac
case "$mode" in
  symlink|copy) ;;
  *) echo "Invalid mode: $mode" >&2; exit 1 ;;
esac

if [[ "$dm" == "none" ]]; then
  dm_theme="none"
fi

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

# shellcheck disable=SC2086
run_cmd "DWM_REPO_ROOT='$repo_root' bash -c '\"$repo_root/scripts/install-dwm-stack.sh\" --display-manager \"$dm\" --dm-theme \"$dm_theme\" --install-xinitrc --install-session $extra_install'"
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

  if [[ "$dm" == "sddm" ]] && command -v lspci >/dev/null 2>&1 && lspci | grep -qi nvidia; then
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
  ensure_session_entry
fi

echo "Bootstrap complete."
