# Version Tracking System

This app includes build version tracking to help verify deployments.

## Components

### 1. Build-time Version Generation
**Script**: `scripts/generate_version.sh`

Generates `web/version.json` with:
- App version (from pubspec.yaml)
- Git commit hash (full and short)
- Git branch
- Build timestamp
- Build environment

**Usage**:
```bash
./scripts/generate_version.sh
```

This should be run **before** `flutter build web` in your CI/CD pipeline.

### 2. Version API Endpoint
**URL**: `https://dexguide.gg/api/version`

Returns JSON with build metadata including Cloudflare Pages environment variables.

**Example**:
```bash
curl https://dexguide.gg/api/version
```

**Response**:
```json
{
  "version": "1.0.0+1",
  "gitCommit": "e0ee510...",
  "gitCommitShort": "e0ee510",
  "gitBranch": "main",
  "buildTime": "2026-02-07T18:03:19Z",
  "buildEnvironment": "production",
  "cfCommitSha": "e0ee510...",
  "cfBranch": "main",
  "cfUrl": "https://dexguide.gg",
  "environment": "production",
  "deployedAt": "2026-02-07T18:03:19Z"
}
```

### 3. In-App Version Display
Version info is displayed at the bottom of the About screen (`/about`).

Shows:
- Version number
- Git commit hash (short)
- Build date

## Cloudflare Pages Build Command

Update your Cloudflare Pages build command to:

```bash
cd pokemondb && ./scripts/generate_version.sh && flutter build web --release
```

Or add it to your build script.

## Quick Deployment Verification

```bash
# Check deployed version
curl -s https://dexguide.gg/api/version | jq -r '.gitCommitShort'

# Compare with local
git rev-parse --short HEAD
```

If they match, deployment is up to date! ✓
