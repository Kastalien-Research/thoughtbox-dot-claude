# thoughtbox-dot-claude

A comprehensive, reusable `.claude/` configuration folder for Claude Code CLI. This repository contains a curated collection of skills, commands, hooks, plugins, agents, and a learning memory system to enhance Claude Code workflows.

## Quick Start

Copy the `.claude/` folder into any project:

```bash
# Clone and copy
git clone https://github.com/Kastalien-Research/thoughtbox-dot-claude.git
cp -r thoughtbox-dot-claude/.claude/ /path/to/your/project/
```

## What's Included

### `/agents` - Custom Sub-Agents

Specialized agents for specific tasks:

- **`meta-agent.md`** - Generates new sub-agent configuration files from descriptions
- **`fact-checking-agent.md`** - Verifies claims in documentation against sources of truth
- **`reasoning-evaluator.md`** - Evaluates reasoning quality and logical consistency

### `/ai_docs` - Reference Documentation

Curated documentation for AI context:

- **Anthropic docs** - Claude Code hooks, subagents, custom commands, output styles
- **OpenAI quick start** - Reference for OpenAI API patterns
- **Memory system design** - Full design documentation for the memory system
- **uv single-file scripts** - Python scripting patterns

### `/bin` - Memory CLI Tools

Command-line utilities for the memory system:

| Command | Description |
|---------|-------------|
| `memory-add` | Add new learnings to memory |
| `memory-query` | Search memory for relevant patterns |
| `memory-stats` | View memory system statistics |
| `memory-rank` | Rank memory entries by relevance |
| `memory-pipe` | Pipe content into memory |

### `/commands` - Slash Commands (Skills)

Organized collection of 60+ slash commands:

#### Core Categories

