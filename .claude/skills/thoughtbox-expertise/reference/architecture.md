# ThoughtBox Architecture Reference

## System Overview

ThoughtBox is a reasoning ledger MCP server (~13,200 LOC TypeScript) that treats reasoning as persistent, structured data. It provides cognitive enhancement infrastructure for AI agents.

```
                        MCP Client (Claude, etc.)
                                  │
                                  ▼
                    ┌─────────────────────────────┐
                    │      src/index.ts           │
                    │   (createServer factory)    │
                    └─────────────────────────────┘
                           │    │    │    │
              ┌────────────┘    │    │    └───────────────┐
              ▼                 ▼    ▼                    ▼
    ┌─────────────────┐ ┌──────────────┐ ┌──────────────┐ ┌─────────────┐
    │ ThoughtboxServer│ │NotebookServer│ │MentalModels  │ │ InitHandler │
    │  (reasoning)    │ │(notebooks)   │ │Server        │ │(context)    │
    └────────┬────────┘ └──────────────┘ └──────────────┘ └─────────────┘
             │
             ▼
    ┌─────────────────┐
    │   persistence/  │ ──────────────────────────────────┐
    │  InMemoryStorage│                                    │
    │  SessionExporter│                                    ▼
    └─────────────────┘                        ~/.thoughtbox/exports/
             │                                             │
             ▼                                             │
    ┌─────────────────┐                                    │
    │   observatory/  │                                    │
    │  ThoughtEmitter │                                    │
    │  WebSocketServer│ ◄──────────────────────────────────┘
    └─────────────────┘               init/ indexes these
             │
             ▼
    WebSocket Clients (Observatory UI at port 1729)
```

---

## Core Modules

### 1. Main Entry (`src/index.ts`)

**Purpose**: Factory function that creates and configures the MCP server.

**Key Exports**:
- `createServer(config?)` - Returns configured MCP Server instance
- `ThoughtboxConfig` - Configuration type

**Responsibilities**:
- Register all tools (thoughtbox, notebook, mental_models)
- Register all resources and resource templates
- Register prompts
- Handle tool dispatch and response formatting
- Manage session lifecycle

**Size Note**: This file is ~46KB - a candidate for modularization into separate tool handlers.

### 2. Persistence (`src/persistence/`)

**Purpose**: In-memory storage for sessions and thoughts with export capability.

**Key Classes**:

```typescript
class InMemoryStorage {
  sessions: Map<string, Session>;
  thoughts: Map<string, LinkedThoughtStore>;

  createSession(title: string, tags?: string[]): string;
  getSession(id: string): Session | undefined;
  addThought(sessionId: string, thought: Thought): void;
  exportSession(sessionId: string): SessionExport;
}

class LinkedThoughtStore {
  nodes: Map<string, ThoughtNode>;
  head: string | null;
  tail: string | null;

  addNode(thought: Thought): ThoughtNode;
  getLinkedList(): ThoughtNode[];
}
```

**Data Structures**:
- `Session`: id, title, tags, createdAt, updatedAt
- `Thought`: number, content, timestamp, branch info, revision info
- `ThoughtNode`: Thought + prev/next pointers + branchOrigin + revisesNode

**Export Format**:
```typescript
interface SessionExport {
  version: string;
  exportedAt: string;
  session: Session;
  thoughts: ThoughtNode[];
}
```

### 3. Observatory (`src/observatory/`)

**Purpose**: Real-time visualization of reasoning via WebSocket + HTML UI.

**Components**:
- `ThoughtEmitter` - Singleton event emitter for thought events
- `WebSocketServer` - Broadcasts events to connected clients
- HTML UI - Snake layout visualization at port 1729

**Event Types**:
- `thought` - New thought added
- `branch` - Branch created
- `revision` - Thought revised
- `session:start` - Session began
- `session:end` - Session completed

**Fire-and-Forget Pattern**:
```typescript
// Emission is synchronous, but listener failures are isolated
thoughtEmitter.emit('thought', {
  sessionId,
  thought,
  node: linkedNode
});
// Main process continues even if listeners fail
```

### 4. Notebook (`src/notebook/`)

**Purpose**: Literate programming with isolated JavaScript/TypeScript execution.

**Architecture**:
```
NotebookServer
    │
    ├── Operations (create, add_cell, run_cell, etc.)
    │
    └── Notebook Instances
            │
            ├── Isolated temp directory
            ├── package.json
            ├── Cells (markdown, code)
            └── Execution via node subprocess
```

**Execution Model**:
- Each notebook gets its own temp directory
- Code cells are written to files, executed via `node`
- stdout/stderr captured and returned
- npm dependencies installed per-notebook

**Templates**:
- `sequential-feynman` - Guided deep learning with Feynman Technique

### 5. Mental Models (`src/mental-models/`)

**Purpose**: 15 structured reasoning frameworks with tag-based discovery.

**Structure**:
```
mental-models/
├── index.ts          # MentalModelsServer class
├── operations.ts     # Model registry and handlers
└── contents/         # Individual model prompts
    ├── first-principles.ts
    ├── rubber-duck.ts
    └── ... (13 more)
```

