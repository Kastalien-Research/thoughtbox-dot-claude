# ThoughtBox API Reference

Complete reference for all MCP primitives: Tools, Resources, Resource Templates, and Prompts.

---

## Tools

### `thoughtbox`

Primary reasoning interface for structured thinking.

**Schema**:
```typescript
{
  thought: string;           // Required: Current thinking step content
  nextThoughtNeeded: boolean; // Required: Whether another thought follows
  thoughtNumber: number;      // Required: Position in sequence (1-based, min: 1)
  totalThoughts: number;      // Required: Estimated total thoughts (min: 1)
  isRevision?: boolean;       // Optional: Marks this as revising previous thought
  revisesThought?: number;    // Optional: Which thought number is being revised (min: 1)
  branchFromThought?: number; // Optional: Fork point for new branch (min: 1)
  branchId?: string;          // Optional: Identifier for the branch
  needsMoreThoughts?: boolean; // Optional: Signal that more thoughts are needed
  includeGuide?: boolean;     // Optional: Request patterns cookbook in response
  sessionTitle?: string;      // Optional: Title for auto-created session (thought 1 only)
  sessionTags?: string[];     // Optional: Tags for session discoverability (thought 1 only)
}
```

**Annotations**:
- `readOnlyHint`: false
- `destructiveHint`: false
- `idempotentHint`: false

**Response Structure**:
```typescript
{
  content: [{ type: 'text', text: string }],
  _meta?: {
    embeddedResources?: [{
      uri: string;
      mimeType: string;
      text: string;
      annotations?: { audience: string[] }
    }]
  }
}
```

**Embedded Resources**:
- Patterns cookbook included automatically at thought 1, final thought, or when `includeGuide: true`

**Usage Examples**:

Forward thinking (1→N):
```json
{
  "thought": "First, let me understand the problem...",
  "thoughtNumber": 1,
  "totalThoughts": 5,
  "nextThoughtNeeded": true,
  "sessionTitle": "Debugging memory leak",
  "sessionTags": ["project:myapp", "task:debugging"]
}
```

Backward planning (N→1):
```json
{
  "thought": "The end state should be a fully tested feature...",
  "thoughtNumber": 5,
  "totalThoughts": 5,
  "nextThoughtNeeded": true
}
```

Branching:
```json
{
  "thought": "Alternative approach: what if we use caching?",
  "thoughtNumber": 3,
  "totalThoughts": 5,
  "nextThoughtNeeded": true,
  "branchFromThought": 2,
  "branchId": "caching-approach"
}
```

Revision:
```json
{
  "thought": "Actually, my earlier analysis missed a key factor...",
  "thoughtNumber": 4,
  "totalThoughts": 5,
  "nextThoughtNeeded": true,
  "isRevision": true,
  "revisesThought": 2
}
```

---

### `notebook`

Literate programming with isolated JavaScript/TypeScript execution.

**Schema**:
```typescript
{
  operation: 'create' | 'list' | 'load' | 'add_cell' | 'update_cell' |
             'run_cell' | 'install_deps' | 'list_cells' | 'get_cell' | 'export';
  args?: Record<string, unknown>;  // Operation-specific arguments
}
```

**Annotations**:
- `readOnlyHint`: false
- `destructiveHint`: false
- `idempotentHint`: false

**Operations**:

#### `create`
Create a new notebook.
```json
{
  "operation": "create",
  "args": {
    "title": "My Analysis",
    "language": "typescript",
    "template": "sequential-feynman"  // Optional template
  }
}
```

#### `list`
List all active notebooks.
```json
{
  "operation": "list",
  "args": {}
}
```

#### `load`
Load notebook from .src.md file.
```json
{
  "operation": "load",
  "args": {
    "path": "/path/to/notebook.src.md"
  }
}
```

#### `add_cell`
Add a cell to notebook.
```json
{
  "operation": "add_cell",
  "args": {
    "notebookId": "abc123",
    "cellType": "code",  // "code" | "markdown"
    "content": "console.log('hello')",
    "filename": "example.ts"  // Required for code cells
  }
}
```

#### `update_cell`
Update existing cell content.
```json
{
  "operation": "update_cell",
  "args": {
    "notebookId": "abc123",
    "cellId": "cell_456",
    "content": "Updated content"
  }
}
```

#### `run_cell`
Execute a code cell.
```json
{
  "operation": "run_cell",
  "args": {
    "notebookId": "abc123",
    "cellId": "cell_456"
  }
}
```

#### `install_deps`
Install npm dependencies for notebook.
```json
{
  "operation": "install_deps",
  "args": {
    "notebookId": "abc123",
    "dependencies": ["lodash", "date-fns"]
  }
}
```

#### `list_cells`
List all cells in notebook.
```json
{
  "operation": "list_cells",
  "args": {
    "notebookId": "abc123"
  }
}
```

#### `get_cell`
Get details of specific cell.
```json
{
  "operation": "get_cell",
  "args": {
    "notebookId": "abc123",
    "cellId": "cell_456"
  }
}
```

#### `export`
Export notebook to .src.md format.
```json
{
  "operation": "export",
  "args": {
    "notebookId": "abc123",
    "path": "/path/to/output.src.md"
  }
}
```

---

### `mental_models`

Access to 15 structured reasoning frameworks.

**Schema**:
```typescript
{
  operation: 'get_model' | 'list_models' | 'list_tags' | 'get_capability_graph';
  args?: {
    model?: string;  // Model name (for get_model)
    tag?: string;    // Tag filter (for list_models)
  }
}
```

**Operations**:

#### `get_model`
Retrieve a specific mental model.
```json
{
  "operation": "get_model",
  "args": { "model": "first-principles" }
}
```

