# Memory System Meta-Rules

## Purpose

This memory system helps Claude agents learn from past work and access relevant information when needed. The goal is to make salient information "ready at hand" through progressive learning.

## Memory Architecture

```
.claude/rules/
├── 00-meta.md (this file)       # How the memory system works
├── tools/                        # Tool-specific patterns and learnings
├── infrastructure/               # Deployment, databases, middleware
├── testing/                      # Testing patterns and conventions
├── lessons/                      # Time-stamped learnings from sessions
└── active-context/              # Current work focus
```

## How This Memory Learns

### 1. Capture (During/After Work)
When you discover something significant:
- Update the relevant `.claude/rules/[domain]/[topic].md` file
- Add a timestamped entry at the TOP of the "Recent Learnings" section
- Use this format:

```markdown
### YYYY-MM-DD: [Brief Title]
- **Issue**: [What was the problem or challenge]
- **Solution**: [What worked, with specifics]
- **Files**: [Key files, with line ranges if relevant]
- **Pattern**: [Reusable principle or heuristic]
- **See Also**: [Links to related learnings or docs]
```

### 2. Consolidate (Weekly/Monthly)
- Review `lessons/` directory
- Integrate recurring patterns into domain-specific rules
- Update AGENTS.md if architectural patterns emerge
- Archive old lessons that are now stable knowledge

### 3. Prune (Quarterly)
- Move learnings >6 months old to `ai_docs/archive/` if still relevant
- Remove outdated information that no longer applies
- Refresh "Common Pitfalls" sections to keep them concise

## Memory Freshness System

Use these tags to indicate recency:

- 🔥 **HOT** (last 2 weeks): Current active work, highest priority
- ⚡ **WARM** (last 3 months): Recent patterns, very relevant  
- 📚 **COLD** (>3 months): Stable knowledge, reference as needed
- 🗄️ **ARCHIVED** (>6 months): Historical, in ai_docs/archive/

## Path-Specific Rules

Rules can use YAML frontmatter to auto-load when working on specific files:

```markdown
---
paths: src/notebook/**/*.ts
---

# Notebook Tool Patterns
...
```

When an agent reads/writes files matching these paths, this rule file is automatically loaded into context.

## When to Update Memory

Update memory when:

✅ **DO capture:**
- Non-obvious bugs and their fixes
- Patterns worth repeating
- Time-saving discoveries
- "I wish I'd known this earlier" moments
- Common mistakes and how to avoid them

❌ **DON'T capture:**
- One-off fixes without broader lessons
- Information already in official docs
- Obvious or self-explanatory patterns
- Overly specific details that won't generalize

## Update Checklist

When adding a significant learning:

- [ ] Update relevant `.claude/rules/[domain]/[topic].md`
- [ ] Add freshness tag (🔥/⚡/📚)
- [ ] Include file references with line numbers
- [ ] Write reusable pattern, not just the specific fix
- [ ] Consider if AGENTS.md needs updating (architectural changes)
- [ ] Add cross-references to related learnings

## Memory Query Patterns

### For Agents Working in This Codebase

**Starting a task:**
1. Check `.claude/rules/active-context/current-focus.md` for ongoing work
2. Path-specific rules auto-load when you read relevant files
3. Use `/memory` command to see all loaded memory

**Stuck on something:**
1. Check `.claude/rules/lessons/` for similar past challenges
2. Look in domain-specific rules (e.g., `tools/[your-tool].md`)
3. Search `ai_docs/` for deeper context

**Finishing a task:**
1. Use `/meta capture-learning` command to reflect
2. Update relevant rules files
3. Update `active-context/current-focus.md` if needed

## Memory Maintenance Commands

```bash
# View current memory
/memory

# Create new lesson
/new .claude/rules/lessons/$(date +%Y-%m-%d)-[topic].md

# Archive old lessons
/run mv .claude/rules/lessons/2025-* ai_docs/archive/lessons-2025/
```

## Principles

