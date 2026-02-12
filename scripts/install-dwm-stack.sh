#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'USAGE'
Usage: install-dwm-stack.sh [options]

Installs a portable DWM stack with distro-aware package selection.

Options:
  --profile laptop|desktop    Force machine profile (default: auto detect)
  --display-manager NAME      Set login manager: lightdm|sddm|greetd|ly|none
  --dm-theme NAME             Login theme: none|hyprlike (for sddm/lightdm)
  --backup                    Backup files before overwrite where supported
  --enable-services           Enable common services (NetworkManager, bluetooth, display manager)
  --install-xinitrc           Install repo xinitrc to ~/.xinitrc
  --install-session           Install sessions/dwm.desktop into /usr/share/xsessions (sudo required)
  --dry-run                   Print commands without executing
  -h, --help                  Show this help
USAGE
}

profile=""
display_manager="none"
dm_theme="none"
backup=0
enable_services=0
install_xinitrc=0
install_session=0
dry_run=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)
      profile="${2:-}"
      shift 2
      ;;
    --display-manager)
      display_manager="${2:-}"
      shift 2
      ;;
    --dm-theme)
      dm_theme="${2:-}"
      shift 2
      ;;
    --backup)
      backup=1
      shift
      ;;
    --enable-services)
      enable_services=1
      shift
      ;;
    --install-xinitrc)
      install_xinitrc=1
      shift
      ;;
    --install-session)
      install_session=1
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

detect_profile() {
  local chassis=""
  if command -v hostnamectl >/dev/null 2>&1; then
    chassis="$(hostnamectl chassis 2>/dev/null || true)"
    case "$chassis" in
      laptop|desktop)
        echo "$chassis"
        return 0
        ;;
    esac
  fi

  if compgen -G "/sys/class/power_supply/BAT*" >/dev/null; then
    echo "laptop"
  else
    echo "desktop"
  fi
}

run_cmd() {
  if [[ $dry_run -eq 1 ]]; then
    printf '[dry-run] %s\n' "$*"
  else
    eval "$*"
  fi
}

require_sudo() {
  if [[ $EUID -eq 0 ]]; then
    SUDO=""
  elif command -v sudo >/dev/null 2>&1; then
    SUDO="sudo"
  else
    echo "Need root privileges or sudo for package installation." >&2
    exit 1
  fi
}

if [[ -z "$profile" ]]; then
  profile="$(detect_profile)"
fi

if [[ "$profile" != "laptop" && "$profile" != "desktop" ]]; then
  echo "Invalid profile: $profile" >&2
  exit 1
fi

if [[ "$display_manager" != "lightdm" && "$display_manager" != "sddm" && "$display_manager" != "greetd" && "$display_manager" != "ly" && "$display_manager" != "none" ]]; then
  echo "Invalid display manager: $display_manager" >&2
  exit 1
fi

if [[ "$dm_theme" != "none" && "$dm_theme" != "hyprlike" ]]; then
  echo "Invalid dm theme: $dm_theme" >&2
  exit 1
fi

if [[ ! -f /etc/os-release ]]; then
  echo "/etc/os-release not found; distro detection failed." >&2
  exit 1
fi

# shellcheck disable=SC1091
source /etc/os-release
os_id="${ID:-unknown}"
os_like="${ID_LIKE:-}"

script_path="${BASH_SOURCE[0]}"
if command -v readlink >/dev/null 2>&1; then
  resolved="$(readlink -f -- "$script_path" 2>/dev/null || true)"
  [[ -n "$resolved" ]] && script_path="$resolved"
fi
repo_root="$(cd -- "$(dirname -- "$script_path")/.." && pwd)"

