# Memory System Design

**Created**: 2026-01-09
**Purpose**: Learning memory system that improves information topology over time

---

## Executive Summary

This document describes the **progressive learning memory system** for Claude Code projects. The system enables Claude agents (Agent SDK, Claude Code CLI) to:

1. **Learn from past work** through structured memory capture
2. **Access relevant information contextually** via path-specific rules
3. **Improve information topology over time** as patterns emerge
4. **Maintain fresh, actionable knowledge** through temporal decay

**Core Principle**: Make salient information "ready at hand" - the right information, at the right time, in the right place.

---

## Design Goals

### 1. Progressive Learning
- Memory improves incrementally through agent interactions
- Patterns emerge and crystallize over time
- Recent learnings prioritized over stale information

### 2. Contextual Discovery
- Information appears when relevant (path-specific rules)
- Hierarchical scoping (project → domain → file-specific)
- Automatic loading reduces cognitive overhead

### 3. Low Friction Capture
- Easy to add learnings during work sessions
- Standard templates and formats
- Integrated into workflow, not separate process

### 4. Temporal Awareness
- Recent insights marked as "hot" (high priority)
- Older stable patterns marked as "cold" (reference)
- Decay and archival prevent information overload

---

## Architecture

### Memory Hierarchy

```
┌─────────────────────────────────────────────────────────────┐
│  CLAUDE.md                                                   │
│  Entry point, router to specialized memory                  │
│  Loaded: Always                                             │
└────────────────────────┬────────────────────────────────────┘
                         │
          ┌──────────────┼──────────────┐
          │              │              │
┌─────────▼─────────┐  ┌─▼──────────┐  ┌▼─────────────────┐
│   AGENTS.md        │  │ .claude/   │  │ active-context/  │
│   Foundation       │  │ rules/     │  │ current-focus    │
│   Architecture     │  │ Domain     │  │ Current work     │
│   Conventions      │  │ Specific   │  │ Recent decisions │
└────────────────────┘  └─┬──────────┘  └──────────────────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
    ┌─────▼─────┐  ┌──────▼──────┐  ┌────▼────┐
    │ tools/    │  │ infra-      │  │ lessons/│
    │ [feature] │  │ structure/  │  │ YYYY-MM-│
    │ [api]     │  │ database    │  │ topic   │
    │ [etc]     │  │ middleware  │  │ ...     │
    └───────────┘  │ deployment  │  │         │
                   └─────────────┘  └─────────┘
```

### Directory Structure

```
.claude/
├── rules/
│   ├── 00-meta.md                      # Memory system guide
│   ├── TEMPLATE.md                     # Template for new rules
│   │
│   ├── tools/                          # Tool-specific patterns
│   │   └── [tool-name].md             [paths: src/[tool]/**]
│   │
│   ├── infrastructure/                 # System-level patterns
│   │   ├── database.md                [paths: src/db/**, src/persistence/**]
│   │   ├── middleware.md              [paths: src/middleware/**]
│   │   └── deployment.md              [paths: Dockerfile, *.yaml]
│   │
│   ├── testing/                        # Testing conventions
│   │   └── testing.md                 [paths: tests/**, **/*.test.ts]
│   │
│   ├── lessons/                        # Cross-cutting learnings
│   │   └── YYYY-MM-[topic].md
│   │
│   └── active-context/                 # Current work state
│       └── current-focus.md
│
└── commands/
    └── meta/
        └── capture-learning.md         # Workflow for capturing learnings
```

---

## Key Mechanisms

### 1. Path-Specific Auto-Loading

**Mechanism**: YAML frontmatter in rules files
```markdown
---
paths: [src/api/**/*.ts, src/api/**/*.js]
---
# API Handler Memory
...
```

**Behavior**: When agent reads/writes files matching these paths, Claude Code automatically loads this rule file into context.

**Benefit**: Relevant information appears without explicit imports.

### 2. Temporal Freshness System

**Tags**:
- HOT (< 2 weeks): Current active work, highest priority
- WARM (< 3 months): Recent patterns, very relevant
- COLD (> 3 months): Stable knowledge, reference as needed
- ARCHIVED (> 6 months): Historical, moved to `ai_docs/archive/`

**Benefit**: Agents prioritize recent learnings, stale info doesn't clutter context.

### 3. Structured Learning Capture

**Standard Format**:
```markdown
### YYYY-MM-DD: [Brief Title] [emoji]
- **Issue**: What was the problem
- **Solution**: What worked (specifics)
- **Files**: Key files with line ranges
- **Pattern**: Reusable principle
- **See Also**: Cross-references
```

**Benefit**: Consistent structure enables quick scanning, pattern recognition.

### 4. Memory Lifecycle

```
┌─────────────┐
│  Capture    │  During/after work session
│  (Hot)      │  Add to domain-specific rules file
└─────┬───────┘
      │
      ▼
┌─────────────┐
│ Consolidate │  Weekly/monthly review
│  (Warm)     │  Integrate recurring patterns
└─────┬───────┘
      │
      ▼
┌─────────────┐
│  Stabilize  │  Patterns become "cold" stable knowledge
│  (Cold)     │  Move to "Core Patterns" section
└─────┬───────┘
      │
      ▼
┌─────────────┐
│   Archive   │  Quarterly cleanup
│ (Archived)  │  Move to ai_docs/archive/
└─────────────┘
```

