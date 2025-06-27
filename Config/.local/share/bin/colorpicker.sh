#!/usr/bin/env bash

# Color picker utility using hyprpicker
# Copies color to clipboard and shows notification

color=$(hyprpicker -a)

if [ $? -eq 0 ] && [ -n "$color" ]; then
    echo "$color" | wl-copy
    notify-send "Color Picker" "Color $color copied to clipboard" -i applications-graphics
else
    notify-send "Color Picker" "No color selected" -i dialog-error
fi