1. **Proximity**: Information should be near where it's used (path-specific rules)
2. **Recency**: Recent learnings are prioritized (temporal tagging)
3. **Actionability**: Capture patterns, not just facts
4. **Discoverability**: Use consistent structure and cross-references
5. **Progressive**: Memory improves incrementally over time
6. **Calibration**: Every agent interaction improves the information topology

## Environmental Calibration

This memory system is not just documentation - it's an **evolving cognitive landscape** that improves through use.

### How Calibration Works

Every agent interaction contributes to the information topology:

1. **Implicit Feedback**: 
   - Fast discovery (< 30s) = good topology
   - Slow/failed discovery = needs improvement
   - Repeated issues = memory gaps

2. **Explicit Feedback** (Future):
   - Session end reflection: "Did memory help?"
   - Learning impact tracking: Which patterns are used most?
   - Pattern convergence: Multiple agents discover same thing

3. **Environmental Reshaping**:
   - Capture → Memory landscape expands
   - Consolidate → Patterns crystallize
   - Archive → Noise reduces
   - Cross-reference → Connections strengthen

### Calibration Metrics to Track

**Discovery Time**:
- How long to find relevant information?
- Target: <30 seconds for common patterns
- Track: Manual timer or tool usage logs

**Repeat Issues**:
- Same problem encountered multiple times?
- Should have been in memory after first occurrence
- Track: Search `.claude/rules/` for similar past issues

**Memory Utilization**:
- High-impact learnings (referenced frequently) vs. dead weight (never used)
- Target: >60% of learnings are warm/hot and actively used
- Track: Could add reference counters (future enhancement)

**Coverage Gaps**:
- Areas with frequent work but sparse memory
- Signals where new rules files are needed
- Track: Compare git activity to rules coverage

### Agent Self-Assessment Template

After significant work, optionally reflect to calibrate the system:

```markdown
## Session Calibration - YYYY-MM-DD

**Task**: [What was I working on]

**Memory Effectiveness**:
- ✅ What helped: [Specific learnings/rules that were useful]
- ❌ What was missing: [What I needed but couldn't find]
- 🔄 What was confusing: [Unclear or conflicting patterns]

**Discovery Time**:
- Relevant info found in: [< 30s | 30s-2m | 2m-5m | >5m]

**Contribution**:
- Added/updated: [Which rules files]
- New patterns captured: [Brief description]

**Overall: [1-10]**
```

**Purpose**: Over time, these assessments reveal:
- Which memory areas are high-quality (consistently helpful)
- Which areas need improvement (frequently rated low)
- Emerging patterns (multiple agents mention same gap)

### Calibration Maintenance

**Weekly** (Automated where possible):
- Scan for pattern convergence (multiple agents, same learning)
- Identify memory gaps (repeated issues, no corresponding memory)
- Track discovery time trends

**Monthly** (Human/agent review):
- Review low-impact learnings (candidates for removal)
- Consolidate converged patterns
- Update freshness tags based on actual usage

**Quarterly** (Strategic):
- Analyze memory effectiveness metrics
- Major restructuring if topology isn't optimal
- Update calibration processes based on what works

### Future Enhancements for Calibration

**Impact Tracking**:
```markdown
### 2026-01-09: Pattern Name 🔥 [Impact: High | Used: 5x]
- **Issue**: ...
- **Solution**: ...
```

**Convergence Detection**:
- When multiple agents independently discover same pattern
- Auto-suggest consolidation

**Decision Trees**:
- Capture not just what worked, but what was tried first
- "If X, try Y before Z" (diagnostic paths)

**Conditional Loading**:
- Load memory based on intent, not just file path
- "I'm debugging" → auto-load debugging patterns

## Meta-Learning

This file itself should evolve! If you discover better ways to organize memory or capture learnings, update this file.

The calibration section above should be updated as we learn what metrics and processes actually improve the information topology.

**Last Updated**: 2026-01-09 (initial creation + calibration mechanisms)
