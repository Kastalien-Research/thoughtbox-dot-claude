---
name: gcp-cloud-run
description: Comprehensive guide for Google Cloud Run development and deployment. This skill should be used when deploying containerized services to Cloud Run, debugging Cloud Run service issues (especially HTTP response problems), configuring service identity and authentication, or integrating with other GCP services like Firestore.
---

# Google Cloud Run Development

This skill provides guidance for developing and deploying applications on Google Cloud Run, with special focus on MCP server deployments, Firestore integration, and debugging common issues.

## Container Runtime Contract

Cloud Run has specific requirements for containers:

### Port Configuration

```typescript
// Cloud Run injects PORT environment variable (default 8080)
const port = parseInt(process.env.PORT || '8080');

// Your server MUST listen on this port
app.listen(port, '0.0.0.0', () => {
  console.log(`Server listening on port ${port}`);
});
```

**Critical:** Cloud Run sends requests to `0.0.0.0:PORT`. Binding only to `localhost` will cause connection failures.

### Required Environment Variables (Auto-Injected)

| Variable | Description |
|----------|-------------|
| `PORT` | Port to listen on (default: 8080) |
| `K_SERVICE` | Service name |
| `K_REVISION` | Revision name |
| `K_CONFIGURATION` | Configuration name |
| `GOOGLE_CLOUD_PROJECT` | Project ID |

### Instance Lifecycle

1. **Startup**: Container starts, Cloud Run waits for it to listen on PORT
2. **Request Processing**: Requests routed to container
3. **Idle**: Container may be kept warm or terminated
4. **Shutdown**: SIGTERM sent, 10 seconds grace period

```typescript
// Handle graceful shutdown
process.on('SIGTERM', async () => {
  console.log('SIGTERM received, shutting down gracefully');
  // Close connections, flush logs, etc.
  await cleanup();
  process.exit(0);
});
```

## Deployment

### From Source Code

```bash
gcloud run deploy SERVICE_NAME \
  --source . \
  --region us-central1 \
  --allow-unauthenticated
```

### From Container Image

```bash
gcloud run deploy SERVICE_NAME \
  --image us-docker.pkg.dev/PROJECT_ID/REPO/IMAGE:TAG \
  --region us-central1 \
  --allow-unauthenticated
```

### Common Deployment Options

```bash
gcloud run deploy SERVICE_NAME \
  --image IMAGE_URL \
  --region us-central1 \
  --memory 512Mi \
  --cpu 1 \
  --min-instances 0 \
  --max-instances 10 \
  --timeout 300 \
  --concurrency 80 \
  --set-env-vars KEY1=VALUE1,KEY2=VALUE2 \
  --service-account SA_EMAIL \
  --allow-unauthenticated
```

### Dockerfile for Node.js/TypeScript

```dockerfile
FROM node:20-slim

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY dist/ ./dist/

# Cloud Run injects PORT
ENV PORT=8080
EXPOSE 8080

CMD ["node", "dist/index.js"]
```

## Service Identity

Cloud Run uses two identity types:

### 1. Deployer Identity
- The person/service running `gcloud run deploy`
- Needs `roles/run.admin` and `roles/iam.serviceAccountUser`

### 2. Service (Runtime) Identity
- The service account the container runs as
- Used for all API calls from within the container
- Default: Compute Engine default SA (NOT recommended for production)

### Configuring Service Identity

```bash
# Create dedicated service account
gcloud iam service-accounts create my-service-sa \
  --display-name="My Cloud Run Service"

# Grant necessary roles
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:my-service-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/datastore.user"

# Deploy with service account
gcloud run deploy SERVICE_NAME \
  --service-account=my-service-sa@PROJECT_ID.iam.gserviceaccount.com
```

### Application Default Credentials (ADC)

On Cloud Run, client libraries automatically use the service account:

```typescript
import { Firestore } from '@google-cloud/firestore';

// No credentials needed - uses attached service account automatically
const firestore = new Firestore();

// Or with explicit project
const firestore = new Firestore({
  projectId: process.env.GOOGLE_CLOUD_PROJECT
});
```