common_pkgs_arch="base-devel git pkgconf libx11 libxft libxinerama xorg-server xorg-xinit xorg-xrandr xorg-xsetroot xorg-setxkbmap feh picom dmenu kitty zsh zsh-autosuggestions zsh-syntax-highlighting fzf rofi dunst network-manager-applet blueman pipewire pipewire-pulse wireplumber pavucontrol playerctl brightnessctl acpi polkit-gnome xdg-user-dirs maim xclip mpv yt-dlp socat"
common_pkgs_debian="build-essential git pkg-config libx11-dev libxft-dev libxinerama-dev xorg xinit x11-xserver-utils feh picom dmenu suckless-tools kitty zsh zsh-autosuggestions zsh-syntax-highlighting fzf rofi dunst network-manager-gnome network-manager blueman pipewire wireplumber pavucontrol playerctl brightnessctl acpi policykit-1-gnome xdg-user-dirs maim xclip mpv yt-dlp socat"
common_pkgs_fedora="gcc make git pkgconf-pkg-config libX11-devel libXft-devel libXinerama-devel xorg-x11-server-Xorg xorg-x11-xinit xrandr xsetroot setxkbmap feh picom dmenu kitty zsh zsh-autosuggestions zsh-syntax-highlighting fzf rofi dunst NetworkManager-applet NetworkManager-tui blueman pipewire wireplumber pavucontrol playerctl brightnessctl acpi policycoreutils-python-utils polkit-gnome xdg-user-dirs maim xclip mpv yt-dlp socat"
common_pkgs_opensuse="gcc make git pkg-config libX11-devel libXft-devel libXinerama-devel xorg-x11-server xinit xrandr xsetroot setxkbmap feh picom dmenu kitty zsh zsh-autosuggestions zsh-syntax-highlighting fzf rofi dunst NetworkManager-applet NetworkManager-tui blueman pipewire wireplumber pavucontrol playerctl brightnessctl acpi polkit-gnome xdg-user-dirs maim xclip mpv yt-dlp socat"

laptop_pkgs_arch="tlp tlp-rdw"
laptop_pkgs_debian="tlp"
laptop_pkgs_fedora="tlp"
laptop_pkgs_opensuse="tlp"

require_sudo

install_with_arch() {
  local pkgs="$1"
  run_cmd "$SUDO pacman -Syu --needed --noconfirm $pkgs"
}

install_with_apt() {
  local pkgs="$1"
  run_cmd "$SUDO apt update"
  run_cmd "$SUDO apt install -y $pkgs"
}

install_with_dnf() {
  local pkgs="$1"
  run_cmd "$SUDO dnf install -y $pkgs"
}

install_with_zypper() {
  local pkgs="$1"
  run_cmd "$SUDO zypper --non-interactive refresh"
  run_cmd "$SUDO zypper --non-interactive install --no-recommends $pkgs"
}

enable_service() {
  local svc="$1"
  run_cmd "$SUDO systemctl enable $svc"
}

install_display_manager() {
  case "$display_manager" in
    none)
      return 0
      ;;
    lightdm)
      case "$pkg_family" in
        arch) run_cmd "$SUDO pacman -S --needed --noconfirm lightdm lightdm-gtk-greeter" ;;
        debian) run_cmd "$SUDO apt install -y lightdm lightdm-gtk-greeter" ;;
        fedora) run_cmd "$SUDO dnf install -y lightdm lightdm-gtk" ;;
        opensuse) run_cmd "$SUDO zypper --non-interactive install --no-recommends lightdm lightdm-gtk-greeter" ;;
      esac
      dm_service="lightdm"
      ;;
    sddm)
      case "$pkg_family" in
        arch) run_cmd "$SUDO pacman -S --needed --noconfirm sddm" ;;
        debian) run_cmd "$SUDO apt install -y sddm" ;;
        fedora) run_cmd "$SUDO dnf install -y sddm" ;;
        opensuse) run_cmd "$SUDO zypper --non-interactive install --no-recommends sddm" ;;
      esac
      dm_service="sddm"
      ;;
    greetd)
      case "$pkg_family" in
        arch) run_cmd "$SUDO pacman -S --needed --noconfirm greetd tuigreet" ;;
        debian) run_cmd "$SUDO apt install -y greetd tuigreet" ;;
        fedora) run_cmd "$SUDO dnf install -y greetd tuigreet" ;;
        opensuse) run_cmd "$SUDO zypper --non-interactive install --no-recommends greetd tuigreet" ;;
      esac
      dm_service="greetd"
      ;;
    ly)
      case "$pkg_family" in
        arch) run_cmd "$SUDO pacman -S --needed --noconfirm ly" ;;
        debian) run_cmd "$SUDO apt install -y ly" ;;
        fedora) run_cmd "$SUDO dnf install -y ly" ;;
        opensuse) run_cmd "$SUDO zypper --non-interactive install --no-recommends ly" ;;
      esac
      dm_service="ly"
      ;;
  esac
}

