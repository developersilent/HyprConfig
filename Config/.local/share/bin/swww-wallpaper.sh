#!/usr/bin/env bash

# Wallpaper slideshow using swww
set -euo pipefail

# Configuration
readonly WALLPAPERS="$HOME/.local/share/wallpapers"
readonly INTERVAL="1h"  # Change frequency: e.g. 10m, 2h, 1800s

# Check if wallpapers directory exists
if [[ ! -d "$WALLPAPERS" ]]; then
    echo "Error: Wallpapers directory '$WALLPAPERS' does not exist"
    exit 1
fi

# Check if swww daemon is running
if ! pgrep -x "swww-daemon" > /dev/null; then
    echo "Starting swww daemon..."
    swww init
fi

echo "Starting wallpaper slideshow from $WALLPAPERS (interval: $INTERVAL)"

while true; do
    # Find and select a random wallpaper
    if img=$(find "$WALLPAPERS" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" -o -name "*.webp" \) | shuf -n 1); then
        if [[ -n "$img" ]]; then
            echo "Setting wallpaper: $(basename "$img")"
            matugen image "$img"
        fi
    fi
    sleep "$INTERVAL"  # Wait before changing again
done

