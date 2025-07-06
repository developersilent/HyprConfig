#!/usr/bin/env bash
# Fixed version of install_aur.sh with proper error handling

set -euo pipefail

readonly SCRIPT_DIR="$(dirname "$(realpath "$0")")"
readonly CLONE_DIR="${HOME}/Clone"
readonly LOG_FILE="${XDG_CACHE_HOME:-$HOME/.cache}/hyde/install_aur.log"

# Source global functions
if ! source "${SCRIPT_DIR}/global.sh"; then
    echo "Error: unable to source global.sh..." >&2
    exit 1
fi

# Create log directory
mkdir -p "$(dirname "$LOG_FILE")"

# Function to log messages
log_message() {
    local level="$1"
    local message="$2"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" | tee -a "$LOG_FILE"
}

# Function to cleanup on exit
cleanup() {
    local exit_code=$?
    if [[ $exit_code -ne 0 ]]; then
        log_message "ERROR" "Script failed with exit code $exit_code"
        # Cleanup partial clone if it exists
        if [[ -d "${CLONE_DIR}/${AUR_HELPER:-}" ]]; then
            rm -rf "${CLONE_DIR}/${AUR_HELPER}"
            log_message "INFO" "Cleaned up partial clone directory"
        fi
    fi
    return $exit_code
}

trap cleanup EXIT

# Check if AUR helper is already installed
if chk_list "aurhlpr" "${aurList[@]}"; then
    log_message "INFO" "AUR helper already detected: ${aurhlpr}"
    exit 0
fi

# Get AUR helper name (default to paru)
readonly AUR_HELPER="${1:-paru}"

# Validate AUR helper name
if [[ ! "$AUR_HELPER" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    log_message "ERROR" "Invalid AUR helper name: $AUR_HELPER"
    exit 1
fi

# Check if git is installed
if ! pkg_installed "git"; then
    log_message "ERROR" "Git is required but not installed"
    exit 1
fi

# Create clone directory
if ! mkdir -p "$CLONE_DIR"; then
    log_message "ERROR" "Failed to create clone directory: $CLONE_DIR"
    exit 1
fi

# Check available disk space (require at least 100MB)
if ! df "$CLONE_DIR" | awk 'NR==2 {if ($4 < 100000) exit 1}'; then
    log_message "ERROR" "Insufficient disk space in $CLONE_DIR"
    exit 1
fi

# Remove existing clone directory if it exists
if [[ -d "${CLONE_DIR}/${AUR_HELPER}" ]]; then
    log_message "INFO" "Removing existing clone directory for $AUR_HELPER"
    rm -rf "${CLONE_DIR}/${AUR_HELPER}"
fi

# Clone AUR helper repository
log_message "INFO" "Cloning $AUR_HELPER from AUR..."
if ! git clone "https://aur.archlinux.org/${AUR_HELPER}.git" "${CLONE_DIR}/${AUR_HELPER}"; then
    log_message "ERROR" "Failed to clone $AUR_HELPER repository"
    exit 1
fi

# Change to AUR helper directory
if ! cd "${CLONE_DIR}/${AUR_HELPER}"; then
    log_message "ERROR" "Failed to change to $AUR_HELPER directory"
    exit 1
fi

# Build and install AUR helper
log_message "INFO" "Building and installing $AUR_HELPER..."
if makepkg ${use_default:+"$use_default"} -si; then
    log_message "INFO" "Successfully installed $AUR_HELPER"
    
    # Cleanup clone directory
    if [[ -d "${CLONE_DIR}/${AUR_HELPER}" ]]; then
        rm -rf "${CLONE_DIR}/${AUR_HELPER}"
        log_message "INFO" "Cleaned up clone directory"
    fi
    
    exit 0
else
    log_message "ERROR" "Failed to build/install $AUR_HELPER"
    exit 1
fi