## Authentication & Access Control

### Making a Service Public

```bash
gcloud run services add-iam-policy-binding SERVICE_NAME \
  --region=REGION \
  --member="allUsers" \
  --role="roles/run.invoker"
```

### Requiring Authentication

```bash
# Remove public access
gcloud run services remove-iam-policy-binding SERVICE_NAME \
  --region=REGION \
  --member="allUsers" \
  --role="roles/run.invoker"

# Grant access to specific service account
gcloud run services add-iam-policy-binding SERVICE_NAME \
  --region=REGION \
  --member="serviceAccount:caller@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/run.invoker"
```

### Service-to-Service Authentication

```typescript
import { GoogleAuth } from 'google-auth-library';

const auth = new GoogleAuth();

async function callAuthenticatedService(url: string) {
  const client = await auth.getIdTokenClient(url);
  const response = await client.request({ url });
  return response.data;
}
```

## Debugging HTTP Response Issues

### HTML Response Instead of Expected JSON/MCP

When Cloud Run returns HTML instead of JSON or MCP protocol responses:

#### 1. Check if Container is Starting Properly

```bash
# View recent logs
gcloud run services logs read SERVICE_NAME --region=REGION --limit=100

# Look for startup errors
gcloud run services logs read SERVICE_NAME --region=REGION --limit=100 | grep -i error
```

#### 2. Verify Service is Listening on Correct Port

```typescript
// CORRECT - Listen on Cloud Run's PORT
const port = parseInt(process.env.PORT || '8080');
app.listen(port, '0.0.0.0');

// WRONG - Hardcoded port or localhost binding
app.listen(3000, 'localhost'); // Will fail on Cloud Run
```

#### 3. Check Request Routing

Ensure your application handles the correct paths:

```typescript
// MCP server should handle /mcp endpoint
app.post('/mcp', handleMcpRequest);

// Also check for path variations
app.post('/mcp/', handleMcpRequest);
```

#### 4. Check for Middleware Issues

Express middleware can redirect or return HTML:

```typescript
// Check order of middleware
app.use(cors());
app.use(express.json());

// Ensure JSON parsing before route handlers
app.post('/mcp', (req, res) => {
  // If express.json() failed, req.body may be undefined
  console.log('Body:', JSON.stringify(req.body));
});
```

#### 5. Verify Content-Type Handling

```bash
# Test with explicit headers
curl -X POST \
  -H "Content-Type: application/json" \
  -H "Accept: application/json" \
  -d '{"jsonrpc":"2.0","method":"initialize","id":1}' \
  https://YOUR-SERVICE.run.app/mcp
```

#### 6. Check for Error Pages

Cloud Run returns HTML error pages for:
- Container not starting (500)
- Service not found (404)
- Authentication required but missing (403)
- Timeout exceeded (504)

```typescript
// Add error handling that returns JSON
app.use((err, req, res, next) => {
  console.error('Error:', err);
  res.status(500).json({
    error: err.message,
    stack: process.env.NODE_ENV === 'development' ? err.stack : undefined
  });
});
```

### Cold Start Issues

```bash
# Set minimum instances to avoid cold starts
gcloud run services update SERVICE_NAME \
  --min-instances=1 \
  --region=REGION
```

### Connection Timeouts to GCP Services

```typescript
// Check if services are accessible during startup
async function healthCheck() {
  try {
    // Test Firestore connection
    await firestore.collection('_health').limit(1).get();
    console.log('Firestore: OK');
  } catch (error) {
    console.error('Firestore connection failed:', error);
    throw error;
  }
}

// Call during startup
await healthCheck();
```

## Firestore Integration

### From Cloud Run Service

```typescript
import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

// Initialize Firebase Admin (uses Cloud Run service account automatically)
if (getApps().length === 0) {
  initializeApp();
}

export const db = getFirestore();

// Use in request handlers
app.get('/data/:id', async (req, res) => {
  try {
    const doc = await db.collection('data').doc(req.params.id).get();
    if (doc.exists) {
      res.json(doc.data());
    } else {
      res.status(404).json({ error: 'Not found' });
    }
  } catch (error) {
    console.error('Firestore error:', error);
    res.status(500).json({ error: 'Database error' });
  }
});
```

