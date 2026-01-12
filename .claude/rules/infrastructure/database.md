---
paths: [src/**/db.*, src/**/database.*, src/**/persistence/**]
---

# Database Patterns Memory

> **Purpose**: Database connection, query patterns, and persistence layer learnings

## Recent Learnings (Most Recent First)

<!-- Add learnings in this format:
### YYYY-MM-DD: [Brief Title] 🔥/⚡/📚
- **Issue**: [What was the problem]
- **Solution**: [What worked]
- **Files**: [Key files with line ranges]
- **Pattern**: [Reusable principle]
- **See Also**: [Related docs/rules]
-->

## Core Patterns

### Connection Management

**Pattern**: Lazy initialization with connection warming

```typescript
// Example pattern - adapt to your database
let _db: Database | null = null;

function getDb(): Database {
  if (!_db) {
    _db = initializeDatabase();
  }
  return _db;
}

// For serverless: warm connections at startup
const initPromise = (async () => {
  const db = getDb();
  await db.ping(); // Warm the connection
  return db;
})();
```

**Why**: Reduces cold start latency in serverless environments.

### Query Patterns

**Pattern**: Use parameterized queries to prevent injection

```typescript
// WRONG - SQL injection vulnerability
const result = await db.query(`SELECT * FROM users WHERE id = '${userId}'`);

// CORRECT - parameterized query
const result = await db.query('SELECT * FROM users WHERE id = ?', [userId]);
```

## Common Pitfalls

1. **Connection Leaks**
   - ❌ Opening connections without closing
   - ✅ Use connection pools or ensure cleanup in finally blocks
   - Why: Exhausts database connections under load

2. **N+1 Query Problem**
   - ❌ Querying related data in a loop
   - ✅ Use JOINs or batch queries
   - Why: Dramatically impacts performance

3. **Missing Indexes**
   - ❌ Querying without appropriate indexes
   - ✅ Add indexes for frequently filtered/sorted columns
   - Why: Full table scans are expensive

## Quick Reference

### Typical Database Files
- **Connection**: `src/db.ts` or `src/database/index.ts`
- **Models**: `src/models/` or `src/entities/`
- **Migrations**: `migrations/` or `src/database/migrations/`

## Testing Database Code

### Patterns
1. **Unit tests**: Mock the database layer
2. **Integration tests**: Use test database or emulator
3. **Always**: Clean up test data

```typescript
// Example test setup
beforeEach(async () => {
  await db.collection('test').deleteMany({});
});
```

## Related Files

- 📁 `src/db.ts` - Database connection (example)
- 📁 `src/persistence/` - Persistence layer (example)
- 📄 `.claude/rules/testing/testing.md` - Testing patterns

---

**Created**: [DATE]
**Last Updated**: [DATE]
**Freshness**: 📚 COLD (template - update when learnings added)
