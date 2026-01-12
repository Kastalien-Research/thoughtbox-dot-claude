#!/usr/bin/env bash
# Pre tool use hook - validates and logs tool usage

set +e  # Don't exit on error, we want to handle them

# Read JSON input from stdin
input_data=$(cat)

# Extract tool name and input
tool_name=$(echo "$input_data" | jq -r '.tool_name // ""')
tool_input=$(echo "$input_data" | jq -c '.tool_input // {}')

# Function to check dangerous rm commands
is_dangerous_rm_command() {
    local cmd=$(echo "$1" | tr -s ' ' | tr '[:upper:]' '[:lower:]')
    
    # Check for rm -rf variations
    if echo "$cmd" | grep -qE '\brm\s+.*-[a-z]*r[a-z]*f'; then
        return 0
    fi
    if echo "$cmd" | grep -qE '\brm\s+.*-[a-z]*f[a-z]*r'; then
        return 0
    fi
    if echo "$cmd" | grep -qE '\brm\s+--recursive\s+--force'; then
        return 0
    fi
    if echo "$cmd" | grep -qE '\brm\s+--force\s+--recursive'; then
        return 0
    fi
    if echo "$cmd" | grep -qE '\brm\s+-r\s+.*-f'; then
        return 0
    fi
    if echo "$cmd" | grep -qE '\brm\s+-f\s+.*-r'; then
        return 0
    fi
    
    # Check for rm with recursive flag and dangerous paths
    if echo "$cmd" | grep -qE '\brm\s+.*-[a-z]*r'; then
        # Check dangerous paths
        if echo "$cmd" | grep -qE '(/\*|~/?|\$HOME|\.\.| \*|^\.)'; then
            return 0
        fi
    fi
    
    return 1
}

# Function to check .env file access
is_env_file_access() {
    local tool="$1"
    local input="$2"
    
    case "$tool" in
        Read|Edit|MultiEdit|Write)
            local file_path=$(echo "$input" | jq -r '.file_path // ""')
            if [[ "$file_path" == *.env* ]] && [[ "$file_path" != *.env.sample ]]; then
                return 0
            fi
            ;;
        Bash)
            local command=$(echo "$input" | jq -r '.command // ""')
            if echo "$command" | grep -qE '\b\.env\b' && ! echo "$command" | grep -qE '\.env\.sample'; then
                return 0
            fi
            ;;
    esac
    
    return 1
}

# Check for .env file access
if is_env_file_access "$tool_name" "$tool_input"; then
    echo "BLOCKED: Access to .env files containing sensitive data is prohibited" >&2
    echo "Use .env.sample for template files instead" >&2
    exit 2
fi

# Check for dangerous rm commands
if [[ "$tool_name" == "Bash" ]]; then
    command=$(echo "$tool_input" | jq -r '.command // ""')
    if is_dangerous_rm_command "$command"; then
        echo "BLOCKED: Dangerous rm command detected and prevented" >&2
        exit 2
    fi
fi

# Ensure log directory exists
log_dir="logs"
mkdir -p "$log_dir"
log_file="$log_dir/pre_tool_use.json"

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

# Write back to file with formatting
echo "$log_data" | jq . > "$log_file"

exit 0