#!/usr/bin/env bash

# CPU information script for Waybar
set -euo pipefail

# Function to map temperature/utilization to icons
map_floor() {
    local pairs=$1
    local value=$2
    local def_val=""
    
    # Split pairs by comma and space
    IFS=', ' read -ra pair_array <<< "$pairs"
    
    # Check if last element is default value (no colon)
    if [[ ${pair_array[-1]} != *":"* ]]; then
        def_val="${pair_array[-1]}"
        unset 'pair_array[${#pair_array[@]}-1]'
    fi
    
    # Process each threshold:icon pair
    for pair in "${pair_array[@]}"; do
        IFS=':' read -r key icon <<< "$pair"
        if (( ${value%%.*} > key )); then
            echo "$icon"
            return
        fi
    done
    
    # Return default value if no threshold matched
    echo "${def_val:- }"
}

# Define glyphs based on emoji preference
if [[ ${NO_EMOJI:-0} -eq 1 ]]; then
    temp_lv="85:, 65:󰔐, 45:, "
else
  temp_lv="85:, 65:󰔐, 45:, "
fi
util_lv="90:󰍛, 60:󰓅, 30:󰾅, 󰾆"

# Get static CPU information
model=$(lscpu | awk -F': ' '/Model name/ {gsub(/^ *| *$| CPU.*/,"",$2); print $2}')
maxfreq=$(lscpu | awk '/CPU max MHz/ { sub(/\..*/,"",$4); print $4}')

# Initialize CPU stat tracking
read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
prevStat=$((user + nice + system + iowait + irq + softirq + steal))
prevIdle=$idle

# Main monitoring loop
while true; do
    # Get current CPU stats
    read -r cpu user nice system idle iowait irq softirq steal guest guest_nice < /proc/stat
    currStat=$((user + nice + system + iowait + irq + softirq + steal))
    currIdle=$idle
    
    # Calculate differences
    diffStat=$((currStat - prevStat))
    diffIdle=$((currIdle - prevIdle))
    
    # Calculate CPU utilization percentage
    if (( (diffStat + diffIdle) > 0 )); then
        utilization=$(awk -v stat="$diffStat" -v idle="$diffIdle" 'BEGIN {printf "%.1f", (stat/(stat+idle))*100}')
    else
        utilization="0.0"
    fi
    
    # Get temperature (try different sensor sources)
    temperature=$(sensors 2>/dev/null | awk -F': ' '/Package id 0|Tctl|Core 0/ { gsub(/^ *\+?|\..*/,"",$2); print $2; exit}' || echo "N/A")
    
    # Get current frequency
    frequency=$(awk '/cpu MHz/{ sum+=$4; c+=1 } END { printf "%.0f", sum/c }' /proc/cpuinfo)
    
    # Generate appropriate icons
    util_icon=$(map_floor "$util_lv" "$utilization")
    temp_icon=$(map_floor "$temp_lv" "$temperature")
    
    # Combine icons for display
    combined_icons="${util_icon}${temp_icon}"
    display_icon="${combined_icons:0:1}"
    temp_display="${combined_icons:1:1}"
    
    # Output JSON for Waybar
    printf '{"text":"%s %s°C", "tooltip":"%s\\n%s Temperature: %s°C\\n%s Utilization: %s%%\\n Clock Speed: %s/%s MHz"}\n' \
        "$temp_display" "$temperature" "$model" "$temp_display" "$temperature" "$display_icon" "$utilization" "$frequency" "$maxfreq"
    
    # Store current state for next iteration
    prevStat=$currStat
    prevIdle=$currIdle
    
    # Sleep for update interval
    sleep 5
done
