---
paths: [src/firebase.ts, src/persistence/firestore.ts]
---

# Firebase & Firestore Memory

> **Purpose**: Firebase Admin SDK initialization, Firestore persistence patterns

## Recent Learnings (Most Recent First)

### 2026-01-09: Initial Setup 🔥
- **Context**: Documenting existing Firebase patterns as baseline
- **Files**: `src/firebase.ts`, `src/persistence/firestore.ts`
- **Pattern**: Firebase Admin SDK for server-side operations, not client SDK

## Core Patterns

### Firebase Admin Initialization

**Location**: `src/firebase.ts`

**Pattern**:
```typescript
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

// Initialize with service account
const app = initializeApp({
  credential: cert({
    projectId: process.env.FIREBASE_PROJECT_ID,
    clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
    privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
  }),
});

export const db = getFirestore(app);
```

**Key Points**:
- Use **Admin SDK**, not client SDK (server environment)
- Service account credentials from environment variables
- Private key requires newline handling (`\\n` → `\n`)
- Single initialization, export `db` instance

### Firestore Collections Structure

**Collections**:
```
/sessions/{sessionId}
  - userId: string
  - createdAt: timestamp
  - expiresAt: timestamp
  - metadata: object

/thoughts/{thoughtId}
  - sessionId: string
  - content: string
  - thoughtNumber: number
  - totalThoughts: number
  - next: string[] (array for branching)
  - prev: string | null
  - createdAt: timestamp

/notebooks/{notebookId}
  - sessionId: string
  - cells: array
  - metadata: object
```

### Firestore Query Patterns

**Session isolation** (critical for security):
```typescript
const thoughtsRef = db.collection('thoughts');
const userThoughts = await thoughtsRef
  .where('sessionId', '==', sessionId)
  .get();
```

**Always filter by sessionId** - prevents data leakage between users.

## Common Pitfalls

1. **Private Key Newline Handling**
   - ❌ `privateKey: process.env.FIREBASE_PRIVATE_KEY`
   - ✅ `privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n')`
   - Why: Environment variables escape newlines as `\\n`

2. **Using Client SDK Instead of Admin SDK**
   - ❌ `import { initializeApp } from 'firebase/app'`
   - ✅ `import { initializeApp } from 'firebase-admin/app'`
   - Why: Server environment, need elevated privileges

3. **Missing Session Validation**
   - ❌ Querying thoughts without session check
   - ✅ Always include `.where('sessionId', '==', sessionId)`
   - Why: Security - prevent cross-user data access

4. **Not Handling Firestore Errors**
   - Operations can fail (network, permissions, quota)
   - Always wrap in try/catch
   - Provide meaningful error messages

## Environment Variables

Required for Firebase:
```bash
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CLIENT_EMAIL=service-account@project.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

**Local Development**:
- Use `.env` file (not committed)
- Or: `export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json`

**Production**:
- Set in Cloud Run environment variables
- Use Secret Manager for private key
- See: `DEPLOYMENT_RUNBOOK.md`

## Testing

### Local Firestore Emulator
```bash
# Install
npm install -g firebase-tools

# Start emulator
firebase emulators:start --only firestore

# Point to emulator in code
process.env.FIRESTORE_EMULATOR_HOST = 'localhost:8080';
```

### Test Patterns
- Use emulator for integration tests
- Mock Firestore for unit tests (if needed)
- Behavioral tests use real Firestore (ephemeral sessions)

## Security Rules

**File**: `firestore.rules`

**Key Principles**:
1. Users can only access their own sessions
2. No public read/write access
3. Admin SDK bypasses rules (server-side)
4. Client SDK (if added later) respects rules

**Current State**:
- Server-only access (Admin SDK)
- Rules are defensive but not enforced for Admin SDK
- Important for future client SDK integration

## Performance Considerations

### Indexing
**File**: `firestore.indexes.json`

- **Compound indexes** for common queries
- Session + createdAt for temporal queries
- Deploy indexes: `firebase deploy --only firestore:indexes`

### Query Optimization
- Use `.limit()` for pagination
- Index frequently queried fields
- Avoid `.get()` on entire collections

### Cost Management
- Firestore charges per read/write/delete
- Cache frequently accessed data in memory (LinkedThoughtStore)
- Batch writes when possible

## Architecture Notes

### Why Firestore (Not PostgreSQL)?

**Pros**:
- Seamless Firebase Auth integration
- Managed (no database administration)
- Real-time capabilities (future feature)
- Scales automatically
- Good free tier

**Cons**:
- Query limitations (no OR, limited JOIN)
- Cost at scale
- Vendor lock-in

### Persistence Layer Abstraction

**Pattern**: Storage interface separates business logic from Firestore
```typescript
// src/persistence/storage.ts - Abstract interface
interface ThoughtStorage {
  save(thought: Thought): Promise<void>;
  retrieve(thoughtId: string): Promise<Thought>;
}

// src/persistence/firestore.ts - Firestore implementation
class FirestoreStorage implements ThoughtStorage {
  // Implementation details
}
```

**Benefit**: Could swap Firestore for PostgreSQL, MongoDB, etc. without changing tool logic.

## Related Files

- 📁 `src/firebase.ts` - Admin SDK initialization
- 📁 `src/persistence/firestore.ts` - Firestore storage implementation
- 📁 `src/middleware/auth.ts` - Firebase token validation
- 📄 `firestore.rules` - Security rules
- 📄 `firestore.indexes.json` - Query indexes
- 📄 `DEPLOYMENT_RUNBOOK.md` - Production setup

## Troubleshooting

### "Failed to initialize Firebase"
- Check environment variables are set
- Verify private key newline handling
- Ensure service account has Firestore permissions

### "Permission denied" errors
- Check Firestore rules
- Verify sessionId in query
- Confirm service account role (Firestore User or Admin)

### Slow queries
- Check Firestore console for missing indexes
- Add compound indexes for common query patterns
- Consider caching frequently accessed data

## Future Considerations

- **Real-time subscriptions**: Use `.onSnapshot()` for live updates
- **Offline support**: If adding client SDK
- **Data archival**: Strategy for old sessions/thoughts
- **Backup/restore**: Firestore export/import procedures
- **Migration**: If ever moving to different database

---

**Created**: 2026-01-09  
**Last Updated**: 2026-01-09  
**Freshness**: 🔥 HOT
