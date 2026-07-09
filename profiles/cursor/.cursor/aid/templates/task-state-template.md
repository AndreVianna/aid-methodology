# Task State -- task-NNN

[!NOTE]
This is the TASK-LEVEL STATE.md template. It is **full-path only** -- it lives at
`deliveries/delivery-NNN/tasks/task-NNN/STATE.md`. All sections are AUTHORED by a
single writer: the delivery branch that owns this task. This file is the SOLE write
target for all per-task mutable state (state cell, review, elapsed, notes, findings,
dispatch log). Its parent `deliveries/delivery-NNN/STATE.md ## Tasks State` and the
work-level `## Tasks State` are DERIVED read-only views assembled from this file at
read time -- never written directly.
Lite (flattened) path has **no per-task STATE.md at all**: each task's mutable cells
live directly in the work-root `STATE.md § ### Tasks lifecycle`, written via
`writeback-state.sh --task-id` targeting that table row instead of a sibling file.

> **Task:** task-NNN
> **Delivery:** delivery-NNN
> **Work:** work-NNN-{name}

---

## Task State

<!-- AUTHORED -- written ONLY by `writeback-state.sh --task-id NNN --field State --value VALUE`.
     State enum (closed; single source of truth):
       Pending | In Progress | In Review | Blocked | Done | Failed | Canceled
     Ordering (most-advanced wins on reconcile):
       Done > Canceled > In Review > In Progress > Blocked > Failed > Pending -->

- **State:** Pending | In Progress | In Review | Blocked | Done | Failed | Canceled
- **Review:** {reviewer tier and outcome, or Pending}
- **Elapsed:** {HH:MM or --}
- **Notes:** {short free-text, or --}

---

## Quick Check Findings

<!-- AUTHORED -- written by `writeback-state.sh --task-id NNN --findings ...` during the
     per-task quick-check step of aid-execute. Records the reviewer tier used and all [HIGH]
     and [CRITICAL] findings for this task. [CRITICAL] findings trigger an immediate fix-on-spot;
     [HIGH] findings are deferred to the delivery gate via delivery-NNN-issues.md.
     No grade is recorded here -- grading is per-delivery, not per-task. -->

- **Reviewer Tier:** Small (quick check always uses Small tier)
- **Findings:**
  - [CRITICAL] {description} -- {source-file:line} -- Fixed-on-spot
  - [HIGH] {description} -- {source-file:line} -- Deferred-to-gate

---

## Dispatch Log

<!-- AUTHORED -- appended by the dispatcher on subagent completion (L1+L2+L3 traceability;
     always-on, never optional). One row per dispatch. The work-level ## Calibration Log
     and ## Dispatches views are DERIVED unions of all per-task Dispatch Log sections.
     Source: `.cursor/skills/aid-discover/SKILL.md ## Dispatch Protocol`. -->

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|
