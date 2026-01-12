# ThoughtBox Troubleshooting Guide

Common issues, their causes, and solutions.

---

## Session Issues

### Thoughts Not Persisting

**Symptoms**: Thoughts are processed but don't appear in exports or Observatory.

**Diagnosis**:
1. Check if session was created: Look for session ID in logs
2. Check storage state: Are thoughts being added to `LinkedThoughtStore`?
3. Check export triggers: Is `nextThoughtNeeded: false` ever sent?

**Solutions**:
- Ensure `config.autoCreateSession` is `true` (default)
- Verify thoughts include required fields (`thoughtNumber`, `totalThoughts`)
- Check that final thought has `nextThoughtNeeded: false` to trigger export

**Debug Code**:
```typescript
// Add logging to processThought
console.log('Session:', currentSessionId);
console.log('Thought count:', storage.getThoughts(currentSessionId).length);
```

### Session Not Auto-Creating

**Symptoms**: First thought fails with "no active session" error.

**Causes**:
- `autoCreateSession` disabled in config
- `reasoningSessionId` set but doesn't exist

**Solutions**:
- Remove `reasoningSessionId` from config if starting fresh
- Set `autoCreateSession: true` explicitly
- Pass `sessionTitle` on first thought to confirm auto-create

### Exports Not Appearing

**Symptoms**: Session completes but no file in `~/.thoughtbox/exports/`.

**Causes**:
- Session never marked complete (`nextThoughtNeeded` always `true`)
- File system permissions
- Export directory doesn't exist

**Solutions**:
- Ensure final thought has `nextThoughtNeeded: false`
- Check permissions: `ls -la ~/.thoughtbox/exports/`
- Create directory manually: `mkdir -p ~/.thoughtbox/exports`
- Check logs for export errors

**Export Filename Format**:
```
{sessionId}-{ISO-timestamp}.json
```

---

## Observatory Issues

### Observatory Not Showing Thoughts

**Symptoms**: Navigate to port 1729, see UI but no thoughts appear.

**Diagnosis**:
1. Check if Observatory is enabled
2. Check WebSocket connection in browser dev tools
3. Check server logs for emission events

**Solutions**:

1. **Enable Observatory**:
   ```bash
   OBSERVATORY_ENABLED=true npx thoughtbox
   ```

2. **Check port availability**:
   ```bash
   lsof -i :1729
   ```

3. **Verify WebSocket**:
   - Open browser dev tools → Network → WS tab
   - Should see active connection to `ws://localhost:1729`

### Observatory Port Conflict

**Symptoms**: Server fails to start with "EADDRINUSE" error.

**Solutions**:
- Change port: `OBSERVATORY_PORT=1730`
- Kill existing process: `kill $(lsof -t -i:1729)`
- Use different transport mode (stdio has Observatory disabled by default)

### Thoughts Not Updating in Real-Time

**Symptoms**: UI shows old state, doesn't update live.

**Causes**:
- WebSocket disconnected
- Browser tab was backgrounded (some browsers throttle)
- Event emission failing silently

**Solutions**:
- Refresh the page
- Check for errors in browser console
- Check server logs for emission errors
- Verify `thoughtEmitter` is properly initialized

---

## Notebook Issues

### Code Execution Fails

**Symptoms**: `run_cell` returns error or no output.

**Diagnosis**:
1. Check cell content for syntax errors
2. Check if dependencies are installed
3. Check temp directory permissions

**Solutions**:

1. **Validate code**:
   ```json
   {
     "operation": "get_cell",
     "args": { "notebookId": "...", "cellId": "..." }
   }
   ```

2. **Install dependencies**:
   ```json
   {
     "operation": "install_deps",
     "args": { "notebookId": "...", "dependencies": ["lodash"] }
   }
   ```

3. **Check temp directory**:
   ```bash
   ls -la /tmp/thoughtbox-notebook-*
   ```

### Notebook Not Found

**Symptoms**: Operations fail with "notebook not found" error.

**Causes**:
- Notebook ID doesn't exist
- Server restarted (in-memory storage lost)
- Wrong notebook ID

**Solutions**:
- List notebooks: `{ "operation": "list", "args": {} }`
- Create new notebook if needed
- Use `load` operation to restore from `.src.md` file

### TypeScript Compilation Errors

**Symptoms**: TypeScript cells fail with type errors.

**Causes**:
- Missing type definitions
- Incompatible TypeScript version
- Module resolution issues

**Solutions**:
- Install type definitions: `@types/node`, `@types/lodash`, etc.
- Check tsconfig.json in notebook directory
- Use explicit `any` for quick fixes

---

## Mental Models Issues

### Model Not Found

**Symptoms**: `get_model` returns error.

**Solutions**:
1. List available models:
   ```json
   { "operation": "list_models", "args": {} }
   ```

2. Check exact model name (lowercase, hyphenated):
   - `first-principles` ✓
   - `First Principles` ✗
   - `firstPrinciples` ✗

