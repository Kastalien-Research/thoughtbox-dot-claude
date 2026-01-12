# .claude/rules - Memory System

This directory contains **domain-specific memory** that helps Claude agents learn from past work and access relevant patterns when needed.

## Quick Start

### For Agents
- 🎯 **Starting work?** Check `active-context/current-focus.md`
- 🔍 **Need patterns?** Rules auto-load when you work on matching files
- 📚 **Stuck?** Check `lessons/` for similar past challenges
- ✍️ **Learned something?** Run `/meta capture-learning` to capture it

### For Humans
- 📖 **Understand the system**: Read `00-meta.md`
- 📝 **Add new rules**: Copy `TEMPLATE.md` and fill it in
- 🔄 **Maintain**: Review/update regularly, archive stale info

## Directory Structure

```
.claude/rules/
├── 00-meta.md              # How this memory system works
├── README.md               # This file
├── TEMPLATE.md             # Template for new rules files
│
├── tools/                  # Tool-specific patterns
│   ├── thoughtbox.md      [Auto-loads for: src/index.ts, src/thought-handler.ts]
│   ├── notebook.md        [Auto-loads for: src/notebook/**]
│   └── mental-models.md   [Auto-loads for: src/mental-models/**]
│
├── infrastructure/         # System-level patterns
│   ├── firebase.md        [Auto-loads for: src/firebase.ts, src/persistence/firestore.ts]
│   ├── middleware.md      [Auto-loads for: src/middleware/**]
│   └── deployment.md      [Auto-loads for: Dockerfile, cloudbuild.yaml]
│
├── testing/                # Testing conventions
│   └── behavioral-tests.md [Auto-loads for: tests/**, scripts/agentic-test.ts]
│
├── lessons/                # Cross-cutting learnings (timestamped)
│   └── 2026-01-version-control-safety.md
│
└── active-context/         # Current work state
    └── current-focus.md
```

## How It Works

### Path-Specific Auto-Loading

Rules files use **YAML frontmatter** to specify which files they apply to:

```markdown
---
paths: [src/notebook/**/*.ts]
---
# Notebook Tool Memory
...
```

When an agent reads/writes files matching those paths, Claude Code automatically loads that rule file into context.

### Standard Learning Format

When capturing significant insights, use this format:

```markdown
### YYYY-MM-DD: [Brief Title] 🔥
- **Issue**: What was the problem
- **Solution**: What worked (specifics)
- **Files**: Key files with line ranges
- **Pattern**: Reusable principle
- **See Also**: Cross-references
```

### Freshness Tags

- 🔥 **HOT** (< 2 weeks): Current active work
- ⚡ **WARM** (< 3 months): Recent patterns
- 📚 **COLD** (> 3 months): Stable knowledge
- 🗄️ **ARCHIVED** (> 6 months): Historical (moved to ai_docs/archive/)

## Common Workflows

### Agent Workflow

```bash
# 1. Check current focus
/read .claude/rules/active-context/current-focus.md

# 2. Work on files (rules auto-load)
/read src/notebook/executor.ts  # Loads rules/tools/notebook.md automatically

# 3. Capture learning when done
/meta capture-learning
```

### Human Workflow

```bash
# 1. Create new rules file
cp .claude/rules/TEMPLATE.md .claude/rules/tools/new-tool.md

# 2. Edit with your insights
vim .claude/rules/tools/new-tool.md

# 3. Add path-specific frontmatter
# ---
# paths: [src/new-tool/**]
# ---

# 4. Commit to share with team
git add .claude/rules/tools/new-tool.md
git commit -m "Add memory for new-tool"
```

## When to Update

✅ **DO capture:**
- Non-obvious bugs and their fixes
- Patterns worth repeating
- Time-saving discoveries
- "I wish I'd known this" moments

❌ **DON'T capture:**
- One-off fixes without broader lessons
- Information already in official docs
- Obvious patterns

## Maintenance

**Weekly**:
- Review new entries in domain files
- Update `active-context/current-focus.md`

**Monthly**:
- Update freshness tags (🔥 → ⚡ → 📚)
- Consolidate similar learnings

**Quarterly**:
- Archive old learnings to `ai_docs/archive/`
- Reorganize if structure isn't working

## File Organization

### By Domain

| Domain | What Goes Here | Example |
|--------|----------------|---------|
| **tools/** | Tool implementation patterns | Thoughtbox thought chain logic |
| **infrastructure/** | System-level patterns | Firebase initialization, middleware |
| **testing/** | Testing conventions | Behavioral test format |
| **lessons/** | Cross-cutting learnings | Version control safety |
| **active-context/** | Current work state | What we're working on now |

### By Freshness

- **Hot/Warm** entries: Top of "Recent Learnings" section in domain files
- **Cold** entries: Move to "Core Patterns" section (stable knowledge)
- **Archived**: Move entire file or entry to `ai_docs/archive/`

## Path-Specific Rule Examples

### Single File
```yaml
---
paths: [src/firebase.ts]
---
```

### Directory
```yaml
---
paths: [src/notebook/**]
---
```

### Multiple Patterns
```yaml
---
paths: [src/middleware/**, tests/middleware.md]
---
```

### Glob Patterns
```yaml
---
paths: [src/**/*.test.ts, tests/**]
---
```

## Cross-References

When writing rules, link to related information:

```markdown
**See Also**:
- `.claude/rules/infrastructure/firebase.md` - Firebase patterns
- `AGENTS.md` - Architectural overview
- `docs/MEMORY_SYSTEM_DESIGN.md` - Full design doc
```

## Commands

**View loaded memory**:
```bash
/memory
```

**Capture learning**:
```bash
/meta capture-learning
```

**Configure memory**:
```bash
/config
```

## Tips for Effective Memory

1. **Be Specific**: "Use 2-space indentation" > "Format code properly"
2. **Include File References**: Always cite relevant files and line ranges
3. **Write Patterns, Not Just Fixes**: Extract the general principle
4. **Cross-Reference**: Link related learnings
5. **Keep It Fresh**: Update freshness tags regularly
6. **Prune Aggressively**: Archive stale information

## Examples

### Good Learning Entry

```markdown
### 2026-01-09: Firestore Emulator Init Order 🔥
- **Issue**: Tests failed despite emulator running
- **Solution**: Set FIRESTORE_EMULATOR_HOST before firebase imports
- **Files**: `scripts/agentic-test.ts:1-5`, `src/firebase.ts:3`
- **Pattern**: Environment vars affecting module imports must be set at entry point
- **See Also**: `.claude/rules/testing/behavioral-tests.md`
```

### Bad Learning Entry

```markdown
### 2026-01-09: Fixed bug
- Changed some code
- It works now
```

(Missing: Issue description, specific files, reusable pattern)

## Philosophy

This memory system treats knowledge as:

- **Living**: Continuously updated, not static
- **Contextual**: Right info, right time, right place
- **Temporal**: Recent insights prioritized
- **Actionable**: Patterns, not just facts

**The goal**: Make salient information always "ready at hand" 🎯

---

**See Also**:
- `00-meta.md` - Comprehensive memory system guide
- `CLAUDE.md` - Memory system entry point
- `docs/MEMORY_SYSTEM_DESIGN.md` - Full design documentation
- `AGENTS.md` - Project architecture and conventions
