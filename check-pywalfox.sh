#!/bin/bash

set -euo pipefail

# Source global functions if available
if [[ -f "$(dirname "$0")/global.sh" ]]; then
    # shellcheck disable=SC1091
    source "$(dirname "$0")/global.sh"
fi

check_for_pywalfox() {
    print_log -sec "pywalfox" -b "Checking installation status..."
    
    if paru -Qi python-pywalfox &> /dev/null; then
        print_log -sec "pywalfox" -g "✓ Found :: " "python-pywalfox is already installed"
        print_log -sec "pywalfox" -y "Reinitializing :: " "Running pywalfox install as root"
        
        if sudo pywalfox install; then
            print_log -sec "pywalfox" -g "✓ Success :: " "pywalfox reinitialized successfully"
            return 0
        else
            print_log -sec "pywalfox" -err "pywalfox install failed"
            return 1
        fi
    else
        print_log -sec "pywalfox" -warn "Not Found" "python-pywalfox is not installed"
        print_log -sec "pywalfox" -b "Installing :: " "python-pywalfox via paru"
        
        if paru -S python-pywalfox --noconfirm; then
            print_log -sec "pywalfox" -g "✓ Installed :: " "python-pywalfox installation completed"
            print_log -sec "pywalfox" -b "Initializing :: " "Running pywalfox install as root"
            
            if sudo pywalfox install; then
                print_log -sec "pywalfox" -g "✓ Success :: " "pywalfox initialized successfully"
                return 0
            else
                print_log -sec "pywalfox" -err "pywalfox install failed"
                return 1
            fi
        else
            print_log -sec "pywalfox" -crit "FAILED" "python-pywalfox installation failed"
            return 1
        fi
    fi
}

# Check if paru is available
if ! command -v paru &> /dev/null; then
    print_log -sec "pywalfox" -warn "paru not found, skipping pywalfox check"
    exit 0
fi

check_for_pywalfox
