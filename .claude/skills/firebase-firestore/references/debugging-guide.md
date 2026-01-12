# Firebase & Firestore Debugging Guide

## HTTP Response Issues

### HTML Response Instead of JSON/MCP

When a Firebase/Cloud Run service returns HTML instead of the expected JSON or MCP protocol response, systematically check these areas:

#### 1. Request Routing Issues

**Symptom:** Getting a default Cloud Run page or error page instead of your endpoint.

**Checks:**
- Verify the URL path is correct (e.g., `/mcp` not `/`)
- Check if trailing slashes matter for your routing
- Confirm the service is actually deployed and running

```bash
# Verify service exists and is running
gcloud run services describe <service-name> --region=<region>

# Check the URL
gcloud run services describe <service-name> --format='value(status.url)'
```

#### 2. Authentication/Authorization Redirects

**Symptom:** Getting a login page or OAuth redirect.

**Causes:**
- Cloud Run configured to require authentication
- Application-level auth middleware redirecting

**Checks:**
```bash
# Check if service requires authentication
gcloud run services describe <service-name> \
  --format='value(spec.template.metadata.annotations["run.googleapis.com/ingress"])'

# For IAM-authenticated services, need proper token
curl -H "Authorization: Bearer $(gcloud auth print-identity-token)" \
  https://your-service.run.app/mcp
```

#### 3. Server Error Pages

**Symptom:** Getting a 500 error page (often HTML).

**Checks:**
```bash
# Check recent logs
gcloud run services logs read <service-name> --limit=100

# Look for startup errors
gcloud run services logs read <service-name> --limit=100 | grep -i error
```

#### 4. Content-Type Negotiation

**Symptom:** Server returning HTML when JSON expected.

**Solution:** Ensure proper request headers:
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","id":1}' \
  https://your-service.run.app/mcp
```

### Firestore Connection Failures

#### Error: "Could not load default credentials"

**Cause:** Firebase Admin SDK cannot find credentials.

**On Cloud Run:** Usually means:
1. Service account doesn't have necessary permissions
2. Firestore database doesn't exist in the project

**Fix:**
```bash
# Check service account
gcloud run services describe <service> \
  --format='value(spec.template.spec.serviceAccountName)'

# If using default compute SA, grant Firestore access
gcloud projects add-iam-policy-binding <project-id> \
  --member="serviceAccount:<project-number>-compute@developer.gserviceaccount.com" \
  --role="roles/datastore.user"
```

#### Error: "PERMISSION_DENIED" on Firestore operations

**Causes:**
1. Service account lacks Firestore permissions
2. Security rules blocking access (for client SDK)
3. Wrong project ID

**Diagnostic code:**
```typescript
try {
  const testDoc = await db.collection('_debug').doc('test').get();
  console.log('Firestore accessible');
} catch (error) {
  console.error('Firestore error:', {
    code: error.code,
    message: error.message,
    details: error.details
  });
}
```

#### Error: Timeout connecting to Firestore

**Causes:**
1. VPC configuration blocking egress
2. Firestore not provisioned in region
3. Network issues

**Checks:**
```bash
# Verify Firestore database exists
gcloud firestore databases list

# Check if database is in expected location
gcloud firestore databases describe --database="(default)"
```

### Initialization Issues

#### "Firebase app already exists" Error

**Cause:** `initializeApp()` called multiple times.

**Fix:**
```typescript
import { initializeApp, getApps } from 'firebase-admin/app';

// Always check before initializing
if (getApps().length === 0) {
  initializeApp();
}
```

#### Firebase Not Initialized When Accessed

**Cause:** Module execution order issues, especially in ESM.

**Symptoms:**
- `Error: The default Firebase app does not exist`
- `FirebaseAppError: Firebase: No Firebase App has been created`

**Fix:** Ensure initialization is synchronous and happens at module load:
```typescript
// firebase.ts - Initialize immediately
import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

