#!/usr/bin/env bash
set -euo pipefail

agents=(
  "/usr/lib/polkit-gnome/polkit-gnome-authentication-agent-1"
  "/usr/libexec/polkit-gnome-authentication-agent-1"
  "/usr/lib/policykit-1-gnome/polkit-gnome-authentication-agent-1"
  "/usr/lib/polkit-kde-authentication-agent-1"
  "/usr/libexec/polkit-kde-authentication-agent-1"
  "/usr/libexec/lxqt-policykit-agent"
  "/usr/lib/lxqt-policykit-agent/lxqt-policykit-agent"
)

for agent in "${agents[@]}"; do
  if [[ -x "$agent" ]]; then
    exec "$agent"
  fi
done

echo "No known Polkit agent binary found." >&2
exit 1
