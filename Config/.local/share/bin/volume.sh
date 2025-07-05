#!/usr/bin/env sh

# Optimized unified volume control script for Waybar
# Handles output, input, and player volume with safety limits

# Configuration
readonly STEP=5
readonly MAX_VOLUME=153
readonly NOTIFY_ID=91190
readonly NOTIFY_TIMEOUT=800
readonly ICON_DIR="$HOME/.config/dunst/icons/vol"

# Fallback to system icons if custom icons don't exist
readonly USE_SYSTEM_ICONS=true

# Print usage information
print_usage() {
    cat <<EOF
Usage: $(basename "$0") -[device] <action> [step]

Devices:
    -o    Output device (speakers/headphones)
    -i    Input device (microphone)
    -p    Player application

Actions:
    i     Increase volume
    d     Decrease volume
    m     Toggle mute

Examples:
    $(basename "$0") -o i     # Increase output volume
    $(basename "$0") -i m     # Toggle microphone mute
    $(basename "$0") -p spotify d  # Decrease Spotify volume

EOF
    exit 1
}

# Get device name for notifications
get_device_name() {
    case "$1" in
        "output")
            pactl info | grep -A1 "Default Sink:" | tail -1 | cut -d' ' -f2- || echo "Output"
            ;;
        "input")
            pactl info | grep -A1 "Default Source:" | tail -1 | cut -d' ' -f2- || echo "Input"
            ;;
        "player")
            echo "$2"
            ;;
    esac
}

# Get appropriate icon for volume level
get_volume_icon() {
    local vol=$1
    local muted=$2
    local device_type=$3
    
    # Use system icons as fallback since custom icon dir doesn't exist
    if [[ "$USE_SYSTEM_ICONS" == "true" ]] || [[ ! -d "$ICON_DIR" ]]; then
        if [[ "$muted" == "true" ]]; then
            case "$device_type" in
                "speaker") echo "audio-volume-muted" ;;
                "mic") echo "microphone-sensitivity-muted" ;;
                "player") echo "media-playback-stop" ;;
                *) echo "audio-volume-muted" ;;
            esac
        else
            case "$device_type" in
                "speaker"|"player")
                    if (( vol >= 70 )); then
                        echo "audio-volume-high"
                    elif (( vol >= 30 )); then
                        echo "audio-volume-medium"
                    else
                        echo "audio-volume-low"
                    fi
                    ;;
                "mic")
                    echo "microphone-sensitivity-high"
                    ;;
                *)
                    echo "audio-volume-medium"
                    ;;
            esac
        fi
    else
        # Use custom icons if directory exists
        if [[ "$muted" == "true" ]]; then
            echo "${ICON_DIR}/muted-${device_type}.svg"
        else
            local angle=$(( (vol / 10) * 10 ))
            echo "${ICON_DIR}/vol-${angle}.svg"
        fi
    fi
}

# Send notification
send_notification() {
    local title=$1
    local body=$2
    local icon=$3
    
    # Check if icon file exists, otherwise use the icon name directly (system icon)
    if [[ ! -f "$icon" ]] && [[ "$icon" == *".svg" ]]; then
        # Extract icon name without extension for system icons
        icon=$(basename "$icon" .svg)
    fi
    
    notify-send -a "waybar-volume" -r $NOTIFY_ID -t $NOTIFY_TIMEOUT -i "$icon" "$title" "$body"
}