| Category | Description | Key Commands |
|----------|-------------|--------------|
| **analysis/** | Code analysis & insights | `/context-aware-review`, `/knowledge-graph`, `/evolution-tracker` |
| **clear-thought/** | Structured thinking | `/think-solve`, `/think-debug`, `/think-decide`, `/think-create` |
| **debugging/** | Systematic debugging | `/systematic-debug`, `/distributed-debug`, `/temporal-debug` |
| **development/** | Code generation | `/implementation-variants`, `/spec-to-test`, `/implement-spec` |
| **exploration/** | Solution discovery | `/parallel-explorer` |
| **loops/** | OODA loop building blocks | Authoring, exploration, verification, refinement loops |
| **meta/** | Higher-order frameworks | `/ulysses-protocol`, `/virgil-protocol`, `/learning-accelerator` |
| **orchestration/** | Multi-agent coordination | `/swarm-intelligence`, `/meta-orchestrator`, `/adaptive-workflow` |
| **research/** | Research workflows | `/docs-researcher` |
| **speckit.*** | Specification workflows | `/speckit.specify`, `/speckit.plan`, `/speckit.tasks`, `/speckit.implement` |
| **startup/** | Session initialization | `/prime`, `/metacursor`, `/metaclaude` |
| **synthesis/** | Pattern extraction | `/pattern-synthesizer`, `/knowledge-fusion`, `/wisdom-distillation` |
| **toolscontext/** | MCP tool context | `/exa`, `/firecrawl`, `/context7` |
| **workflows/** | MCP orchestration | `/mcp-workflow`, `/mcp-chain`, `/mcp-orchestrate` |

#### Memory Commands

- `/memory-start` - Initialize memory system
- `/memory-add-quick` - Quick add to memory
- `/memory-search` - Search memory

### `/hooks` - Lifecycle Hooks

Event-driven shell scripts for Claude Code:

| Hook | Trigger | Purpose |
|------|---------|---------|
| `pre_tool_use.sh` | Before tool execution | Block dangerous git operations, validate commands |
| `post_tool_use.sh` | After tool execution | Log operations, track file access |
| `session_start.sh` | Session begins | Load context, show memory status |
| `session_end_memory.sh` | Session ends | Prompt for learning capture |
| `user_prompt_submit.sh` | User submits prompt | Pre-process user input |
| `git-validator.sh` | Permission requests | Advanced git validation (block/approve/prompt) |
| `notification.sh` | Various events | Desktop notifications |
| `track_file_access.sh` | File operations | Track which files agents access |
| `memory_pattern_detector.sh` | Periodic | Identify memory gaps and patterns |

**Protection Features:**
- Blocks force pushes and direct pushes to protected branches
- Prevents dangerous `rm -rf` operations
- Validates commit message format
- Logs all git operations for audit trail

### `/hooks-alternate` - Alternative Hook Set

Alternative hook implementations with additional utilities:

- **`utils/llm/`** - LLM API wrappers (Anthropic, OpenAI, Ollama)
- **`utils/tts/`** - Text-to-speech integrations (ElevenLabs, OpenAI, pyttsx3)

### `/output-styles` - Response Formatting

Customize Claude's output format:

| Style | Description |
|-------|-------------|
| `ultra-concise.md` | Minimal, essential information only |
| `bullet-points.md` | Structured bullet point format |
| `markdown-focused.md` | Rich markdown formatting |
| `table-based.md` | Tabular data presentation |
| `yaml-structured.md` | YAML-formatted responses |
| `html-structured.md` | HTML-formatted output |
| `tts-summary.md` | Optimized for text-to-speech |
| `genui.md` | Generative UI components |

### `/plugins` - Claude Code Plugins

Modular extensions with commands and agents:

#### agent-sdk-dev
- **Command:** `/new-sdk-app` - Scaffold new Agent SDK projects
- **Agents:** SDK verifiers for Python and TypeScript

#### commit-commands
- **Commands:** `/commit`, `/commit-push-pr`, `/clean_gone`
- **Purpose:** Streamlined git workflows

#### feature-dev
- **Command:** `/feature-dev` - 7-phase feature development workflow
- **Agents:** `code-explorer`, `code-architect`, `code-reviewer`

#### pr-review-toolkit
- **Command:** `/review-pr` - Comprehensive PR review
- **Agents:** `code-reviewer`, `silent-failure-hunter`, `code-simplifier`, `comment-analyzer`, `pr-test-analyzer`, `type-design-analyzer`

#### security-guidance
- **Purpose:** Security-focused hooks and validation

### `/rules` - Learning Memory System

A living memory system that improves over time:

```
rules/
├── 00-meta.md              # How the memory system works
├── TEMPLATE.md             # Template for new rules
├── active-context/         # Current work focus
│   └── current-focus.md
├── infrastructure/         # System-level patterns
│   ├── firebase.md
│   └── hooks-calibration.md
├── lessons/                # Time-stamped learnings
│   └── 2026-01-version-control-safety.md
├── testing/                # Testing conventions
│   └── behavioral-tests.md
└── tools/                  # Tool-specific patterns
    └── thoughtbox.md
```

**Key Features:**
- **Path-specific auto-loading:** Rules load automatically when working on matching files
- **Freshness tags:** Hot (2 weeks), Warm (3 months), Cold (>3 months), Archived
- **Calibration metrics:** Track discovery time, coverage gaps, repeated issues
- **Progressive learning:** Memory improves with each agent interaction

### `/skills` - Reusable Skills

Domain expertise modules:

| Skill | Description |
|-------|-------------|
| `docker/` | Multi-stage builds, security, optimization |
| `effect-ts/` | Effect-TS functional TypeScript patterns |
| `firebase-firestore/` | Firebase Admin SDK and Firestore |
| `gcp-cloud-run/` | Google Cloud Run deployment |
| `mcp-builder/` | Building MCP servers |
| `mcp-client-builder/` | Building MCP clients |
| `skill-creator/` | Creating new skills |
| `thoughtbox-expertise/` | ThoughtBox MCP server patterns |
| `thoughtbox-mcp/` | Building thoughtbox-style MCP servers |
| `zod4/` | Zod 4 schema validation |

### `/status_lines` - Status Line Scripts

Python scripts for custom Claude Code status lines (v2, v3, v4 variants).

### `/data` & `/state`

- **`data/`** - Persistent data storage
- **`state/`** - Runtime state (hook logs, calibration data, file access logs)

### `settings.local.json`

Local settings for enabled MCP servers:

```json
{
  "enabledMcpjsonServers": [
    "github",
    "thoughtbox",
    "firecrawl-mcp",
    "context7"
  ]
}
```

## Memory System Overview

The memory system is designed to make salient information "ready at hand":

1. **Capture** - Document learnings as they happen
2. **Consolidate** - Integrate patterns into domain rules
3. **Prune** - Archive stale information
4. **Calibrate** - Track metrics to improve topology

### Using Memory

```bash
# Check current focus
/read .claude/rules/active-context/current-focus.md

# Search memory
/memory-search "pattern name"

# Capture a learning
/meta capture-learning

# View memory status
.claude/bin/memory-stats
```

## Customization

### Adding New Rules

1. Copy `TEMPLATE.md` to the appropriate domain folder
2. Add YAML frontmatter with path patterns
3. Document learnings in the standard format

### Creating New Commands

Add markdown files to `/commands/[category]/`:

```markdown
# Command Name

Description of what this command does.

## Usage

/command-name [args]

## Implementation

[Command logic here]
```

### Adding Hooks

1. Create shell script in `/hooks/`
2. Make executable: `chmod +x .claude/hooks/your-hook.sh`
3. Configure in `.claude/settings.json`

## Repository Structure

```
.claude/
├── agents/          # Custom sub-agents
├── ai_docs/         # Reference documentation
├── bin/             # CLI utilities
├── commands/        # Slash commands (60+)
├── data/            # Persistent data
├── hooks/           # Lifecycle hooks
├── hooks-alternate/ # Alternative hooks with LLM/TTS utils
├── output-styles/   # Response formatting
├── plugins/         # Modular extensions
├── rules/           # Learning memory system
├── skills/          # Domain expertise
├── state/           # Runtime state
├── status_lines/    # Status line scripts
└── settings.local.json
```

## License

MIT

## Contributing

1. Fork the repository
2. Add your improvements
3. Submit a pull request

Focus areas for contributions:
- New skills for common development tasks
- Additional hooks for safety and automation
- Memory system improvements
- New slash commands for workflows
