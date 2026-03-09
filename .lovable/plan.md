
## Plan: Add Production/Sandbox Environment Selector

### Overview
Add a toggle/select to switch between sandbox and production MTN API environments in the Settings page.

### Implementation

**1. Settings.tsx Changes**
- Add a Select dropdown with two options: "sandbox" and "production"
- Store selection in component state (default to current environment from health check)
- Pass selected environment to health check function
- Show warning banner when production is selected
- Display environment-specific info (sandbox = EUR test currency, production = ZMW real money)

**2. Edge Function Update (mtn-health-check)**
- Accept optional `environment` parameter in request body
- Use passed environment to determine which base URL and settings to use
- Return environment in response

**3. UI Layout**
```
Environment Mode
┌─────────────────────────────┐
│ [Sandbox ▼]                 │
│ ○ Sandbox - Test API        │
│ ○ Production - Live API     │
└─────────────────────────────┘
⚠️ Production mode uses real funds (when selected)
```

### Files to Modify
- `src/pages/Settings.tsx` - Add Select component and environment state
- `supabase/functions/mtn-health-check/index.ts` - Accept environment param
