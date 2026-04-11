
Goal: make transaction error messages under Batches fully readable without breaking the table layout.

Plan

1. Update the Batch Detail table error cell
- Replace the current `max-w-[200px] truncate` rendering in `src/pages/BatchDetail.tsx`.
- Keep a compact preview inside the table so rows stay aligned.
- Add a clear “View error” interaction for long messages.

2. Add a full error viewer
- Use the existing dialog component pattern already present in the project.
- When a transaction has an error, open a modal showing the complete message in a scrollable, wrapped block (`whitespace-pre-wrap` / break-long-words style).
- Preserve the raw backend error text exactly, including JSON fragments and line breaks where possible.

3. Improve usability for short vs long errors
- Short errors can remain directly readable in-cell.
- Long errors should show:
  - a short preview in the table
  - full content in the dialog
  - optional tooltip/title fallback for quick hover viewing

4. Match existing app conventions
- Reuse existing UI components from `src/components/ui/dialog.tsx`, `button.tsx`, and table styling already used in `BatchDetail.tsx`.
- Keep the change localized to Batch Detail so it does not affect approval, refund, or timeline logic.

5. Optional consistency pass
- Apply the same full-message treatment to other truncated error surfaces found during review:
  - `src/components/TransactionTimeline.tsx`
  - `src/pages/Settings.tsx` health check error text
- This is optional but recommended so users get consistent error visibility across the app.

Technical details
- Current truncation point:
  - `src/pages/BatchDetail.tsx:362`
  - current class: `text-xs text-destructive max-w-[200px] truncate`
- Recommended implementation:
  - add component state like `selectedError: string | null`
  - render compact preview with line clamp or truncated single line
  - add a small button/link such as “View”
  - show full error inside `<Dialog>` with responsive max width and scroll area
- Benefit:
  - users can inspect full MTN/API failure details like `Transfer failed: 403 { ... }`
  - table remains readable on smaller screens

What I will change once you approve
- Edit `src/pages/BatchDetail.tsx`
- Possibly make the same visibility improvement in `src/components/TransactionTimeline.tsx` and `src/pages/Settings.tsx` for consistency