### Required IAM Roles for Firestore

```bash
# Minimal Firestore access
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA_EMAIL" \
  --role="roles/datastore.user"

# Full Firebase access
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA_EMAIL" \
  --role="roles/firebase.admin"
```

### Firestore Event Triggers (Eventarc)

```bash
gcloud eventarc triggers create TRIGGER_NAME \
  --location=REGION \
  --destination-run-service=SERVICE_NAME \
  --destination-run-region=REGION \
  --event-filters="type=google.cloud.firestore.document.v1.written" \
  --event-filters="database=(default)" \
  --event-filters-path-pattern="document=users/{userId}" \
  --service-account=PROJECT_NUMBER-compute@developer.gserviceaccount.com
```

## Effect-TS on Cloud Run

Effect-TS applications work on Cloud Run as standard Node.js applications:

```typescript
import { Effect, Config, Console } from 'effect';
import express from 'express';

// Type-safe configuration from Cloud Run environment
const AppConfig = Config.all({
  port: Config.integer('PORT').pipe(Config.withDefault(8080)),
  projectId: Config.string('GOOGLE_CLOUD_PROJECT'),
  serviceName: Config.string('K_SERVICE').pipe(Config.withDefault('local')),
});

const startServer = Effect.gen(function* () {
  const config = yield* AppConfig;

  const app = express();
  app.use(express.json());

  app.get('/health', (req, res) => {
    res.json({ status: 'healthy', service: config.serviceName });
  });

  yield* Effect.promise(() =>
    new Promise<void>((resolve) => {
      app.listen(config.port, '0.0.0.0', () => {
        resolve();
      });
    })
  );

  yield* Console.log(`Server started on port ${config.port}`);
});

Effect.runPromise(startServer).catch(console.error);
```

## Health Checks

```typescript
// Liveness probe - is the process running?
app.get('/healthz', (req, res) => {
  res.status(200).send('OK');
});

// Readiness probe - can we serve traffic?
app.get('/ready', async (req, res) => {
  try {
    // Check dependencies
    await db.collection('_health').limit(1).get();
    res.status(200).json({ status: 'ready' });
  } catch (error) {
    res.status(503).json({ status: 'not ready', error: error.message });
  }
});
```

## Logging

Cloud Run integrates with Cloud Logging. Use structured logs:

```typescript
// Structured log format for Cloud Logging
function log(severity: string, message: string, data?: object) {
  console.log(JSON.stringify({
    severity,
    message,
    ...data,
    timestamp: new Date().toISOString(),
    service: process.env.K_SERVICE,
    revision: process.env.K_REVISION,
  }));
}

log('INFO', 'Processing request', { userId: '123', action: 'update' });
log('ERROR', 'Request failed', { error: err.message, stack: err.stack });
```

## Common Errors

### "Container failed to start"

**Causes:**
- Application not listening on PORT
- Crash during startup
- Missing dependencies

**Fix:** Check logs and ensure proper port binding.

### "The request was aborted because there was no available instance"

**Causes:**
- All instances busy
- Concurrency limit reached
- Cold start timeout

**Fix:** Increase max-instances or concurrency.

### "Permission denied" accessing GCP services

**Causes:**
- Service account lacks IAM roles
- Wrong project

**Fix:** Grant appropriate roles to the Cloud Run service account.

## References

For extended documentation:
- `references/container-contract.md` - Full container runtime contract details
- `references/service-identity.md` - Service identity and authentication patterns
- `references/debugging-guide.md` - Extended debugging scenarios

For documentation not in references, key URLs:
- Container Contract: https://cloud.google.com/run/docs/container-contract
- Service Identity: https://cloud.google.com/run/docs/securing/service-identity
- HTTPS Requests: https://cloud.google.com/run/docs/triggering/https-request
- Firestore Integration: https://cloud.google.com/run/docs/using-gcp-services
