#!/bin/bash

WALLPAPER_DIR="/usr/share/wallpapers"

IMG=$( find "$WALLPAPER_DIR" -type f \( -iname '*.jpg' -o -iname '*.png' \) | shuf -n 1)

feh --bg-scale "$IMG"

echo "$(date): $IMG" >> ~/.feh-wallpaper-log

