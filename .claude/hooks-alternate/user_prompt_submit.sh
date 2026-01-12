#!/usr/bin/env bash
# User prompt submit hook - logs and validates user prompts

set +e

# Parse command line arguments
validate_flag=false
log_only=false
store_last_prompt=false
name_agent=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --validate) validate_flag=true; shift ;;
        --log-only) log_only=true; shift ;;
        --store-last-prompt) store_last_prompt=true; shift ;;
        --name-agent) name_agent=true; shift ;;
        *) shift ;;
    esac
done

# Read JSON input from stdin
input_data=$(cat)

# Extract fields
session_id=$(echo "$input_data" | jq -r '.session_id // "unknown"')
prompt=$(echo "$input_data" | jq -r '.prompt // ""')

# Ensure log directory exists
log_dir="logs"
mkdir -p "$log_dir"
log_file="$log_dir/user_prompt_submit.json"

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

# Manage session data
if [[ "$store_last_prompt" == "true" ]] || [[ "$name_agent" == "true" ]]; then
    sessions_dir=".claude/data/sessions"
    mkdir -p "$sessions_dir"
    session_file="$sessions_dir/$session_id.json"
    
    # Load or create session file
    if [[ -f "$session_file" ]]; then
        session_data=$(cat "$session_file" 2>/dev/null || echo '{}')
        if ! echo "$session_data" | jq empty 2>/dev/null; then
            session_data='{"session_id":"'"$session_id"'","prompts":[]}'
        fi
    else
        session_data='{"session_id":"'"$session_id"'","prompts":[]}'
    fi
    
    # Add the new prompt
    session_data=$(echo "$session_data" | jq --arg p "$prompt" '.prompts += [$p]')
    
    # Generate agent name if requested and not already present
    if [[ "$name_agent" == "true" ]]; then
        has_name=$(echo "$session_data" | jq 'has("agent_name")')
        if [[ "$has_name" == "false" ]]; then
            # Try Ollama first
            agent_name=$(timeout 5s ".claude/hooks/utils/llm/ollama.sh" --agent-name 2>/dev/null || true)
            
            # Validate name (single alphanumeric word)
            if [[ -z "$agent_name" ]] || [[ "$agent_name" =~ [^a-zA-Z0-9] ]] || [[ $(echo "$agent_name" | wc -w) -gt 1 ]]; then
                # Fall back to Anthropic
                agent_name=$(timeout 10s ".claude/hooks/utils/llm/anth.sh" --agent-name 2>/dev/null || true)
            fi
            
            # Add name if valid
            if [[ -n "$agent_name" ]] && [[ "$agent_name" =~ ^[a-zA-Z0-9]+$ ]]; then
                session_data=$(echo "$session_data" | jq --arg n "$agent_name" '.agent_name = $n')
            fi
        fi
    fi
    
    # Save the updated session data
    echo "$session_data" | jq . > "$session_file" 2>/dev/null || true
fi

# Validate prompt if requested (and not in log-only mode)
if [[ "$validate_flag" == "true" ]] && [[ "$log_only" == "false" ]]; then
    # Add any blocked patterns here
    # Example: if echo "$prompt" | grep -qi "rm -rf /"; then
    #     echo "Prompt blocked: Dangerous command detected" >&2
    #     exit 2
    # fi
    :
fi

exit 0
