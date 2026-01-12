---
name: thoughtbox-expertise
description: Deep expertise on the ThoughtBox MCP server - architecture, implementation patterns, and effective usage. This skill should be used when building, extending, debugging, or understanding ThoughtBox. It provides crystallized expert knowledge so agents can navigate the codebase effectively without exploratory overhead.
---

# ThoughtBox Expert Guide

This skill provides expert-level knowledge of the ThoughtBox reasoning ledger MCP server. Use it to navigate the codebase, understand architectural decisions, extend functionality, or debug issues.

## Core Concepts

An expert on ThoughtBox has internalized these 10 fundamental ideas:

1. **Reasoning Ledger**: ThoughtBox treats reasoning as *data*, not just process. Every thought is numbered, timestamped, linked, persistent, and exportable.

2. **Infrastructure vs Intelligence**: The server provides *process scaffolds* that tell agents HOW to think, not WHAT to think. Tools are cognitive enhancement infrastructure.

3. **Graph-Structured Thoughts**: Thoughts exist in a doubly-linked structure supporting forward thinking (1→N), backward planning (N→1), branching explorations, and revisions.

4. **Toolhost Pattern**: Complex capabilities are exposed through single-tool dispatchers (`notebook`, `mental_models`) rather than many separate tools.

5. **Fire-and-Forget Events**: The Observatory emits events synchronously with isolated failures - external observation never affects reasoning.

6. **Session Auto-Create**: Sessions are created automatically on first thought with configurable title/tags, enabling zero-configuration usage.

7. **Resource Embedding**: Tool responses include contextual documentation as embedded resources targeting LLM consumption.

8. **Dual Transport Architecture**: Same server logic works with stdio (CLI) and HTTP (Smithery) via the `createServer()` factory.

9. **MCP Protocol Native**: Built on @modelcontextprotocol/sdk, exposing Tools, Resources, Resource Templates, and Prompts as first-class primitives.

10. **Linked Thought Store**: In-memory storage with doubly-linked list and Map index for O(1) lookups, supporting tree structures via array-based `next` pointers.

---

## Quick Reference

### File Paths

| Purpose | Path |
|---------|------|
| Main entry | `/src/index.ts` |
| Persistence | `/src/persistence/storage.ts` |
| Notebook module | `/src/notebook/index.ts` |
| Mental models | `/src/mental-models/index.ts` |
| Observatory | `/src/observatory/index.ts` |
| Init flow | `/src/init/index.ts` |
| HTTP transport | `/src/http.ts` |
| Stateful HTTP | `/src/http-stateful.ts` |
| Patterns cookbook | `/src/resources/patterns-cookbook-content.ts` |
| Prompts | `/src/prompts/index.ts` |

### Module Purposes

| Module | Purpose |
|--------|---------|
| `persistence` | In-memory session/thought storage with linked export |
| `observatory` | WebSocket server + HTML UI for real-time visualization |
| `notebook` | Literate programming with isolated JS/TS execution |
| `mental-models` | 15 reasoning frameworks with tag-based discovery |
| `init` | Session index builder for context continuity |
| `prompts` | Prompt templates (list_mcp_assets, interleaved-thinking) |
| `resources` | Static content (patterns cookbook, architecture guide) |

### Configuration

| Setting | Env Var | Default |
|---------|---------|---------|
| Thought logging | `DISABLE_THOUGHT_LOGGING` | `false` |
| Observatory port | `OBSERVATORY_PORT` | `1729` |
| Observatory enabled | `OBSERVATORY_ENABLED` | `false` (stdio), `true` (http) |
| Session auto-create | config.autoCreateSession | `true` |

For detailed architecture documentation, see [./reference/architecture.md](./reference/architecture.md).

---

## Common Tasks

### Adding a New Mental Model

1. Create a new file in `/src/mental-models/contents/` following the existing pattern
2. Export the content as a constant with the model prompt
3. Register the model in `/src/mental-models/operations.ts`:
   - Add to the `MENTAL_MODELS` record with name, description, tags, and content
4. The model automatically becomes available via `mental_models` tool with `get_model` operation

### Adding a Notebook Operation

