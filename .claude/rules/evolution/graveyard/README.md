# Pattern Graveyard

Deprecated patterns preserved as stepping stones. Failed experiments that might seed future breakthroughs.

## Why Keep Failed Patterns?

From the Darwin Godel Machine research:

> Open-ended search "allows goal switching" and maintains diverse historical agents. Unlike hill-climbing, this preserves "less-performant ancestor agents" that may seed breakthrough innovations.

A pattern that failed in one context might work in another. Keeping them (with context) enables resurrection when conditions change.

## File Format

Each graveyard entry includes:

```yaml
---
deprecated: 2026-01-12
reason: "Superseded by async pattern"
replacement: infrastructure/async-patterns.md#connection-handling
resurrection_if: "Sync becomes viable for <10ms operations"
original_fitness: 3.2
final_usage: 5
parent: lessons/2025-12-original.md
---

# [Original Pattern Title]

[Original pattern content preserved...]

---

## Post-Mortem

### Why It Failed
- [Specific reasons]

### What Replaced It
- [Link to replacement pattern]

### Lessons Learned
- [What we learned from this failure]

### Resurrection Conditions
- [When this pattern might become viable again]
```

## Searching the Graveyard

```bash
# Search deprecated patterns
grep -r "resurrection_if" .claude/rules/evolution/graveyard/

# Find patterns deprecated for specific reason
grep -l "async" .claude/rules/evolution/graveyard/
```

## Resurrection Process

If conditions change and a graveyard pattern becomes viable:

1. Review the pattern and its post-mortem
2. Update for current context
3. Move to `../experiments/` with new frontmatter
4. Let it prove itself through the normal experiment lifecycle

## Philosophy

> "The deer that got mauled by the lion didn't prove it was slower. It just was. But its genetic variations live on in its offspring."

Failed patterns are genetic variations. They didn't work here, now. But evolution is open-ended.
