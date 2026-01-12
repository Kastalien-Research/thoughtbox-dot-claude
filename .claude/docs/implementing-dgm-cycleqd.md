# Implementing DGM + CycleQD Evolution for Memory Systems

A guide for AI agents implementing self-improving memory systems in codebases with existing `.claude/` structures.

---

## Overview

This guide explains how to add **Darwin Gödel Machine (DGM)** and **CycleQD** evolution to an existing memory system. These techniques, based on Sakana AI research, enable:

- **DGM**: Patterns evolve through empirical fitness - what works survives
- **CycleQD**: Diverse population of patterns, each excelling in different niches

**Prerequisites:**
- Existing `.claude/rules/` or similar memory structure
- Firecrawl MCP connection (for research)
- Basic pattern capture already working

---

## Step 1: Research the Foundations

Use Firecrawl to understand the underlying research:

```bash
# Search for DGM overview
mcp__firecrawl-mcp__firecrawl_search "Darwin Godel Machine Sakana AI site:sakana.ai"

# Scrape the key pages
mcp__firecrawl-mcp__firecrawl_scrape "https://sakana.ai/dgm/"
mcp__firecrawl-mcp__firecrawl_scrape "https://sakana.ai/cycleqd/"
```

**Key papers:**
- DGM: https://arxiv.org/abs/2505.22954
- CycleQD: https://arxiv.org/abs/2410.14735

**Core insights to internalize:**

1. **DGM**: "We do not require formal proof, but empirical verification of self-modification based on benchmark testing."

2. **CycleQD**: Instead of optimizing for one "best" solution, maintain diverse specialists that each occupy a unique niche.

---

## Step 2: Create the Evolution Directory Structure

Add to existing `.claude/rules/`:

```
.claude/rules/evolution/
├── README.md           # How evolution works
├── fitness.json        # Pattern fitness scores + BCs
├── niches.json         # CycleQD niche grid
├── lineage.json        # Pattern ancestry
├── signals.jsonl       # Success/failure signals
├── experiments/        # Unproven variations
│   └── README.md
└── graveyard/          # Deprecated stepping stones
    └── README.md
```

---

## Step 3: Implement fitness.json

This tracks fitness scores and Behavior Characteristics for each pattern:

```json
{
  "$schema": "fitness-schema",
  "version": "2.0.0",
  "lastUpdated": "2026-01-12T00:00:00Z",
  "patterns": {},

  "metadata": {
    "description": "Fitness scores and Behavior Characteristics for memory patterns",
    "scoring": {
      "usage_weight": 0.4,
      "success_weight": 0.4,
      "recency_weight": 0.2
    },
    "thresholds": {
      "high_fitness": 7.0,
      "low_fitness": 3.0,
      "experimental_min_uses": 3,
      "experimental_max_days": 30
    }
  },

  "patternSchema": {
    "description": "Schema for individual pattern entries",
    "example": {
      "tools/api-patterns.md#rate-limiting": {
        "fitness": 8.5,
        "metrics": {
          "usage_count": 12,
          "success_signals": 9,
          "failure_signals": 1,
          "last_used": "2026-01-10T14:30:00Z",
          "created": "2025-12-15T00:00:00Z"
        },
        "behaviorCharacteristics": {
          "specificity": 5,
          "applicability": 7,
          "complexity": 4,
          "maturity": 8
        },
        "niche": {
          "cell": "3,4",
          "isChampion": true,
          "challengedBy": []
        },
        "lineage": {
          "parent": null,
          "children": ["evolution/experiments/general-rate-limiting.md"],
          "generation": 0
        }
      }
    }
  },

  "cycleQD": {
    "enabled": true,
    "currentCycle": {
      "quality": "usage",
      "round": 0,
      "startedAt": null
    },
    "history": []
  }
}
```

---

## Step 4: Implement niches.json

The CycleQD niche grid:

