#!/usr/bin/env bash

# Screenshot utility script for Hyprland
# Uses grim and slurp for region selection

case "$1" in
    "full")
        # Full screen screenshot
        grim ~/Pictures/Screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png
        notify-send "Screenshot" "Full screen captured" -i camera-photo
        ;;
    "region")
        # Region selection screenshot
        grim -g "$(slurp)" ~/Pictures/Screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png
        notify-send "Screenshot" "Region captured" -i camera-photo
        ;;
    "window")
        # Active window screenshot
        grim -g "$(hyprctl activewindow -j | jq -r '.at | "\(.[0]),\(.[1]) \(.size | "\(.[0])x\(.[1])")"')" ~/Pictures/Screenshots/screenshot_$(date +%Y%m%d_%H%M%S).png
        notify-send "Screenshot" "Window captured" -i camera-photo
        ;;
    *)
        echo "Usage: $0 {full|region|window}"
        echo "  full   - Capture full screen"
        echo "  region - Capture selected region"
        echo "  window - Capture active window"
        exit 1
        ;;
esac
