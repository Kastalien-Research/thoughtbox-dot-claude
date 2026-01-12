#!/usr/bin/env bash
# Pre compact hook - logs and backs up transcript before compaction

set +e

# Parse command line arguments
backup_flag=false
verbose_flag=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --backup) backup_flag=true; shift ;;
        --verbose) verbose_flag=true; shift ;;
        *) shift ;;
    esac
done

# Read JSON input from stdin
input_data=$(cat)

# Extract fields
session_id=$(echo "$input_data" | jq -r '.session_id // "unknown"')
transcript_path=$(echo "$input_data" | jq -r '.transcript_path // ""')
trigger=$(echo "$input_data" | jq -r '.trigger // "unknown"')
custom_instructions=$(echo "$input_data" | jq -r '.custom_instructions // ""')

# Ensure logs directory exists
log_dir="logs"
mkdir -p "$log_dir"
log_file="$log_dir/pre_compact.json"

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

# Create backup if requested
backup_path=""
if [[ "$backup_flag" == "true" ]] && [[ -n "$transcript_path" ]] && [[ -f "$transcript_path" ]]; then
    backup_dir="logs/transcript_backups"
    mkdir -p "$backup_dir"
    
    timestamp=$(date +"%Y%m%d_%H%M%S")
    session_name=$(basename "$transcript_path" .jsonl)
    backup_name="${session_name}_pre_compact_${trigger}_${timestamp}.jsonl"
    backup_path="$backup_dir/$backup_name"
    
    cp "$transcript_path" "$backup_path" 2>/dev/null || true
fi

# Provide feedback if verbose
if [[ "$verbose_flag" == "true" ]]; then
    session_id_short=$(echo "$session_id" | cut -c1-8)
    if [[ "$trigger" == "manual" ]]; then
        echo "Preparing for manual compaction (session: ${session_id_short}...)"
        if [[ -n "$custom_instructions" ]]; then
            echo "Custom instructions: $(echo "$custom_instructions" | cut -c1-100)..."
        fi
    else
        echo "Auto-compaction triggered due to full context window (session: ${session_id_short}...)"
    fi
    
    if [[ -n "$backup_path" ]]; then
        echo "Transcript backed up to: $backup_path"
    fi
fi

exit 0