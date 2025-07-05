#!/usr/bin/env bash

# Optimized update script with better error handling and caching
set -euo pipefail

# Configuration
readonly SCRIPT_DIR="$(dirname "$(realpath "$0")")"
readonly CACHE_FILE="/tmp/waybar_updates_cache"
readonly CACHE_DURATION=1800  # 30 minutes
readonly AUR_HELPER="paru"

# Check if we're on Arch Linux
[[ ! -f /etc/arch-release ]] && exit 0

# Source global variables if available
[[ -f "${SCRIPT_DIR}/globalctr.sh" ]] && source "${SCRIPT_DIR}/globalctr.sh" && get_aurhlpr

# Use configured AUR helper or fallback
aurhlpr="${aurhlpr:-$AUR_HELPER}"

# Function to check if cache is valid
is_cache_valid() {
    [[ -f "$CACHE_FILE" ]] && [[ $(($(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0))) -lt $CACHE_DURATION ]]
}

# Function to get update counts with caching
get_update_counts() {
    if is_cache_valid; then
        cat "$CACHE_FILE"
        return
    fi

    # Get updates in parallel for better performance
    local aur_updates=0 official_updates=0
    
    # AUR updates
    if command -v "$aurhlpr" &>/dev/null; then
        aur_updates=$("$aurhlpr" -Qua 2>/dev/null | wc -l || echo 0)
    fi
    
    # Official updates
    if command -v checkupdates &>/dev/null; then
        official_updates=$(checkupdates 2>/dev/null | wc -l || echo 0)
    fi
    
    # Cache results
    echo "$official_updates $aur_updates" > "$CACHE_FILE"
    echo "$official_updates $aur_updates"
}

# Handle upgrade trigger
if [[ "${1:-}" == "up" ]]; then
    # Clear cache to force refresh after update
    rm -f "$CACHE_FILE"
    
    # Signal waybar to refresh
    trap 'pkill -RTMIN+20 waybar' EXIT
    
    # Run update in terminal
    exec alacritty --title "System Update" -e bash -c "
        fastfetch
        echo 'Starting system update...'
        $aurhlpr -Syu
        echo 'Update completed!'
        read -n 1 -p 'Press any key to continue...'
    "
fi

# Get update counts
read -r official_count aur_count <<< "$(get_update_counts)"
total_updates=$((official_count + aur_count))

# Handle upgrade info display
if [[ "${1:-}" == "upgrade" ]]; then
    printf "[Official] %-10s\n[AUR]      %-10s\n" "$official_count" "$aur_count"
    exit 0
fi

# Output for Waybar
if [[ $total_updates -eq 0 ]]; then
    echo '{"text":"", "tooltip":"System is up to date"}'
else
    echo "{\"text\":\"󰏗 $total_updates\", \"tooltip\":\"󱓽 Official: $official_count\\n󱓾 AUR: $aur_count\"}"
fi
