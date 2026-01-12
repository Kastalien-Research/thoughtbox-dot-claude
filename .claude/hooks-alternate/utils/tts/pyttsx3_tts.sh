#!/usr/bin/env bash
# pyttsx3 TTS utility script (uses macOS 'say' command for offline TTS)

set -e

# Get text from command line or use default
if [[ $# -gt 0 ]]; then
    text="$*"
else
    # Default completion messages
    messages=("Work complete!" "All done!" "Task finished!" "Job complete!" "Ready for next task!")
    text="${messages[$((RANDOM % ${#messages[@]}))]}"
fi

# Use macOS 'say' command for offline TTS
if command -v say &>/dev/null; then
    # Use say with a pleasant voice and moderate rate
    say -v Samantha -r 180 "$text" 2>/dev/null
elif command -v espeak &>/dev/null; then
    # Fallback to espeak on Linux
    espeak -s 180 "$text" 2>/dev/null
elif command -v spd-say &>/dev/null; then
    # Fallback to speech-dispatcher on Linux
    spd-say -r 20 "$text" 2>/dev/null
else
    echo "❌ Error: No TTS engine found (tried say, espeak, spd-say)" >&2
    echo "Text to speak: $text" >&2
    exit 1
fi

exit 0