---

## Information Topology Principles

### 1. Proximity Principle
**Definition**: Information should be near where it's used.

**Implementation**:
- Path-specific rules load when working on matching files
- Domain organization mirrors codebase structure
- Related concepts cross-referenced

**Example**: Editing `src/database.ts` auto-loads `.claude/rules/infrastructure/database.md`

### 2. Specificity Hierarchy
**Definition**: More specific information overrides general.

**Implementation**:
```
Highest Priority:
├─ Path-specific rules (e.g., tools/api.md)
├─ Recent lessons (e.g., lessons/2026-01-topic.md)
├─ Active context (e.g., active-context/current-focus.md)
├─ Domain rules (e.g., infrastructure/database.md)
└─ Foundation (AGENTS.md)
Lowest Priority
```

### 3. Recency Bias
**Definition**: Recent information is prioritized.

**Implementation**:
- Entries sorted newest-first
- Temporal tags
- "Recent Learnings" section at top of files

### 4. Actionability Over Description
**Definition**: Capture patterns, not just facts.

**Implementation**:
- "Pattern" field in learning format
- "Common Pitfalls" with examples
- "Quick Reference" for immediate use

---

## Workflows

### Agent Starting a Task

```
Agent receives task
     ↓
Check active-context/current-focus.md
     ↓
CLAUDE.md loads foundation
     ↓
Agent reads relevant files
     ↓
Path-specific rules auto-load
     ↓
Begin work with context
```

**What's loaded**:
1. `CLAUDE.md` (entry point)
2. `AGENTS.md` (foundation)
3. `active-context/current-focus.md` (current state)
4. Path-specific rules (automatic)

### Agent Capturing Learning

```
Significant insight occurs
     ↓
Run /meta capture-learning
     ↓
Reflect on problem/solution/pattern
     ↓
Draft learning entry
     ↓
Identify domain
     ↓
Update relevant rules file
     ↓
Optional: Update current-focus.md
     ↓
Learning is now available
```

**Result**: Next agent working in that domain will have this knowledge.

### Memory Maintenance (Periodic)

**Weekly**:
- Review `lessons/` directory
- Integrate recurring patterns into domain rules
- Update `active-context/current-focus.md`

**Monthly**:
- Update freshness tags
- Consolidate similar learnings
- Archive deprecated information

**Quarterly**:
- Move >6 month learnings to `ai_docs/archive/`
- Major reorganization if structure isn't working
- Update `00-meta.md` with system improvements

---

## Success Metrics

### Quantitative

1. **Discovery Time**: How long to find relevant information
   - Baseline: 2-5 minutes searching codebase/docs
   - Target: < 30 seconds via path-specific rules

2. **Repeated Mistakes**: Same issue encountered multiple times
   - Baseline: 3-5 repeats of common issues (observed)
   - Target: 0-1 repeats (captured in memory)

3. **Ramp-Up Time**: New agent (or context window) getting productive
   - Baseline: 10-20 minutes understanding codebase
   - Target: 2-5 minutes with memory system

4. **Memory Staleness**: Age of information in rules files
   - Track: Percentage of entries < 3 months old
   - Target: > 60% warm or hot

### Qualitative

1. **Relevance**: Right information at right time?
2. **Actionability**: Can agents apply learnings immediately?
3. **Discoverability**: Can agents find information without help?
4. **Evolution**: Is memory improving over time?

---

## Getting Started

### For New Developers

1. Read `CLAUDE.md` (entry point)
2. Read `AGENTS.md` (foundation)
3. Skim `.claude/rules/00-meta.md` (system guide)
4. Browse domain rules relevant to your work
5. Use `/memory` to see what's loaded

### For Agents (New Context Window)

1. CLAUDE.md loads automatically
2. Check `active-context/current-focus.md` first
3. Path-specific rules load as you work
4. When stuck, check `lessons/` for similar issues
5. When done, capture learnings with `/meta capture-learning`

### For Maintainers

1. Weekly: Review new learnings in rules files
2. Monthly: Update freshness tags, consolidate patterns
3. Quarterly: Archive old learnings, reorganize if needed
4. Continuously: Improve `00-meta.md` as system evolves

---

## Conclusion

This Memory System is an **experiment in progressive learning** for AI agents. It treats codebase knowledge as:

- **Living**: Continuously updated, not static
- **Contextual**: Right information, right time, right place
- **Temporal**: Recent insights prioritized
- **Actionable**: Patterns, not just facts

**Success means**: Agents get smarter over time. Mistakes aren't repeated. Patterns are discovered and reused. Information topology improves.

**The goal**: Make salient information always "ready at hand"

---

**References**:
- Implementation: `.claude/rules/` directory
- System Guide: `.claude/rules/00-meta.md`

**Created**: 2026-01-09
**Status**: Initial implementation, evolving
