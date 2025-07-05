#!/usr/bin/env bash

# Global control functions for HyprConfig scripts
set -euo pipefail

# Check if package is installed
pkg_installed() {
    local pkgIn=$1
    
    # Check with pacman first
    if pacman -Qi "$pkgIn" &> /dev/null; then
        return 0
    # Check if command exists
    elif command -v "$pkgIn" &> /dev/null; then
        return 0
    else
        return 1
    fi
}

# Get AUR helper with preference order
get_aurhlpr() {
    local aur_helpers=("paru" "yay" "trizen" "pamac" "pikaur")
    
    for helper in "${aur_helpers[@]}"; do
        if pkg_installed "$helper"; then
            aurhlpr="$helper"
            return 0
        fi
    done
    
    # If no AUR helper found, default to pacman
    aurhlpr="pacman"
    return 1
}

# Check if running on Arch Linux
is_arch() {
    [[ -f /etc/arch-release ]] || [[ -f /etc/manjaro-release ]]
}

# Get system information
get_system_info() {
    if command -v lsb_release &> /dev/null; then
        lsb_release -d | cut -f2
    elif [[ -f /etc/os-release ]]; then
        grep "PRETTY_NAME" /etc/os-release | cut -d'"' -f2
    else
        echo "Unknown Linux Distribution"
    fi
}

# Initialize AUR helper on load
get_aurhlpr


