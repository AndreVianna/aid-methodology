---
state: Done
review: "--"
elapsed: "--"
notes: "--"
ticket_ref: "--"
---

# Task State -- task-021

[!NOTE]
This is the TASK-LEVEL STATE.md template. It is **full-path only** -- it lives at
`deliveries/delivery-NNN/tasks/task-NNN/STATE.md`. The `## Task State` mutable cell
(state/review/elapsed/notes) lives in the YAML frontmatter block above; the remaining
sections (Quick Check Findings, Dispatch Log) are AUTHORED as markdown body. All of it
is written by a single writer: the delivery branch that owns this task. This file is the
SOLE write target for all per-task mutable state (state cell, review, elapsed, notes,
findings, dispatch log). Its parent `deliveries/delivery-NNN/STATE.md ## Tasks State` and
the work-level `## Tasks State` are DERIVED read-only views assembled from this file at
read time -- never written directly.

> **Task:** task-021
> **Delivery:** delivery-003
> **Work:** work-017-cli-improvements

---

## Task State

<!-- AUTHORED -- values live in the YAML frontmatter block at the top of this file
     (`state`, `review`, `elapsed`, `notes`), written ONLY by
     `writeback-state.sh --task-id NNN --field State --value VALUE` (surgical frontmatter
     rewrite; the markdown body is never touched by that write).
     State enum (closed; single source of truth):
       Pending | In Progress | In Review | Blocked | Done | Failed | Canceled
     Ordering (most-advanced wins on reconcile):
       Done > Canceled > In Review > In Progress > Blocked > Failed > Pending -->

---

## Quick Check Findings

<!-- AUTHORED -- written by `writeback-state.sh --task-id NNN --findings ...` during the
     per-task quick-check step of aid-execute. Records the reviewer tier used and all [HIGH]
     and [CRITICAL] findings for this task. -->

- **Reviewer Tier:** -- (quick check not yet run)
- **Findings:** -- (none yet)

---

## Dispatch Log

<!-- AUTHORED -- appended by the dispatcher on subagent completion (L1+L2+L3 traceability;
     always-on, never optional). One row per dispatch. -->

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|