### Tags Return Empty

**Symptoms**: `list_models` with tag filter returns no results.

**Solutions**:
- Check available tags:
  ```json
  { "operation": "list_tags", "args": {} }
  ```
- Use exact tag names: `debugging`, `planning`, `decision-making`, etc.

---

## Init Flow Issues

### Sessions Index Empty

**Symptoms**: `thoughtbox://init/sessions` returns no sessions.

**Causes**:
- No exports exist in `~/.thoughtbox/exports/`
- Export files corrupted or malformed
- Wrong directory scanned

**Solutions**:
- Check exports exist: `ls ~/.thoughtbox/exports/`
- Validate JSON: `cat ~/.thoughtbox/exports/*.json | jq .`
- Check IndexBuilder logs for errors

### Session Load Fails

**Symptoms**: `thoughtbox://init/load/{sessionId}` returns error.

**Causes**:
- Session ID doesn't match any export
- Export file corrupted
- File system permissions

**Solutions**:
- Verify session exists in index first
- Check file integrity manually
- Ensure read permissions on exports directory

---

## Branching Issues

### Branch Creates Duplicate Thoughts

**Symptoms**: Branch has same thought numbers as main line, causing confusion.

**Clarification**: This is expected behavior. Branches have their own thought number sequences. The `branchId` differentiates them.

**Node ID Format**:
```
Main line:  {sessionId}-thought-{number}
Branch:     {sessionId}-branch-{branchId}-thought-{number}
```

### Branch Origin Not Linked

**Symptoms**: Branch thought doesn't show connection to fork point.

**Causes**:
- `branchFromThought` references non-existent thought
- Missing `branchId`

**Solutions**:
- Ensure `branchFromThought` is a valid existing thought number
- Always provide `branchId` when branching:
  ```json
  {
    "branchFromThought": 3,
    "branchId": "alternative-approach"
  }
  ```

---

## Revision Issues

### Revision Not Showing Link

**Symptoms**: Revision thought doesn't connect to revised thought.

**Solutions**:
- Ensure both `isRevision: true` AND `revisesThought: N` are provided
- Verify `revisesThought` is a valid existing thought number

**Correct Usage**:
```json
{
  "isRevision": true,
  "revisesThought": 2,
  "thought": "Let me reconsider my earlier analysis..."
}
```

---

## Transport Issues

### stdio: No Response

**Symptoms**: Commands sent to stdin produce no output.

**Causes**:
- Malformed JSON-RPC request
- Server crashed silently
- Buffer not flushed

**Solutions**:
- Validate JSON: `echo '{"jsonrpc":"2.0","method":"..."}' | jq .`
- Add newline after each request
- Check stderr for errors

### HTTP: Timeout

**Symptoms**: HTTP requests take too long and timeout.

**Causes**:
- Long-running operations (code execution)
- Server overloaded
- Network issues

**Solutions**:
- Increase client timeout
- For notebook execution, use shorter code
- Check server logs for blocking operations

---

## Performance Issues

### Slow Thought Processing

**Symptoms**: Each thought takes several seconds.

**Causes**:
- Large embedded resources
- Expensive logging
- Observatory overhead

**Solutions**:
- Disable thought logging: `DISABLE_THOUGHT_LOGGING=true`
- Disable Observatory if not needed
- Check for expensive operations in custom code

### Memory Growth

**Symptoms**: Server memory increases over time.

**Causes**:
- Sessions not being cleaned up
- Large notebooks with many cells
- Event listener leaks

**Solutions**:
- Restart server periodically for long-running instances
- Export and clear old sessions
- Monitor with `process.memoryUsage()`

---

## Development Issues

### TypeScript Compilation Errors

**Symptoms**: `npm run build` fails.

**Solutions**:
1. Check TypeScript version matches project requirements
2. Ensure all dependencies installed: `npm install`
3. Check for breaking changes in `@modelcontextprotocol/sdk`

### Tests Failing

**Symptoms**: `npm test` reports failures.

**Solutions**:
1. Run in isolation to identify flaky tests
2. Check test dependencies are installed
3. Verify test fixtures exist
4. Check for port conflicts (Observatory tests)

### MCP Connection Issues

**Symptoms**: Client can't connect to server.

**Solutions**:
1. Verify MCP SDK version compatibility
2. Check transport configuration
3. Validate server is running and accessible
4. Check for firewall/network restrictions

---

## Quick Diagnostic Commands

```bash
# Check if server is running
lsof -i :1729

# View recent exports
ls -la ~/.thoughtbox/exports/ | tail -5

# Validate export JSON
cat ~/.thoughtbox/exports/latest.json | jq '.session.title'

# Check server logs (if using systemd)
journalctl -u thoughtbox -f

# Monitor memory usage
node -e "setInterval(() => console.log(process.memoryUsage()), 1000)"

# Test MCP connection
echo '{"jsonrpc":"2.0","id":1,"method":"mcp/list_tools"}' | npx thoughtbox
```