# Handle volume changes
change_volume() {
    local action=$1
    local step=${2:-$STEP}
    local current_vol new_vol device_name
    
    case "$device_type" in
        "output")
            current_vol=$(pamixer --get-volume || echo "0")
            
            if [ "$action" = "i" ]; then
                new_vol=$((current_vol + step))
                [ $new_vol -gt $MAX_VOLUME ] && new_vol=$MAX_VOLUME
            else
                new_vol=$((current_vol - step))
                [ $new_vol -lt 0 ] && new_vol=0
            fi
            
            pamixer --allow-boost --set-volume $new_vol
            device_name=$(get_device_name "output")
            icon=$(get_volume_icon "$new_vol" "false" "speaker")
            send_notification "Volume ${new_vol}%" "$device_name" "$icon"
            ;;
            
        "input")
            current_vol=$(pamixer --default-source --get-volume || echo "0")
            
            if [ "$action" = "i" ]; then
                new_vol=$((current_vol + step))
                [ $new_vol -gt $MAX_VOLUME ] && new_vol=$MAX_VOLUME
            else
                new_vol=$((current_vol - step))
                [ $new_vol -lt 0 ] && new_vol=0
            fi
            
            pamixer --default-source --allow-boost --set-volume $new_vol
            device_name=$(get_device_name "input")
            icon=$(get_volume_icon "$new_vol" "false" "mic")
            send_notification "Microphone ${new_vol}%" "$device_name" "$icon"
            ;;
            
        "player")
            [ -z "$player_name" ] && { echo "Error: Player name required"; exit 1; }
            
            current_vol=$(playerctl --player="$player_name" volume 2>/dev/null | awk '{ printf "%.0f", $0 * 100 }')
            [ -z "$current_vol" ] && { echo "Error: Player not found or not playing"; exit 1; }
            
            if [ "$action" = "i" ]; then
                new_vol=$((current_vol + step))
                [ $new_vol -gt $MAX_VOLUME ] && new_vol=$MAX_VOLUME
            else
                new_vol=$((current_vol - step))
                [ $new_vol -lt 0 ] && new_vol=0
            fi
            
            playerctl --player="$player_name" volume $(awk -v vol="$new_vol" 'BEGIN {print vol/100}')
            device_name=$(get_device_name "player" "$player_name")
            icon=$(get_volume_icon "$new_vol" "false" "player")
            send_notification "Player ${new_vol}%" "$device_name" "$icon"
            ;;
    esac
}

# Handle mute toggle
toggle_mute() {
    local is_muted device_name icon status
    
    case "$device_type" in
        "output")
            pamixer -t
            is_muted=$(pamixer --get-mute)
            device_name=$(get_device_name "output")
            icon=$(get_volume_icon "0" "$is_muted" "speaker")
            status=$([ "$is_muted" = "true" ] && echo "Muted" || echo "Unmuted")
            send_notification "$status" "$device_name" "$icon"
            ;;
            
        "input")
            pamixer --default-source -t
            is_muted=$(pamixer --default-source --get-mute)
            device_name=$(get_device_name "input")
            icon=$(get_volume_icon "0" "$is_muted" "mic")
            status=$([ "$is_muted" = "true" ] && echo "Microphone Muted" || echo "Microphone Unmuted")
            send_notification "$status" "$device_name" "$icon"
            ;;
            
        "player")
            [ -z "$player_name" ] && { echo "Error: Player name required"; exit 1; }
            
            current_vol=$(playerctl --player="$player_name" volume 2>/dev/null | awk '{ printf "%.2f", $0 }')
            [ -z "$current_vol" ] && { echo "Error: Player not found or not playing"; exit 1; }
            
            if [ "$current_vol" != "0.00" ]; then
                echo "$current_vol" > "/tmp/waybar_volume_${player_name}"
                playerctl --player="$player_name" volume 0
                status="Player Muted"
            else
                saved_vol=$(cat "/tmp/waybar_volume_${player_name}" 2>/dev/null || echo "0.5")
                playerctl --player="$player_name" volume "$saved_vol"
                status="Player Unmuted"
            fi
            
            device_name=$(get_device_name "player" "$player_name")
            icon=$(get_volume_icon "0" "$is_muted" "player")
            send_notification "$status" "$device_name" "$icon"
            ;;
    esac
}

# Parse command line arguments
device_type=""
player_name=""

while getopts "iop:" opt; do
    case $opt in
        i) device_type="input" ;;
        o) device_type="output" ;;
        p) device_type="player"; player_name="$OPTARG" ;;
        *) print_usage ;;
    esac
done

shift $((OPTIND-1))

# Validate arguments
[ -z "$device_type" ] && print_usage
[ -z "$1" ] && print_usage

# Execute the requested action
case "$1" in
    i|d) change_volume "$1" "$2" ;;
    m) toggle_mute ;;
    *) print_usage ;;
esac
