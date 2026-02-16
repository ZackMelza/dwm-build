# DWM Build

This repo gives you a portable, profile-aware DWM setup with:

- distro-aware package installation
- laptop/desktop detection
- profile-based DWM build + runtime config
- Xorg-only session defaults (no Wayland dependency)
- Hypr-like rofi tooling (RofiBeats/search/calc)
- kitty terminal + zsh shell defaults (Oh My Zsh compatible)
- optional SDDM/LightDM theming
- dwmblocks package + scripts
- bootstrap, health-check, and uninstall helpers

## Fast Start (Recommended)

Run one command on a fresh system:

```bash
./scripts/bootstrap.sh
```

What this does (single entrypoint):

1. Installs packages and builds/installs DWM.
2. Deploys user config/scripts.
3. Sets profile and rebuilds DWM for that profile.
4. Installs rofi suite and (optionally) DM theme.

## Manual Setup (Optional Advanced)

### 1) Install packages + DWM

```bash
./scripts/install-dwm-stack.sh --display-manager sddm --dm-theme breeze --install-xinitrc --install-session --enable-services --backup
```

### 2) Deploy user config and extras

```bash
./scripts/post-install.sh --mode symlink --force --setup-rofi --setup-shell --display-manager sddm --dm-theme breeze --rebuild-dwm --backup
```

## Start DWM

- With display manager: choose `DWM` at login.
- With `startx`: run `startx` (after installing `~/.xinitrc`).

## Keybind Highlights

- `Super+H`: keybind cheat-sheet
- `Super+R`: rofi launcher
- `Super+S`: rofi web search
- `Super+Alt+C`: rofi calc
- `Super+Shift+M`: RofiBeats
- `Super+Q`: close/kill focused app
- `Ctrl+Alt+L`: lock session
- `Super+Shift+O`: rofi zsh theme picker
- `Super+Shift+T`: rofi kitty theme picker
- `Super+Shift+S`: screenshot area
- `Super+Print`: full screenshot

## Script Reference

### `scripts/bootstrap.sh`
One-shot installer for fresh systems. This is the main script that runs full configuration.

Options:

- Prompts interactively by default for profile/DM/theme/mode/services
- `--profile auto|laptop|desktop`: force machine profile
- `--display-manager lightdm|sddm|greetd|ly|none`: login manager to set up
- `--dm-theme none|breeze|hyprlike`: apply DM theme preset (`breeze` recommended for compatibility)
- `--mode symlink|copy`: deployment mode for post-install files
- `--enable-services`: enable NetworkManager/bluetooth/tlp/DM when available
- `--disable-services`: skip service enablement
- `--non-interactive`: skip prompts and use flags/defaults
- `--dry-run`: print actions without applying changes

### `scripts/install-dwm-stack.sh`
Installs dependencies, builds DWM, installs helper scripts.

Options:

- `--profile laptop|desktop`: force profile (default is auto-detect)
- `--display-manager NAME`: `lightdm|sddm|greetd|ly|none`
- `--dm-theme NAME`: `none|breeze|hyprlike` (used for `sddm`/`lightdm`)
- `--backup`: keep timestamped backups before overwrite where supported
- `--enable-services`: enable core services
- `--install-xinitrc`: install repo `xinitrc` to `~/.xinitrc`
- `--install-session`: install `sessions/dwm.desktop` to `/usr/share/xsessions`
- `--dry-run`: print commands only
- `-h, --help`: show help

### `scripts/post-install.sh`
Deploys user-level files, profile config, optional rofi/theme, optional rebuild.

Options:

- `--mode symlink|copy`: symlink from repo, or copy files into home
- `--profile laptop|desktop`: force profile while configuring
- `--install-session`: install X session desktop entry
- `--setup-rofi`: install rofi suite
- `--setup-shell`: install kitty + zsh suite
- `--display-manager NAME`: `lightdm|sddm` (required if using `--dm-theme`)
- `--dm-theme breeze|hyprlike`: apply DM theme
- `--rebuild-dwm`: rebuild/install DWM after deployment
- `--backup`: backup target files before overwrite
- `--force`: overwrite existing files/links
- `--dry-run`: print actions only
- `-h, --help`: show help

### `scripts/rebuild-dwm-profile.sh`
Applies profile + keybind profile, rebuilds DWM, installs DWM.

Options:

- `--profile laptop|desktop`: force profile
- `--dry-run`: print actions only
- `--no-install`: build only, skip `make install`
- `-h, --help`: show help

### `scripts/setup-rofi-suite.sh`
Installs the full `rofi/` directory and rofi helper scripts.

Options:

- `--mode symlink|copy`: deploy by symlink or copy
- `--force`: replace existing files
- `--backup`: move existing targets to timestamped backup before replace
- `--dry-run`: print actions only

### `scripts/setup-shell-suite.sh`
Installs kitty config and zsh defaults (Oh My Zsh + agnosterzak theme compatibility).

Options:

- `--mode symlink|copy`: deploy by symlink or copy
- `--force`: replace existing files
- `--backup`: move existing targets to timestamped backup before replace
- `--dry-run`: print actions only

### `scripts/setup-display-manager-theme.sh`
Applies login screen theme config.

Options:

- `--dm sddm|lightdm`: target display manager
- `--theme breeze|hyprlike`: theme preset
- `--backup`: backup old DM config/theme before overwrite
- `--dry-run`: print actions only

### `scripts/setup-dwmblocks.sh`
Deploys `dwmblocks` config package; can also build/install dwmblocks.

Options:

- `--mode symlink|copy`: deploy mode
- `--dwmblocks-src PATH`: local dwmblocks source tree path
- `--build`: build/install dwmblocks in that source tree
- `--force`: overwrite existing targets
- `--dry-run`: print actions only
- `-h, --help`: show help

### `scripts/health-check.sh`
Verifies required commands/files and reports missing parts.

Usage:

```bash
./scripts/health-check.sh
```

### `scripts/uninstall-dwm-stack.sh`
Removes deployed user-side stack and optional DM/session changes.

Options:

- `--restore-backups`: restore latest backup copies where present
- `--remove-session`: remove `/usr/share/xsessions/dwm.desktop`
- `--dm sddm|lightdm|none`: remove DM theme config for selected DM
- `--dry-run`: print actions only

## Profile Commands

```bash
./scripts/set-dwm-profile.sh --profile laptop --force
./scripts/set-dwm-keybind-profile.sh --profile laptop
./scripts/rebuild-dwm-profile.sh --profile laptop
```

Use `desktop` instead of `laptop` when needed.

## Useful Checks

Dry-run before changes:

```bash
./scripts/install-dwm-stack.sh --dry-run --display-manager sddm --dm-theme breeze --install-xinitrc --install-session --enable-services
./scripts/post-install.sh --dry-run --mode symlink --force --setup-rofi --setup-shell --display-manager sddm --dm-theme breeze --rebuild-dwm
```

## Xorg Compatibility

- Session environment is forced to X11 (`XDG_SESSION_TYPE=x11`, `GDK_BACKEND=x11`, `QT_QPA_PLATFORM=xcb`).
- SDDM is forced to `DisplayServer=x11`.
- On Arch-like systems, bootstrap installs `paru` automatically if missing.
- For maximum display-manager stability on old GPUs, prefer `--dm-theme breeze`.

## Notes

- Use `scripts/bootstrap.sh` as the only required entrypoint.
- Other scripts are internal helpers and optional for advanced/manual control.
