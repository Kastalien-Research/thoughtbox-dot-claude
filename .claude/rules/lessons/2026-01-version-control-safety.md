# Version Control Safety Lessons

> **Purpose**: Example lesson file demonstrating patterns for git safety with AI agents

## Context

This lesson captures learnings about version control safety when working with AI coding agents. These patterns apply to any codebase using git.

## Key Learnings

### 1. Destructive Operations Need Explicit User Consent

**Issue**: Agents could potentially perform destructive git operations (force push, hard reset, etc.) without clear understanding of consequences.

**Solution**:
- Implement pre-commit hooks that validate operations
- Require explicit user confirmation for destructive actions
- Use CODEOWNERS file to protect critical paths

**Pattern**:
```bash
# In .claude/hooks/pre_tool_use.sh or similar
if [[ $TOOL_NAME == "Bash" ]] && echo "$ARGS" | grep -E "(git push --force|git reset --hard)"; then
  echo "DESTRUCTIVE GIT OPERATION DETECTED"
  echo "This requires explicit user approval"
  exit 1
fi
```

### 2. Hook-Based Protection is Environment-Dependent

**Issue**: Claude Code CLI has robust hook system; other environments may not have equivalent protections.

**Solution**:
- Document which protections exist in which environments
- Implement server-side validation for critical operations
- Add defensive checks in code, not just hooks

**Pattern**: Defense-in-depth strategy
1. **Hook layer**: Block at tool invocation
2. **Code layer**: Validate before operations
3. **Review layer**: Critical changes require approval

### 3. Git Operations Should Be Auditable

**Issue**: Need visibility into git operations performed by agents.

**Solution**:
- Log all git operations
- Include timestamp, operation type, and session context
- Maintain reviewable audit trail

### 4. Protected Paths Pattern

**Issue**: Some files (deployments, infrastructure) are too critical for automated changes.

**Solution**: Use GitHub CODEOWNERS

```
# .github/CODEOWNERS example
/src/database.ts @senior-devs
/infrastructure/ @devops-team
/.github/ @admins
```

**Pattern**: Match protection level to risk:
- Critical (prod infra): Require human review always
- Important (core logic): Automated OK, but log and notify
- Safe (docs, tests): Fully automated

### 5. Agent Self-Awareness About Capabilities

**Issue**: Agents should know what operations they can/can't perform safely.

**Solution**: Include in agent rules:

```markdown
## Git Operations Safety

You have permission to:
- Create branches
- Commit changes (non-destructive)
- Push to feature branches

You DO NOT have permission to:
- Force push to main/master
- Delete branches without confirmation
- Modify .github/ or deployment files
- Hard reset or rebase without explicit request

For any destructive operation, ASK the user first.
```

## Recommendations

1. **Server-Side Validation**: Don't rely solely on client-side hooks
2. **Audit Dashboard**: Visualize git operations from logs
3. **Graduated Autonomy**: Start agents with restricted permissions
4. **Rollback Mechanisms**: Make it easy to undo agent changes

## Key Principle

**Trust but verify.** Give agents autonomy, but have safety nets.

---

**Created**: 2026-01-09
**Status**: Active - update as new patterns emerge
**Applicability**: Universal (any git-based project)
