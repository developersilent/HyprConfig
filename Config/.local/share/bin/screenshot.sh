#!/usr/bin/env bash

# Screenshot utility script for Hyprland
# Uses grim and slurp for region selection
set -euo pipefail

# Configuration
readonly SCREENSHOTS_DIR="$HOME/Pictures/Screenshots"
readonly TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Ensure screenshots directory exists
mkdir -p "$SCREENSHOTS_DIR"

# Check for required tools
for tool in grim slurp hyprctl jq; do
    if ! command -v "$tool" &> /dev/null; then
        notify-send "Screenshot Error" "Required tool '$tool' not found" -i dialog-error
        exit 1
    fi
done

# Function to take screenshot
take_screenshot() {
    local mode=$1
    local output_file="$SCREENSHOTS_DIR/screenshot_${TIMESTAMP}.png"
    
    case "$mode" in
        "full")
            grim "$output_file"
            notify-send "Screenshot" "Full screen captured\n$(basename "$output_file")" -i camera-photo
            ;;
        "region")
            if grim -g "$(slurp)" "$output_file"; then
                notify-send "Screenshot" "Region captured\n$(basename "$output_file")" -i camera-photo
            else
                notify-send "Screenshot" "Region capture cancelled" -i dialog-information
                exit 0
            fi
            ;;
        "window")
            local window_geometry
            if window_geometry=$(hyprctl activewindow -j | jq -r '"\(.at[0]),\(.at[1]) \(.size[0])x\(.size[1])"'); then
                grim -g "$window_geometry" "$output_file"
                notify-send "Screenshot" "Window captured\n$(basename "$output_file")" -i camera-photo
            else
                notify-send "Screenshot Error" "Could not get window geometry" -i dialog-error
                exit 1
            fi
            ;;
        *)
            echo "Usage: $0 {full|region|window}"
            echo "  full   - Capture full screen"
            echo "  region - Capture selected region"
            echo "  window - Capture active window"
            exit 1
            ;;
    esac
    
    # Copy to clipboard
    if command -v wl-copy &> /dev/null; then
        wl-copy < "$output_file"
    fi
}

# Main execution
take_screenshot "${1:-}"