if (getApps().length === 0) {
  initializeApp();
}

export const db = getFirestore();

// other-module.ts - Import ensures init happens first
import { db } from './firebase.js';
// db is guaranteed to be initialized here
```

### Cold Start Issues

#### Slow First Request

**Cause:** Firebase SDK initialization during cold start.

**Mitigation:**
1. Use minimum instance count > 0
2. Implement connection warming
3. Reduce container size

```bash
# Set minimum instances
gcloud run services update <service> --min-instances=1
```

#### Timeout on First Request

**Cause:** Cold start + Firestore connection takes too long.

**Fix:**
```typescript
// Increase request timeout in Cloud Run
// Or implement eager initialization

// In your server startup
const initPromise = (async () => {
  if (getApps().length === 0) {
    initializeApp();
  }
  const db = getFirestore();
  // Warm connection
  await db.collection('_health').limit(1).get();
  return db;
})();

// In request handler
app.use(async (req, res, next) => {
  req.db = await initPromise;
  next();
});
```

## Logging Strategies

### Structured Logging for Cloud Run

Cloud Run integrates with Cloud Logging. Use structured logs:

```typescript
// Simple structured log
console.log(JSON.stringify({
  severity: 'INFO',
  message: 'Processing request',
  labels: {
    service: 'thoughtbox',
    component: 'firestore'
  },
  data: {
    userId: userId,
    operation: 'saveThought'
  }
}));

// Error with stack trace
console.error(JSON.stringify({
  severity: 'ERROR',
  message: error.message,
  stack: error.stack,
  labels: {
    service: 'thoughtbox',
    component: 'firestore'
  }
}));
```

### Request Tracing

Add trace IDs to track requests through the system:

```typescript
import { randomUUID } from 'crypto';

app.use((req, res, next) => {
  req.traceId = req.headers['x-cloud-trace-context']?.split('/')[0] || randomUUID();
  console.log(JSON.stringify({
    severity: 'INFO',
    message: 'Request started',
    traceId: req.traceId,
    path: req.path,
    method: req.method
  }));
  next();
});
```

## Health Check Patterns

### Comprehensive Health Check

```typescript
app.get('/health', async (req, res) => {
  const checks = {
    server: 'ok',
    firestore: 'unknown',
    timestamp: new Date().toISOString()
  };

  try {
    const start = Date.now();
    await db.collection('_health').doc('ping').set({
      timestamp: FieldValue.serverTimestamp()
    });
    checks.firestore = 'ok';
    checks.firestoreLatencyMs = Date.now() - start;
  } catch (error) {
    checks.firestore = 'error';
    checks.firestoreError = error.message;
  }

  const status = checks.firestore === 'ok' ? 200 : 503;
  res.status(status).json(checks);
});
```

### Liveness vs Readiness

```typescript
// Liveness - is the server running?
app.get('/healthz', (req, res) => {
  res.status(200).send('ok');
});

// Readiness - can we serve traffic?
app.get('/ready', async (req, res) => {
  try {
    await db.collection('_health').limit(1).get();
    res.status(200).send('ready');
  } catch (error) {
    res.status(503).send('not ready');
  }
});
```

## Query Debugging

### Explain Query Performance

```typescript
const query = db.collection('users').where('status', '==', 'active');

// Get query explanation (requires indexes)
const explanation = await query.explain();
console.log('Query plan:', JSON.stringify(explanation, null, 2));
```

### Index Missing Errors

**Symptom:** `Error: The query requires an index`

**Fix:** The error message includes a URL to create the index:
```bash
# Or create manually
gcloud firestore indexes composite create \
  --collection-group=users \
  --field-config field-path=status,order=ASCENDING \
  --field-config field-path=createdAt,order=DESCENDING
```

### Query Performance Issues

For slow queries, check:
1. Index usage (explain output)
2. Result set size (use limit)
3. Field equality before inequality filters
4. Avoid != and NOT_IN on large collections
