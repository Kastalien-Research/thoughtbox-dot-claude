---
name: firebase-firestore
description: Comprehensive guide for Firebase Admin SDK and Firestore development. This skill should be used when working with Firebase services in server environments (especially Cloud Run), implementing Firestore data operations, debugging Firebase connectivity issues, or deploying Firebase-backed applications.
---

# Firebase & Firestore Development

This skill provides guidance for developing with Firebase Admin SDK and Firestore in server environments, with special focus on Cloud Run deployments and MCP server patterns.

## Firebase Admin SDK Initialization

### Standard Server Initialization

For Cloud Run and other Google Cloud environments, use Application Default Credentials (ADC):

```typescript
import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

// Initialize only once - critical for serverless environments
if (getApps().length === 0) {
  initializeApp();
}

export const db = getFirestore();
```

**Key Points:**
- `initializeApp()` without arguments uses ADC automatically on Cloud Run
- Always check `getApps().length` before initializing to prevent duplicate app errors
- The service account running Cloud Run must have Firestore permissions

### Explicit Service Account (for local development)

```typescript
import { initializeApp, cert } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

const serviceAccount = require('./serviceAccountKey.json');

initializeApp({
  credential: cert(serviceAccount)
});

export const db = getFirestore();
```

**Security Note:** Never commit service account keys. Use environment variables or Secret Manager.

### Environment Detection Pattern

```typescript
const isCloudRun = !!process.env.K_SERVICE;
const isLocalEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;

if (getApps().length === 0) {
  if (isLocalEmulator) {
    // Emulator mode - no credentials needed
    initializeApp({ projectId: process.env.GCLOUD_PROJECT || 'demo-project' });
  } else if (isCloudRun) {
    // Cloud Run - uses ADC automatically
    initializeApp();
  } else {
    // Local development with real Firebase
    initializeApp({ credential: cert(serviceAccount) });
  }
}
```

## Firestore Data Model

### Collection/Document Structure

Firestore uses a hierarchical data model:
- **Collections** contain documents
- **Documents** contain fields and subcollections
- Document IDs are strings (auto-generated or custom)

```
users/
  {userId}/
    sessions/
      {sessionId}/
        thoughts/
          {thoughtId}
```

### Multi-Tenancy Pattern

Scope data to users using top-level user documents:

```typescript
class FirestoreStorage {
  private db: Firestore;
  private userId: string;

  private getUserRef() {
    return this.db.collection('users').doc(this.userId);
  }

  private getSessionsCollection() {
    return this.getUserRef().collection('sessions');
  }
}
```

### Document Operations

**Create/Set:**
```typescript
// Set with auto-generated ID
const docRef = await db.collection('users').add({ name: 'John' });

// Set with custom ID (creates or overwrites)
await db.collection('users').doc('userId').set({ name: 'John' });

// Set with merge (partial update, creates if doesn't exist)
await db.collection('users').doc('userId').set({ name: 'John' }, { merge: true });
```

**Read:**
```typescript
// Single document
const doc = await db.collection('users').doc('userId').get();
if (doc.exists) {
  const data = doc.data();
}

// Collection query
const snapshot = await db.collection('users').where('active', '==', true).get();
snapshot.docs.forEach(doc => console.log(doc.data()));
```

**Update:**
```typescript
// Update specific fields (document must exist)
await db.collection('users').doc('userId').update({
  name: 'Jane',
  updatedAt: FieldValue.serverTimestamp()
});
```

**Delete:**
```typescript
await db.collection('users').doc('userId').delete();

// Delete subcollections requires deleting each document
const batch = db.batch();
const snapshot = await db.collection('users').doc('userId').collection('posts').get();
snapshot.docs.forEach(doc => batch.delete(doc.ref));
await batch.commit();
```

### Timestamp Handling

Firestore uses its own Timestamp type. Convert properly:

```typescript
import { Timestamp } from 'firebase-admin/firestore';

// Writing dates
await doc.set({
  createdAt: Timestamp.now(),
  // or from JS Date
  createdAt: Timestamp.fromDate(new Date())
});

// Reading dates
const data = doc.data();
const jsDate = data.createdAt.toDate(); // Convert Firestore Timestamp to JS Date
```

### Batch Operations

For atomic operations across multiple documents:

```typescript
const batch = db.batch();

batch.set(db.collection('users').doc('user1'), { name: 'A' });
batch.update(db.collection('users').doc('user2'), { active: false });
batch.delete(db.collection('users').doc('user3'));

await batch.commit(); // All succeed or all fail
```

**Limits:** Max 500 operations per batch.

### Transactions

For operations that depend on current state:

```typescript
await db.runTransaction(async (transaction) => {
  const doc = await transaction.get(docRef);
  const newCount = (doc.data()?.count || 0) + 1;
  transaction.update(docRef, { count: newCount });
});
```

## Queries

### Basic Queries

