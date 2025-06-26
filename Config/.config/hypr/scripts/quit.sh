#!/bin/bash

if [[ $(hyprctl activewindow -j | jq -r ".class") == "Stream" ]]; then
    xdotool windowunmap $(xdotool getactivewindow)
else
    hyprctl dispatch killactive ""
fi