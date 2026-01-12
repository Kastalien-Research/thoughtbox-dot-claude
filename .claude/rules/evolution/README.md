# Pattern Evolution System

This directory implements **Darwin Godel Machine (DGM)** and **CycleQD** principles for the memory system. Patterns evolve through empirical fitness testing and compete for niches based on their unique characteristics.

## Directory Structure

```
evolution/
├── README.md           # This file
├── fitness.json        # Fitness scores + Behavior Characteristics
├── niches.json         # CycleQD niche grid
├── lineage.json        # Pattern ancestry and mutation history
├── signals.jsonl       # Raw success/failure signals from sessions
├── experiments/        # Unproven pattern variations
│   └── README.md
└── graveyard/          # Deprecated patterns (stepping stones)
    └── README.md
```

## Two Evolution Paradigms

### 1. DGM (Darwin Gödel Machine)
- **What**: Empirical fitness testing - patterns that work survive
- **How**: Usage + success signals → fitness score
- **Selection**: High fitness promoted, low fitness archived

### 2. CycleQD (Quality Diversity)
- **What**: Maintain diverse population across niches
- **How**: Patterns have Behavior Characteristics (BCs) that place them in a grid
- **Selection**: One champion per niche, cyclic quality focus

## Behavior Characteristics (BCs)

Every pattern can be scored on 4 dimensions:

| BC | Description | Low (1) | High (10) |
|----|-------------|---------|-----------|
| **Specificity** | How targeted vs general | Fix for line 47 | Universal principle |
| **Applicability** | Domain scope | PostgreSQL only | Any external service |
| **Complexity** | Implementation difficulty | One-liner | Multi-step saga |
| **Maturity** | Battle-tested level | Just discovered | Used 50+ times |

## The Niche Grid

Patterns occupy cells in a 5x5 grid (specificity × applicability):

```
                 APPLICABILITY →
        │  1  │  2  │  3  │  4  │  5  │
    ────┼─────┼─────┼─────┼─────┼─────┤
  S  1  │     │     │     │     │     │
  P ────┼─────┼─────┼─────┼─────┼─────┤
  E  2  │     │  •  │     │     │     │
  C ────┼─────┼─────┼─────┼─────┼─────┤
  ↓  3  │     │     │  •  │  •  │     │
    ────┼─────┼─────┼─────┼─────┼─────┤
     4  │     │     │     │  •  │  •  │
    ────┼─────┼─────┼─────┼─────┼─────┤
     5  │     │     │     │     │  •  │
    ────┴─────┴─────┴─────┴─────┴─────┘
```

**Rules:**
- One champion per cell
- New patterns must beat incumbent by >1 fitness
- Empty niches give +2 bonus (encourages diversity)
- Champions get +1 defense bonus (stability)

## Cyclic Quality Focus

CycleQD rotates which metric determines "best":

```
Round 1: USAGE         → Most referenced wins
Round 2: SUCCESS_RATE  → Best success/failure ratio wins
Round 3: GENERALIZABILITY → Highest applicability wins
Round 4: CLARITY       → Lowest complexity wins
Round 5: EFFICIENCY    → Best usage/complexity ratio wins
[Repeat]
```

## Commands

```bash
# DGM Evolution
/meta:dgm-evolve all --mode=assess    # Calculate fitness
/meta:dgm-evolve all --mode=mutate    # Generate variations
/meta:dgm-evolve all --mode=prune     # Archive low-fitness
/meta:dgm-evolve all --mode=full      # Complete cycle

# CycleQD Evolution
/meta:dgm-evolve all --mode=niche     # View niche grid
/meta:dgm-evolve all --mode=cycle     # Advance quality focus + evolve
```

## Signals Format

Add signals to `signals.jsonl`:
```json
{"timestamp": "2026-01-12T10:30:00Z", "pattern": "tools/api.md#rate-limiting", "signal": "success", "context": "Solved API abuse issue"}
{"timestamp": "2026-01-12T11:45:00Z", "pattern": "testing/mocks.md#msw", "signal": "failure", "reason": "Didn't work with WebSocket connections"}
```

## Fitness Formula

```
base_fitness = (usage * 0.4) + (success_rate * 0.4) + (recency * 0.2)

# CycleQD modifiers
if fills_empty_niche: fitness += 2
if is_champion: fitness += 1
```

## Philosophy

> "We do not require formal proof, but empirical verification."
> — Darwin Gödel Machine

> "Instead of one best solution, maintain a diverse population."
> — CycleQD (Quality Diversity)

The deer that survives the lion didn't prove it was faster. It just was.
But we also want fast deer, strong deer, clever deer - not just one "best" deer.

## Sources

- [DGM Paper](https://arxiv.org/abs/2505.22954)
- [CycleQD Paper](https://arxiv.org/abs/2410.14735)
- [Sakana AI Research](https://sakana.ai/)
