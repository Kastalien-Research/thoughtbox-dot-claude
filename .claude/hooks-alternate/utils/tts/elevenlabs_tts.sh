#!/usr/bin/env bash
# ElevenLabs TTS utility script

set -e

# Load .env file if it exists
if [[ -f .env ]]; then
    export $(grep -v '^#' .env | xargs)
fi

# Check for API key
if [[ -z "$ELEVENLABS_API_KEY" ]]; then
    echo "❌ Error: ELEVENLABS_API_KEY not found in environment variables" >&2
    echo "Please add your ElevenLabs API key to .env file:" >&2
    echo "ELEVENLABS_API_KEY=your_api_key_here" >&2
    exit 1
fi

# Get text from command line or use default
if [[ $# -gt 0 ]]; then
    text="$*"
else
    text="The first move is what sets everything in motion."
fi

# ElevenLabs voice ID and model
VOICE_ID="WejK3H1m7MI9CHnIjW9K"
MODEL_ID="eleven_turbo_v2_5"

# Create temp file for audio
temp_audio=$(mktemp).mp3

# Generate audio using ElevenLabs API
curl -s "https://api.elevenlabs.io/v1/text-to-speech/$VOICE_ID" \
    -H "xi-api-key: $ELEVENLABS_API_KEY" \
    -H "Content-Type: application/json" \
    -d "{
        \"text\": $(echo "$text" | jq -Rs .),
        \"model_id\": \"$MODEL_ID\",
        \"voice_settings\": {
            \"stability\": 0.5,
            \"similarity_boost\": 0.5
        }
    }" \
    -o "$temp_audio" 2>/dev/null

# Check if audio was generated
if [[ ! -s "$temp_audio" ]]; then
    echo "❌ Error: Failed to generate audio" >&2
    rm -f "$temp_audio"
    exit 1
fi

# Play audio on macOS using afplay
if command -v afplay &>/dev/null; then
    afplay "$temp_audio" 2>/dev/null
elif command -v mpg123 &>/dev/null; then
    mpg123 -q "$temp_audio" 2>/dev/null
elif command -v ffplay &>/dev/null; then
    ffplay -nodisp -autoexit -loglevel quiet "$temp_audio" 2>/dev/null
else
    echo "❌ Error: No audio player found (tried afplay, mpg123, ffplay)" >&2
    rm -f "$temp_audio"
    exit 1
fi

# Clean up
rm -f "$temp_audio"
exit 0
