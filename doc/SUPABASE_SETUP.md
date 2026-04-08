# Supabase Configuration Guide

## Security First

**NEVER commit Supabase credentials to git.** This repo is public.

## Important: Two Different Credentials

This project uses Supabase in two different contexts:

1. **`SUPABASE_ACCESS_TOKEN`** - For CLI operations (local development only)
   - Used for: `supabase link`, `supabase db push`, `supabase gen types`
   - Configured in: `.env.local` (local machine only)
   - NOT used in deployment

2. **`DATABASE_URL`** - For database connection (production deployment)
   - Used for: Application runtime database connection
   - Configured in: GitHub Secrets → DigitalOcean App Platform
   - Format: `postgres://postgres.[REF]:[PASSWORD]@...pooler.supabase.com:6543/postgres`

## Setup Steps

### 1. Revoke Exposed Token (If Applicable)

If you previously exposed a token, revoke it immediately:
1. Go to https://supabase.com/dashboard/account/tokens
2. Find the token and click "Revoke"

### 2. Create New Access Token

1. Visit https://supabase.com/dashboard/account/tokens
2. Click "Generate new token"
3. Give it a name: `paperclip-companies-cli`
4. Copy the token (starts with `sbp_`)

### 3. Configure Local Environment

1. Copy the environment file:
   ```bash
   cp .env.example .env.local
   ```

2. Edit `.env.local` and add your **CLI token** (not the database URL):
   ```bash
   SUPABASE_ACCESS_TOKEN=sbp_your_actual_token_here
   SUPABASE_PROJECT_REF=nxixwsexfuxpelsthmwd
   ```

3. The `.env.local` file is automatically ignored by git (see `.gitignore`)

**Note:** The `DATABASE_URL` is configured separately as a GitHub Secret for deployment. 
For local dev, leave `DATABASE_URL` empty to use embedded PGlite.

### 4. Load Credentials

#### Option A: PowerShell Script (Recommended)
```powershell
. .\scripts\load-supabase-env.ps1
```

#### Option B: Manual Environment Variable
```powershell
$env:SUPABASE_ACCESS_TOKEN = "sbp_your_actual_token_here"
```

#### Option C: System Environment Variable (Persistent)
```powershell
[System.Environment]::SetEnvironmentVariable('SUPABASE_ACCESS_TOKEN', 'sbp_your_token', 'User')
```

### 5. Verify Configuration

```bash
supabase projects list
```

You should see:
- **Companies** project (ref: `nxixwsexfuxpelsthmwd`)

## Working with Supabase

### Link to Project
```bash
supabase link --project-ref nxixwsexfuxpelsthmwd
```

### Generate TypeScript Types
```bash
supabase gen types typescript --linked > packages/db/src/supabase-types.ts
```

### Push Migrations (When Ready)
```bash
supabase db push
```

## Troubleshooting

### "Access token not provided"
- Ensure `SUPABASE_ACCESS_TOKEN` is set in your current shell session
- Run: `. .\scripts\load-supabase-env.ps1`
- This token is for CLI operations only

### "Cannot find project ref"
- Make sure you've run: `supabase link --project-ref nxixwsexfuxpelsthmwd`

### Wrong Account/Projects Listed
- You may be authenticated with a different Supabase account
- Revoke old token and create a new one from the correct account

### Database Connection Issues in Deployment
- This is NOT related to `SUPABASE_ACCESS_TOKEN`
- Check that `DATABASE_URL` GitHub Secret is configured correctly
- See `DO_DATABASE_FIX.md` for deployment database configuration
