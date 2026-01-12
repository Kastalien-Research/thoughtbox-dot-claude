# /dgm-evolve - Darwin Godel Machine for Memory Patterns

Evolve the memory system through empirical fitness testing. Patterns that help solve problems survive; patterns that don't fade away. No formal proofs required - just results.

## Core Insight

The original Godel Machine required *mathematical proof* that a self-modification would improve performance. This is impractical. The Darwin Godel Machine (DGM) instead uses *empirical evidence* - like evolution, where the deer that survives the lion didn't prove it was faster; it just was.

Our memory system can work the same way:
- **Patterns that get used and work** → promoted (hot/warm)
- **Patterns that don't get used** → decay (cold/archived)
- **Patterns that fail when tried** → marked as anti-patterns or deprecated
- **Variations of successful patterns** → explored as experiments

## Command Signature

```bash
/meta:dgm-evolve [focus-area] [--mode=MODE] [--dry-run]
```

### Parameters

- `focus-area`: Domain to evolve (`tools`, `infrastructure`, `testing`, `lessons`, or `all`)
- `--mode`: Evolution mode
  - `assess` - Analyze current pattern fitness (default)
  - `mutate` - Generate variations of high-performing patterns
  - `prune` - Archive low-fitness patterns
  - `full` - Complete evolution cycle
- `--dry-run`: Show what would change without modifying

## The DGM-Memory Architecture

### 1. Archive = Memory System

```
.claude/rules/
├── tools/           # Active patterns (the "population")
├── infrastructure/
├── testing/
├── lessons/
└── evolution/       # NEW: Pattern evolution tracking
    ├── lineage.json       # Pattern ancestry
    ├── fitness.json       # Usage/success metrics
    ├── experiments/       # Unproven variations
    └── graveyard/         # Deprecated patterns (stepping stones)
```

### 2. Fitness = Empirical Success

Unlike DGM's coding benchmarks, we measure:

| Metric | Signal | How to Track |
|--------|--------|--------------|
| **Usage** | Pattern was referenced | Search logs, explicit citations |
| **Success** | Pattern helped solve problem | Session calibration feedback |
| **Convergence** | Multiple agents discover same pattern | Duplicate detection |
| **Decay** | Pattern not used recently | Freshness tags |

**Fitness Score Formula:**
```
fitness = (usage_count * 0.4) + (success_signals * 0.4) + (recency_bonus * 0.2)
```

### 3. Mutations = Pattern Variations

When a pattern shows high fitness, generate variations:

```markdown
## Original Pattern (fitness: 8.5)
### 2026-01-09: Rate Limiting at Middleware Layer
- **Issue**: API endpoints vulnerable to abuse
- **Solution**: Token bucket rate limiter as middleware
- **Pattern**: Rate limiting should be middleware, not per-endpoint

## Mutation 1: Generalization
- **Pattern**: Cross-cutting concerns belong in middleware, not scattered

## Mutation 2: Specification
- **Pattern**: Token bucket > sliding window for bursty traffic

## Mutation 3: Combination
- **Pattern**: Middleware for rate limiting + circuit breaker = resilient APIs
```

### 4. Selection = Empirical Validation

Variations enter as "experiments" with:
- `status: experimental`
- `parent: <original-pattern-id>`
- `created: <timestamp>`

After N uses or M days:
- **Outperforms parent** → Promoted, parent demoted
- **Underperforms** → Archived as stepping stone
- **Neutral** → Remains experimental

### 5. Open-Ended Exploration

Key DGM insight: Keep "stepping stones" - patterns that failed but might seed future breakthroughs.

```
.claude/rules/evolution/graveyard/
├── 2026-01-rate-limit-per-endpoint.md  # Failed, but why documented
├── 2026-01-sync-file-writes.md          # Superseded by async
└── ...
```

Each graveyard entry includes:
- Why it was tried
- Why it failed
- What replaced it
- Potential resurrection conditions

## Evolution Workflow

### Phase 1: Fitness Assessment

```bash
/meta:dgm-evolve all --mode=assess
```

1. Scan all patterns in `.claude/rules/`
2. Calculate fitness scores from:
   - Git history (when pattern files were read/cited)
   - Session calibration data
   - Freshness tags
3. Output fitness report:
   ```
   HIGH FITNESS (promote/explore):
   - infrastructure/database.md:connection-pooling (8.7)
   - tools/api-patterns.md:error-handling (8.2)

   LOW FITNESS (prune candidates):
   - lessons/2025-12-old-approach.md (1.2)
   - tools/deprecated-feature.md (0.8)

   EXPERIMENTAL (awaiting validation):
   - evolution/experiments/async-validation.md (pending: 3 more uses)
   ```

### Phase 2: Mutation Generation

```bash
/meta:dgm-evolve tools --mode=mutate
```

For high-fitness patterns:
1. **Generalize**: Extract broader principle
2. **Specialize**: Add context-specific variants
3. **Combine**: Merge with complementary patterns
4. **Invert**: Document the anti-pattern

Generated mutations go to `evolution/experiments/` with metadata:
```yaml
---
status: experimental
parent: tools/api-patterns.md#error-handling
mutation_type: generalization
created: 2026-01-12
expires: 2026-02-12
---
```

### Phase 3: Pruning

```bash
/meta:dgm-evolve all --mode=prune
```

