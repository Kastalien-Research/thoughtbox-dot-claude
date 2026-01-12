# ThoughtBox Design Patterns

Architectural patterns and idioms used throughout the ThoughtBox codebase.

---

## 1. Toolhost Dispatcher Pattern

**Problem**: MCP clients see many tools when capabilities are exposed individually (e.g., `notebook_create`, `notebook_add_cell`, `notebook_run_cell`, etc.).

**Solution**: Expose a single tool with an `operation` parameter that dispatches to specific handlers.

```typescript
// Instead of many tools:
server.registerTool('notebook_create', ...);
server.registerTool('notebook_add_cell', ...);
server.registerTool('notebook_run_cell', ...);

// Use one dispatcher:
server.registerTool('notebook', {
  inputSchema: z.object({
    operation: z.enum(['create', 'add_cell', 'run_cell', ...]),
    args: z.record(z.unknown())
  })
}, async ({ operation, args }) => {
  switch (operation) {
    case 'create': return handleCreate(args);
    case 'add_cell': return handleAddCell(args);
    case 'run_cell': return handleRunCell(args);
  }
});
```

**Benefits**:
- Cleaner client interface (1 tool vs 10+)
- Operations discoverable via catalog resource
- Add operations without changing MCP registration
- Consistent error handling across operations
- Grouping communicates related functionality

**Used In**: `notebook` tool, `mental_models` tool

---

## 2. Fire-and-Forget Events

**Problem**: External observation (Observatory) should never affect core reasoning performance or reliability.

**Solution**: Emit events synchronously but wrap listeners in isolated try/catch blocks.

```typescript
class ThoughtEmitter extends EventEmitter {
  emit(event: string, data: unknown): boolean {
    const listeners = this.listeners(event);
    for (const listener of listeners) {
      try {
        listener(data);
      } catch (error) {
        // Log but swallow - external failures don't affect reasoning
        logger.error(`Listener failed for ${event}:`, error);
      }
    }
    return listeners.length > 0;
  }
}

// Usage - main code doesn't care about failures
thoughtEmitter.emit('thought', {
  sessionId,
  thought,
  node: linkedNode
});
// Continues immediately, even if WebSocket fails
```

**Benefits**:
- Main process never blocked by observer failures
- Zero overhead when no listeners attached
- Failures logged for debugging but contained
- Clean separation between core logic and observation

**Used In**: Observatory module (`src/observatory/emitter.ts`)

---

## 3. Resource Embedding

**Problem**: Tool responses often benefit from contextual documentation, but separate resource reads are inefficient.

**Solution**: Include relevant documentation as embedded resources in tool responses.

```typescript
return {
  content: [{ type: 'text', text: mainResponse }],
  _meta: {
    embeddedResources: [{
      uri: 'thoughtbox://patterns-cookbook',
      mimeType: 'text/markdown',
      text: cookbookContent,
      annotations: {
        audience: ['llm']  // Target LLM consumption
      }
    }]
  }
};
```

**Triggers for Patterns Cookbook**:
- Thought 1 (session start)
- Final thought (`thoughtNumber === totalThoughts`)
- Explicit request (`includeGuide: true`)

**Benefits**:
- Reduces round trips
- Contextual documentation at the right moment
- Audience annotations guide consumption
- Progressive disclosure of information

**Used In**: `thoughtbox` tool responses

---

## 4. Session Auto-Create

**Problem**: Requiring explicit session creation adds friction and cognitive overhead.

**Solution**: Implicitly create sessions on first thought with optional customization.

```typescript
// In processThought handler:
if (!currentSessionId && config.autoCreateSession) {
  currentSessionId = storage.createSession(
    args.sessionTitle ?? `Session ${new Date().toISOString()}`,
    args.sessionTags ?? []
  );
}
```

**Customization Points**:
- `sessionTitle` - Human-readable session name
- `sessionTags` - Array of tags for discoverability

**Tag Convention**:
```
project:<name>  - Project context
task:<type>     - Task category (debugging, planning, etc.)
aspect:<focus>  - Specific focus area
```

**Benefits**:
- Zero-configuration usage
- Sensible defaults (timestamp-based titles)
- Full customization when needed
- Enables cross-chat discovery via init flow

**Used In**: `thoughtbox` tool, session lifecycle

---

## 5. Linked Thought Storage

**Problem**: Thoughts form complex structures (sequences, branches, revisions) but need efficient access patterns.

**Solution**: Doubly-linked list with Map index supporting tree structures.

```typescript
class LinkedThoughtStore {
  nodes: Map<string, ThoughtNode>;
  head: string | null;  // First thought
  tail: string | null;  // Latest thought

  addNode(thought: Thought): ThoughtNode {
    const nodeId = generateId(thought);
    const node: ThoughtNode = {
      id: nodeId,
      thought,
      prev: this.tail,
      next: [],          // Array for branching
      branchOrigin: thought.branchFromThought
        ? findNode(thought.branchFromThought)?.id
        : undefined,
      revisesNode: thought.revisesThought
        ? findNode(thought.revisesThought)?.id
        : undefined
    };

    this.nodes.set(nodeId, node);

    if (this.tail) {
      this.nodes.get(this.tail)!.next.push(nodeId);
    }
    this.tail = nodeId;

    return node;
  }
}
```

**Node ID Generation**:
```typescript
// Includes branchId to prevent collisions on parallel thought numbers
const nodeId = branchId
  ? `${sessionId}-branch-${branchId}-thought-${thoughtNumber}`
  : `${sessionId}-thought-${thoughtNumber}`;
```

**Benefits**:
- O(1) lookup by thought number
- Efficient traversal (forward/backward)
- Tree structure for branches via array `next`
- Revision links preserve history
- Export-ready linked structure