```json
{
  "$schema": "niches-schema",
  "version": "1.0.0",
  "lastUpdated": "2026-01-12T00:00:00Z",
  "description": "CycleQD niche grid for memory patterns",

  "behaviorCharacteristics": {
    "specificity": {
      "description": "How targeted (1) vs general (10) the pattern is",
      "range": [1, 10],
      "examples": {
        "1": "Fix for specific bug in auth.ts line 47",
        "5": "Pattern for handling API rate limits",
        "10": "Universal principle: fail fast, recover gracefully"
      }
    },
    "applicability": {
      "description": "Single domain (1) vs cross-cutting (10)",
      "range": [1, 10],
      "examples": {
        "1": "Only applies to PostgreSQL connections",
        "5": "Applies to all database connections",
        "10": "Applies to any external service integration"
      }
    },
    "complexity": {
      "description": "Simple rule (1) vs complex procedure (10)",
      "range": [1, 10]
    },
    "maturity": {
      "description": "New/experimental (1) vs battle-tested (10)",
      "range": [1, 10]
    }
  },

  "primaryAxes": {
    "x": "specificity",
    "y": "applicability",
    "color": "maturity"
  },

  "gridResolution": 5,
  "grid": {
    "description": "5x5 grid of niches. Keys are 'x,y' coordinates",
    "cells": {}
  },

  "cycleState": {
    "currentQuality": "usage",
    "cycleOrder": ["usage", "success_rate", "generalizability", "clarity", "efficiency"],
    "roundNumber": 0,
    "lastCycleTime": null
  },

  "qualityDefinitions": {
    "usage": {
      "description": "How often the pattern is referenced",
      "metric": "usage_count"
    },
    "success_rate": {
      "description": "Ratio of success to failure signals",
      "metric": "success_signals / (success_signals + failure_signals)"
    },
    "generalizability": {
      "description": "Applicability score",
      "metric": "applicability_bc"
    },
    "clarity": {
      "description": "Inverse of complexity",
      "metric": "11 - complexity_bc"
    },
    "efficiency": {
      "description": "Value per complexity",
      "metric": "usage_count / complexity_bc"
    }
  },

  "nicheRules": {
    "oneChampionPerCell": true,
    "diversityBonus": 2,
    "incumbentBonus": 1
  }
}
```

---

## Step 5: Create the Evolution Command

Add a slash command (e.g., `.claude/commands/meta/dgm-evolve.md`) that implements:

### Modes

| Mode | Description |
|------|-------------|
| `assess` | Calculate fitness scores for all patterns |
| `mutate` | Generate variations of high-fitness patterns |
| `prune` | Archive low-fitness patterns to graveyard |
| `full` | Complete DGM evolution cycle |
| `niche` | Display CycleQD niche grid |
| `cycle` | Advance quality focus and run CycleQD evolution |

### Fitness Calculation

```
base_fitness = (usage * 0.4) + (success_rate * 0.4) + (recency * 0.2)

# Normalize to 0-10 scale
usage = min(usage_count / 10, 10)
success_rate = (success / (success + failure)) * 10 if signals else 5
recency = max(0, 10 - days_since_last_use / 3)

# CycleQD modifiers
if fills_empty_niche: fitness += 2
if is_champion: fitness += 1
```

### Niche Assignment

Map Behavior Characteristics to grid cells:

```python
# Convert BC (1-10) to grid position (1-5)
def bc_to_cell(specificity, applicability):
    x = min(5, max(1, (specificity + 1) // 2))
    y = min(5, max(1, (applicability + 1) // 2))
    return f"{x},{y}"
```

---

## Step 6: Implement Signal Collection

Patterns gain/lose fitness through signals. Add to `signals.jsonl`:

```jsonl
{"timestamp": "2026-01-12T10:30:00Z", "pattern": "tools/api.md#rate-limiting", "signal": "success", "context": "Solved API abuse issue"}
{"timestamp": "2026-01-12T11:45:00Z", "pattern": "testing/mocks.md#msw", "signal": "failure", "reason": "Didn't work with WebSockets"}
```

### Collection Methods

1. **Explicit signals** - Agent logs after using a pattern
2. **Session calibration** - End-of-session reflection template
3. **Implicit signals** - Track which rule files are loaded (requires hooks)

---

## Step 7: Create Supporting Structures

### experiments/README.md

```markdown
# Experimental Patterns

Unproven pattern variations awaiting empirical validation.

## Lifecycle

Created → Testing → [Promoted | Archived | Extended]

## File Format

Each experiment includes frontmatter:

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
```

### graveyard/README.md

