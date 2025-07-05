#!/usr/bin/env bash

# Color picker utility using hyprpicker
# Copies color to clipboard and shows notification
set -euo pipefail

# Check if required tools are available
for tool in hyprpicker wl-copy notify-send; do
    if ! command -v "$tool" &> /dev/null; then
        echo "Error: Required tool '$tool' not found"
        if command -v notify-send &> /dev/null; then
            notify-send "Color Picker Error" "Required tool '$tool' not found" -i dialog-error
        fi
        exit 1
    fi
done

# Pick color with hyprpicker
if color=$(hyprpicker -a 2>/dev/null); then
    if [[ -n "$color" ]]; then
        # Copy to clipboard
        echo "$color" | wl-copy
        
        # Show success notification
        notify-send "Color Picker" \
            "Color $color copied to clipboard" \
            -i applications-graphics \
            -t 3000
        
        echo "Color $color copied to clipboard"
    else
        notify-send "Color Picker" "No color selected" -i dialog-information
        echo "No color selected"
    fi
else
    notify-send "Color Picker" "Color picking cancelled or failed" -i dialog-error
    echo "Color picking cancelled or failed"
    exit 1
fi
