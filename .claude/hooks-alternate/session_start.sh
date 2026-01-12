#!/usr/bin/env bash
# Session start hook - logs session start and optionally loads context

set +e

# Parse command line arguments
load_context=false
announce=false
while [[ $# -gt 0 ]]; do
    case "$1" in
        --load-context) load_context=true; shift ;;
        --announce) announce=true; shift ;;
        *) shift ;;
    esac
done

# Read JSON input from stdin
input_data=$(cat)

# Extract fields
session_id=$(echo "$input_data" | jq -r '.session_id // "unknown"')
source=$(echo "$input_data" | jq -r '.source // "unknown"')

# Ensure log directory exists
log_dir="logs"
mkdir -p "$log_dir"
log_file="$log_dir/session_start.json"

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

# Load development context if requested
if [[ "$load_context" == "true" ]]; then
    context=""
    context+="Session started at: $(date '+%Y-%m-%d %H:%M:%S')\n"
    context+="Session source: $source\n"
    
    # Add git information
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
        context+="Git branch: $branch\n"
        
        changes=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
        if [[ "$changes" -gt 0 ]]; then
            context+="Uncommitted changes: $changes files\n"
        fi
    fi
    
    # Load project-specific context files
    for file in ".claude/CONTEXT.md" ".claude/TODO.md" "TODO.md" ".github/ISSUE_TEMPLATE.md"; do
        if [[ -f "$file" ]]; then
            context+="\n--- Content from $file ---\n"
            context+="$(head -c 1000 "$file")\n"
        fi
    done
    
    # Add recent GitHub issues if gh CLI is available
    if command -v gh &>/dev/null; then
        issues=$(gh issue list --limit 5 --state open 2>/dev/null || true)
        if [[ -n "$issues" ]]; then
            context+="\n--- Recent GitHub Issues ---\n"
            context+="$issues\n"
        fi
    fi
    
    # Output context as JSON
    if [[ -n "$context" ]]; then
        echo "{\"hookSpecificOutput\":{\"hookEventName\":\"SessionStart\",\"additionalContext\":\"$context\"}}"
    fi
fi

# Announce session start if requested
if [[ "$announce" == "true" ]]; then
    script_dir="$(dirname "$0")"
    tts_script="$script_dir/utils/tts/pyttsx3_tts.sh"
    
    if [[ -f "$tts_script" ]]; then
        case "$source" in
            startup) message="Claude Code session started" ;;
            resume) message="Resuming previous session" ;;
            clear) message="Starting fresh session" ;;
            *) message="Session started" ;;
        esac
        
        timeout 5s "$tts_script" "$message" 2>/dev/null || true
    fi
fi

exit 0
