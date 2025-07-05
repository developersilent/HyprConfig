#!/usr/bin/env bash

# Process kill script for Hyprland
set -euo pipefail

# Check if required tools are available
if ! command -v hyprctl &> /dev/null; then
    echo "Error: hyprctl not found. Make sure you're running Hyprland."
    exit 1
fi

# Get active window class
if window_info=$(hyprctl activewindow -j 2>/dev/null); then
    window_class=$(echo "$window_info" | jq -r ".class" 2>/dev/null || echo "")
    
    if [[ "$window_class" == "Stream" ]]; then
        # For Stream windows, use xdotool if available
        if command -v xdotool &> /dev/null; then
            xdotool windowunmap "$(xdotool getactivewindow)" 2>/dev/null || {
                echo "Failed to unmap window with xdotool, falling back to hyprctl"
                hyprctl dispatch killactive ""
            }
        else
            echo "xdotool not found, using hyprctl killactive"
            hyprctl dispatch killactive ""
        fi
    else
        # For other windows, use hyprctl
        hyprctl dispatch killactive ""
    fi
else
    echo "Error: Could not get active window information"
    exit 1
fi