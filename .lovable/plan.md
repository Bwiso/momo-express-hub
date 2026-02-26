

## Plan: Enforce Dual-Authorization Workflow

**Current problem:** The `BulkUpload.tsx` page auto-approves the batch and triggers disbursements immediately after upload (lines 158-174). This bypasses the approver role entirely.

**Goal:** Initiator uploads CSV → batch stays `pending` → Approver reviews and approves → only then are disbursements triggered.

### Changes

**1. `src/pages/BulkUpload.tsx`** — Remove auto-approve and auto-disburse logic
- Remove lines 156-174 (the auto-approve `update` call and `functions.invoke` call)
- Replace with a success toast telling the user the batch is pending approval: `"Batch created successfully — awaiting approver authorization"`
- The batch stays in `pending` status after upload

**2. `src/pages/Batches.tsx`** — Already correct
- The approve button already triggers `process-disbursements` when an approver clicks the green checkmark
- Dual-authorization check already exists (approver cannot be the same as initiator)
- No changes needed here

### Summary
This is a single-file change: remove the 18 lines of auto-disbursement code from `BulkUpload.tsx` and update the toast message. The existing approval flow in `Batches.tsx` already handles everything correctly.

