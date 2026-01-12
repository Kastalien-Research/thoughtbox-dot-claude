# Claude Code Hooks - Shell Scripts

All hook scripts have been converted from Python to pure shell scripts for better portability and reduced dependencies.

## Hook Scripts

### Main Hooks
- **post_tool_use.sh** - Logs tool usage events after execution
- **pre_tool_use.sh** - Validates tool usage before execution (blocks dangerous commands)
- **pre_compact.sh** - Logs and backs up transcripts before context compaction
- **notification.sh** - Logs notifications and announces via TTS
- **session_start.sh** - Logs session start and loads development context
- **stop.sh** - Logs stop events and announces completion
- **subagent_stop.sh** - Logs subagent completion
- **user_prompt_submit.sh** - Logs and validates user prompts

### Utility Scripts

#### LLM Utilities (`utils/llm/`)
- **oai.sh** - OpenAI API integration for completion messages and agent naming
- **anth.sh** - Anthropic (Claude) API integration
- **ollama.sh** - Ollama local LLM integration

#### TTS Utilities (`utils/tts/`)
- **openai_tts.sh** - OpenAI TTS API for voice synthesis
- **elevenlabs_tts.sh** - ElevenLabs TTS API for high-quality voice
- **pyttsx3_tts.sh** - Offline TTS using macOS `say` command (no API key needed)

## API Keys Configuration

To enable optional features, add API keys to a `.env` file in the project root:

### LLM Services (for completion messages and agent naming)

```bash
# OpenAI (gpt-4o-mini)
OPENAI_API_KEY=sk-...

# Anthropic (Claude Haiku)
ANTHROPIC_API_KEY=sk-ant-...

# Ollama (local, no key needed but must be running)
OLLAMA_BASE_URL=http://localhost:11434/v1  # optional, defaults to this
OLLAMA_MODEL=gpt-oss:20b                    # optional, defaults to this
```

### TTS Services (for voice notifications)

```bash
# ElevenLabs (highest quality, highest priority)
ELEVENLABS_API_KEY=...

# OpenAI TTS (good quality, second priority)
OPENAI_API_KEY=sk-...

# pyttsx3/say (offline fallback, no key needed - uses macOS 'say' command)
```

### Optional Configuration

```bash
# Engineer name (optionally included in notifications ~30% of the time)
ENGINEER_NAME="YourName"
```

## Priority Order

**LLM Services** (for completion messages):
1. OpenAI (if `OPENAI_API_KEY` is set)
2. Anthropic (if `ANTHROPIC_API_KEY` is set)
3. Ollama (if running locally)
4. Fallback to predefined messages

**TTS Services** (for voice notifications):
1. ElevenLabs (if `ELEVENLABS_API_KEY` is set)
2. OpenAI TTS (if `OPENAI_API_KEY` is set)
3. macOS `say` command (offline, always available on macOS)

## Dependencies

The scripts require these common Unix utilities:
- `bash` (shell)
- `jq` (JSON processing)
- `curl` (API requests)
- `afplay` or `say` (audio playback on macOS)
- Standard tools: `grep`, `awk`, `date`, `git`, etc.

## No Python/UV Required

Unlike the previous Python versions, these shell scripts:
- Don't require Python or `uv`
- Don't need dependency installation
- Work with just standard Unix tools
- Are more portable across systems

## Testing Utilities

You can test individual utility scripts:

```bash
# Test LLM scripts
.claude/hooks/utils/llm/oai.sh --completion
.claude/hooks/utils/llm/oai.sh --agent-name
.claude/hooks/utils/llm/anth.sh "Hello, how are you?"

# Test TTS scripts
.claude/hooks/utils/tts/openai_tts.sh "Hello world"
.claude/hooks/utils/tts/elevenlabs_tts.sh "Testing audio"
.claude/hooks/utils/tts/pyttsx3_tts.sh "No API key needed"
```

## Notes

- All logs are saved to the `logs/` directory
- The `.claude/` directory is gitignored by default
- Hook scripts run automatically when Claude Code triggers them
- TTS and LLM features are optional - hooks work without them
