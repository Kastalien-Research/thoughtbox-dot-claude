---
paths: [tests/**, **/*.test.ts, **/*.spec.ts, scripts/*test*]
---

# Testing Patterns Memory

> **Purpose**: Testing conventions, patterns, and learnings for this codebase

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

### Test Structure

**Pattern**: Arrange-Act-Assert (AAA)

```typescript
describe('FeatureName', () => {
  it('should do expected behavior when condition', async () => {
    // Arrange - set up test data and conditions
    const input = { /* ... */ };

    // Act - perform the action being tested
    const result = await featureFunction(input);

    // Assert - verify the expected outcome
    expect(result).toEqual(expectedValue);
  });
});
```

### Naming Conventions

**Pattern**: Descriptive test names that explain behavior

```typescript
// GOOD - describes behavior
it('should return empty array when no items match filter')
it('should throw ValidationError when input is invalid')

// BAD - vague names
it('works correctly')
it('test filter')
```

### Mocking

**Pattern**: Mock external dependencies, not internal logic

```typescript
// Mock external services
jest.mock('./external-api', () => ({
  fetchData: jest.fn().mockResolvedValue({ data: 'mocked' })
}));

// Don't mock the code you're testing
```

## Common Pitfalls

1. **Flaky Tests**
   - ❌ Tests that depend on timing or external state
   - ✅ Use deterministic data, mock time-dependent operations
   - Why: Unreliable tests erode confidence

2. **Test Interdependence**
   - ❌ Tests that depend on other tests running first
   - ✅ Each test should set up its own state
   - Why: Tests should run in any order

3. **Testing Implementation Details**
   - ❌ Asserting on private methods or internal state
   - ✅ Test observable behavior and public interfaces
   - Why: Implementation can change; behavior shouldn't

4. **Missing Edge Cases**
   - ❌ Only testing happy path
   - ✅ Test errors, empty inputs, boundaries
   - Why: Edge cases are where bugs hide

## Quick Reference

### Test Locations
- **Unit tests**: `tests/` or alongside source files
- **Integration tests**: `tests/integration/`
- **E2E tests**: `tests/e2e/`

### Common Commands
```bash
# Run all tests
npm test

# Run specific test file
npm test -- path/to/test.spec.ts

# Run with coverage
npm test -- --coverage

# Watch mode
npm test -- --watch
```

## Test Data Patterns

### Factories

```typescript
// Create test data factories
function createTestUser(overrides = {}) {
  return {
    id: 'test-id',
    name: 'Test User',
    email: 'test@example.com',
    ...overrides
  };
}

// Usage
const user = createTestUser({ name: 'Custom Name' });
```

### Fixtures

```typescript
// Load test fixtures
import fixtures from './fixtures/users.json';

// Or define inline for clarity
const validInput = { /* ... */ };
const invalidInput = { /* ... */ };
```

## Debugging Failed Tests

1. **Check test isolation** - Is shared state leaking?
2. **Check async handling** - Missing await? Unhandled promise?
3. **Check mocks** - Are they set up correctly? Reset between tests?
4. **Add logging** - console.log in the test to see actual values
5. **Run in isolation** - Does it pass when run alone?

## Related Files

- 📁 `tests/` - Test files
- 📁 `jest.config.js` or `vitest.config.ts` - Test configuration
- 📄 `.claude/rules/infrastructure/database.md` - Database testing patterns

---

**Created**: [DATE]
**Last Updated**: [DATE]
**Freshness**: 📚 COLD (template - update when learnings added)