pkg_family=""
case "$os_id" in
  arch|endeavouros|manjaro)
    pkg_family="arch"
    install_with_arch "$common_pkgs_arch"
    if [[ "$profile" == "laptop" ]]; then
      install_with_arch "$laptop_pkgs_arch"
    fi
    ;;
  ubuntu|debian|linuxmint|pop)
    pkg_family="debian"
    install_with_apt "$common_pkgs_debian"
    if [[ "$profile" == "laptop" ]]; then
      install_with_apt "$laptop_pkgs_debian"
    fi
    ;;
  fedora)
    pkg_family="fedora"
    install_with_dnf "$common_pkgs_fedora"
    if [[ "$profile" == "laptop" ]]; then
      install_with_dnf "$laptop_pkgs_fedora"
    fi
    ;;
  opensuse*|sles)
    pkg_family="opensuse"
    install_with_zypper "$common_pkgs_opensuse"
    if [[ "$profile" == "laptop" ]]; then
      install_with_zypper "$laptop_pkgs_opensuse"
    fi
    ;;
  *)
    if [[ "$os_like" == *"arch"* ]]; then
      pkg_family="arch"
      install_with_arch "$common_pkgs_arch"
      if [[ "$profile" == "laptop" ]]; then
        install_with_arch "$laptop_pkgs_arch"
      fi
    elif [[ "$os_like" == *"debian"* ]]; then
      pkg_family="debian"
      install_with_apt "$common_pkgs_debian"
      if [[ "$profile" == "laptop" ]]; then
        install_with_apt "$laptop_pkgs_debian"
      fi
    elif [[ "$os_like" == *"fedora"* || "$os_like" == *"rhel"* ]]; then
      pkg_family="fedora"
      install_with_dnf "$common_pkgs_fedora"
      if [[ "$profile" == "laptop" ]]; then
        install_with_dnf "$laptop_pkgs_fedora"
      fi
    elif [[ "$os_like" == *"suse"* ]]; then
      pkg_family="opensuse"
      install_with_zypper "$common_pkgs_opensuse"
      if [[ "$profile" == "laptop" ]]; then
        install_with_zypper "$laptop_pkgs_opensuse"
      fi
    else
      echo "Unsupported distro: ID=$os_id ID_LIKE=$os_like" >&2
      exit 1
    fi
    ;;
esac

run_cmd "make -C '$repo_root' clean"
run_cmd "'$repo_root/scripts/set-dwm-keybind-profile.sh' --profile '$profile'"
run_cmd "make -C '$repo_root'"
run_cmd "$SUDO make -C '$repo_root' install"
run_cmd "'$repo_root/scripts/set-dwm-profile.sh' --profile '$profile' --force"

run_cmd "mkdir -p '$HOME/.local/bin'"

install_to_user_bin() {
  local src="$1"
  local dst="$2"
  if [[ ! -e "$src" && ! -L "$src" ]]; then
    echo "Missing source path: $src" >&2
    exit 1
  fi
  run_cmd "mkdir -p '$(dirname "$dst")'"
  run_cmd "install -m 755 '$src' '$dst'"
}

