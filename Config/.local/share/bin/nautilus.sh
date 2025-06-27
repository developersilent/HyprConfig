#!/usr/bin/env bash

# Nautilus launcher script with crash prevention
# Sets proper environment variables before launching nautilus

# Ensure proper DBus session
export DBUS_SESSION_BUS_ADDRESS="unix:path=$XDG_RUNTIME_DIR/bus"

# GTK/GDK settings for Wayland
export GDK_BACKEND=wayland,x11
export QT_QPA_PLATFORM=wayland;xcb

# Nautilus specific fixes
export NAUTILUS_SCRIPT_CURRENT_URI="file://"
export GSETTINGS_BACKEND=dconf
export GIO_USE_VFS=local

# Ensure gvfs is running
if ! pgrep -x "gvfsd" > /dev/null; then
    gvfsd &
fi

# Start nautilus with proper flags
exec nautilus --new-window "$@"
