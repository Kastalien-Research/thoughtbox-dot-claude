# Firebase Admin SDK Setup Reference

## Installation

```bash
npm install firebase-admin
```

## Initialization Patterns

### Cloud Run / GCP Environments

On Google Cloud environments (Cloud Run, Cloud Functions, Compute Engine, GKE), the SDK automatically uses Application Default Credentials:

```typescript
import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

if (getApps().length === 0) {
  initializeApp();
}

export const db = getFirestore();
```

**How ADC works:**
1. Checks `GOOGLE_APPLICATION_CREDENTIALS` env var for service account key path
2. Uses attached service account (Cloud Run, Functions, Compute Engine)
3. Uses gcloud CLI credentials (local development with `gcloud auth application-default login`)

### Explicit Project ID

When project ID cannot be auto-detected:

```typescript
import { initializeApp, getApps } from 'firebase-admin/app';

if (getApps().length === 0) {
  initializeApp({
    projectId: process.env.GOOGLE_CLOUD_PROJECT || 'my-project-id'
  });
}
```

### Service Account Key (Local Development)

For local development with a downloaded service account key:

```typescript
import { initializeApp, cert, getApps } from 'firebase-admin/app';

const serviceAccount = require('./path/to/serviceAccountKey.json');

if (getApps().length === 0) {
  initializeApp({
    credential: cert(serviceAccount)
  });
}
```

**Or using environment variable:**
```typescript
// GOOGLE_APPLICATION_CREDENTIALS=./path/to/serviceAccountKey.json
import { initializeApp, getApps } from 'firebase-admin/app';

if (getApps().length === 0) {
  initializeApp();  // Will use GOOGLE_APPLICATION_CREDENTIALS
}
```

### Emulator Configuration

For local Firestore emulator:

```typescript
import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

if (getApps().length === 0) {
  initializeApp({
    projectId: 'demo-project'  // 'demo-' prefix bypasses credentials
  });
}

const db = getFirestore();

// Set emulator host (alternatively via env var FIRESTORE_EMULATOR_HOST)
db.settings({
  host: 'localhost:8080',
  ssl: false
});
```

**Environment variable method:**
```bash
export FIRESTORE_EMULATOR_HOST="localhost:8080"
export GCLOUD_PROJECT="demo-project"
```

### Multi-Environment Pattern

```typescript
import { initializeApp, cert, getApps, App } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

function initializeFirebase(): App {
  if (getApps().length > 0) {
    return getApps()[0];
  }

  const isEmulator = !!process.env.FIRESTORE_EMULATOR_HOST;
  const isCloudRun = !!process.env.K_SERVICE;
  const hasServiceAccount = !!process.env.GOOGLE_APPLICATION_CREDENTIALS;

  if (isEmulator) {
    console.log('[Firebase] Using emulator');
    return initializeApp({
      projectId: process.env.GCLOUD_PROJECT || 'demo-project'
    });
  }

  if (isCloudRun) {
    console.log('[Firebase] Using Cloud Run ADC');
    return initializeApp();
  }

  if (hasServiceAccount) {
    console.log('[Firebase] Using service account key');
    return initializeApp({
      credential: cert(process.env.GOOGLE_APPLICATION_CREDENTIALS!)
    });
  }

  console.log('[Firebase] Using default credentials (gcloud auth)');
  return initializeApp({
    projectId: process.env.GCLOUD_PROJECT
  });
}

const app = initializeFirebase();
export const db = getFirestore(app);
```

## Available Services

After initialization, access Firebase services:

```typescript
import { getFirestore } from 'firebase-admin/firestore';
import { getAuth } from 'firebase-admin/auth';
import { getStorage } from 'firebase-admin/storage';
import { getMessaging } from 'firebase-admin/messaging';

const db = getFirestore();
const auth = getAuth();
const storage = getStorage();
const messaging = getMessaging();
```

## Firestore Settings

Configure Firestore behavior:

```typescript
const db = getFirestore();

db.settings({
  // Ignore undefined values in document data
  ignoreUndefinedProperties: true,

  // Use timestamps instead of Date objects
  timestampsInSnapshots: true,

  // Custom host (for emulator)
  host: 'localhost:8080',
  ssl: false
});
```

## IAM Roles for Cloud Run

The Cloud Run service account needs these roles for full Firebase access:

### Minimal Firestore Access
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SERVICE_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/datastore.user"
```

### Full Firebase Admin Access
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SERVICE_ACCOUNT@PROJECT_ID.iam.gserviceaccount.com" \
  --role="roles/firebase.admin"
```

### Specific Roles

| Role | Description |
|------|-------------|
| `roles/datastore.user` | Read/write Firestore documents |
| `roles/datastore.viewer` | Read-only Firestore access |
| `roles/firebase.admin` | Full Firebase access |
| `roles/firebase.viewer` | Read-only Firebase access |
| `roles/storage.objectAdmin` | Full Cloud Storage access |
| `roles/storage.objectViewer` | Read Cloud Storage objects |

## Common Errors

### "The default Firebase app does not exist"

**Cause:** Accessing a Firebase service before `initializeApp()`.

**Fix:** Ensure initialization happens first:
```typescript
// firebase.ts
import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

if (getApps().length === 0) {
  initializeApp();
}
export const db = getFirestore();

// Usage in other files
import { db } from './firebase.js';  // Import triggers initialization
```

### "Firebase app named '[DEFAULT]' already exists"

**Cause:** `initializeApp()` called multiple times.

**Fix:** Always check before initializing:
```typescript
if (getApps().length === 0) {
  initializeApp();
}
```

### "Could not load the default credentials"

**Cause:** No credentials available for Firebase to use.

**Fixes:**
1. On Cloud Run: Ensure service account has proper IAM roles
2. Locally: Run `gcloud auth application-default login`
3. Locally: Set `GOOGLE_APPLICATION_CREDENTIALS` to service account key path

### "Permission denied" or "PERMISSION_DENIED"

**Cause:** Service account lacks required IAM permissions.

**Fix:** Grant appropriate role to service account:
```bash
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="serviceAccount:SA_EMAIL" \
  --role="roles/datastore.user"
```

## TypeScript Module Considerations

For ESM projects (type: "module" in package.json):

```typescript
// Use .js extension in imports
import { db } from './firebase.js';

// For JSON imports (service account key), enable in tsconfig:
// "resolveJsonModule": true
import serviceAccount from './serviceAccountKey.json' assert { type: 'json' };
```

For CommonJS:
```typescript
// Can use without extension
const { db } = require('./firebase');

// JSON import works directly
const serviceAccount = require('./serviceAccountKey.json');
```
