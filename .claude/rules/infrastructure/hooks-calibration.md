---
paths: [.claude/hooks/**]
---

# Memory System Hooks & Calibration

> **Purpose**: Automatic memory system calibration through lifecycle hooks

## Overview

The memory system uses **lifecycle hooks** to guarantee that every agent interaction contributes to improving information topology. This is environmental calibration - we're not training the model, we're training the environment.

## Hook Architecture

```
┌─────────────────────────────────────────────────────────┐
│                   Agent Lifecycle                        │
└─────────────────────────────────────────────────────────┘

Session Start
     ↓
  [session_start.sh - Load current-focus + memory status]
     ↓
     ├─→ Show active context
     ├─→ Count available memory files
     └─→ Display hot/warm learnings count
     ↓
Agent Works (Multiple Tools)
     ↓
  [post_tool_use.sh → track_file_access.sh]
     ├─→ Log which files are accessed
     ├─→ Track errors encountered
     └─→ Detect repeated patterns
     ↓
  [post_tool_use.sh → memory_pattern_detector.sh] (periodic)
     ├─→ Find coverage gaps (frequent access, no memory)
     ├─→ Find repeated issues (same problem multiple times)
     ├─→ Calculate discovery time metrics
     └─→ Suggest memory improvements
     ↓
Session End
     ↓
  [session_end_memory.sh - Prompt for learning capture]
     ├─→ Ask: "Did memory help?"
     ├─→ Prompt: "What did you learn?"
     └─→ Suggest: Run /meta capture-learning
     ↓
Agent Updates Memory (if significant learnings)
     ↓
  [Memory topology improved for next agent]
```

## Hook Files

### 1. **session_start.sh** (Enhanced)
**Path**: `.claude/hooks/session_start.sh`  
**Trigger**: Session begins  
**Purpose**: Load context and show memory system status

**What it does**:
- Loads `.claude/rules/active-context/current-focus.md`
- Counts available memory files
- Counts hot/warm learnings
- Shows git status and recent changes

**Output to agent**:
```
--- 🎯 Current Focus (Memory System) ---
[Contents of current-focus.md]

--- 🧠 Memory System Status ---
Available memory files: 12
Hot learnings (< 2 weeks): 5
Warm learnings (< 3 months): 8

See CLAUDE.md for memory system guide
```

### 2. **track_file_access.sh** (New)
**Path**: `.claude/hooks/track_file_access.sh`  
**Trigger**: After every tool use  
**Purpose**: Track which files agents access

**What it tracks**:
- Files read/written by agents
- Errors encountered
- Timestamps for discovery time analysis

**Data stored**: `.claude/state/file_access.log`, `.claude/state/errors.log`

**Silent**: No output to agent (background tracking)

### 3. **memory_pattern_detector.sh** (New)
**Path**: `.claude/hooks/memory_pattern_detector.sh`  
**Trigger**: Periodically (every ~10 tool uses) or on-demand  
**Purpose**: Analyze patterns and suggest memory improvements

**What it detects**:
- **Coverage gaps**: Files accessed frequently but no memory rules
- **Repeated issues**: Same problems encountered multiple times
- **Slow discovery**: Taking >2 minutes to find information
- **Pattern convergence**: Multiple agents learning same thing

**Output to agent** (if patterns found):
```
🎯 **Coverage Gaps Detected:**

Files with frequent access but no memory rules:
  - src/sampling/handler.ts (5x accessed)
  - src/templates/index.ts (4x accessed)

Consider creating path-specific rules for these files.

🔁 **Repeated Issues:**

Same problems encountered multiple times:
  - "Firestore connection timeout" (3x)
  - "Session validation failed" (2x)

These should be documented in .claude/rules/lessons/
```

**Data stored**: `.claude/state/memory-calibration.json`

### 4. **session_end_memory.sh** (New)
**Path**: `.claude/hooks/session_end_memory.sh`  
**Trigger**: Session ends  
**Purpose**: Prompt agent to capture learnings

**What it does**:
- Counts turns in session
- Prompts reflection questions
- Suggests `/meta capture-learning` command
- Requests optional effectiveness rating (1-10)

**Output to agent**:
```
📝 Session Complete - Memory System Calibration

## 🧠 Memory System Calibration

This session is ending. Help improve the memory system:

### Quick Reflection

1. **Did memory help you?**
   - Were relevant patterns/rules loaded when you needed them?
   - What information was readily available?
   - What was missing or hard to find?

2. **What did you learn?**
   - Non-obvious patterns?
   - Problems future agents should know about?
   - Anti-patterns or common mistakes?

### If You Learned Something Significant

Run: `/meta capture-learning`

OR update: `.claude/rules/[domain]/[topic].md`

### Memory Effectiveness Rating (Optional)
Rate this session: [1-10]

**No action required** if this was a simple session.
```

## Calibration Data

### Location
All calibration data is stored in `.claude/state/`:

```
.claude/state/
├── memory-calibration.log      # Event log (timestamped)
├── memory-calibration.json     # Structured metrics
├── file_access.log             # Files accessed (last 500)
└── errors.log                  # Errors encountered (last 200)
```

### Metrics Tracked

**memory-calibration.json structure**:
```json
{
  "coverage_gaps": [
    {
      "file": "src/sampling/handler.ts",
      "access_count": 5,
      "detected": "2026-01-09 10:30:15"
    }
  ],
  "repeated_issues": [
    {
      "error": "Firestore connection timeout",
      "count": 3,
      "detected": "2026-01-09 11:45:22"
    }
  ],
  "discovery_times": [
    {
      "seconds": 18,
      "timestamp": "2026-01-09 09:15:30"
    }
  ],
  "last_analysis": "2026-01-09 12:00:00"
}
```

## Integration

### Automatic (Session Lifecycle)

**session_start.sh**: Already runs automatically ✅

**session_end_memory.sh**: Add to `.claude/settings.json`:
```json
{
  "hooks": {
    "session_end": ".claude/hooks/session_end_memory.sh"
  }
}
```

### Manual Integration (post_tool_use.sh)

Add to `.claude/hooks/post_tool_use.sh`:

```bash
# At the end of the file, before exit

# Track file access (every tool use)
.claude/hooks/track_file_access.sh <<< "$hook_input" 2>/dev/null || true

# Run pattern detection periodically (every ~10 tool uses)
if (( $(($RANDOM % 10)) == 0 )); then
    .claude/hooks/memory_pattern_detector.sh <<< "$hook_input" 2>/dev/null || true
fi
```

### On-Demand Analysis

Run pattern detector manually:
```bash
echo '{}' | .claude/hooks/memory_pattern_detector.sh
```

## Calibration Workflow

### Daily (Automatic)
1. Agent starts session → Loads current focus
2. Agent works → Files tracked, errors logged
3. Pattern detector runs → Identifies gaps
4. Session ends → Prompt for learnings
5. Agent updates memory → Topology improves

### Weekly (Human Review)
```bash
# View calibration metrics
jq '.' .claude/state/memory-calibration.json

# Find coverage gaps
jq '.coverage_gaps // []' .claude/state/memory-calibration.json

# Find repeated issues
jq '.repeated_issues // []' .claude/state/memory-calibration.json

# View recent log
tail -100 .claude/state/memory-calibration.log
```

### Monthly (Analysis)
- Review which files have high access but no memory
- Create new rules files for coverage gaps
- Document repeated issues in lessons/
- Update freshness tags in existing rules

## Calibration Metrics

### Success Indicators

**Good Calibration**:
- Discovery time trending down (target: <30s)
- Coverage gaps decreasing
- Repeated issues = 0 (captured in memory)
- High agent effectiveness ratings (7-10)

**Needs Improvement**:
- Discovery time >2 minutes frequently
- Same files accessed repeatedly without memory
- Same errors recurring
- Low effectiveness ratings (1-6)

### Analysis Queries

**Average discovery time**:
```bash
jq '[.discovery_times[] | .seconds] | add / length' .claude/state/memory-calibration.json
```

**Top coverage gaps** (most accessed, no memory):
```bash
jq '.coverage_gaps | sort_by(-.access_count) | .[0:5]' .claude/state/memory-calibration.json
```

**Most repeated issues**:
```bash
jq '.repeated_issues | sort_by(-.count) | .[0:5]' .claude/state/memory-calibration.json
```

## Example: Coverage Gap Resolution

### Detection
```
[$timestamp] ⚠️  Coverage Gap: src/sampling/handler.ts accessed 5x but no memory rules found
```

### Resolution
1. Create `.claude/rules/tools/sampling.md`:
```markdown
---
paths: [src/sampling/**]
---

# Sampling Tool Memory

## Recent Learnings

### 2026-01-09: Sampling Handler Patterns 🔥
- **Issue**: Understanding how sampling parameters affect responses
- **Solution**: [Document the pattern]
- **Files**: `src/sampling/handler.ts:50-80`
- **Pattern**: [Reusable principle]
```

2. Next agent working on `src/sampling/handler.ts` → Rules auto-load → No more gap

## Example: Repeated Issue Resolution

### Detection
```
[$timestamp] 🔁 Repeated Issue: "Firestore connection timeout" seen 3x
```

### Resolution
1. Add to `.claude/rules/infrastructure/firebase.md`:
```markdown
### 2026-01-09: Firestore Connection Timeouts 🔥
- **Issue**: Intermittent Firestore connection timeouts in tests
- **Solution**: Set FIRESTORE_EMULATOR_HOST before imports
- **Files**: `scripts/agentic-test.ts:1-5`
- **Pattern**: Environment vars affecting module imports must be set early
- **See Also**: `.claude/rules/testing/behavioral-tests.md`
```

2. Next agent hits same issue → Finds solution in firebase.md → Problem solved immediately

## Testing Hooks

### Test session start enhancement:
```bash
echo '{"session_id": "test", "source": "terminal"}' | .claude/hooks/session_start.sh --load-context
```

### Test session end prompt:
```bash
echo '{"session_id": "test", "transcript_path": "~/.claude/transcript.json"}' | .claude/hooks/session_end_memory.sh
```

### Test file tracking:
```bash
echo '{"tool_name": "read_file", "tool_arguments": {"target_file": "src/index.ts"}}' | .claude/hooks/track_file_access.sh
cat .claude/state/file_access.log
```

### Test pattern detection:
```bash
# Simulate some file accesses first
for i in {1..5}; do
    echo '{"tool_name": "read_file", "tool_arguments": {"target_file": "src/test.ts"}}' | .claude/hooks/track_file_access.sh
done

# Run pattern detector
echo '{}' | .claude/hooks/memory_pattern_detector.sh
```

## Troubleshooting

### Hooks not running
- Check if executable: `ls -l .claude/hooks/*.sh`
- Make executable: `chmod +x .claude/hooks/*.sh`
- Check hook output: Run manually with test data

### No calibration data
- Hooks might not be integrated yet
- Check `.claude/state/` directory exists
- Run `mkdir -p .claude/state`

### Pattern detector shows no patterns
- Need more data (run for a few days)
- Check if tracking is working: `cat .claude/state/file_access.log`

## Related Files

- 📁 `.claude/hooks/session_start.sh` - Session initialization
- 📁 `.claude/hooks/session_end_memory.sh` - Learning capture prompt
- 📁 `.claude/hooks/track_file_access.sh` - Background tracking
- 📁 `.claude/hooks/memory_pattern_detector.sh` - Pattern analysis
- 📄 `.claude/rules/00-meta.md` - Memory system guide
- 📄 `docs/MEMORY_SYSTEM_DESIGN.md` - Complete design doc

## Philosophy

These hooks embody the principle: **Every agent interaction improves the environment**.

- **Automatic**: No agent effort required for tracking
- **Opportunistic**: Prompts at natural boundaries (session end)
- **Actionable**: Suggests specific improvements
- **Cumulative**: Benefits compound over time

The calibration loop is now **guaranteed** through hooks - no manual intervention needed for the system to learn and improve.

---

**Created**: 2026-01-09  
**Status**: ✅ Hooks created, ready for integration  
**Next**: Integrate with post_tool_use.sh and settings.json
