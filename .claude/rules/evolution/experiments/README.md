# Experimental Patterns

Unproven pattern variations awaiting empirical validation.

## How Patterns Get Here

1. High-fitness patterns spawn mutations via `/meta:dgm-evolve --mode=mutate`
2. Each mutation enters as an experiment with:
   - Parent pattern reference
   - Mutation type (generalization, specialization, combination, etc.)
   - Creation date
   - Expiration date (default: 30 days)

## Experiment Lifecycle

```
Created → Testing → [Promoted | Archived | Extended]
```

### Promotion (Success)
- Used N+ times with positive signals
- Outperforms or complements parent
- Moved to main rules directory
- Parent may be demoted or archived

### Archived (Failure)
- Low usage after expiration
- Negative signals when tried
- Moved to `../graveyard/` with failure notes
- Still searchable as stepping stone

### Extended (Inconclusive)
- Some usage but unclear results
- Extended another 30 days
- Maximum 3 extensions before forced decision

## File Format

Each experiment includes frontmatter:

```yaml
---
status: experimental
parent: tools/api-patterns.md#error-handling
mutation_type: generalization
created: 2026-01-12
expires: 2026-02-12
usage_count: 0
signals:
  success: 0
  failure: 0
---

# Generalized Error Handling Pattern

[Pattern content...]
```

## Commands

```bash
# List experiments
ls .claude/rules/evolution/experiments/

# Check experiment status
/meta:dgm-evolve all --mode=assess

# Manually promote
# (Move file to appropriate rules directory, update lineage.json)

# Manually archive
# (Move to graveyard/, add failure notes)
```
