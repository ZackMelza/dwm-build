#!/usr/bin/env bash
set -euo pipefail

script_path="${BASH_SOURCE[0]}"
if command -v readlink >/dev/null 2>&1; then
  resolved="$(readlink -f -- "$script_path" 2>/dev/null || true)"
  [[ -n "$resolved" ]] && script_path="$resolved"
fi
repo_root="$(cd -- "$(dirname -- "$script_path")/.." && pwd)"

if [[ $EUID -eq 0 ]]; then
  SUDO=()
elif command -v sudo >/dev/null 2>&1; then
  SUDO=(sudo)
else
  echo "Need root or sudo."
  exit 1
fi

echo "[1/5] Rebuilding dwm..."
make -C "$repo_root" clean
make -C "$repo_root"
"${SUDO[@]}" make -C "$repo_root" install

dwm_bin="$(command -v dwm 2>/dev/null || true)"
if [[ -z "$dwm_bin" && -x /usr/local/bin/dwm ]]; then
  dwm_bin="/usr/local/bin/dwm"
fi
if [[ -z "$dwm_bin" && -x /usr/bin/dwm ]]; then
  dwm_bin="/usr/bin/dwm"
fi
if [[ -z "$dwm_bin" ]]; then
  echo "dwm binary not found after install."
  exit 1
fi

echo "[2/5] Installing session entry..."
"${SUDO[@]}" install -Dm644 "$repo_root/sessions/dwm.desktop" /usr/share/xsessions/dwm.desktop

echo "[3/5] Installing dwm session wrapper..."
cat <<'WRAP' | "${SUDO[@]}" tee /usr/local/bin/dwm-session >/dev/null
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
"${SUDO[@]}" chmod 755 /usr/local/bin/dwm-session

echo "[4/5] Pointing session to wrapper..."
"${SUDO[@]}" sed -i 's|^Exec=.*|Exec=/usr/local/bin/dwm-session|; s|^TryExec=.*|TryExec=/usr/local/bin/dwm-session|' /usr/share/xsessions/dwm.desktop

echo "[5/5] Restarting display manager..."
if systemctl list-unit-files | grep -q '^sddm\.service'; then
  "${SUDO[@]}" systemctl restart sddm
elif systemctl list-unit-files | grep -q '^lightdm\.service'; then
  "${SUDO[@]}" systemctl restart lightdm
else
  echo "No sddm/lightdm service found. Start your DM manually."
fi

echo "Done. If login still fails, check: /tmp/dwm-session.log"
