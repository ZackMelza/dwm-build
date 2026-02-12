#!/bin/sh

userresources="$HOME/.Xresources"
usermodmap="$HOME/.Xmodmap"
sysresources="/etc/X11/xinit/.Xresources"
sysmodmap="/etc/X11/xinit/.Xmodmap"

if [ -f "$sysresources" ]; then
  xrdb -merge "$sysresources"
fi

if [ -f "$sysmodmap" ]; then
  xmodmap "$sysmodmap"
fi

if [ -f "$userresources" ]; then
  xrdb -merge "$userresources"
fi

if [ -f "$usermodmap" ]; then
  xmodmap "$usermodmap"
fi

if [ -d /etc/X11/xinit/xinitrc.d ]; then
  for f in /etc/X11/xinit/xinitrc.d/?*.sh; do
    [ -x "$f" ] && . "$f"
  done
  unset f
fi

if command -v dwm-autostart.sh >/dev/null 2>&1; then
  dwm-autostart.sh
elif [ -x "$HOME/.local/bin/dwm-autostart.sh" ]; then
  "$HOME/.local/bin/dwm-autostart.sh"
fi

exec dwm
