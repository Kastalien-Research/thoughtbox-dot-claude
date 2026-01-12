#!/usr/bin/env bash
# Post tool use hook - logs tool usage events

set -e

# Read JSON input from stdin
input_data=$(cat)

# Ensure log directory exists
log_dir="logs"
mkdir -p "$log_dir"
log_file="$log_dir/post_tool_use.json"

# Read existing log data or initialize empty array
if [[ -f "$log_file" ]]; then
    log_data=$(cat "$log_file" 2>/dev/null || echo '[]')
    # Validate JSON, fallback to empty array if invalid
    if ! echo "$log_data" | jq empty 2>/dev/null; then
        log_data='[]'
    fi
else
    log_data='[]'
fi

# Append new data
log_data=$(echo "$log_data" | jq --argjson new "$input_data" '. + [$new]')

# Write back to file with formatting
echo "$log_data" | jq . > "$log_file"

exit 0