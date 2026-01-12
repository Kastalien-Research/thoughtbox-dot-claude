---
paths: [src/index.ts, src/thought-handler.ts, src/persistence/storage.ts]
---

# Thoughtbox Tool Memory

## Recent Learnings (Most Recent First)

### 2026-01-09: Session Management Validation 🔥
- **Issue**: Session IDs weren't being validated consistently before thought storage operations
- **Solution**: Middleware-level session validation ensures sessions exist before any persistence
- **Files**: `src/middleware/session.ts:45-67`
- **Pattern**: Always validate session existence at middleware layer, not in individual tools
- **See Also**: `.claude/rules/infrastructure/middleware.md`

### 2025-12-15: Branching Thought Chains ⚡
- **Issue**: Creating branches from parent thoughts in different sessions created orphaned nodes
- **Solution**: Enforce parent-child session consistency checks before allowing branch creation
- **Files**: `src/persistence/storage.ts:120-145`
- **Pattern**: Cross-session operations require explicit validation; don't assume session context

## Core Patterns

### Resource Embedding Pattern
**Always include embedded resources at thought chain boundaries:**
- Start of chain: Include Patterns Cookbook
- End of chain: Include completion guidance
- Branch points: Include branching strategies

```typescript
return {
  content: [
    { type: "text", text: JSON.stringify(result) },
    {
      type: "resource",
      resource: {
        uri: "thoughtbox://patterns-cookbook",
        annotations: { audience: ["assistant"], priority: 0.9 }
      }
    }
  ]
};
```

### Doubly-Linked List Storage
- **O(1) lookups**: Use Map-based indexing by thoughtId
- **Session isolation**: Separate head/tail Maps per session
- **Branching support**: `next` is an array, not single pointer
- **Traversal**: Support both forward and backward iteration

## Common Pitfalls

1. **Forgetting `.js` extensions in ESM imports**
   - ❌ `import { foo } from "./bar"`
   - ✅ `import { foo } from "./bar.js"`
   - TypeScript requires explicit `.js` even for `.ts` files

2. **Not checking `nextThoughtNeeded` flag**
   - Can cause infinite reasoning loops
   - Agent continues thinking without natural stopping point
   - Always respect when agent signals completion

3. **Missing Zod validation**
   - All tool inputs MUST use Zod schemas
   - Validates at MCP protocol layer before handler runs
   - See `src/index.ts` for schema patterns

4. **Inconsistent thought numbering**
   - thoughtNumber is 1-indexed (1 of 5, not 0 of 5)
   - totalThoughts can change (start with 3, expand to 5)
   - Don't assume sequential IDs

## Quick Reference

### Tool Registration Location
- **File**: `src/index.ts:150-250`
- **Pattern**: Inline registration for thoughtbox tool (not in separate module)
- **Why**: Tool is central to the service, close coupling is intentional

### Zod Schema Pattern
```typescript
const ThoughtboxInputSchema = z.object({
  thought: z.string().describe("The thought content"),
  thoughtNumber: z.number().int().positive(),
  totalThoughts: z.number().int().positive(),
  nextThoughtNeeded: z.boolean(),
  // ... more fields
});
```

### Session Access
- Available via `req.session` (set by middleware)
- Never pass sessionId as tool parameter
- Middleware handles Firebase token → session mapping

## Testing

### Behavioral Test Location
- **File**: `tests/thoughtbox.md`
- **Runner**: `scripts/agentic-test.ts`
- **Run**: `npm run test:tool -- thoughtbox`

### Key Test Scenarios
1. Sequential forward thinking (1→2→3)
2. Backward reflection after forward chain
3. Branching from existing thought
4. Revision of historical thought
5. Session isolation (can't access other user's thoughts)

## Architecture Notes

### Why Inline in index.ts?
The thoughtbox tool is NOT in a separate module because:
- It's the core service offering
- Tight coupling with persistence layer
- Direct access to server context needed
- Simpler than over-abstraction

### Storage Layer Separation
- **LinkedThoughtStore** (`src/persistence/storage.ts`): In-memory doubly-linked list logic
- **FirestoreStorage** (`src/persistence/firestore.ts`): Firebase backend implementation
- **Interface**: Abstract storage to allow different backends

## Related Files

- 📁 `src/index.ts` - Tool registration and handler
- 📁 `src/thought-handler.ts` - Core thought processing logic (if separated)
- 📁 `src/persistence/storage.ts` - Linked list data structure
- 📁 `src/persistence/firestore.ts` - Firestore persistence
- 📄 `tests/thoughtbox.md` - Behavioral tests
- 📄 `local-docs/thoughtbox-patterns-cookbook.md` - Usage patterns

## Future Considerations

- **Thought search/query**: Currently no search across thoughts
- **Thought export**: Format for extracting reasoning chains
- **Visualization**: Graph view of branching thought structures
- **Archival**: Long-term storage strategy for completed chains

---

**Last Updated**: 2026-01-09