**Available Models**:
1. First Principles Thinking
2. Rubber Duck Debugging
3. Socratic Questioning
4. Devil's Advocate
5. Six Thinking Hats
6. OODA Loop
7. Fermi Estimation
8. Premortem Analysis
9. Five Whys
10. Eisenhower Matrix
11. SWOT Analysis
12. Backcasting
13. Red Team/Blue Team
14. Stakeholder Analysis
15. Decision Matrix

**Tags**: debugging, planning, decision-making, risk-analysis, estimation, prioritization, communication, architecture, validation

### 6. Init Flow (`src/init/`)

**Purpose**: Session context continuity across conversations.

**Components**:
- `IndexBuilder` - Constructs session indices from exports
- `InitHandler` - State machine for init flow navigation
- Resource templates for session discovery

**Flow**:
1. Client requests `thoughtbox://init/sessions` resource
2. IndexBuilder scans `~/.thoughtbox/exports/`
3. Returns session index with titles, tags, dates
4. Client can load specific session via resource template

### 7. Prompts (`src/prompts/`)

**Purpose**: MCP prompt templates for guided workflows.

**Available Prompts**:
- `list_mcp_assets` - Inventory all MCP capabilities
- `interleaved-thinking` - Structured reasoning workflow

### 8. Resources (`src/resources/`)

**Purpose**: Static content served as MCP resources.

**Key Resources**:
- `thoughtbox://patterns-cookbook` - 6 core reasoning patterns
- `thoughtbox://architecture` - System architecture guide
- `thoughtbox://notebook/operations` - Notebook operation catalog

---

## Transport Modes

### stdio (`src/index.ts` with stdio transport)
- Default mode for CLI usage
- Observatory disabled by default
- Direct stdin/stdout communication

### HTTP (`src/http.ts`)
- Stateless HTTP endpoints
- Observatory enabled by default
- For Smithery deployment

### Stateful HTTP (`src/http-stateful.ts`)
- HTTP with session persistence
- WebSocket support for Observatory
- For persistent server deployments

---

## Key Abstractions

### ThoughtboxStorage Interface
```typescript
interface ThoughtboxStorage {
  createSession(title: string, tags?: string[]): string;
  getSession(id: string): Session | undefined;
  addThought(sessionId: string, thought: Thought): void;
  getThoughts(sessionId: string): Thought[];
  exportSession(sessionId: string): SessionExport;
}
```

### Tool Registration Pattern
```typescript
server.registerTool(
  'toolName',
  zodSchema.shape,
  async (args) => {
    // Handle tool call
    return {
      content: [{ type: 'text', text: result }],
      _meta: { embeddedResources: [...] }
    };
  },
  { description: 'Tool description' }
);
```

### Resource Template Pattern
```typescript
server.registerResourceTemplate({
  uriTemplate: 'thoughtbox://sessions/{sessionId}',
  name: 'Session Details',
  description: 'Get details for a specific session',
  mimeType: 'application/json'
});
```

---

## Extension Points

### Adding a New Tool
1. Define Zod schema in `/src/index.ts` or separate module
2. Register tool with `server.registerTool()`
3. Handle in tool dispatch logic
4. Add documentation to resources

### Adding a New Resource
1. Use `server.registerResource()` for static resources
2. Use `server.registerResourceTemplate()` for parameterized resources
3. Handle in ListResourcesRequestSchema and ReadResourceRequestSchema handlers

### Adding a New Prompt
1. Create content in `/src/prompts/contents/`
2. Register with `server.registerPrompt()`
3. Handle in GetPromptRequestSchema handler

---

## File Index

### Core Files
| File | Lines | Purpose |
|------|-------|---------|
| `src/index.ts` | ~1200 | Main entry, tool registration |
| `src/http.ts` | ~150 | HTTP transport |
| `src/http-stateful.ts` | ~200 | Stateful HTTP transport |

### Persistence
| File | Lines | Purpose |
|------|-------|---------|
| `src/persistence/storage.ts` | ~300 | InMemoryStorage, LinkedThoughtStore |
| `src/persistence/types.ts` | ~80 | Type definitions |
| `src/persistence/exporter.ts` | ~100 | Session export logic |

### Observatory
| File | Lines | Purpose |
|------|-------|---------|
| `src/observatory/index.ts` | ~400 | WebSocket server, HTML UI |
| `src/observatory/emitter.ts` | ~80 | ThoughtEmitter singleton |
| `src/observatory/types.ts` | ~40 | Event types |

### Notebook
| File | Lines | Purpose |
|------|-------|---------|
| `src/notebook/index.ts` | ~500 | NotebookServer class |
| `src/notebook/operations.ts` | ~400 | Operation handlers |
| `src/notebook/types.ts` | ~100 | Type definitions |

### Mental Models
| File | Lines | Purpose |
|------|-------|---------|
| `src/mental-models/index.ts` | ~200 | MentalModelsServer class |
| `src/mental-models/operations.ts` | ~150 | Model registry |
| `src/mental-models/contents/*.ts` | ~100 each | Individual model prompts |

### Init
| File | Lines | Purpose |
|------|-------|---------|
| `src/init/index.ts` | ~50 | Module exports |
| `src/init/index-builder.ts` | ~200 | Session index construction |
| `src/init/init-handler.ts` | ~150 | Init flow state machine |
