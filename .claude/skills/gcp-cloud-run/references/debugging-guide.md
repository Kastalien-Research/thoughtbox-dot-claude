# Cloud Run Debugging Guide

## HTTP Response Issues

### HTML Response Instead of JSON/MCP

When a Cloud Run service returns HTML instead of the expected JSON or MCP protocol response, systematically check these areas:

#### 1. Container Startup Failures

**Symptom:** Getting a default Cloud Run error page.

**Diagnostic Steps:**

```bash
# Check service status
gcloud run services describe SERVICE_NAME --region=REGION

# View startup logs
gcloud run services logs read SERVICE_NAME --region=REGION --limit=100

# Look specifically for errors
gcloud run services logs read SERVICE_NAME --region=REGION --limit=100 2>&1 | grep -E "(error|Error|ERROR|failed|Failed)"
```

**Common Startup Issues:**

1. **Port Binding:**
```typescript
// WRONG - binds to localhost only
app.listen(8080, 'localhost');

// CORRECT - binds to all interfaces
app.listen(process.env.PORT || 8080, '0.0.0.0');
```

2. **Missing Environment Variables:**
```typescript
// WRONG - crashes if PROJECT_ID not set
const projectId = process.env.PROJECT_ID;  // undefined in Cloud Run

// CORRECT - use Cloud Run's automatic env vars
const projectId = process.env.GOOGLE_CLOUD_PROJECT || process.env.GCP_PROJECT;
```

3. **Module Resolution Errors (ESM):**
```typescript
// WRONG - missing .js extension in ESM
import { db } from './firebase';

// CORRECT - ESM requires explicit extensions
import { db } from './firebase.js';
```

#### 2. Request Routing Issues

**Symptom:** 404 response as HTML.

**Checks:**

```bash
# Verify the service URL
gcloud run services describe SERVICE_NAME --format='value(status.url)' --region=REGION

# Test the exact endpoint
curl -v https://SERVICE-URL/mcp

# Check if trailing slash matters
curl -v https://SERVICE-URL/mcp/
```

**Common Routing Issues:**

```typescript
// Ensure routes are registered BEFORE error handlers
app.post('/mcp', handleMcpRequest);  // This should come first
app.use(errorHandler);                // This should come last

// Check for conflicting routes
app.get('/*', serveSPA);              // This might catch /mcp before it reaches the handler
app.post('/mcp', handleMcpRequest);   // Never reached!
```

#### 3. Authentication/Authorization Redirects

**Symptom:** Getting a login page or OAuth redirect.

**Checks:**

```bash
# Check if service requires authentication
gcloud run services describe SERVICE_NAME \
  --format='yaml(spec.template.metadata.annotations)' \
  --region=REGION

# For authenticated services, include bearer token
TOKEN=$(gcloud auth print-identity-token)
curl -H "Authorization: Bearer $TOKEN" https://SERVICE-URL/mcp
```

**Application-Level Auth:**

```typescript
// Check if auth middleware is redirecting
app.use(authMiddleware);  // This might redirect to /login

// Exclude specific routes from auth
app.post('/mcp', handleMcpRequest);  // Should this bypass auth?
app.use(authMiddleware);
```

#### 4. Content Negotiation Issues

**Symptom:** Server returning HTML when JSON expected.

**Fix:**

```bash
# Always set proper headers
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","id":1}' \
  https://SERVICE-URL/mcp
```

**Server-Side Fix:**

```typescript
// Force JSON response regardless of Accept header
app.post('/mcp', (req, res) => {
  res.setHeader('Content-Type', 'application/json');
  // ... handle request
});

// Reject non-JSON requests
app.post('/mcp', (req, res, next) => {
  if (!req.is('application/json')) {
    return res.status(415).json({ error: 'Content-Type must be application/json' });
  }
  next();
});
```

#### 5. Error Page Responses

**Symptom:** 500 error returned as HTML.

Cloud Run returns HTML error pages for unhandled errors. Add explicit JSON error handling:

```typescript
// Global error handler - MUST be last middleware
app.use((err: Error, req: express.Request, res: express.Response, next: express.NextFunction) => {
  console.error(JSON.stringify({
    severity: 'ERROR',
    message: err.message,
    stack: err.stack,
    path: req.path,
    method: req.method
  }));

  // Always return JSON, never let Express render HTML
  res.status(500).json({
    error: 'Internal Server Error',
    message: process.env.NODE_ENV === 'development' ? err.message : undefined
  });
});

// Handle 404s as JSON
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    path: req.path
  });
});
```

### Firestore Connection Debugging

#### "Could not load the default credentials"

**On Cloud Run:**

```bash
# Check which service account is attached
gcloud run services describe SERVICE_NAME \
  --format='value(spec.template.spec.serviceAccountName)' \
  --region=REGION

# Verify service account has Firestore permissions
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:SERVICE_ACCOUNT_EMAIL" \
  --format="table(bindings.role)"
```