1. Move low-fitness patterns to `evolution/graveyard/`
2. Update cross-references
3. Add graveyard metadata:
   ```yaml
   ---
   deprecated: 2026-01-12
   reason: "Superseded by async pattern"
   replacement: infrastructure/async-patterns.md
   resurrection_if: "Sync becomes viable for <10ms operations"
   ---
   ```

### Phase 4: Full Evolution Cycle

```bash
/meta:dgm-evolve all --mode=full
```

Runs all phases:
1. Assess fitness
2. Mutate high performers
3. Validate experiments (check if ready for promotion)
4. Prune low performers
5. Update lineage tracking
6. Generate evolution report

## Extended Memory Format

To support DGM, patterns gain new fields:

```markdown
### 2026-01-12: Pattern Title 🔥
- **Issue**: What was the problem
- **Solution**: What worked
- **Pattern**: Reusable principle
- **Files**: Relevant code locations
- **See Also**: Related patterns

<!-- DGM Metadata (optional, for high-value patterns) -->
- **Fitness**: 8.5 (usage: 12, success: 9, age: 14d)
- **Lineage**: Evolved from `lessons/2025-12-original.md`
- **Variants**:
  - `evolution/experiments/generalized-version.md` (testing)
  - `evolution/graveyard/failed-variant.md` (archived)
```

## Fitness Tracking Implementation

### Implicit Signals (Automatic)

```bash
# Track when patterns are read during sessions
# Hook into session start/end to log pattern access

# .claude/hooks/session_end_fitness.sh
#!/bin/bash
# Log which rule files were loaded this session
# Increment usage counters in evolution/fitness.json
```

### Explicit Signals (Agent Feedback)

After using a pattern, agents can signal:
```bash
# Pattern helped
echo '{"pattern": "tools/api.md#rate-limiting", "signal": "success"}' >> .claude/rules/evolution/signals.jsonl

# Pattern didn't help
echo '{"pattern": "tools/api.md#rate-limiting", "signal": "failure", "reason": "..."}' >> .claude/rules/evolution/signals.jsonl
```

Or via the calibration template:
```markdown
## Session Calibration - 2026-01-12

**Patterns Used**:
- ✅ `infrastructure/database.md:connection-pooling` - Solved timeout issue
- ❌ `tools/validation.md:schema-first` - Didn't apply to this case
- 🔄 `lessons/error-handling.md` - Partially helpful, needs refinement
```

## Example Evolution

### Before: Scattered Patterns

```
lessons/2025-12-rate-limiting.md     (fitness: 3.2, rarely used)
tools/api-security.md                 (fitness: 7.8, often used)
infrastructure/middleware.md          (fitness: 6.5)
```

### After: `/meta:dgm-evolve all --mode=full`

```
tools/api-security.md                 (fitness: 8.1, enhanced)
infrastructure/middleware.md          (fitness: 7.2, cross-referenced)
evolution/experiments/
  └── unified-security-middleware.md  (experimental: combines both)
evolution/graveyard/
  └── 2025-12-rate-limiting.md        (archived: subsumed by middleware)
evolution/lineage.json                (tracks ancestry)
```

## Integration Points

### With Existing Memory Commands

```bash
# Search includes fitness scores
.claude/bin/memory-query "rate limiting" --show-fitness

# Add with lineage
.claude/bin/memory-add --domain=tools --parent=existing-pattern-id

# Stats include evolution metrics
.claude/bin/memory-stats --evolution
```

### With Session Workflow

```bash
# Start of session
cat .claude/rules/active-context/current-focus.md
.claude/bin/memory-stats --evolution  # See what's hot

# End of session
/meta:dgm-evolve all --mode=assess  # Update fitness
/meta capture-learning               # Add new patterns
```

## Why This Works

1. **No Formal Proofs**: Like biological evolution, we don't need to prove a pattern is better - we just observe if it works.

2. **Stepping Stones Preserved**: Failed patterns aren't deleted; they're archived with context. A future mutation might resurrect them.

3. **Open-Ended**: The system can discover patterns we didn't anticipate, just by tracking what actually helps.

4. **Self-Improving**: High-fitness patterns spawn variations; the best variations replace their parents.

5. **Low Overhead**: Fitness tracking can be mostly automatic (file access logs + occasional explicit signals).

## Comparison to Original DGM

| DGM Component | Original (Sakana) | Memory System Adaptation |
|---------------|-------------------|--------------------------|
| Archive | Python agent variants | Pattern files in .claude/rules/ |
| Fitness Function | SWE-bench, Polyglot scores | Usage + success signals |
| Mutations | LLM-generated code changes | Pattern generalizations/specializations |
| Selection | Benchmark comparison | Freshness decay + promotion |
| Open-Ended | Keep stepping stones | Graveyard with resurrection conditions |

## Future Enhancements

1. **Automated Fitness Hooks**: Instrument Claude Code to track pattern usage automatically

2. **Cross-Codebase Learning**: Share high-fitness patterns across projects

3. **Mutation Templates**: Standard ways to generalize/specialize patterns

4. **Visualization**: Graph of pattern evolution over time

5. **A/B Testing**: Serve different pattern variants to see which performs better

---

**The memory system becomes a living organism** - patterns compete for attention, successful ones reproduce (spawn variants), unsuccessful ones fade but aren't forgotten. Over time, the system evolves toward higher and higher fitness.

---

**Sources:**
- [Darwin Gödel Machine Paper (arXiv)](https://arxiv.org/abs/2505.22954)
- [Sakana AI DGM Overview](https://sakana.ai/dgm/)
- [GitHub: jennyzzt/dgm](https://github.com/jennyzzt/dgm)