```typescript
// Equality
db.collection('users').where('status', '==', 'active')

// Comparison
db.collection('users').where('age', '>=', 18)

// Array contains
db.collection('users').where('tags', 'array-contains', 'premium')

// Array contains any
db.collection('users').where('tags', 'array-contains-any', ['premium', 'trial'])

// In
db.collection('users').where('status', 'in', ['active', 'pending'])
```

### Ordering and Limiting

```typescript
db.collection('users')
  .orderBy('createdAt', 'desc')
  .limit(10)
  .offset(20)  // Use sparingly - pagination with cursors is preferred
```

### Pagination with Cursors

```typescript
// First page
const first = await db.collection('users').orderBy('name').limit(25).get();
const lastDoc = first.docs[first.docs.length - 1];

// Next page
const next = await db.collection('users')
  .orderBy('name')
  .startAfter(lastDoc)
  .limit(25)
  .get();
```

## Common Debugging Patterns

### HTML Response Instead of JSON/MCP

When receiving HTML instead of expected JSON responses, check:

1. **Endpoint URL correctness** - Ensure hitting `/mcp` not root
2. **Cloud Run service is actually running** - Check Cloud Run console/logs
3. **Authentication middleware** - May redirect to login page
4. **Error pages** - 404/500 errors often return HTML
5. **Request headers** - Missing `Accept: application/json` or wrong `Content-Type`

**Diagnostic approach:**
```bash
# Check if service responds at all
curl -v https://your-service.run.app/mcp

# Check with proper headers
curl -H "Accept: application/json" -H "Content-Type: application/json" \
  https://your-service.run.app/mcp

# Check Cloud Run logs
gcloud run services logs read <service-name> --limit=50
```

### Firestore Connection Issues

**Symptoms:** Timeouts, permission denied, "Could not load default credentials"

**Checklist:**
1. **Cloud Run service account permissions:**
   ```bash
   gcloud run services describe <service> --format='value(spec.template.spec.serviceAccountName)'

   # Grant Firestore access
   gcloud projects add-iam-policy-binding <project> \
     --member="serviceAccount:<sa>@<project>.iam.gserviceaccount.com" \
     --role="roles/datastore.user"
   ```

2. **Firestore database exists and is initialized:**
   ```bash
   gcloud firestore databases list
   ```

3. **Correct project ID:**
   ```typescript
   console.log('Project:', process.env.GOOGLE_CLOUD_PROJECT || process.env.GCLOUD_PROJECT);
   ```

4. **Network connectivity (for VPC configurations):**
   - Check if Cloud Run is configured with VPC connector
   - Ensure VPC allows egress to Firestore APIs

### Initialization Order Issues

**Problem:** Firebase not initialized errors, or duplicate app errors

**Solution:** Ensure initialization happens before any Firebase calls:

```typescript
// BAD - db may be used before init
export const db = getFirestore();
initializeApp();

// GOOD - init first, then export
if (getApps().length === 0) {
  initializeApp();
}
export const db = getFirestore();
```

### Cold Start Debugging

Cloud Run cold starts can cause initialization timing issues:

```typescript
// Add logging to track initialization
console.log('[Firebase] Starting initialization...');
const start = Date.now();

if (getApps().length === 0) {
  initializeApp();
}
const db = getFirestore();

console.log(`[Firebase] Initialized in ${Date.now() - start}ms`);

// Verify connection works
db.collection('_health').doc('check').get()
  .then(() => console.log('[Firebase] Connection verified'))
  .catch(err => console.error('[Firebase] Connection failed:', err));
```

## Cloud Run Integration

### Required Environment Variables

Cloud Run automatically provides:
- `GOOGLE_CLOUD_PROJECT` - Project ID
- `K_SERVICE` - Service name
- `K_REVISION` - Revision name
- `PORT` - Port to listen on (usually 8080)

### Deployment Checklist

1. **Dockerfile or buildpack configured correctly**
2. **Service account has necessary IAM roles:**
   - `roles/datastore.user` for Firestore read/write
   - `roles/firebase.admin` for full Firebase access
3. **Region alignment** - Cloud Run and Firestore in same region for lowest latency
4. **Memory allocation** - Firebase SDK needs ~256MB minimum
5. **Concurrency settings** - Consider single vs multi-request handling

### Health Check Endpoint

Cloud Run needs a health check. Include Firestore connectivity:

```typescript
app.get('/health', async (req, res) => {
  try {
    await db.collection('_health').doc('check').set({
      timestamp: FieldValue.serverTimestamp()
    });
    res.json({ status: 'healthy', firestore: 'connected' });
  } catch (error) {
    res.status(503).json({ status: 'unhealthy', error: error.message });
  }
});
```

## Security Rules (for client SDKs)

Note: Admin SDK bypasses security rules. These apply to client SDK access:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User can only access their own data
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## References

For detailed Firestore documentation patterns, see:
- `references/admin-sdk-setup.md` - Full Admin SDK initialization options
- `references/data-modeling.md` - Complex data structure patterns
- `references/debugging-guide.md` - Extended debugging scenarios

For documentation not in references, search local docs at:
`local-docs/firebase-docs-20260101/firebase.google.com_docs_firestore*.md`
