#!/usr/bin/env bash
# Notification hook - logs notifications and optionally announces via TTS

set +e

# Parse command line arguments
notify_flag=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --notify) notify_flag=true; shift ;;
        *) shift ;;
    esac
done

# Read JSON input from stdin
input_data=$(cat)

# Ensure log directory exists
log_dir="logs"
mkdir -p "$log_dir"
log_file="$log_dir/notification.json"

# Read existing log data or initialize empty array
if [[ -f "$log_file" ]]; then
    log_data=$(cat "$log_file" 2>/dev/null || echo '[]')
    if ! echo "$log_data" | jq empty 2>/dev/null; then
        log_data='[]'
    fi
else
    log_data='[]'
fi

# Append new data
log_data=$(echo "$log_data" | jq --argjson new "$input_data" '. + [$new]')
echo "$log_data" | jq . > "$log_file"

# Get TTS script path based on available API keys
get_tts_script() {
    local script_dir="$(dirname "$0")"
    local tts_dir="$script_dir/utils/tts"
    
    # Check for ElevenLabs API key (highest priority)
    if [[ -n "$ELEVENLABS_API_KEY" ]] && [[ -f "$tts_dir/elevenlabs_tts.sh" ]]; then
        echo "$tts_dir/elevenlabs_tts.sh"
        return 0
    fi
    
    # Check for OpenAI API key (second priority)
    if [[ -n "$OPENAI_API_KEY" ]] && [[ -f "$tts_dir/openai_tts.sh" ]]; then
        echo "$tts_dir/openai_tts.sh"
        return 0
    fi
    
    # Fall back to pyttsx3 (no API key required)
    if [[ -f "$tts_dir/pyttsx3_tts.sh" ]]; then
        echo "$tts_dir/pyttsx3_tts.sh"
        return 0
    fi
    
    return 1
}

# Announce notification via TTS if requested
message=$(echo "$input_data" | jq -r '.message // ""')
if [[ "$notify_flag" == "true" ]] && [[ "$message" != "Claude is waiting for your input" ]]; then
    tts_script=$(get_tts_script)
    if [[ -n "$tts_script" ]]; then
        # Get engineer name if available
        engineer_name="${ENGINEER_NAME:-}"
        
        # Create notification message with 30% chance to include name
        if [[ -n "$engineer_name" ]] && [[ $((RANDOM % 10)) -lt 3 ]]; then
            notification_message="$engineer_name, your agent needs your input"
        else
            notification_message="Your agent needs your input"
        fi
        
        # Call the TTS script
        timeout 10s "$tts_script" "$notification_message" 2>/dev/null || true
    fi
fi

exit 0
