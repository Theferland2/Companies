#!/usr/bin/env pwsh
# Helper script to set Supabase access token from .env.local
# Usage: . ./scripts/load-supabase-env.ps1

if (Test-Path .env.local) {
    Get-Content .env.local | ForEach-Object {
        if ($_ -match '^SUPABASE_ACCESS_TOKEN=(.+)$') {
            $token = $matches[1]
            if ($token -ne 'your_supabase_token_here' -and $token -ne '') {
                $env:SUPABASE_ACCESS_TOKEN = $token
                Write-Host "✓ SUPABASE_ACCESS_TOKEN loaded from .env.local" -ForegroundColor Green
            } else {
                Write-Host "⚠ SUPABASE_ACCESS_TOKEN not configured in .env.local" -ForegroundColor Yellow
                Write-Host "  Please update .env.local with your token from:" -ForegroundColor Yellow
                Write-Host "  https://supabase.com/dashboard/account/tokens" -ForegroundColor Yellow
            }
        }
        if ($_ -match '^SUPABASE_PROJECT_REF=(.+)$') {
            $env:SUPABASE_PROJECT_REF = $matches[1]
            Write-Host "✓ SUPABASE_PROJECT_REF loaded: $($matches[1])" -ForegroundColor Green
        }
    }
} else {
    Write-Host "⚠ .env.local not found. Copy from .env.example and configure." -ForegroundColor Yellow
}

# Verify Supabase CLI is configured
if ($env:SUPABASE_ACCESS_TOKEN) {
    Write-Host "`nVerifying Supabase connection..." -ForegroundColor Cyan
    supabase projects list 2>&1 | Select-Object -First 5
}
