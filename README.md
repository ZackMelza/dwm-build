# DWM Build

A portable, Xorg-first DWM setup that aims to feel close to your Hyprland workflow, but lighter for weaker hardware.

## What You Get

- one main installer (`scripts/bootstrap.sh`)
- distro-aware package install
- laptop/desktop auto-detection
- display manager support (`sddm`, `lightdm`, `greetd`, `ly`, or none)
- `kitty` + `zsh` defaults
- rofi tools (`RofiBeats`, search, calc, theme pickers)
- `dwmblocks` build + config deployment
- lightweight tray (`stalonetray`) autostart
- profile-based autostart behavior

## Quick Start (Recommended)

From a fresh system:

```bash
./scripts/bootstrap.sh
```

The bootstrap script is interactive and asks for numbered choices.

After install:

1. Reboot.
2. In your display manager, select `DWM` session.
3. Log in.
4. Run health check:

```bash
~/.local/bin/dwm-health-check.sh
```

## Non-Interactive Example

```bash
./scripts/bootstrap.sh \
  --non-interactive \
  --profile auto \
  --display-manager sddm \
  --dm-theme breeze \
  --mode copy \
  --enable-services
```

## Start Session

- Display manager: choose `DWM` at login.
- `startx`: install `~/.xinitrc` and run `startx`.

## Keybind Highlights

- `Super+H`: show keybind cheat-sheet
- `Super+R`: rofi launcher
- `Super+S`: rofi web search
- `Super+Alt+C`: rofi calc
- `Super+Shift+M`: RofiBeats
- `Super+Q`: kill focused window
- `Ctrl+Alt+L`: lock session
- `Super+Shift+S`: area screenshot
- `Super+Print`: full screenshot
- `Super+Shift+J/K`: move focused window in stack
- `Super+[ / ]`: previous/next tag
- `Super+Shift+[ / ]`: move focused window to previous/next tag

## Main Scripts

### `scripts/bootstrap.sh`
The primary entrypoint. Use this unless you explicitly want manual control.

Options:

- `--profile auto|laptop|desktop`
- `--display-manager lightdm|sddm|greetd|ly|none`
- `--dm-theme none|breeze|hyprlike`
- `--mode symlink|copy`
- `--enable-services`
- `--disable-services`
- `--non-interactive`
- `--dry-run`

### `scripts/install-dwm-stack.sh`
Installs packages, builds DWM, installs helper scripts.

### `scripts/post-install.sh`
Deploys user files and optional extras (`rofi`, `shell`, `dm-theme`, rebuild).

### `scripts/setup-dwmblocks.sh`
Deploys `dwmblocks` config and can build/install `dwmblocks`.

### `scripts/fix-dwm-login.sh`
Repair helper when display manager login/session setup breaks.

### `scripts/health-check.sh`
Checks required binaries/files and reports what is missing.

## Manual Install (Advanced)

Step 1:

```bash
./scripts/install-dwm-stack.sh \
  --display-manager sddm \
  --dm-theme breeze \
  --install-xinitrc \
  --install-session \
  --enable-services \
  --backup
```

Step 2:

```bash
./scripts/post-install.sh \
  --mode copy \
  --force \
  --setup-rofi \
  --setup-shell \
  --display-manager sddm \
  --dm-theme breeze \
  --rebuild-dwm \
  --backup
```

## Xorg + Compatibility Notes

- Stack is configured for X11 (`XDG_SESSION_TYPE=x11`, `GDK_BACKEND=x11`, `QT_QPA_PLATFORM=xcb`).
- SDDM is forced to `DisplayServer=x11`.
- On Arch-like distros, bootstrap auto-installs `paru` if missing.
- For old GPUs, use `--dm-theme breeze` for safest DM behavior.

## Troubleshooting

### Black screen after login

Run from TTY:

```bash
./scripts/fix-dwm-login.sh
```

Then reboot and try DWM session again.

### Missing command/file errors

Run:

```bash
~/.local/bin/dwm-health-check.sh
```

Install/re-run bootstrap until required items are `[OK]`.

### Dry-run before applying changes

```bash
./scripts/bootstrap.sh --dry-run
```

## Uninstall

```bash
./scripts/uninstall-dwm-stack.sh --dry-run
```

Then remove `--dry-run` when you are ready.
