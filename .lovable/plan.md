

## Plan: Add Sandbox/Production Environment Toggle

### What Changes

**Edge function** (`supabase/functions/process-disbursements/index.ts`):

1. **Read `MTN_ENVIRONMENT` secret** — defaults to `"sandbox"` if not set
2. **Dynamic base URL** — sandbox uses `sandbox.momodeveloper.mtn.com`, production uses `momodeveloper.mtn.com`
3. **Conditional API user provisioning** — sandbox auto-provisions API user/key on each call; production reads `MTN_API_USER` and `MTN_API_KEY` from secrets (provided by MTN during onboarding)
4. **Currency** — `EUR` for sandbox, `ZMW` for production
5. **Target environment** — `sandbox` or country identifier (e.g., `zambia`)
6. **Callback host** — configurable via `MTN_CALLBACK_URL` secret for production

### New Secrets Needed (production only)

| Secret | Purpose |
|--------|---------|
| `MTN_ENVIRONMENT` | `"sandbox"` or `"production"` — controls which mode runs |
| `MTN_API_USER` | Production API user (from MTN onboarding) |
| `MTN_API_KEY` | Production API key (from MTN onboarding) |
| `MTN_CALLBACK_URL` | Production callback URL |
| `MTN_TARGET_ENVIRONMENT` | Country code, e.g. `zambia` |

No secrets will be requested now — the function will default to sandbox when these aren't set, so it stays backward-compatible.

### Technical Details

```text
MTN_ENVIRONMENT secret
  ├── "sandbox" (default)
  │     ├── Base URL: sandbox.momodeveloper.mtn.com
  │     ├── Auto-provision API user/key
  │     ├── Currency: EUR
  │     └── Target: sandbox
  └── "production"
        ├── Base URL: momodeveloper.mtn.com
        ├── Read MTN_API_USER + MTN_API_KEY from secrets
        ├── Currency: ZMW
        └── Target: from MTN_TARGET_ENVIRONMENT secret
```

The function will be redeployed after changes.

