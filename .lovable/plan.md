
## Plan: Transaction Timeline + Admin MTN Settings

### Feature 1: Transaction Timeline in Batch Detail

**Goal**: Show a visual timeline of events (transfer, retry, refund) for each transaction using audit_logs.

**Approach**:
1. Query `audit_logs` filtered by batch_id or transaction_id stored in `details` JSONB column
2. Add a collapsible timeline section below each transaction row (or as a modal/drawer)
3. Display events chronologically with icons: transfer initiated → processing → completed/failed → retry → refund

**UI Design**:
- Add "View History" button per transaction row
- Open a Sheet/Dialog showing vertical timeline with:
  - Event type icon (Send, RefreshCw, Undo2, XCircle)
  - Timestamp
  - User who performed action
  - Status/result

**Data**: Filter audit_logs where `details->>'transactionId' = tx.id` or `details->>'batchId' = batchId`

---

### Feature 2: Admin Settings Screen for MTN Configuration

**Goal**: Super admins can view/update MTN environment settings and run a live health check.

**Approach**:
1. Create new page `src/pages/Settings.tsx` (super_admin only)
2. Add route `/settings` and sidebar nav item
3. Display current MTN config (read-only display of environment type)
4. Create new edge function `mtn-health-check` that:
   - Calls `/disbursement/token/` to verify credentials
   - Calls `/v1_0/account/balance` to confirm API access
   - Returns latency metrics and status
5. "Run Health Check" button triggers the function and shows results
6. Show configured secrets status (present/missing) without exposing values

**Settings UI**:
```
┌─────────────────────────────────────────┐
│ MTN MoMo Configuration                  │
├─────────────────────────────────────────┤
│ Environment: sandbox / production       │
│ Primary Key: ●●●●●●●● (configured)      │
│ API User: (sandbox=auto, prod=required) │
│                                         │
│ [Run Health Check]                      │
│                                         │
│ ✓ Token generation: 142ms               │
│ ✓ Balance API: 89ms                     │
│ ✓ Ready for disbursements               │
└─────────────────────────────────────────┘
```

---

### Implementation Tasks

1. **BatchDetail.tsx**: Add timeline query + collapsible UI per transaction
2. **Settings.tsx**: New page with MTN config display + health check button
3. **mtn-health-check edge function**: Token + balance check with latency
4. **App.tsx**: Add `/settings` route
5. **AppSidebar.tsx**: Add Settings nav item for super_admin

---

### Technical Details

**Timeline query**:
```typescript
const { data: timeline } = useQuery({
  queryKey: ["tx-timeline", txId],
  queryFn: async () => {
    const { data } = await supabase
      .from("audit_logs")
      .select("*")
      .or(`details->transactionId.eq.${txId},details->batchId.eq.${batchId}`)
      .order("created_at", { ascending: true });
    return data;
  }
});
```

**Health check response**:
```json
{
  "success": true,
  "tokenLatency": 142,
  "balanceLatency": 89,
  "balance": { "availableBalance": 50000, "currency": "EUR" },
  "environment": "sandbox"
}
```
