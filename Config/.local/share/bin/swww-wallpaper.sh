#!/bin/bash

WALLPAPERS="$HOME/.local/share/wallpapers"
INTERVAL="1h"  # Change frequency: e.g. 10m, 2h, 1800s

while true; do
  img=$(find "$WALLPAPERS" -type f | shuf -n 1)
  swww img "$img"
  sleep "$INTERVAL"
done