1. Define the operation handler in `/src/notebook/operations.ts`
2. Add the operation to the operations catalog
3. Create a Zod schema for the operation's arguments
4. Register the handler in the operation dispatcher switch statement
5. Update the operations resource to document the new operation

### Extending the Observatory

1. Add new event types in `/src/observatory/emitter.ts`
2. Emit events from the appropriate module using `thoughtEmitter.emit()`
3. Handle events in the WebSocket channel subscription
4. Update the HTML UI in `/src/observatory/index.ts` to render new event types

### Creating Custom Init Flows

1. Understand the init flow architecture in `/src/init/`
2. Use `IndexBuilder` to construct session indices
3. Create resource templates that expose session navigation
4. Handle init state transitions in `InitHandler`

### Debugging Session Persistence

1. Sessions are stored in `InMemoryStorage.sessions` Map
2. Thoughts are stored in `LinkedThoughtStore` per session
3. Check auto-export to `~/.thoughtbox/exports/` on session close
4. Enable thought logging by ensuring `DISABLE_THOUGHT_LOGGING` is not set
5. Use Observatory UI at port 1729 for real-time visualization

For detailed troubleshooting, see [./reference/troubleshooting.md](./reference/troubleshooting.md).

---

## API Reference

### The `thoughtbox` Tool

Primary reasoning interface with these parameters:

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `thought` | string | Yes | Current thinking step content |
| `thoughtNumber` | number | Yes | Position in sequence (1-based) |
| `totalThoughts` | number | Yes | Estimated total thoughts needed |
| `nextThoughtNeeded` | boolean | Yes | Whether another thought follows |
| `isRevision` | boolean | No | Marks this as revising previous thought |
| `revisesThought` | number | No | Which thought number is being revised |
| `branchFromThought` | number | No | Fork point for new branch |
| `branchId` | string | No | Identifier for the branch |
| `sessionTitle` | string | No | Title for auto-created session |
| `sessionTags` | string[] | No | Tags for session discoverability |
| `includeGuide` | boolean | No | Request patterns cookbook |

### The `notebook` Tool

Literate programming interface with operation-based dispatch:

| Operation | Purpose |
|-----------|---------|
| `create` | Create new notebook (optionally from template) |
| `list` | List all active notebooks |
| `load` | Load notebook from .src.md file |
| `add_cell` | Add cell (title/markdown/code) |
| `update_cell` | Update cell content |
| `run_cell` | Execute code cell |
| `install_deps` | Install npm dependencies |
| `list_cells` | List all cells in notebook |
| `get_cell` | Get cell details |
| `export` | Export notebook to .src.md |

### The `mental_models` Tool

Access to 15 structured reasoning frameworks:

| Operation | Purpose |
|-----------|---------|
| `get_model` | Retrieve specific model by name |
| `list_models` | List available models (optionally by tag) |
| `list_tags` | List all tags with descriptions |
| `get_capability_graph` | Get structured data for knowledge graph |

**Available Tags**: debugging, planning, decision-making, risk-analysis, estimation, prioritization, communication, architecture, validation

For complete API schemas, see [./reference/api-reference.md](./reference/api-reference.md).

---

## Patterns and Idioms

### Toolhost Dispatcher Pattern

Instead of registering many tools (`notebook_create`, `notebook_add_cell`, etc.), use a single tool with an operation parameter:

```typescript
server.registerTool('notebook', schema, async (args) => {
  switch (args.operation) {
    case 'create': return handleCreate(args);
    case 'add_cell': return handleAddCell(args);
    // ...
  }
});
```

Benefits: Cleaner client interface, operation discovery via catalog resource, add operations without changing MCP registration.

### Fire-and-Forget Events

Observatory events use synchronous emission with isolated failure handling:

```typescript
thoughtEmitter.emit('thought', thoughtData);
// Emission is synchronous but listeners are wrapped in try/catch
// Main process continues even if WebSocket fails
```

### Resource Embedding

Tool responses include contextual documentation:

```typescript
return {
  content: [{ type: 'text', text: responseText }],
  _meta: {
    embeddedResources: [{
      uri: 'thoughtbox://patterns-cookbook',
      mimeType: 'text/markdown',
      text: cookbookContent,
      annotations: { audience: ['llm'] }
    }]
  }
};
```

### Session Auto-Create

