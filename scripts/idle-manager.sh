#!/usr/bin/env bash
set -euo pipefail

lock_minutes="${DWM_IDLE_LOCK_MINUTES:-20}"
sleep_minutes="${DWM_IDLE_SLEEP_MINUTES:-30}"

if ! [[ "$lock_minutes" =~ ^[0-9]+$ ]] || (( lock_minutes < 1 )); then
  lock_minutes=20
fi
if ! [[ "$sleep_minutes" =~ ^[0-9]+$ ]] || (( sleep_minutes < lock_minutes )); then
  sleep_minutes=30
fi

if ! command -v xautolock >/dev/null 2>&1; then
  echo "xautolock not found; idle lock/suspend disabled." >&2
  exit 0
fi

locker_cmd='if command -v loginctl >/dev/null 2>&1; then loginctl lock-session; elif command -v xdg-screensaver >/dev/null 2>&1; then xdg-screensaver lock; fi'
suspend_cmd='if command -v loginctl >/dev/null 2>&1; then loginctl lock-session; fi; systemctl suspend'

if (( sleep_minutes > lock_minutes )); then
  kill_after="$((sleep_minutes - lock_minutes))"
  exec xautolock -detectsleep -time "$lock_minutes" -locker "$locker_cmd" -killtime "$kill_after" -killer "$suspend_cmd"
fi

exec xautolock -detectsleep -time "$lock_minutes" -locker "$locker_cmd"
