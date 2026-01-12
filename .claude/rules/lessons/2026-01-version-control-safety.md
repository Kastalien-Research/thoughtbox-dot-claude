# Version Control Safety Lessons 🔥

> Extracted from VERSION_CONTROL_VULNERABILITIES.md analysis

## Context

In early 2026, we conducted a comprehensive analysis of version control safety vulnerabilities across the codebase, particularly around destructive git operations and how different coding agents handle them.

**Reference**: `VERSION_CONTROL_VULNERABILITIES.md` (1151 lines)

## Key Learnings

### 1. Destructive Operations Need Explicit User Consent

**Issue**: Agents could potentially perform destructive git operations (force push, hard reset, etc.) without clear understanding of consequences.

**Solution**: 
- Implement pre-commit hooks that validate operations
- Require explicit user confirmation for destructive actions
- Use CODEOWNERS file to protect critical paths

**Pattern**: 
```bash
# In .claude/hooks/pre_tool_use.sh
if [[ $TOOL_NAME == "Bash" ]] && echo "$ARGS" | grep -E "(git push --force|git reset --hard)"; then
  echo "⚠️  DESTRUCTIVE GIT OPERATION DETECTED"
  echo "This requires explicit user approval"
  exit 1
fi
```

**Files**: 
- `.claude/hooks/pre_tool_use.sh:45-78`
- `.github/CODEOWNERS`
- `VERSION_CONTROL_VULNERABILITIES.md`

### 2. Hook-Based Protection is Environment-Dependent

**Issue**: Claude Code CLI has robust hook system; other environments (Agent SDK, API) don't have equivalent protections.

**Solution**: 
- Document which protections exist in which environments
- Implement server-side validation for critical operations
- Add defensive checks in code, not just hooks

**Pattern**: Defense-in-depth strategy
1. **Hook layer** (Claude Code): Block at tool invocation
2. **Code layer** (everywhere): Validate before operations
3. **Review layer** (human): Critical changes require approval

**Environments**:
- ✅ Claude Code CLI: Full hook support
- ⚠️  Agent SDK: Limited protection (manual tool filtering)
- ⚠️  API direct: No hook protection

### 3. Git Operations Should Be Auditable

**Issue**: Need visibility into git operations performed by agents.

**Solution**:
- Log all git operations to `.claude/state/hook.log`
- Include timestamp, operation type, and agent session ID
- Reviewable audit trail

**Files**: `.claude/hooks/post_tool_use.sh:20-35`

### 4. Protected Paths Pattern

**Issue**: Some files (deployments, infrastructure) are too critical for automated changes.

**Solution**: Use GitHub CODEOWNERS

```
# .github/CODEOWNERS
/src/firebase.ts @senior-devs
/cloudbuild.yaml @devops-team
/.github/ @admins
```

**Pattern**: Match protection level to risk:
- 🔴 Critical (prod infra): Require human review always
- 🟡 Important (core logic): Automated OK, but log and notify
- 🟢 Safe (docs, tests): Fully automated

### 5. Agent Self-Awareness About Capabilities

**Issue**: Agents should know what operations they can/can't perform safely.

**Solution**: Include in agent rules:

```markdown
## Git Operations Safety

You have permission to:
- ✅ Create branches
- ✅ Commit changes (non-destructive)
- ✅ Push to feature branches

You DO NOT have permission to:
- ❌ Force push to main/master
- ❌ Delete branches without confirmation
- ❌ Modify .github/ or deployment files
- ❌ Hard reset or rebase without explicit request

For any destructive operation, ASK the user first.
```

## CODEOWNERS Implementation

### What We Did
Created `.github/CODEOWNERS` with path-based ownership:

```
# Core infrastructure - requires senior review
/src/firebase.ts @senior-engineers
/src/middleware/ @senior-engineers
/Dockerfile @devops-team
/cloudbuild.yaml @devops-team

# Testing - more open
/tests/ @all-engineers
/scripts/ @all-engineers

# Documentation - fully open
/docs/ @team
*.md @team
```

### Why It Matters
- GitHub enforces required reviews for owned paths
- Prevents automated agents from modifying critical infrastructure
- Clear ownership for different codebase areas

## Pre-Tool-Use Hook Strategy

### Implementation Pattern

```bash
#!/bin/bash
# .claude/hooks/pre_tool_use.sh

TOOL_NAME=$1
ARGS=$2

# Parse args to detect git operations
if [[ $TOOL_NAME == "Bash" ]]; then
  if echo "$ARGS" | grep -q "git push --force"; then
    log_warning "Destructive git operation blocked: force push"
    exit 1
  fi
  
  if echo "$ARGS" | grep -q "rm -rf"; then
    log_warning "Destructive file operation requires confirmation"
    exit 1
  fi
fi

# Allow operation
exit 0
```

### Limitations
- Only works in Claude Code CLI environment
- Can be bypassed by creative command construction
- Not a replacement for proper access control

## Testing the Protections

### Test Scenarios Created
1. Agent attempts force push → blocked by hook
2. Agent modifies firebase.ts → requires CODEOWNER review
3. Agent commits to feature branch → allowed
4. Agent tries to delete branch → confirmation required

**Test Results**: See `DESTRUCTIVE_ACTIONS_ANALYSIS.md`

## Recommendations for Future Work

1. **Server-Side Validation**
   - Add critical operation checks in codebase itself
   - Don't rely solely on client-side hooks

2. **Audit Dashboard**
   - Visualize git operations from hook logs
   - Alert on suspicious patterns

3. **Agent Education**
   - Improve agent rules with safety guidelines
   - Include examples of safe vs. unsafe operations

4. **Graduated Autonomy**
   - Start agents with restricted permissions
   - Grant more autonomy as they prove reliable

5. **Rollback Mechanisms**
   - Make it easy to undo agent changes
   - Maintain checkpoint commits

## Cross-References

- 📄 `VERSION_CONTROL_VULNERABILITIES.md` - Full analysis
- 📄 `DESTRUCTIVE_ACTIONS_ANALYSIS.md` - Specific scenarios
- 📄 `.github/CODEOWNERS` - Path ownership rules
- 📄 `.claude/hooks/pre_tool_use.sh` - Hook implementation
- 📄 `.claude/rules/00-meta.md` - Memory system context

## Ongoing Vigilance

This is not a "set and forget" - version control safety requires:
- Regular review of hook logs
- Updates as new patterns emerge
- Training agents on what operations are risky
- Balancing safety with agent productivity

**Key Principle**: Trust but verify. Give agents autonomy, but have safety nets.

---

**Created**: 2026-01-09  
**Based On**: VERSION_CONTROL_VULNERABILITIES.md analysis  
**Status**: Active - update as new patterns emerge