Sessions are created implicitly on first thought:

```typescript
if (!currentSessionId && config.autoCreateSession) {
  currentSessionId = createSession({
    title: args.sessionTitle ?? `Session ${timestamp}`,
    tags: args.sessionTags ?? []
  });
}
```

For detailed pattern documentation, see [./reference/patterns.md](./reference/patterns.md).

---

## Expert Knowledge FAQ

| Question | Answer |
|----------|--------|
| Where is the main entry point? | `/src/index.ts` - exports `createServer()` factory |
| What are the 3 main tools? | `thoughtbox` (reasoning), `notebook` (literate programming), `mental_models` (frameworks) |
| How many mental models? | 15 models across 9 tags |
| How are thoughts stored? | In-memory via `InMemoryStorage` with `LinkedThoughtStore` for export |
| How does branching work? | `branchFromThought` + `branchId` parameters fork from any thought |
| When does session auto-create? | On first thought when `currentSessionId` is null |
| What is the Observatory? | Real-time WebSocket UI at port 1729 for visualizing reasoning |
| How are sessions exported? | Auto-export to `~/.thoughtbox/exports/` when reasoning completes |
| What triggers patterns cookbook? | Thought 1, final thought, or `includeGuide: true` |
| How does notebook execution work? | Isolated temp directories with their own package.json |
| How do I add a new mental model? | Create file in `/src/mental-models/contents/`, register in operations.ts |
| How does session persistence work? | In-memory Maps, `LinkedThoughtStore` for export, auto-export on session end |
| What is the init flow? | Resource-based navigation for loading context from previous sessions |
| How do I enable the Observatory? | Set `OBSERVATORY_ENABLED=true` environment variable |
| What is the session export format? | `SessionExport` type with version, session metadata, and linked `ThoughtNode[]` |
| How do revisions work? | `isRevision: true` + `revisesThought: N` creates node with `revisesNode` pointer |
| What MCP primitives are used? | Tools (3), Resources (6+ static), Resource Templates (5), Prompts (2) |
| How is dual transport achieved? | `createServer()` factory returns Server, entry points connect transports |
| What are the notebook templates? | `sequential-feynman` - guided deep learning workflow |
| What are the mental model tags? | debugging, planning, decision-making, risk-analysis, estimation, prioritization, communication, architecture, validation |

---

## Historical Context

### From Clear Thought 2.0 to Reasoning Ledger

ThoughtBox evolved from a fork of "Clear Thought 2.0", transforming from a step-by-step thinking tool into a comprehensive reasoning ledger. The key insight: treat reasoning as data - every thought becomes a node in a persistent graph that can be visualized, exported, and analyzed.

Development phases:
1. Basic thoughtbox tool with forward/backward/branching patterns
2. Notebook module for literate programming
3. Mental models toolhost for structured reasoning frameworks
4. Observatory for real-time visualization
5. Init flow for session context continuity across conversations

### Why Toolhost Pattern?

Traditional MCP design exposes each capability as a separate tool. ThoughtBox uses the toolhost pattern instead: a single tool with an operation parameter that dispatches to handlers.

Benefits:
- Cleaner client interface (1 tool vs 10)
- Operations discoverable via catalog resource
- Add operations without changing MCP registration
- Consistent error handling across operations

### Why Fire-and-Forget Events?

The Observatory emits events synchronously with isolated failure handling because:
- External observers should never affect reasoning performance
- Listener failures are logged but swallowed
- Main process continues even if WebSocket fails
- Zero overhead when no listeners attached

---

## Key Classes

| Class | File | Purpose |
|-------|------|---------|
| `ThoughtboxServer` | index.ts | Core reasoning tool handler |
| `InMemoryStorage` | persistence/storage.ts | Session/thought persistence |
| `LinkedThoughtStore` | persistence/storage.ts | Doubly-linked thought graph |
| `NotebookServer` | notebook/index.ts | Notebook toolhost dispatcher |
| `MentalModelsServer` | mental-models/index.ts | Mental models toolhost |
| `ThoughtEmitter` | observatory/emitter.ts | Fire-and-forget event emission |
| `IndexBuilder` | init/index-builder.ts | Session index construction |
| `InitHandler` | init/init-handler.ts | Init flow state machine |