install_to_user_bin "$repo_root/scripts/dwm-autostart.sh" "$HOME/.local/bin/dwm-autostart.sh"
install_to_user_bin "$repo_root/scripts/initial-boot.sh" "$HOME/.local/bin/initial-boot.sh"
install_to_user_bin "$repo_root/scripts/start-polkit-agent.sh" "$HOME/.local/bin/start-polkit-agent.sh"
install_to_user_bin "$repo_root/scripts/set-random-wallpaper.sh" "$HOME/.local/bin/set-random-wallpaper.sh"
install_to_user_bin "$repo_root/scripts/set-dwm-profile.sh" "$HOME/.local/bin/set-dwm-profile.sh"
install_to_user_bin "$repo_root/scripts/set-dwm-keybind-profile.sh" "$HOME/.local/bin/set-dwm-keybind-profile.sh"
install_to_user_bin "$repo_root/scripts/rebuild-dwm-profile.sh" "$HOME/.local/bin/rebuild-dwm-profile.sh"
install_to_user_bin "$repo_root/scripts/dwm-power-menu.sh" "$HOME/.local/bin/dwm-power-menu.sh"
install_to_user_bin "$repo_root/scripts/post-install.sh" "$HOME/.local/bin/post-install.sh"
install_to_user_bin "$repo_root/scripts/setup-dwmblocks.sh" "$HOME/.local/bin/setup-dwmblocks.sh"
install_to_user_bin "$repo_root/scripts/setup-rofi-suite.sh" "$HOME/.local/bin/setup-rofi-suite.sh"
install_to_user_bin "$repo_root/scripts/setup-shell-suite.sh" "$HOME/.local/bin/setup-shell-suite.sh"
install_to_user_bin "$repo_root/scripts/rofi/rofi-beats.sh" "$HOME/.local/bin/rofi-beats.sh"
install_to_user_bin "$repo_root/scripts/rofi/rofi-search.sh" "$HOME/.local/bin/rofi-search.sh"
install_to_user_bin "$repo_root/scripts/rofi/rofi-calc.sh" "$HOME/.local/bin/rofi-calc.sh"
install_to_user_bin "$repo_root/scripts/rofi/rofi-zsh-theme.sh" "$HOME/.local/bin/rofi-zsh-theme.sh"
install_to_user_bin "$repo_root/scripts/rofi/rofi-kitty-theme.sh" "$HOME/.local/bin/rofi-kitty-theme.sh"
install_to_user_bin "$repo_root/scripts/setup-display-manager-theme.sh" "$HOME/.local/bin/setup-display-manager-theme.sh"
install_to_user_bin "$repo_root/scripts/bootstrap.sh" "$HOME/.local/bin/dwm-bootstrap.sh"
install_to_user_bin "$repo_root/scripts/health-check.sh" "$HOME/.local/bin/dwm-health-check.sh"
install_to_user_bin "$repo_root/scripts/uninstall-dwm-stack.sh" "$HOME/.local/bin/dwm-uninstall.sh"
install_to_user_bin "$repo_root/scripts/generate-keybind-cheatsheet.sh" "$HOME/.local/bin/generate-keybind-cheatsheet.sh"
install_to_user_bin "$repo_root/scripts/show-keybinds.sh" "$HOME/.local/bin/show-keybinds.sh"
run_cmd "'$HOME/.local/bin/setup-dwmblocks.sh' --mode copy --force"
if [[ $backup -eq 1 ]]; then
  run_cmd "'$HOME/.local/bin/setup-rofi-suite.sh' --mode copy --force --backup"
else
  run_cmd "'$HOME/.local/bin/setup-rofi-suite.sh' --mode copy --force"
fi
if [[ $backup -eq 1 ]]; then
  run_cmd "'$HOME/.local/bin/setup-shell-suite.sh' --mode copy --force --backup"
else
  run_cmd "'$HOME/.local/bin/setup-shell-suite.sh' --mode copy --force"
fi

if [[ $install_xinitrc -eq 1 ]]; then
  if [[ ! -f "$repo_root/xinitrc" ]]; then
    echo "Missing source path: $repo_root/xinitrc" >&2
    exit 1
  fi
  if [[ -f "$HOME/.xinitrc" ]]; then
    run_cmd "cp '$HOME/.xinitrc' '$HOME/.xinitrc.bak.$(date +%Y%m%d%H%M%S)'"
  fi
  run_cmd "install -m 644 '$repo_root/xinitrc' '$HOME/.xinitrc'"
fi

