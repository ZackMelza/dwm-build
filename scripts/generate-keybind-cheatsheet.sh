#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
config_file="$repo_root/config.h"

if [[ ! -f "$config_file" ]]; then
  echo "Missing config.h" >&2
  exit 1
fi

mod_pretty() {
  local m="$1"
  m="${m//MODKEY/Super}"
  m="${m//ShiftMask/Shift}"
  m="${m//ControlMask/Ctrl}"
  m="${m//Mod1Mask/Alt}"
  m="${m//|/+}"
  m="${m// /}"
  [[ -z "$m" || "$m" == "0" ]] && m=""
  printf '%s' "$m"
}

key_pretty() {
  local k="$1"
  k="${k#XK_}"
  k="${k#XF86XK_}"
  printf '%s' "$k"
}

printf 'DWM Keybind Cheat Sheet\n'
printf 'Generated: %s\n\n' "$(date '+%F %T')"

awk '
  /static const Key keys\[\] = \{/ {in_keys=1; next}
  in_keys && /};/ {in_keys=0}
  in_keys && $0 ~ /\{.*XK_|\{.*XF86XK_/ {print}
' "$config_file" | while IFS= read -r line; do
  clean="$(printf '%s' "$line" | sed -E 's@/\*.*\*/@@g' | tr -d '\t')"
  mod="$(printf '%s' "$clean" | awk -F',' '{gsub(/^[[:space:]]*\{[[:space:]]*/,"",$1); gsub(/[[:space:]]+$/,"",$1); print $1}')"
  key="$(printf '%s' "$clean" | awk -F',' '{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2); print $2}')"
  fn="$(printf '%s' "$clean" | awk -F',' '{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$3); print $3}')"

  modp="$(mod_pretty "$mod")"
  keyp="$(key_pretty "$key")"

  if [[ -n "$modp" ]]; then
    printf '%-30s -> %s\n' "$modp+$keyp" "$fn"
  else
    printf '%-30s -> %s\n' "$keyp" "$fn"
  fi
done

profile_include="$(awk -F'"' '/#include "config-profile-/{print $2; exit}' "$repo_root/profiles/config-profile.h" || true)"
if [[ -n "$profile_include" && -f "$repo_root/profiles/$profile_include" ]]; then
  printf '\nProfile extras (%s)\n' "$profile_include"
  awk '/XK_|XF86XK_/ {print}' "$repo_root/profiles/$profile_include" | while IFS= read -r line; do
    clean="$(printf '%s' "$line" | sed -E 's@/\*.*\*/@@g' | tr -d '\t')"
    mod="$(printf '%s' "$clean" | awk -F',' '{gsub(/^[[:space:]]*\{[[:space:]]*/,"",$1); gsub(/[[:space:]]+$/,"",$1); print $1}')"
    key="$(printf '%s' "$clean" | awk -F',' '{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$2); print $2}')"
    fn="$(printf '%s' "$clean" | awk -F',' '{gsub(/^[[:space:]]+|[[:space:]]+$/,"",$3); print $3}')"
    modp="$(mod_pretty "$mod")"
    keyp="$(key_pretty "$key")"
    if [[ -n "$modp" ]]; then
      printf '%-30s -> %s\n' "$modp+$keyp" "$fn"
    else
      printf '%-30s -> %s\n' "$keyp" "$fn"
    fi
  done
fi
