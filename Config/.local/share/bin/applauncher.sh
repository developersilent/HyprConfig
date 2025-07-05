#!/usr/bin/env bash

# App launcher using rofi
set -euo pipefail

# Configuration
readonly THEME="$HOME/.config/rofi/applauncher.rasi"
readonly ICON_THEME="Tela-circle-black"

# Check if theme exists, fallback to default if not
if [[ -f "$THEME" ]]; then
    theme_arg="-theme $THEME"
else
    theme_arg=""
fi

# Launch rofi with error handling
rofi -show drun \
    $theme_arg \
    -icon-theme "$ICON_THEME" \
    -show-icons