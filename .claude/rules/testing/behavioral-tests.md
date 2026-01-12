---
paths: [tests/**, scripts/agentic-test.ts]
---

# Behavioral Testing Memory

## Philosophy

**We use agentic behavioral tests, NOT traditional unit tests.**

Tests are natural language specifications that a Claude agent interprets and executes. This matches how LLMs will actually use the tools in production.

## Recent Learnings (Most Recent First)

### 2026-01-08: Test Execution Reports ⚡
- **Issue**: Needed visibility into which tests passed/failed and why
- **Solution**: Created comprehensive test reports in `reports/` directory
- **Files**: `reports/behavioral_execution_report_*.md`
- **Pattern**: Generate timestamped reports after each test run for debugging
- **See Also**: `scripts/agentic-test.ts` - report generation logic

### 2025-12-20: Semantic Test Interpretation 📚
- **Issue**: Tests were too prescriptive, specifying exact API calls
- **Solution**: Write tests as goals and expected outcomes, not rigid steps
- **Pattern**: Agent figures out HOW to achieve the goal, test specifies WHAT
- **Example**:
  ```markdown
  ❌ BAD: "Call thoughtbox with params {thought: 'x', thoughtNumber: 1, ...}"
  ✅ GOOD: "Create a thought chain with 3 thoughts about X topic"
  ```

## Test Structure

### Standard Test Format
```markdown
## Test N: [Descriptive Name]

**Goal:** [What this test verifies]

**Steps:**
1. [High-level action 1]
2. [High-level action 2]
3. [Expected state change]

**Expected:** [Success criteria, not exact values]

**Why This Matters:** [Optional context]
```

### Example: Good Test

```markdown
## Test 1: Basic Forward Thinking Flow

**Goal:** Verify sequential thought progression works correctly.

**Steps:**
1. Start a reasoning chain with initial thought (1 of 3)
2. Add second thought that builds on the first
3. Complete with third thought
4. Verify chain is complete and navigable

**Expected:** 
- Each thought links to next/previous
- Guide resources appear at chain boundaries
- thoughtNumber increments correctly
- Final thought has nextThoughtNeeded: false
```

## Test Locations

| Test File | Purpose | Run Command |
|-----------|---------|-------------|
| `tests/thoughtbox.md` | Core thought operations | `npm run test:tool -- thoughtbox` |
| `tests/notebook.md` | Notebook tool features | `npm run test:tool -- notebook` |
| `tests/mental-models.md` | Mental model frameworks | `npm run test:tool -- mental-models` |
| `tests/behavioral/*.md` | Complex multi-tool workflows | `npm test` |

## Running Tests

```bash
# All tests (with rebuild)
npm test

# Specific tool (with rebuild)
npm run test:tool -- thoughtbox

# Quick run (skip rebuild)
npm run test:quick -- notebook

# Watch mode during development
npm run test:watch -- thoughtbox
```

## Test Runner Details

### Agent Configuration
- **File**: `scripts/agentic-test.ts`
- **SDK**: Anthropic Agent SDK (not MCP client)
- **Model**: claude-sonnet-4-20250514 (configurable)
- **Mode**: Single-turn with tool use enabled

### How Tests Execute
1. Test runner reads markdown test specification
2. Creates Agent SDK session with test content as initial prompt
3. Agent interprets test semantically and uses MCP tools
4. Agent reports results in natural language
5. Runner captures success/failure and generates report

## Common Pitfalls

### 1. Over-Specification
❌ **Don't**: Specify exact tool parameters
```markdown
Call thoughtbox with:
{
  thought: "This is thought 1",
  thoughtNumber: 1,
  totalThoughts: 3,
  nextThoughtNeeded: true
}
```

✅ **Do**: Describe the goal
```markdown
Create the first of 3 thoughts about solving a math problem
```

### 2. Brittle Assertions
❌ **Don't**: Check for exact response strings
```markdown
Verify response includes: "Thought successfully recorded"
```

✅ **Do**: Check for semantic outcomes
```markdown
Verify the thought was recorded and is retrievable
```

### 3. Missing Context
❌ **Don't**: Assume test isolation is perfect
```markdown
Test 5: Update the notebook
(Which notebook? From which test?)
```

✅ **Do**: Make tests self-contained
```markdown
Test 5: Create a new notebook, add a cell, then update that cell
```

## Debugging Failed Tests

### Steps:
1. Check test execution report: `reports/behavioral_execution_report_*.md`
2. Look for agent's reasoning: What did it try? Why did it fail?
3. Check tool response logs in report
4. Run test in isolation: `npm run test:tool -- [toolname]`
5. If needed, run local server and test manually with MCP inspector

### Common Failure Patterns:
- **"Tool not found"**: Check tool registration in `src/index.ts`
- **"Session not found"**: Middleware issue, check `src/middleware/session.ts`
- **"Zod validation error"**: Schema mismatch, check tool input schema
- **Agent confusion**: Test specification too vague, add more context

## Writing New Tests

### Checklist:
- [ ] Test is in correct file (`tests/[tool].md`)
- [ ] Uses standard test format (Goal/Steps/Expected)
- [ ] Goal is clear and specific
- [ ] Steps are high-level actions, not exact API calls
- [ ] Expected outcomes are semantic, not brittle strings
- [ ] Test is self-contained (doesn't depend on other tests)
- [ ] "Why This Matters" explains the importance (optional but helpful)

### Test Coverage Areas:
1. **Happy path**: Normal usage flow
2. **Error handling**: Invalid inputs, edge cases
3. **Session isolation**: Users can't access each other's data
4. **State persistence**: Data survives across operations
5. **Integration**: Multi-tool workflows

## Test Reports

### Location
`reports/behavioral_execution_report_YYYY-MM-DD.md`

### Contents
- Timestamp and test run metadata
- Per-test results (pass/fail)
- Agent reasoning and tool calls
- Error messages and stack traces
- Summary statistics

### Usage
- Review after test runs to understand failures
- Archive for historical context
- Reference when debugging similar issues

## Integration with Development

### TDD Pattern (Test-Driven Development)
1. Write behavioral test describing desired feature
2. Run test → it fails (feature doesn't exist)
3. Implement feature
4. Run test → it passes
5. Refactor if needed
6. Update test if behavior changes

### Regression Prevention
- Add test for every bug fix
- Document the bug in test's "Why This Matters"
- Ensures bug doesn't reoccur

## Related Documentation

- 📄 `AGENTS.md` - Testing strategy section
- 📁 `scripts/agentic-test.ts` - Test runner implementation
- 📁 `tests/` - All test specifications
- 📄 `reports/` - Historical test execution reports

## Future Improvements

- **Parallel test execution**: Run tests concurrently
- **Coverage metrics**: Track which tools/features are tested
- **Performance benchmarks**: Track test execution time
- **Visual test reports**: HTML/dashboard for results

---

**Last Updated**: 2026-01-09
