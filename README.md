# DWM Build

This repo is a portable, Xorg-first `dwm` setup aimed at people who want a lighter desktop without giving up the creature comforts of a more customized environment.

It includes:

- a bootstrap installer
- package installation for several distros
- laptop and desktop profiles
- display manager integration
- `rofi`, `kitty`, and `zsh` setup
- `dwmblocks` config and build helpers
- autostart scripts for wallpaper, tray, notifications, and session services

## What This Is For

Use this if you want a full `dwm` stack, not just a bare window manager binary.

The repo tries to give you:

- a usable first login
- sane X11 defaults
- helper scripts that are installed into `~/.local/bin`
- a repeatable way to rebuild the setup after profile or config changes

## Recommended Install

For most people, this is the only command that matters:

```bash
./scripts/bootstrap.sh
```

The bootstrap script is interactive. It will walk you through profile choice, display manager choice, install mode, and optional service setup.

After installation:

1. Reboot.
2. Select the `DWM` session in your display manager, or start it with `startx`.
3. Log in.
4. Run:

```bash
~/.local/bin/dwm-health-check.sh
```

That health check will tell you what is still missing on the machine.

## Non-Interactive Example

If you want to script the install:

```bash
./scripts/bootstrap.sh \
  --non-interactive \
  --profile auto \
  --display-manager sddm \
  --dm-theme breeze \
  --mode copy \
  --enable-services
```

## Session Startup

You have two normal ways to start it:

- Through a display manager: choose `DWM` at login
- Through `startx`: install `~/.xinitrc`, then run `startx`

The stack is designed for X11. It sets:

- `XDG_SESSION_TYPE=x11`
- `GDK_BACKEND=x11`
- `QT_QPA_PLATFORM=xcb`

## Keybind Highlights

- `Super+Return`: terminal
- `Super+R`: app launcher
- `Super+B`: browser
- `Super+E`: file manager
- `Super+C`: editor
- `Super+S`: web search
- `Super+Alt+C`: calculator
- `Super+Shift+M`: RofiBeats
- `Super+H`: keybind help
- `Super+Q`: kill focused window
- `Ctrl+Alt+L`: lock session
- `Super+Shift+S`: area screenshot
- `Super+Print`: full screenshot
- `Super+Shift+J` / `Super+Shift+K`: move focused client in stack
- `Super+[` / `Super+]`: move between tags
- `Super+Shift+[` / `Super+Shift+]`: send focused client to previous or next tag

## Main Scripts

### `scripts/bootstrap.sh`

Primary entry point. Use this unless you have a good reason not to.

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

Lower-level installer. It installs packages, builds `dwm`, installs the session files, and places helper scripts in `~/.local/bin`.

Use this when you want tighter control over the system-level part of the install.

### `scripts/post-install.sh`

User-level deployment step. It sets up config files, profile files, `rofi`, shell theming, `dwmblocks`, and optional rebuild steps.

Use this when packages are already installed and you mainly want to refresh your local setup.

### `scripts/setup-dwmblocks.sh`

Deploys the `dwmblocks` config package to `~/.config/dwmblocks`. It can also patch, build, and install `dwmblocks` itself if you point it at a source tree or let it clone one.

### `scripts/fix-dwm-login.sh`

Repair helper for broken display manager logins or session startup issues.

### `scripts/health-check.sh`

Checks installed commands, deployed files, and a few expected runtime processes.

## Manual Install

If you do not want to use `bootstrap.sh`, use the two-step install.

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

## Compatibility Notes

- The setup is built for Xorg, not Wayland.
- On SDDM, bootstrap forces `DisplayServer=x11`.
- On Arch-like systems, bootstrap will install `paru` if it is missing.
- If you are working with older hardware or want the least surprising display-manager behavior, `--dm-theme breeze` is the safest choice.

## Troubleshooting

### Black Screen After Login

From a TTY:

```bash
./scripts/fix-dwm-login.sh
```

Then reboot and try the `DWM` session again.

### Missing Commands or Missing Files

Run:

```bash
~/.local/bin/dwm-health-check.sh
```

If it reports missing items, rerun the relevant install step instead of guessing.

As a rule:

- rerun `bootstrap.sh` if the whole machine is only partially installed
- rerun `post-install.sh` if packages are present but your user config is incomplete
- rerun `setup-dwmblocks.sh` if the status bar is wrong or stale

### Dry Run

To preview changes:

```bash
./scripts/bootstrap.sh --dry-run
```

## Uninstall

Preview first:

```bash
./scripts/uninstall-dwm-stack.sh --dry-run
```

Then remove `--dry-run` when you are ready to actually remove it.
