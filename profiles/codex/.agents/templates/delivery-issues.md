# delivery-NNN-issues.md — Deferred [HIGH] Log

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

| task-id | Severity | Description | Source File:Line | Deferred At | Status |
|---------|----------|-------------|------------------|-------------|--------|
| task-NNN | [HIGH] | {one-line description of the finding} | {path/to/file:NN} | {YYYY-MM-DDTHH:MM:SSZ} | Open |

**Column definitions:**

- **task-id** — the `task-NNN` that generated this finding during quick-check.
- **Severity** — always `[HIGH]` in this file; `[CRITICAL]` findings are fixed on-the-spot and
  never reach this log.
- **Description** — one-line summary matching the finding text in the quick-check report.
- **Source File:Line** — canonical path and line number where the issue was observed, enabling the
  gate reviewer to locate it without re-reading the quick-check report.
- **Deferred At** — ISO-8601 timestamp when the quick-check triage marked this finding
  `Deferred-to-gate` and appended the row here.
- **Status** — lifecycle of the row:
  - `Open` — not yet reviewed by the delivery gate.
  - `Resolved` — gate reviewer confirmed the issue was fixed during the gate FIX cycle.
  - `Accepted` — gate reviewer accepted the issue as a known risk / non-blocking; rationale
    recorded in the delivery gate block of `STATE.md ## Delivery Gates`.
