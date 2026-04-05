# GitHub Actions Prevention Guide

**Last Updated**: 2026-04-05  
**Version**: 1.0

## Overview

This document outlines the root causes of 9 GitHub Actions workflow failures and the fixes applied to prevent recurrence.

---

## Failure History

### Total Failures Analyzed: 9

| Date | Workflow | Status | Issue |
|------|----------|--------|-------|
| 2026-04-05 21:26 | release.yml | YAML PARSE ERROR | Indentation |
| 2026-04-05 21:26 | do-deploy | yq lexer error | Complex condition |
| 2026-04-05 21:02 | publish_canary | ENEEDAUTH | Fork publish attempt |
| 2026-04-05 21:02 | do-deploy | yq lexer error | Complex condition |
| 2026-04-05 20:24 | do-deploy | yq lexer error | Complex condition |
| 2026-04-05 20:24 | Release | YAML issue | Unknown |
| 2026-04-05 19:36 | Release | YAML issue | Unknown |
| 2026-04-05 19:36 | do-deploy | yq lexer error | Complex condition |
| 2026-04-05 18:03 | Release | YAML issue | Unknown |

---

## Root Causes & Fixes

### 1. YAML Indentation Errors

**Problem**: Lines in `release.yml` had inconsistent indentation
- Line 104: `if:` had 9 spaces (should be 8)
- Line 105: `env:` had 8 spaces
- Result: YAML parser couldn't recognize structure

**Location**: `.github/workflows/release.yml`

**Fix Applied**:
```yaml
# BEFORE (broken - 9 spaces):
       - name: Publish canary
          if: github.repository == 'paperclip-ai/Companies'
         env:

# AFTER (fixed - 8 spaces):
       - name: Publish canary
        if: github.repository == 'paperclip-ai/Companies'
         env:
```

**Commit**: `951ad809`

**Prevention**:
- Review YAML indentation in PRs
- Use consistent 2-space indentation
- Test locally: `gh workflow view .github/workflows/release.yml`

---

### 2. Complex YQ Expression Failures

**Problem**: Complex nested conditions in `yq eval` caused parsing errors

**Command**:
```bash
yq eval '.services[] |= (if .envs != null then .envs |= map(if .key == "DATABASE_URL"...'
```

**Error**:
```
Error: 1:17: lexer: invalid input text "if .envs != null..."
```

**Root Cause**:
- Nested update operators (`|=`) with conditions
- Array iteration incompatible with the syntax
- yq version compatibility issues

**Fix Applied**: Replaced with Python script

**Location**: `.github/workflows/do-deploy.yml`

```python
import os
import yaml

with open('app-spec.yaml', 'r') as f:
    spec = yaml.safe_load(f)

if 'services' in spec:
    for service in spec['services']:
        if 'envs' in service:
            for env in service['envs']:
                if env.get('key') == 'DATABASE_URL':
                    env['value'] = os.environ.get('DATABASE_URL_SECRET', '')
                    env['type'] = 'SECRET'
                    env['scope'] = 'RUN_AND_BUILD_TIME'

with open('app-spec.yaml', 'w') as f:
    yaml.dump(spec, f)
```

**Commit**: `4e479988`

**Prevention**:
- Avoid complex nested yq expressions
- Use Python/Node for complex YAML manipulation
- Test YAML changes locally before pushing
- Keep expressions simple and single-level when possible

---

### 3. NPM Publishing from Forks

**Problem**: Fork attempted to publish to npm without credentials

**Error**:
```
npm error code ENEEDAUTH
need auth This command requires you to be logged in
```

**Root Cause**:
- `publish_canary` job didn't check repository
- Fork doesn't have `NPM_TOKEN` secret
- Attempted to authenticate with no credentials

**Fix Applied**: Added repository guard

**Location**: `.github/workflows/release.yml`

```yaml
- name: Publish canary
  if: github.repository == 'paperclip-ai/Companies'  # ← GUARD
  env:
    GITHUB_ACTIONS: "true"
  run: ./scripts/release.sh canary --skip-verify
```

**Commit**: `ebc09e85`

**Prevention**:
- All publish/deploy jobs must check: `if: github.repository == 'OFFICIAL_REPO'`
- Document required secrets in README
- Test in fork mode before merging
- Never hardcode credentials or assume fork environment has secrets

---

## Prevention Checklist

### Before Modifying Workflows

- [ ] YAML syntax is valid (no indentation errors)
- [ ] All nested structures use consistent indentation
- [ ] Complex transformations use Python/Node, not yq
- [ ] Publish/deploy jobs have repository guards
- [ ] No credentials are hardcoded
- [ ] All required GitHub Secrets are documented

### During Review

- [ ] Check indentation matches surrounding code
- [ ] Verify `if` conditions on sensitive jobs
- [ ] Ensure no hardcoded API keys or tokens
- [ ] Test locally if possible

### After Merge

- [ ] Monitor first workflow run
- [ ] Check for YAML parsing errors
- [ ] Verify all steps execute correctly
- [ ] Document any configuration requirements

---

## GitHub Secrets Required

For this repository to deploy successfully:

### DigitalOcean Deployment
- `DIGITALOCEAN_ACCESS_TOKEN` - DO API token
- `DO_APP_NAME` - Name of DigitalOcean app
- `DATABASE_URL` - PostgreSQL connection string

### NPM Publishing (Official Repo Only)
- NPM Trusted Publishing via OIDC (no token needed in fork)

---

## Workflow Validation

To validate workflows before pushing:

```bash
# Check syntax
gh workflow view .github/workflows/release.yml

# List all workflows
gh workflow list

# View run history
gh run list --repo ferangarita01/Companies
```

---

## Quick Reference

| Issue | Solution |
|-------|----------|
| YAML parsing error | Check indentation (8 spaces per level) |
| yq fails | Use Python script instead |
| NPM auth fails | Add `if: github.repository == 'official/repo'` |
| Secret not found | Add to GitHub Secrets settings |
| Build fails | Check dependencies (pnpm/Node versions) |

---

## Related Documents

- `.github/workflows/release.yml` - Release automation
- `.github/workflows/do-deploy.yml` - DigitalOcean deployment
- `doc/SPEC-implementation.md` - Build requirements

---

## Contact

For workflow issues or questions:
1. Check this guide
2. Review recent commits to workflows
3. Check GitHub Actions run logs: https://github.com/ferangarita01/Companies/actions
