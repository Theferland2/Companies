# DigitalOcean Deployment Debugging Guide

## Current Issue

**Status**: GitHub Actions workflow completes successfully, but DigitalOcean deployment fails during container startup.

**Error**: `DeployContainerExitNonZero` - Container exits with non-zero exit code during deployment phase.

**Workflow Status**: ✅ All steps pass (typecheck, build, test, secret sync)

**DigitalOcean Behavior**: Auto-rollback to previous deployment after failure

## Recent History

- Active Deployment: `d2d1c653-a1fa-45ef-aae6-fb7db1b5ee74` (automated rollback from 2026-04-07)
- Last 4 deployments with "app spec updated" all failed with `DeployContainerExitNonZero`
- App is currently running fine on the rollback deployment

## Environment Variables

### In GitHub Secrets (6 total):
- `DATABASE_URL` ← Synced to DO
- `GEMINI_API_KEY` ← Synced to DO
- `OPENROUTER_API_KEY` ← Synced to DO
- `DIGITALOCEAN_ACCESS_TOKEN` (workflow only)
- `DO_APP_ID` (workflow only)
- `DO_APP_NAME` (workflow only)

### In DigitalOcean App (17 total):

**Synced from GitHub:**
1. `DATABASE_URL`
2. `GEMINI_API_KEY`
3. `OPENROUTER_API_KEY`

**Managed in DO only:**
4. `NODE_ENV` = "production"
5. `PORT` = "3100"
6. `SERVE_UI` = "true"
7. `PAPERCLIP_DEPLOYMENT_MODE` = "authenticated"
8. `PAPERCLIP_AUTH_PUBLIC_BASE_URL` = "https://companies-app-e73lt.ondigitalocean.app/"
9. `PAPERCLIP_AUTH_MODE` = "explicit"
10. `PAPERCLIP_AGENT_JWT_SECRET`
11. `RELAYER_API_KEY`
12. `RELAYER_API_KEY_ADDRESS`
13. `POLYMARKET_API_SECRET`
14. `POLYMARKET_API_ADDRESS`
15. `PAPERCLIP_ALLOWED_HOSTNAMES`
16. `BETTER_AUTH_URL`
17. `DIGITALOCEAN_ACCESS_TOKEN`

## Workflow Sync Logic

The `do-deploy.yml` workflow:
1. Downloads current app spec with `doctl apps spec get`
2. Only updates the 3 GitHub-managed secrets using `yq`
3. Preserves all other DO-managed variables
4. Applies updated spec with `doctl apps update`

## Next Steps to Debug

### 1. Check deployment logs after next failure

The workflow now includes a failure handler that will capture:
- Deployment progress details
- Deploy-time logs
- Runtime logs (if available)

### 2. Manual log inspection

If needed, manually check logs:

```bash
# Get app ID
APP_ID="e98c9441-89d0-48ef-8f76-cae5b5d6ac83"

# Get latest deployment
doctl apps list-deployments $APP_ID --format ID,Phase,Cause

# Get deployment details
doctl apps get-deployment $APP_ID <DEPLOYMENT_ID>

# Get logs
doctl apps logs $APP_ID --type run --follow false --tail 200
```

### 3. Test locally with DO environment

To reproduce the exact DO environment locally:

```bash
# Use the same env vars as DO
export DATABASE_URL="<from-gh-secret>"
export NODE_ENV="production"
export PORT="3100"
export SERVE_UI="true"
export PAPERCLIP_DEPLOYMENT_MODE="authenticated"
# ... etc

# Build and run the exact Dockerfile
docker build -t companies-test .
docker run -p 3100:3100 --env-file .env.do companies-test
```

### 4. Check for recent code changes

Compare current master with the last successful deployment commit:

```bash
git log --oneline --since="2026-04-07"
```

Look for changes in:
- `server/src/index.ts` (startup logic)
- `server/src/config.ts` (env var validation)
- `Dockerfile` (container setup)
- `scripts/docker-entrypoint.sh` (entrypoint logic)

## Possible Root Causes

1. **Database connection failure** - `DATABASE_URL` might be malformed or unreachable
2. **Missing required env var** - New code might require an env var not set in DO
3. **Build artifact issue** - Something in the build is broken that only manifests at runtime
4. **Health check timeout** - Container starts but doesn't respond in time (no health check configured currently)
5. **Port binding issue** - Container can't bind to port 3100
6. **Permission issue** - User/group ID mismatch in the entrypoint script

## Resolution Workflow

1. ✅ Added deployment failure log capture to workflow
2. ⏳ Wait for next deployment attempt to capture logs
3. ⏳ Analyze startup error from captured logs
4. ⏳ Fix root cause
5. ⏳ Verify deployment succeeds

## References

- Workflow: `.github/workflows/do-deploy.yml`
- App Spec: Managed in DigitalOcean (not `.do/app.yaml` which is outdated)
- Dockerfile: `Dockerfile`
- Entrypoint: `scripts/docker-entrypoint.sh`
