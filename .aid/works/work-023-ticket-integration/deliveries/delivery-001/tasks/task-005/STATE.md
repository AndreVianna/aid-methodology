---
state: Done
review: 'self-verified 89/89 structural assertions pass; no work-folder dep; glob-discoverable'
elapsed: "--"
notes: "--"
ticket_ref: "--"   # OPTIONAL; e.g. jira:PROJ-123 -- no issue-tracker connector catalogued for this repo
---

# Task State -- task-005

[!NOTE]
This is the TASK-LEVEL STATE.md template. It is **full-path only** -- it lives at
`deliveries/delivery-001/tasks/task-005/STATE.md`. The `## Task State` mutable cell
(state/review/elapsed/notes) lives in the YAML frontmatter block above; the remaining
sections (Quick Check Findings, Dispatch Log) are AUTHORED as markdown body. All of it is
written by a single writer: the delivery branch that owns this task. This file is the SOLE
write target for all per-task mutable state. Its parent
`deliveries/delivery-001/STATE.md ## Tasks State` and the work-level `## Tasks State` are
DERIVED read-only views assembled from this file at read time -- never written directly.

> **Task:** task-005
> **Delivery:** delivery-001
> **Work:** work-023-ticket-integration

---

## Task State

<!-- AUTHORED -- values live in the YAML frontmatter block at the top of this file
     (`state`, `review`, `elapsed`, `notes`), written ONLY by
     `writeback-state.sh --task-id 005 --field State --value VALUE`.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled
     MANDATORY: write `state` the INSTANT it changes -- In Progress before work starts,
     In Review before the reviewer is dispatched, a terminal value (Done/Failed) when finished. -->

---

## Quick Check Findings

<!-- AUTHORED -- written by `writeback-state.sh --task-id 005 --findings ...` during the
     per-task quick-check step of aid-execute. Records the reviewer tier and all [HIGH]/[CRITICAL]
     findings for this task. No grade is recorded here -- grading is per-delivery. -->

- **Reviewer Tier:** Small (quick check always uses Small tier)
- **Findings:** none yet

---

## Dispatch Log

<!-- AUTHORED -- appended by the dispatcher on subagent completion (L1+L2+L3 traceability;
     always-on). One row per dispatch. -->

| Date | Agent | ETA Band | Actual | Outcome |
|------|-------|----------|--------|---------|
