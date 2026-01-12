#!/usr/bin/env bash
# Ollama LLM utility script (uses OpenAI-compatible API)

set -e

# Ollama default settings
OLLAMA_BASE_URL="${OLLAMA_BASE_URL:-http://localhost:11434/v1}"
OLLAMA_MODEL="${OLLAMA_MODEL:-gpt-oss:20b}"

# Generate completion message
generate_completion() {
    local engineer_name="${ENGINEER_NAME:-}"
    local name_instruction=""
    local examples=""
    
    if [[ -n "$engineer_name" ]]; then
        name_instruction="Sometimes (about 30% of the time) include the engineer's name '$engineer_name' in a natural way."
        examples="Examples of the style:
- Standard: \"Work complete!\", \"All done!\", \"Task finished!\", \"Ready for your next move!\"
- Personalized: \"$engineer_name, all set!\", \"Ready for you, $engineer_name!\", \"Complete, $engineer_name!\", \"$engineer_name, we're done!\""
    else
        examples="Examples of the style: \"Work complete!\", \"All done!\", \"Task finished!\", \"Ready for your next move!\""
    fi
    
    local prompt="Generate a short, friendly completion message for when an AI coding assistant finishes a task.

Requirements:
- Keep it under 10 words
- Make it positive and future focused
- Use natural, conversational language
- Focus on completion/readiness
- Do NOT include quotes, formatting, or explanations
- Return ONLY the completion message text
$name_instruction

$examples

Generate ONE completion message:"
    
    local response=$(curl -s "$OLLAMA_BASE_URL/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$OLLAMA_MODEL\",
            \"messages\": [{\"role\": \"user\", \"content\": $(echo "$prompt" | jq -Rs .)}],
            \"max_tokens\": 1000
        }" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "Error generating completion message" >&2
        return 1
    fi
    
    # Extract and clean the message
    local message=$(echo "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null)
    if [[ -n "$message" ]]; then
        # Remove quotes and take first line
        message=$(echo "$message" | tr -d '"' | tr -d "'" | head -n1)
        echo "$message"
    else
        echo "Error generating completion message" >&2
        return 1
    fi
}

# Generate agent name
generate_agent_name() {
    local examples=("Phoenix" "Sage" "Nova" "Echo" "Atlas" "Cipher" "Nexus" "Oracle" "Quantum" "Zenith")
    local examples_str=$(IFS=,; echo "${examples[*]:0:10}")
    
    local prompt="Generate exactly ONE unique agent/assistant name.

Requirements:
- Single word only (no spaces, hyphens, or punctuation)
- Abstract and memorable
- Professional sounding
- Easy to pronounce
- Similar style to these examples: $examples_str

Generate a NEW name (not from the examples). Respond with ONLY the name, nothing else.

Name:"
    
    local response=$(curl -s "$OLLAMA_BASE_URL/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$OLLAMA_MODEL\",
            \"messages\": [{\"role\": \"user\", \"content\": $(echo "$prompt" | jq -Rs .)}],
            \"max_tokens\": 1000
        }" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        # Fallback to random name
        echo "${examples[$((RANDOM % ${#examples[@]}))]}"
        return 0
    fi
    
    # Extract and validate the name
    local name=$(echo "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null | tr -d '"' | tr -d "'" | awk '{print $1}')
    # Remove non-alphanumeric characters
    name=$(echo "$name" | tr -cd '[:alnum:]')
    # Capitalize first letter
    name=$(echo "$name" | awk '{print toupper(substr($0,1,1)) tolower(substr($0,2))}')
    
    # Validate length
    if [[ -n "$name" ]] && [[ ${#name} -ge 3 ]] && [[ ${#name} -le 20 ]]; then
        echo "$name"
    else
        # Fallback to random name
        echo "${examples[$((RANDOM % ${#examples[@]}))]}"
    fi
}

# Prompt LLM with custom text
prompt_llm() {
    local prompt_text="$1"
    
    local response=$(curl -s "$OLLAMA_BASE_URL/chat/completions" \
        -H "Content-Type: application/json" \
        -d "{
            \"model\": \"$OLLAMA_MODEL\",
            \"messages\": [{\"role\": \"user\", \"content\": $(echo "$prompt_text" | jq -Rs .)}],
            \"max_tokens\": 1000
        }" 2>/dev/null)
    
    if [[ -z "$response" ]]; then
        echo "Error calling Ollama API" >&2
        return 1
    fi
    
    local message=$(echo "$response" | jq -r '.choices[0].message.content // empty' 2>/dev/null)
    if [[ -n "$message" ]]; then
        echo "$message"
    else
        echo "Error calling Ollama API" >&2
        return 1
    fi
}

# Main CLI
if [[ $# -gt 0 ]]; then
    case "$1" in
        --completion)
            generate_completion
            ;;
        --agent-name)
            generate_agent_name
            ;;
        *)
            prompt_llm "$*"
            ;;
    esac
else
    echo "Usage: $0 'your prompt here' or $0 --completion or $0 --agent-name"
    exit 1
fi