if [[ $install_session -eq 1 ]]; then
  if [[ ! -f "$repo_root/sessions/dwm.desktop" ]]; then
    echo "Missing source path: $repo_root/sessions/dwm.desktop" >&2
    exit 1
  fi
  run_cmd "$SUDO install -Dm644 '$repo_root/sessions/dwm.desktop' /usr/share/xsessions/dwm.desktop"
fi

install_display_manager

if [[ "$dm_theme" != "none" && ( "$display_manager" == "sddm" || "$display_manager" == "lightdm" ) ]]; then
  if [[ $backup -eq 1 ]]; then
    run_cmd "'$HOME/.local/bin/setup-display-manager-theme.sh' --dm '$display_manager' --theme '$dm_theme' --backup"
  else
    run_cmd "'$HOME/.local/bin/setup-display-manager-theme.sh' --dm '$display_manager' --theme '$dm_theme'"
  fi
fi

install_optional_pkg() {
  local cmd_name="$1"
  local arch_pkg="$2"
  local deb_pkg="$3"
  local fed_pkg="$4"
  local suse_pkg="$5"
  local pkg_candidates=""

  if command -v "$cmd_name" >/dev/null 2>&1; then
    return 0
  fi

  case "$pkg_family" in
    arch) pkg_candidates="$arch_pkg" ;;
    debian) pkg_candidates="$deb_pkg" ;;
    fedora) pkg_candidates="$fed_pkg" ;;
    opensuse) pkg_candidates="$suse_pkg" ;;
  esac

  IFS='|' read -r -a candidates <<< "$pkg_candidates"
  for pkg in "${candidates[@]}"; do
    if [[ -z "$pkg" ]]; then
      continue
    fi
    if [[ $dry_run -eq 1 ]]; then
      case "$pkg_family" in
        arch) run_cmd "$SUDO pacman -S --needed --noconfirm $pkg" ;;
        debian) run_cmd "$SUDO apt install -y $pkg" ;;
        fedora) run_cmd "$SUDO dnf install -y $pkg" ;;
        opensuse) run_cmd "$SUDO zypper --non-interactive install --no-recommends $pkg" ;;
      esac
      return 0
    fi

    case "$pkg_family" in
      arch) $SUDO pacman -S --needed --noconfirm "$pkg" >/dev/null 2>&1 && return 0 ;;
      debian) $SUDO apt install -y "$pkg" >/dev/null 2>&1 && return 0 ;;
      fedora) $SUDO dnf install -y "$pkg" >/dev/null 2>&1 && return 0 ;;
      opensuse) $SUDO zypper --non-interactive install --no-recommends "$pkg" >/dev/null 2>&1 && return 0 ;;
    esac
  done

  echo "Optional package fallback failed for '$cmd_name'." >&2
}

install_optional_pkg qalc "qalculate-gtk|qalculate-qt" "qalc|qalculate-gtk" "qalculate-gtk|qalculate-qt" "qalculate|qalculate-qt"
install_optional_pkg nmtui "networkmanager|network-manager-applet" "network-manager" "NetworkManager-tui|NetworkManager" "NetworkManager-tui|NetworkManager"
install_optional_pkg arandr "arandr" "arandr" "arandr" "arandr"

if [[ $enable_services -eq 1 ]]; then
  enable_service NetworkManager
  if [[ $dry_run -eq 1 ]]; then
    enable_service bluetooth
    if [[ "$profile" == "laptop" ]]; then
      enable_service tlp
    fi
  else
    if systemctl list-unit-files | grep -q '^bluetooth\.service'; then
      enable_service bluetooth
    fi
    if [[ "$profile" == "laptop" ]] && systemctl list-unit-files | grep -q '^tlp\.service'; then
      enable_service tlp
    fi
  fi
  if [[ -n "${dm_service:-}" ]]; then
    enable_service "$dm_service"
  fi
fi

echo "DWM stack installation completed."
echo "Detected profile: $profile"
echo "Distro family: $pkg_family"
if [[ "$display_manager" != "none" ]]; then
  echo "Display manager selected: $display_manager"
fi
