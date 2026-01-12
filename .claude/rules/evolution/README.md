# Pattern Evolution System

This directory implements Darwin Godel Machine (DGM) principles for the memory system. Patterns evolve through empirical fitness testing - what works survives, what doesn't fades away.

## Directory Structure

```
evolution/
├── README.md           # This file
├── fitness.json        # Current fitness scores for all patterns
├── lineage.json        # Pattern ancestry and mutation history
├── signals.jsonl       # Raw success/failure signals from sessions
├── experiments/        # Unproven pattern variations
│   └── README.md
└── graveyard/          # Deprecated patterns (stepping stones)
    └── README.md
```

## How It Works

### Fitness Tracking

Patterns gain fitness through:
- **Usage**: Being referenced during work sessions
- **Success**: Explicit signals that a pattern helped solve a problem
- **Convergence**: Multiple independent discoveries of the same pattern

Patterns lose fitness through:
- **Decay**: Time without use
- **Failure**: Explicit signals that a pattern didn't work
- **Supersession**: Being replaced by a better pattern

### Evolution Cycle

Run `/meta:dgm-evolve` to:
1. **Assess**: Calculate current fitness scores
2. **Mutate**: Generate variations of high-fitness patterns
3. **Prune**: Archive low-fitness patterns
4. **Report**: Show evolution status

### Signals Format

Add signals to `signals.jsonl`:
```json
{"timestamp": "2026-01-12T10:30:00Z", "pattern": "tools/api.md#rate-limiting", "signal": "success", "context": "Solved API abuse issue"}
{"timestamp": "2026-01-12T11:45:00Z", "pattern": "testing/mocks.md#msw", "signal": "failure", "reason": "Didn't work with WebSocket connections"}
```

### Fitness Score

```
fitness = (usage * 0.4) + (success_rate * 0.4) + (recency * 0.2)
```

- **usage**: Normalized count of references (0-10)
- **success_rate**: success_signals / (success + failure) * 10
- **recency**: Days since last use, inverse scaled (0-10)

## Commands

```bash
# View current fitness
/meta:dgm-evolve all --mode=assess

# Generate pattern variations
/meta:dgm-evolve tools --mode=mutate

# Archive low-fitness patterns
/meta:dgm-evolve all --mode=prune

# Full evolution cycle
/meta:dgm-evolve all --mode=full
```

## Philosophy

> "We do not require formal proof, but empirical verification of self-modification based on benchmark testing, so that the system can improve and explore based on observed results."
> — Darwin Godel Machine paper

The deer that survives the lion didn't prove it was faster. It just was.