**Fix:**

```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SERVICE_ACCOUNT_EMAIL" \
  --role="roles/datastore.user"
```

#### "PERMISSION_DENIED" on Firestore Operations

**Diagnostic Code:**

```typescript
// Add this to startup to verify Firestore access
async function checkFirestoreAccess() {
  try {
    console.log('Testing Firestore connection...');
    const testDoc = await db.collection('_debug').doc('connection-test').get();
    console.log('Firestore READ: OK');

    await db.collection('_debug').doc('connection-test').set({
      timestamp: new Date(),
      service: process.env.K_SERVICE
    });
    console.log('Firestore WRITE: OK');
  } catch (error) {
    console.error('Firestore access failed:', {
      code: error.code,
      message: error.message,
      details: error.details
    });
    throw error;
  }
}
```

#### Firestore Connection Timeout

**Causes:**
- VPC configuration blocking egress
- Firestore not provisioned
- Wrong project ID

**Checks:**

```bash
# Verify Firestore database exists
gcloud firestore databases list --project=PROJECT_ID

# Check database location
gcloud firestore databases describe --database="(default)" --project=PROJECT_ID
```

### Cold Start Debugging

#### Slow First Request

**Causes:**
- Container image too large
- Heavy initialization
- Firestore/Firebase SDK initialization

**Mitigation:**

```bash
# Set minimum instances to keep warm
gcloud run services update SERVICE_NAME \
  --min-instances=1 \
  --region=REGION

# Enable CPU boost for faster startup
gcloud run services update SERVICE_NAME \
  --cpu-boost \
  --region=REGION
```

**Code Optimization:**

```typescript
// Lazy initialization pattern
let _db: Firestore | null = null;

function getDb(): Firestore {
  if (!_db) {
    if (getApps().length === 0) {
      initializeApp();
    }
    _db = getFirestore();
  }
  return _db;
}

// Eager initialization with connection warming
const initPromise = (async () => {
  if (getApps().length === 0) {
    initializeApp();
  }
  const db = getFirestore();

  // Warm the connection
  await db.collection('_health').limit(1).get();
  console.log('Firestore connection warmed');

  return db;
})();

// Use in handlers
app.get('/data', async (req, res) => {
  const db = await initPromise;
  // ...
});
```

#### Timeout on First Request

Cloud Run default timeout is 300 seconds, but cold starts can still cause issues.

**Fix:**

```bash
# Increase timeout
gcloud run services update SERVICE_NAME \
  --timeout=600 \
  --region=REGION
```

### Memory Issues

#### "Container exceeded memory limit"

**Diagnostic:**

```bash
# Check current memory setting
gcloud run services describe SERVICE_NAME \
  --format='value(spec.template.spec.containers[0].resources.limits.memory)' \
  --region=REGION
```

**Fix:**

```bash
# Increase memory
gcloud run services update SERVICE_NAME \
  --memory=1Gi \
  --region=REGION
```

**Note:** Firebase Admin SDK typically needs at least 256MB.

### Logging for Debugging

#### Structured Logging Pattern

```typescript
interface LogEntry {
  severity: 'DEBUG' | 'INFO' | 'WARNING' | 'ERROR';
  message: string;
  [key: string]: any;
}

function log(entry: LogEntry) {
  console.log(JSON.stringify({
    ...entry,
    timestamp: new Date().toISOString(),
    service: process.env.K_SERVICE,
    revision: process.env.K_REVISION,
    traceId: getCurrentTraceId() // If available
  }));
}

// Usage
log({
  severity: 'INFO',
  message: 'Processing MCP request',
  method: 'tools/call',
  toolName: 'thoughtbox'
});

log({
  severity: 'ERROR',
  message: 'Request failed',
  error: err.message,
  stack: err.stack
});
```

#### Request Tracing

```typescript
import { randomUUID } from 'crypto';

// Add trace ID to all requests
app.use((req, res, next) => {
  // Use Cloud Trace header if available, otherwise generate
  req.traceId = req.headers['x-cloud-trace-context']?.toString().split('/')[0] || randomUUID();

  log({
    severity: 'INFO',
    message: 'Request received',
    traceId: req.traceId,
    method: req.method,
    path: req.path,
    contentType: req.headers['content-type']
  });

  next();
});
```

### Viewing Logs

```bash
# Real-time logs
gcloud run services logs tail SERVICE_NAME --region=REGION

# Historical logs
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=SERVICE_NAME" \
  --limit=50 \
  --format="table(timestamp, jsonPayload.severity, jsonPayload.message)"

# Filter by severity
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=SERVICE_NAME AND severity>=ERROR" \
  --limit=50
```