**Used In**: `src/persistence/storage.ts`

---

## 6. Factory Transport Pattern

**Problem**: Same server logic needs to work with different transports (stdio, HTTP, WebSocket).

**Solution**: Factory function returns configured server, transport handled by entry points.

```typescript
// src/index.ts - Factory
export function createServer(config?: ThoughtboxConfig): Server {
  const server = new Server({ name: 'thoughtbox', version: '1.0.0' });
  // Register all tools, resources, prompts
  return server;
}

// src/cli.ts - stdio transport
const server = createServer();
const transport = new StdioTransport();
await server.connect(transport);

// src/http.ts - HTTP transport
const server = createServer();
app.post('/mcp', async (req, res) => {
  const response = await server.handle(req.body);
  res.json(response);
});
```

**Benefits**:
- Clean separation of concerns
- Test server logic without transport
- Easy to add new transports
- Configuration passed once at creation

**Used In**: `src/index.ts`, `src/http.ts`, `src/http-stateful.ts`

---

## 7. Resource Template Pattern

**Problem**: Need parameterized resources (e.g., get session by ID) without pre-registering all possible values.

**Solution**: Use MCP resource templates with URI patterns.

```typescript
server.registerResourceTemplate({
  uriTemplate: 'thoughtbox://sessions/{sessionId}',
  name: 'Session Details',
  description: 'Load details for a specific session',
  mimeType: 'application/json'
});

// Handle in ReadResourceRequestSchema
if (uri.startsWith('thoughtbox://sessions/')) {
  const sessionId = uri.split('/').pop();
  const session = storage.getSession(sessionId);
  return { contents: [{ uri, text: JSON.stringify(session) }] };
}
```

**Templates Used**:
- `thoughtbox://sessions/{sessionId}` - Session details
- `thoughtbox://sessions/{sessionId}/thoughts` - Session thoughts
- `thoughtbox://mental-models/{modelName}` - Specific model
- `thoughtbox://notebooks/{notebookId}` - Notebook details
- `thoughtbox://init/load/{sessionId}` - Load session context

**Benefits**:
- Dynamic content without pre-registration
- Clean URI structure
- Client discovery via template listing
- Pattern matching in handlers

**Used In**: Session loading, mental model access, notebook access

---

## 8. Lazy Initialization Pattern

**Problem**: Resources like temp directories are expensive to create but may not be needed.

**Solution**: Defer initialization until first use.

```typescript
class NotebookServer {
  private tempDir: string | null = null;

  private ensureTempDir(): string {
    if (!this.tempDir) {
      this.tempDir = mkdtempSync(join(tmpdir(), 'thoughtbox-notebook-'));
      // Create package.json, etc.
    }
    return this.tempDir;
  }

  async createNotebook(title: string): Promise<Notebook> {
    const dir = this.ensureTempDir();  // Only created when needed
    // ...
  }
}
```

**Benefits**:
- Faster startup when feature not used
- Resources allocated only when needed
- Clean cleanup on shutdown

**Used In**: Notebook module (temp directories)

---

## 9. Configuration Schema Pattern

**Problem**: Configuration options need validation, defaults, and documentation.

**Solution**: Use Zod schemas for configuration with `.default()` values.

```typescript
const ThoughtboxConfigSchema = z.object({
  disableThoughtLogging: z.boolean().default(false)
    .describe("Disable console logging of thoughts"),
  autoCreateSession: z.boolean().default(true)
    .describe("Auto-create session on first thought"),
  reasoningSessionId: z.string().optional()
    .describe("Existing session ID to resume"),
  observatory: z.object({
    enabled: z.boolean().default(false),
    port: z.number().default(1729)
  }).optional()
});

type ThoughtboxConfig = z.infer<typeof ThoughtboxConfigSchema>;
```

**Environment Variables**:
```typescript
const config = ThoughtboxConfigSchema.parse({
  disableThoughtLogging: process.env.DISABLE_THOUGHT_LOGGING === 'true',
  observatory: {
    enabled: process.env.OBSERVATORY_ENABLED === 'true',
    port: parseInt(process.env.OBSERVATORY_PORT || '1729')
  }
});
```

**Benefits**:
- Type safety from Zod inference
- Documentation via `.describe()`
- Validation with helpful errors
- Defaults in one place

**Used In**: Server configuration throughout

---

## 10. Catalog Resource Pattern

**Problem**: Toolhost pattern hides operations from discovery.

**Solution**: Expose operation catalog as a static resource.

```typescript
// Register catalog resource
server.registerResource({
  uri: 'thoughtbox://notebook/operations',
  name: 'Notebook Operations',
  description: 'Catalog of all notebook operations',
  mimeType: 'application/json'
});

// Serve catalog
const operationsCatalog = {
  create: {
    description: 'Create a new notebook',
    args: { title: 'string', language: 'typescript | javascript', template: 'string?' }
  },
  add_cell: {
    description: 'Add a cell to notebook',
    args: { notebookId: 'string', cellType: 'code | markdown', content: 'string' }
  },
  // ...
};
```

**Benefits**:
- Operations discoverable despite single-tool pattern
- Documentation in structured format
- Machine-readable for tooling
- Separate from tool schema

**Used In**: Notebook operations, mental models catalog

---

## Anti-Patterns to Avoid

### 1. Separate Tools for Each Operation
Don't register 10+ tools when they're logically grouped. Use toolhost pattern.

### 2. Blocking on Observer Failures
Never let visualization or logging failures affect core functionality.

### 3. Eager Resource Creation
Don't create temp directories, open connections, etc. until actually needed.

### 4. Implicit Session Requirements
Don't require explicit session creation - use auto-create with customization options.

### 5. Hardcoded URIs
Use resource templates for parameterized access instead of pre-registering all combinations.
