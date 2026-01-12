# Capture Session Learning

**Purpose**: Help improve the codebase memory by capturing significant learnings from this session.

---

## Step 1: Reflect on This Session

Please think about the work we just completed:

### What was the main problem or task?
[Describe in 1-2 sentences]

### What was non-obvious, tricky, or took time to figure out?
[Things that weren't immediately clear, required debugging, or exploration]

### What pattern or insight would help future agents working on similar problems?
[The reusable principle, not just the specific fix]

### Which domain does this learning belong to?
- [ ] Tools (thoughtbox, notebook, mental_models, init)
- [ ] Infrastructure (Firebase, middleware, deployment)
- [ ] Testing (behavioral tests, debugging)
- [ ] Other: _______________

---

## Step 2: Draft a Memory Entry

Based on your reflection, draft an entry using this format:

```markdown
### YYYY-MM-DD: [Brief Descriptive Title] 🔥
- **Issue**: [What was the problem or challenge]
- **Solution**: [What worked, with specific details]
- **Files**: [Key files with line ranges, e.g., `src/index.ts:150-165`]
- **Pattern**: [The reusable principle or heuristic]
- **See Also**: [Optional: links to related rules, docs, or code]
```

**Freshness tags**:
- 🔥 **HOT**: Current work, within last 2 weeks
- ⚡ **WARM**: Recent work, within last 3 months
- 📚 **COLD**: Older but stable knowledge

---

## Step 3: Choose the Right File

Based on the domain you identified, add your entry to the appropriate rules file:

| Domain | File to Update |
|--------|----------------|
| Thoughtbox tool | `.claude/rules/tools/thoughtbox.md` |
| Notebook tool | `.claude/rules/tools/notebook.md` (create if needed) |
| Mental models | `.claude/rules/tools/mental-models.md` (create if needed) |
| Firebase/Firestore | `.claude/rules/infrastructure/firebase.md` |
| Middleware | `.claude/rules/infrastructure/middleware.md` (create if needed) |
| Deployment | `.claude/rules/infrastructure/deployment.md` (create if needed) |
| Testing | `.claude/rules/testing/behavioral-tests.md` |
| Cross-cutting concern | `.claude/rules/lessons/YYYY-MM-[topic].md` (new file) |

**For new files**: Use `.claude/rules/TEMPLATE.md` as a starting point.

---

## Step 4: Update the File

1. Open the appropriate rules file
2. Find the "Recent Learnings (Most Recent First)" section
3. Add your entry at the **TOP** (most recent first)
4. Ensure formatting is consistent

---

## Step 5: Update Current Focus (Optional)

If this session changes what we're actively working on:

1. Open `.claude/rules/active-context/current-focus.md`
2. Update the "What We're Working On Now" section
3. Add to "Recent Decisions" if you made an important choice
4. Update the timestamp at the top

---

## Example: Complete Flow

### Reflection
**Problem**: Tests were failing because Firestore wasn't properly initializing in test environment.

**Non-obvious**: The emulator host needs to be set BEFORE importing firebase module, not after.

**Pattern**: Environment variables that affect module initialization must be set at the very top of the entry point.

**Domain**: Infrastructure

### Draft Entry
```markdown
### 2026-01-09: Firestore Emulator Initialization Order 🔥
- **Issue**: Tests failed with "Firestore unavailable" despite emulator running
- **Solution**: Set `FIRESTORE_EMULATOR_HOST` before any firebase imports
- **Files**: `scripts/agentic-test.ts:1-5`, `src/firebase.ts:3`
- **Pattern**: Environment variables affecting module imports must be set at entry point, before imports
- **See Also**: `.claude/rules/testing/behavioral-tests.md` for test setup patterns
```

### File to Update
`.claude/rules/infrastructure/firebase.md` (Firebase domain)

### Result
Opened `firebase.md`, added entry at top of "Recent Learnings" section, saved.

---

## Guidelines

**DO**:
- ✅ Capture insights that would save future agents time
- ✅ Include specific file references
- ✅ Write patterns as principles, not just "we did X"
- ✅ Add freshness tags
- ✅ Cross-reference related learnings

**DON'T**:
- ❌ Capture obvious things already in docs
- ❌ Write only the specific fix without the general pattern
- ❌ Leave out file references
- ❌ Forget to timestamp

---

## After Capturing

The memory system now contains this learning! Future agents working on similar problems will:
1. Have path-specific rules auto-load when working on those files
2. Find the learning in the domain-specific rules file
3. Benefit from your experience

Thank you for contributing to the collective knowledge! 🎯

---

**See Also**:
- `.claude/rules/00-meta.md` - Full memory system guide
- `.claude/rules/TEMPLATE.md` - Template for new rules files
- `CLAUDE.md` - Memory system overview