Available models:
- `first-principles` - Break down to fundamental truths
- `rubber-duck` - Explain to debug
- `socratic-questioning` - Question assumptions
- `devils-advocate` - Challenge positions
- `six-thinking-hats` - Multiple perspectives
- `ooda-loop` - Observe-Orient-Decide-Act
- `fermi-estimation` - Quick approximations
- `premortem-analysis` - Anticipate failures
- `five-whys` - Root cause analysis
- `eisenhower-matrix` - Urgency vs importance
- `swot-analysis` - Strengths, weaknesses, opportunities, threats
- `backcasting` - Work backward from goals
- `red-team-blue-team` - Attack/defend analysis
- `stakeholder-analysis` - Identify affected parties
- `decision-matrix` - Multi-criteria evaluation

#### `list_models`
List available models, optionally filtered by tag.
```json
{
  "operation": "list_models",
  "args": { "tag": "debugging" }
}
```

#### `list_tags`
List all available tags with descriptions.
```json
{
  "operation": "list_tags",
  "args": {}
}
```

Tags:
- `debugging` - Troubleshooting and root cause analysis
- `planning` - Strategy and project planning
- `decision-making` - Choices and trade-offs
- `risk-analysis` - Identifying and mitigating risks
- `estimation` - Approximations and forecasting
- `prioritization` - Ordering tasks and goals
- `communication` - Explaining and persuading
- `architecture` - System design decisions
- `validation` - Testing and verification

#### `get_capability_graph`
Get structured data for knowledge graph initialization.
```json
{
  "operation": "get_capability_graph",
  "args": {}
}
```

---

### `export_reasoning_chain`

Export session to filesystem.

**Schema**:
```typescript
{
  sessionId?: string;    // Session to export (default: current)
  destination?: string;  // Export directory (default: ~/.thoughtbox/exports/)
}
```

**Annotations**:
- `readOnlyHint`: true
- `destructiveHint`: false
- `idempotentHint`: true

---

## Resources

### Static Resources

| URI | Description |
|-----|-------------|
| `thoughtbox://patterns-cookbook` | 6 core reasoning patterns with examples |
| `thoughtbox://architecture` | System architecture documentation |
| `thoughtbox://notebook/operations` | Notebook operation catalog |
| `thoughtbox://mental-models/catalog` | Mental models catalog |
| `thoughtbox://init/sessions` | Session index for context loading |
| `thoughtbox://capabilities` | Server capabilities overview |

### Resource Templates

| URI Template | Description |
|--------------|-------------|
| `thoughtbox://sessions/{sessionId}` | Load specific session details |
| `thoughtbox://sessions/{sessionId}/thoughts` | Get all thoughts from session |
| `thoughtbox://mental-models/{modelName}` | Get specific mental model |
| `thoughtbox://notebooks/{notebookId}` | Get notebook details |
| `thoughtbox://init/load/{sessionId}` | Load session context |

---

## Prompts

### `list_mcp_assets`

Inventory all available MCP capabilities.

**Arguments**: None

**Returns**: Formatted list of all tools, resources, and prompts available to the client.

### `interleaved-thinking`

Structured reasoning workflow for complex tasks.

**Arguments**:
```typescript
{
  task: string;          // The task to accomplish
  thoughtsLimit?: number; // Max thoughts (default: 100)
  clearFolder?: boolean;  // Clean up artifacts (default: false)
}
```

**Phases**:
1. Tooling Inventory - Enumerate available tools
2. Sufficiency Assessment - Determine if tools are adequate
3. Strategy Development - Plan using thoughtbox
4. Execution - Execute the strategy
5. Final Answer - Synthesize results

---

## Response Formats

### Success Response
```typescript
{
  content: [
    { type: 'text', text: string }
  ],
  isError?: false,
  _meta?: {
    embeddedResources?: EmbeddedResource[]
  }
}
```

### Error Response
```typescript
{
  content: [
    { type: 'text', text: string }  // Error message
  ],
  isError: true
}
```

### Embedded Resource Format
```typescript
{
  uri: string;                    // Resource URI
  mimeType: string;               // e.g., 'text/markdown'
  text: string;                   // Resource content
  annotations?: {
    audience: ('human' | 'llm')[] // Target audience
  }
}
```

---

## Session Export Format

```typescript
interface SessionExport {
  version: string;           // Export format version
  exportedAt: string;        // ISO timestamp
  session: {
    id: string;
    title: string;
    tags: string[];
    createdAt: string;
    updatedAt: string;
  };
  thoughts: ThoughtNode[];   // Linked thought list
}

interface ThoughtNode {
  id: string;
  thought: Thought;
  prev: string | null;
  next: string[];           // Array for branching
  branchOrigin?: string;    // Fork point reference
  revisesNode?: string;     // Revision target
}

interface Thought {
  number: number;
  content: string;
  timestamp: string;
  branchId?: string;
  isRevision?: boolean;
  revisesThought?: number;
}
```

---

## Error Codes

| Error | Cause | Resolution |
|-------|-------|------------|
| `SESSION_NOT_FOUND` | Invalid session ID | Check session exists or let auto-create handle it |
| `THOUGHT_NOT_FOUND` | Invalid thought reference for revision/branch | Verify thought number exists |
| `NOTEBOOK_NOT_FOUND` | Invalid notebook ID | Check notebook ID from `list` operation |
| `CELL_NOT_FOUND` | Invalid cell ID | Check cell ID from `list_cells` operation |
| `MODEL_NOT_FOUND` | Invalid mental model name | Use `list_models` to see available models |
| `EXECUTION_FAILED` | Code cell execution error | Check code syntax and dependencies |
| `EXPORT_FAILED` | File system error during export | Check write permissions |
