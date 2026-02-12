#!/usr/bin/env bash
set -euo pipefail

music_dir="${ROFI_BEATS_MUSIC_DIR:-$HOME/Music}"
conf_dir="${ROFI_CONF_DIR:-$HOME/.config/rofi}"
rofi_theme="$conf_dir/config-rofi-Beats.rasi"
mpv_socket="${XDG_RUNTIME_DIR:-/tmp}/rofibeats-mpv.sock"

notify_msg() {
  if command -v notify-send >/dev/null 2>&1; then
    notify-send "RofiBeats" "$1" >/dev/null 2>&1 || true
  fi
}

rofi_menu() {
  rofi -i -dmenu -p "$1" -config "$rofi_theme"
}

mpv_running() {
  pgrep -x mpv >/dev/null 2>&1
}

stop_music() {
  if mpv_running; then
    pkill -x mpv >/dev/null 2>&1 || true
    rm -f "$mpv_socket"
    notify_msg "Stopped"
  fi
}

start_mpv() {
  local title="$1"
  shift
  stop_music
  nohup mpv --vid=no --force-window=no --input-ipc-server="$mpv_socket" "$@" >/dev/null 2>&1 &
  notify_msg "Now playing: $title"
}

mpv_ipc() {
  local payload="$1"
  if [[ ! -S "$mpv_socket" ]]; then
    notify_msg "No active player"
    return
  fi

  if command -v socat >/dev/null 2>&1; then
    printf '%s\n' "$payload" | socat - "$mpv_socket" >/dev/null 2>&1 || true
  elif command -v nc >/dev/null 2>&1; then
    printf '%s\n' "$payload" | nc -U "$mpv_socket" >/dev/null 2>&1 || true
  fi
}

play_local() {
  [[ -d "$music_dir" ]] || { notify_msg "No music dir: $music_dir"; return; }

  mapfile -t files < <(find -L "$music_dir" -type f \( -iname '*.mp3' -o -iname '*.flac' -o -iname '*.ogg' -o -iname '*.wav' -o -iname '*.m4a' \) | sort)
  [[ ${#files[@]} -gt 0 ]] || { notify_msg "No audio files found"; return; }

  mapfile -t names < <(for f in "${files[@]}"; do printf '%s\n' "${f#"$music_dir"/}"; done)
  choice="$(printf '%s\n' "${names[@]}" | rofi_menu "Local Music")"
  [[ -n "$choice" ]] || return

  for i in "${!names[@]}"; do
    if [[ "${names[$i]}" == "$choice" ]]; then
      start_mpv "$choice" --playlist-start="$i" --loop-playlist "${files[@]}"
      return
    fi
  done
}

play_url() {
  url="$(printf '' | rofi -dmenu -p "Paste URL" -config "$rofi_theme")"
  [[ -n "$url" ]] || return
  start_mpv "$url" "$url"
}

search_youtube() {
  query="$(printf '' | rofi -dmenu -p "YouTube Search" -config "$rofi_theme")"
  [[ -n "$query" ]] || return

  if command -v yt-dlp >/dev/null 2>&1; then
    mapfile -t rows < <(yt-dlp --no-warnings --flat-playlist --print '%(title)s|%(id)s' "ytsearch10:${query}" 2>/dev/null)
    [[ ${#rows[@]} -gt 0 ]] || { start_mpv "$query" "ytdl://ytsearch1:${query}"; return; }

    mapfile -t titles < <(for r in "${rows[@]}"; do printf '%s\n' "${r%%|*}"; done)
    pick="$(printf '%s\n' "${titles[@]}" | rofi_menu "YouTube Results")"
    [[ -n "$pick" ]] || return

    for r in "${rows[@]}"; do
      title="${r%%|*}"
      vid="${r##*|}"
      if [[ "$title" == "$pick" ]]; then
        start_mpv "$title" "https://www.youtube.com/watch?v=$vid"
        return
      fi
    done
  else
    start_mpv "$query" "ytdl://ytsearch1:${query}"
  fi
}

player_controls() {
  action="$(printf '%s\n' \
    'Pause/Resume' 'Next' 'Previous' 'Seek +10s' 'Seek -10s' 'Volume +5' 'Volume -5' 'Mute/Unmute' 'Stop' \
    | rofi_menu "Player")"

  case "$action" in
    "Pause/Resume") mpv_ipc '{"command": ["cycle", "pause"]}' ;;
    "Next") mpv_ipc '{"command": ["playlist-next"]}' ;;
    "Previous") mpv_ipc '{"command": ["playlist-prev"]}' ;;
    "Seek +10s") mpv_ipc '{"command": ["seek", 10]}' ;;
    "Seek -10s") mpv_ipc '{"command": ["seek", -10]}' ;;
    "Volume +5") mpv_ipc '{"command": ["add", "volume", 5]}' ;;
    "Volume -5") mpv_ipc '{"command": ["add", "volume", -5]}' ;;
    "Mute/Unmute") mpv_ipc '{"command": ["cycle", "mute"]}' ;;
    "Stop") stop_music ;;
  esac
}

main() {
  choice="$(printf '%s\n' \
    'Play Local Music' \
    'Search YouTube' \
    'Play URL' \
    'Player Controls' \
    'Stop Music' \
    | rofi_menu "RofiBeats")"

  case "$choice" in
    "Play Local Music") play_local ;;
    "Search YouTube") search_youtube ;;
    "Play URL") play_url ;;
    "Player Controls") player_controls ;;
    "Stop Music") stop_music ;;
  esac
}

main
