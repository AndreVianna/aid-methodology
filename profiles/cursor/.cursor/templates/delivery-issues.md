# Delivery Issue Log — delivery-NNN

> **Source:** `aid-execute` delivery-gate step (step 0 AGGREGATE) — written once when every task
> in the delivery reaches `Done`. Single-writer, no parallel-write race.
> **Work:** {work-NNN-name}
> **Delivery:** delivery-NNN
> **Created:** {YYYY-MM-DDTHH:MM:SSZ}
> **Status:** Open | Resolved | Accepted

This file aggregates all `[HIGH]` findings that were deferred from per-task quick-checks (written
to `work-NNN/STATE.md ## Quick Check Findings`). It is the input to the delivery gate reviewer
(step 2 REVIEW of `aid-execute`'s DELIVERY-GATE flow). After the gate passes, every row is updated
to `Resolved` or `Accepted`.

Instances live at `.aid/work-NNN/delivery-NNN-issues.md`. Template source:
`canonical/templates/delivery-issues.md`.

## Deferred [HIGH] Issues

| Source task | Severity | Description | Status |
|-------------|----------|-------------|--------|
| task-NNN | [HIGH] | {one-line description of the finding} | Open |

**Column definitions:**

- **Source task** — the `task-NNN` that generated this finding during quick-check.
- **Severity** — always `[HIGH]` in this file; `[CRITICAL]` findings are fixed on-the-spot and
  never reach this log.
- **Description** — one-line summary matching the finding text in the quick-check report.
- **Status** — lifecycle of the row:
  - `Open` — not yet reviewed by the delivery gate.
  - `Resolved` — gate reviewer confirmed the issue was fixed during the gate FIX cycle.
  - `Accepted` — gate reviewer accepted the issue as a known risk / non-blocking; rationale
    recorded in the delivery gate block of `STATE.md ## Delivery Gates`.

> **Schema note (IQ11 — Cross-phase Q&A):** Task-020 scope originally proposed a richer 6-column
> schema (adding `Source File:Line` and `Deferred At` columns). Reverted to the 4-column SPEC
> per feature-004 SPEC L272-282; the richer columns can be added back via /aid-specify if needed.
