#!/usr/bin/env bash
# Subagent stop hook - logs subagent stop events

set +e

# Parse command line arguments
chat_flag=false
notify_flag=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --chat) chat_flag=true; shift ;;
        --notify) notify_flag=true; shift ;;
        *) shift ;;
    esac
done

# Read JSON input from stdin
input_data=$(cat)

# Extract fields
transcript_path=$(echo "$input_data" | jq -r '.transcript_path // ""')

# Ensure log directory exists
log_dir="logs"
mkdir -p "$log_dir"
log_file="$log_dir/subagent_stop.json"

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

# Handle --chat switch
if [[ "$chat_flag" == "true" ]] && [[ -n "$transcript_path" ]] && [[ -f "$transcript_path" ]]; then
    chat_file="$log_dir/chat.json"
    
    # Read .jsonl file and convert to JSON array
    chat_data="["
    first=true
    while IFS= read -r line; do
        if [[ -n "$line" ]]; then
            if [[ "$first" == "true" ]]; then
                first=false
            else
                chat_data+=","
            fi
            chat_data+="$line"
        fi
    done < "$transcript_path"
    chat_data+="]"
    
    echo "$chat_data" | jq . > "$chat_file" 2>/dev/null || true
fi

# Get TTS script path
get_tts_script() {
    local script_dir="$(dirname "$0")"
    local tts_dir="$script_dir/utils/tts"
    
    if [[ -n "$ELEVENLABS_API_KEY" ]] && [[ -f "$tts_dir/elevenlabs_tts.sh" ]]; then
        echo "$tts_dir/elevenlabs_tts.sh"
        return 0
    fi
    if [[ -n "$OPENAI_API_KEY" ]] && [[ -f "$tts_dir/openai_tts.sh" ]]; then
        echo "$tts_dir/openai_tts.sh"
        return 0
    fi
    if [[ -f "$tts_dir/pyttsx3_tts.sh" ]]; then
        echo "$tts_dir/pyttsx3_tts.sh"
        return 0
    fi
    return 1
}

# Announce subagent completion via TTS if requested
if [[ "$notify_flag" == "true" ]]; then
    tts_script=$(get_tts_script)
    if [[ -n "$tts_script" ]]; then
        timeout 10s "$tts_script" "Subagent Complete" 2>/dev/null || true
    fi
fi

exit 0