```markdown
# Pattern Graveyard

Deprecated patterns preserved as stepping stones.

## Why Keep Failed Patterns?

A pattern that failed in one context might work in another.
Keeping them (with context) enables resurrection when conditions change.

## File Format

---
deprecated: 2026-01-12
reason: "Superseded by async pattern"
replacement: infrastructure/async-patterns.md
resurrection_if: "Sync becomes viable for <10ms operations"
---
```

---

## Step 8: Update Memory Meta Documentation

Add to your memory system's meta documentation (e.g., `00-meta.md`):

```markdown
## Evolution System

The memory system implements DGM + CycleQD principles:

### DGM (Darwin Gödel Machine)
- Empirical fitness testing - what works survives
- No formal proofs required, just results

### CycleQD (Quality Diversity)
- Maintain diverse population across niches
- Behavior Characteristics: specificity, applicability, complexity, maturity
- Cyclic quality focus rotates through: usage → success → generalizability → clarity → efficiency

### Commands

/meta:dgm-evolve all --mode=assess    # Calculate fitness
/meta:dgm-evolve all --mode=niche     # View niche grid
/meta:dgm-evolve all --mode=cycle     # Advance quality + evolve
```

---

## Step 9: Extend Existing Pattern Format

Add optional BC fields to your pattern template:

```markdown
### 2026-01-12: Pattern Title 🔥
- **Issue**: What was the problem
- **Solution**: What worked
- **Pattern**: Reusable principle
- **Files**: Relevant code locations
- **BCs**: specificity=5, applicability=8, complexity=4, maturity=3
```

Or let the system infer BCs from:
- Domain file location → applicability
- Pattern length/steps → complexity
- Age + usage count → maturity

---

## Step 10: Establish Evolution Cadence

Recommend running evolution:

| Frequency | Mode | Purpose |
|-----------|------|---------|
| Per session | `assess` | Update fitness based on new signals |
| Weekly | `cycle` | Advance quality focus, run competition |
| Monthly | `full` | Complete evolution with pruning |
| Quarterly | Manual review | Archive cold patterns, restructure if needed |

---

## Key Principles to Remember

1. **No Formal Proofs**: The deer that survives the lion didn't prove it was faster. It just was.

2. **Diversity Over Optimization**: We want fast deer, strong deer, clever deer - not just one "best" deer.

3. **Stepping Stones Matter**: Failed patterns might seed future breakthroughs. Archive, don't delete.

4. **Cyclic Attention**: Each quality dimension gets its moment in the spotlight.

5. **One Champion Per Niche**: Prevents convergence to all similar patterns.

---

## Adaptation Notes

When adapting to an existing memory system:

1. **Preserve existing patterns** - Don't restructure; add evolution metadata alongside
2. **Start with assessment only** - Run `--mode=assess` for a few weeks before pruning
3. **Infer initial BCs** - Use heuristics based on file location and content
4. **Gradual adoption** - Enable CycleQD after DGM fitness tracking is working

---

## Research Resources

For deeper understanding, use Firecrawl to explore:

```bash
# DGM
mcp__firecrawl-mcp__firecrawl_scrape "https://sakana.ai/dgm/"
mcp__firecrawl-mcp__firecrawl_scrape "https://arxiv.org/abs/2505.22954"

# CycleQD
mcp__firecrawl-mcp__firecrawl_scrape "https://sakana.ai/cycleqd/"
mcp__firecrawl-mcp__firecrawl_scrape "https://arxiv.org/abs/2410.14735"

# Related: Digital Red Queen (adversarial evolution)
mcp__firecrawl-mcp__firecrawl_scrape "https://sakana.ai/drq/"

# Related: AI Scientist (automated research)
mcp__firecrawl-mcp__firecrawl_scrape "https://sakana.ai/ai-scientist/"
```

---

## Reference Implementation

See the full implementation at:
https://github.com/Kastalien-Research/thoughtbox-dot-claude

Key files:
- `.claude/rules/evolution/` - Evolution system
- `.claude/commands/meta/dgm-evolve.md` - Command documentation
- `.claude/rules/00-meta.md` - Meta documentation

---

**Last Updated**: 2026-01-12
**Based on**: Sakana AI DGM + CycleQD research
