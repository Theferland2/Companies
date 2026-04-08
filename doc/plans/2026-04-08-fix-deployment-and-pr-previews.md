# Resolve CI/CD Deployment and Node.js Deprecation

The goal is to fix the `DeployContainerExitNonZero` error in DigitalOcean, resolve the "Node.js 20 actions are deprecated" warning, and implement PR Previews as described in the provided DigitalOcean documentation.

## User Review Required

> [!IMPORTANT]
> - **PR Previews**: I will be implementing two new workflows (`deploy-preview.yml` and `delete-preview.yml`) to enable ephemeral test deployments for each PR. This requires you to have enough capacity in your DigitalOcean account for temporary apps.
> - **Secret Sync**: I will update the secret synchronization logic to include `BETTER_AUTH_SECRET` if it is missing, as it is a common cause for startup crashes in `authenticated` mode.
> - **Node 20 to 24**: I will be forcing internal actions to run on Node 24 by setting `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24=true` and updating action versions.

## Proposed Changes

### [CI/CD Workflows]

#### [MODIFY] [do-deploy.yml](file:///c:/Users/Natan/.gemini/antigravity/scratch/Companies/.github/workflows/do-deploy.yml)
- Set `FORCE_JAVASCRIPT_ACTIONS_TO_NODE24: true` at the job level.
- Update `actions/checkout`, `actions/setup-node`, and `pnpm/action-setup` to ensure they are consistent with Node 24.
- Improve the secret injection script to be more robust and log when required secrets are missing.

#### [NEW] [deploy-preview.yml](file:///c:/Users/Natan/.gemini/antigravity/scratch/Companies/.github/workflows/deploy-preview.yml)
- Implement PR Preview deployment using the `digitalocean/app_action/deploy@v2` action with `deploy_pr_preview: "true"`.
- This will allow testing changes in an isolated environment before merging.

#### [NEW] [delete-preview.yml](file:///c:/Users/Natan/.gemini/antigravity/scratch/Companies/.github/workflows/delete-preview.yml)
- Implement cleanup logic to delete the preview app when its PR is closed or merged.

#### [MODIFY] [pr.yml](file:///c:/Users/Natan/.gemini/antigravity/scratch/Companies/.github/workflows/pr.yml)
- Update to Node 24 and set the Node 24 force flag.

### [Container & Server]

#### [MODIFY] [Dockerfile](file:///c:/Users/Natan/.gemini/antigravity/scratch/Companies/Dockerfile)
- Correct the `CMD` to use the standard entrypoint without unnecessary TSX loading if the server is already compiled.
- Move `pnpm install --global` steps where they won't fail build caching if possible.

#### [MODIFY] [docker-entrypoint.sh](file:///c:/Users/Natan/.gemini/antigravity/scratch/Companies/scripts/docker-entrypoint.sh)
- Ensure the script has proper error handling and logging if it fails to remap UID/GID, which might cause the `DeployContainerExitNonZero` error.

---

## Open Questions

> [!CAUTION]
> 1. **Secret Validation**: Does your DigitalOcean App have `BETTER_AUTH_SECRET` set? The `server` crashes if it is missing in `authenticated` mode. I noticed it is currently *not* being synced from GitHub.
> 2. **DigitalOcean Capacity**: Are you okay with DigitalOcean creating temporary apps for PR Previews? (These incur costs if they stay up, though they are tiny and deleted automatically).

## Verification Plan

### Automated Tests
- `pnpm -r typecheck` (already verified locally, will be run in CI).
- `pnpm build` (to ensure the container build step is solid).

### Manual Verification
1. Push a change to `main` and monitor the `do-deploy.yml` run for Node 24 warnings and deployment success.
2. Open a test Pull Request to verify that `deploy-preview.yml` creates a preview app in DigitalOcean.
3. Close the test PR to verify `delete-preview.yml` removes the ephemeral app.
