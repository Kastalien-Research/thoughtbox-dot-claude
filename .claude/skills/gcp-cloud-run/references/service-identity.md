# Cloud Run Service Identity Reference

## Identity Types

Cloud Run uses two distinct identity types:

### 1. Deployer Identity

The identity of the person or service account that deploys the Cloud Run service.

**Required Roles for Deployment:**
- `roles/run.admin` - Deploy and manage Cloud Run services
- `roles/iam.serviceAccountUser` - Act as the runtime service account

```bash
# Grant deployer permissions
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:developer@example.com" \
  --role="roles/run.admin"

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:developer@example.com" \
  --role="roles/iam.serviceAccountUser"
```

### 2. Service (Runtime) Identity

The service account that the Cloud Run container runs as. This identity is used for:
- Authenticating to Google Cloud APIs
- Accessing GCP resources (Firestore, Cloud Storage, etc.)
- Service-to-service authentication

**Default:** Compute Engine default service account (`PROJECT_NUMBER-compute@developer.gserviceaccount.com`)

**Recommendation:** Use a dedicated service account per service.

## Configuring Service Identity

### Create Dedicated Service Account

```bash
# Create service account
gcloud iam service-accounts create thoughtbox-sa \
  --display-name="ThoughtBox Cloud Run Service"

# View the service account email
gcloud iam service-accounts list --filter="displayName:ThoughtBox"
```

### Grant Required Roles

```bash
PROJECT_ID=your-project-id
SA_EMAIL=thoughtbox-sa@${PROJECT_ID}.iam.gserviceaccount.com

# Firestore access
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/datastore.user"

# Cloud Storage access (if needed)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/storage.objectAdmin"

# Secret Manager access (if needed)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/secretmanager.secretAccessor"

# Full Firebase Admin (if needed)
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:$SA_EMAIL" \
  --role="roles/firebase.admin"
```

### Deploy with Service Account

```bash
gcloud run deploy SERVICE_NAME \
  --image IMAGE_URL \
  --service-account=$SA_EMAIL \
  --region=us-central1
```

## Using the Service Identity

### Automatic Authentication (ADC)

Google Cloud client libraries automatically use the attached service account:

```typescript
// Firebase Admin SDK - uses service account automatically
import { initializeApp, getApps } from 'firebase-admin/app';
import { getFirestore } from 'firebase-admin/firestore';

if (getApps().length === 0) {
  initializeApp();  // No credentials needed on Cloud Run
}

const db = getFirestore();
```

```typescript
// Google Cloud Firestore client - also automatic
import { Firestore } from '@google-cloud/firestore';

const firestore = new Firestore();  // Uses ADC automatically
```

### Generating Access Tokens

For calling Google APIs directly:

```typescript
import { GoogleAuth } from 'google-auth-library';

async function getAccessToken(): Promise<string> {
  const auth = new GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/cloud-platform']
  });
  const client = await auth.getClient();
  const token = await client.getAccessToken();
  return token.token!;
}

// Use in API calls
const response = await fetch('https://some-google-api.googleapis.com/v1/...', {
  headers: {
    'Authorization': `Bearer ${await getAccessToken()}`
  }
});
```

### Generating ID Tokens (Service-to-Service)

For calling other Cloud Run services that require authentication:

```typescript
import { GoogleAuth } from 'google-auth-library';

async function callAuthenticatedCloudRun(targetUrl: string, body: object) {
  const auth = new GoogleAuth();

  // Get client with ID token for the target audience
  const client = await auth.getIdTokenClient(targetUrl);

  const response = await client.request({
    url: targetUrl,
    method: 'POST',
    headers: {
      'Content-Type': 'application/json'
    },
    data: body
  });

  return response.data;
}

// Usage
const result = await callAuthenticatedCloudRun(
  'https://other-service-abc123-uc.a.run.app/api/action',
  { key: 'value' }
);
```

### Impersonating Another Service Account

```typescript
import { GoogleAuth } from 'google-auth-library';

async function impersonateServiceAccount(targetSA: string): Promise<string> {
  const auth = new GoogleAuth({
    scopes: ['https://www.googleapis.com/auth/cloud-platform']
  });

  const client = await auth.getClient();

  // Generate impersonated credentials
  const response = await fetch(
    `https://iamcredentials.googleapis.com/v1/projects/-/serviceAccounts/${targetSA}:generateAccessToken`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${(await client.getAccessToken()).token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        scope: ['https://www.googleapis.com/auth/cloud-platform'],
        lifetime: '3600s'
      })
    }
  );

  const data = await response.json();
  return data.accessToken;
}
```

## Common IAM Roles

| Role | Description | When to Use |
|------|-------------|-------------|
| `roles/datastore.user` | Read/write Firestore documents | Most Firestore operations |
| `roles/datastore.viewer` | Read-only Firestore access | Read-only services |
| `roles/firebase.admin` | Full Firebase access | Services needing Auth, Messaging, etc. |
| `roles/storage.objectAdmin` | Full Cloud Storage access | Upload/download files |
| `roles/storage.objectViewer` | Read Cloud Storage objects | Read-only file access |
| `roles/secretmanager.secretAccessor` | Access secrets | Reading API keys, credentials |
| `roles/run.invoker` | Invoke Cloud Run services | Service-to-service calls |
| `roles/pubsub.publisher` | Publish to Pub/Sub topics | Event publishing |
| `roles/pubsub.subscriber` | Subscribe to Pub/Sub | Event consumption |

## Troubleshooting

### "Permission denied" Errors

```bash
# Check what roles the service account has
gcloud projects get-iam-policy PROJECT_ID \
  --flatten="bindings[].members" \
  --filter="bindings.members:SA_EMAIL" \
  --format="table(bindings.role)"

# Check which service account Cloud Run is using
gcloud run services describe SERVICE_NAME \
  --format='value(spec.template.spec.serviceAccountName)' \
  --region=REGION
```

### "Could not load default credentials"

This usually means:
1. Running locally without ADC configured
2. Service account doesn't exist
3. IAM propagation delay (wait a few minutes after granting roles)

```bash
# For local development
gcloud auth application-default login

# Or use a service account key (not recommended for production)
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/key.json"
```

### IAM Policy Propagation

IAM changes can take up to 60 seconds to propagate. If you just granted a role, wait and retry.

```bash
# Force a new revision to pick up IAM changes
gcloud run services update SERVICE_NAME --region=REGION
```
