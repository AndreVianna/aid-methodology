---
pipeline:
  path: full
  initiator: aid-describe
started: "2026-08-12"
minimum_grade: "A"
user_approved: yes
lifecycle: Running
phase: Define
active_skill: aid-define
updated: '2026-08-12T17:47:05Z'
pause_reason: --
block_reason: --
block_artifact: --
ticket_ref: "--"
---

# Work State -- work-004-frontmatter-review-criteria

> **State:** Describing
> **Phase:** Describe

This is the single state file for **this work** -- the full dev lifecycle from req to spec to plan
to impl to deploy. One STATE.md per `.aid/works/work-NNN-{name}/` directory. See also: per-delivery
`delivery-NNN/STATE.md` (delivery lifecycle + gate + delivery-scoped Q&A + derived task rollup)
and per-task `delivery-NNN/tasks/task-NNN/STATE.md` (mutable task cells).

---

## Pipeline State

<!-- AUTHORED -- values live in the YAML frontmatter block at the top of this file
     (`lifecycle`, `phase`, `active_skill`, `updated`, `pause_reason`, `block_reason`,
     `block_artifact`), written ONLY by `writeback-state.sh --pipeline ...` at every
     phase/state transition the pipeline performs (surgical frontmatter rewrite; never
     hand-edited). All values are closed enums so a deterministic reader needs no
     inference. This section retains the enum reference below for human readability. -->
>
> Lifecycle enum:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
> Phase enum:        Describe | Define | Specify | Plan | Detail | Execute
> Active Skill enum: aid-{skill} | none

---

## Interview State

<!-- AUTHORED -- updated by `aid-describe` as each section is completed. -->

**Interview State:** Approved  **Grade:** Pending

| # | Section | State | Last Updated |
|---|---------|-------|--------------|
| 1 | Objective | Complete | 2026-08-12 |
| 2 | Problem Statement | Complete | 2026-08-12 |
| 3 | Users & Stakeholders | Complete | 2026-08-12 |
| 4 | Scope | Complete | 2026-08-12 |
| 5 | Functional Requirements | Complete | 2026-08-12 |
| 6 | Non-Functional Requirements | Complete | 2026-08-12 |
| 7 | Constraints | Complete | 2026-08-12 |
| 8 | Assumptions & Dependencies | Complete | 2026-08-12 |
| 9 | Acceptance Criteria | Complete | 2026-08-12 |
| 10 | Priority | Complete | 2026-08-12 |

### Review History

| Date | Event | Outcome | Notes |
|------|-------|---------|-------|
| 2026-08-12 | COMPLETION quality check | 1 defect found and fixed | A stale `341` in FR-6 — the work-003 figure this document corrects two sections earlier |
| 2026-08-12 | COMPLETION KB hydration | No KB write warranted | Reasons recorded in REQUIREMENTS.md § KB hydration assessment; gap check found no empty doc |
| 2026-08-12 | Interview approved by owner | Approved | All 10 sections Complete; identity fields confirmed as "Declared Review Criteria" |

---

## Lifecycle History

<!-- AUTHORED -- written by the orchestrator on the work's active branch (single writer).
     Append-only audit trail of phase transitions and gate approvals.
     Newest entry last (append to bottom). -->

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-08-12 | Work created | -- | Worktree + branch `work-004` off `master` (`9260fc88`); prior-art evidence captured in `prior-art.md` |
| 2026-08-12 | Describe → approved | -- | REQUIREMENTS.md approved by the owner; awaiting `/aid-define` |

---

## Deploy State

<!-- AUTHORED -- written ONLY by `aid-deploy` at each delivery deploy (single writer; one row
     per delivery). Never derived from child files; aid-deploy is the sole author. -->

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|-----|-------|
| _none yet_ | | | | | |

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     The sections below are assembled at READ TIME from per-delivery and per-task STATE.md files.
     They are NEVER written directly. Agents MUST target the per-unit STATE.md files instead.
     ============================================================ -->

## Features State

<!-- DERIVED -- read-only view assembled from features/{feature}/SPEC.md progress. -->

| # | Feature | Spec State | Spec Grade | Q&A Count | Notes |
|---|---------|------------|------------|-----------|-------|
| _none yet_ | | | | | |

## Plan / Deliveries

<!-- DERIVED -- read-only view assembled from delivery-NNN/STATE.md lifecycle fields. -->

| Delivery | State | Tasks | Notes |
|----------|-------|-------|-------|
| _none yet_ | | | |

## Tasks State

<!-- DERIVED -- read-only view assembled at read time from per-task STATE.md files
     (delivery-NNN/tasks/task-NNN/STATE.md). Never written directly into this file.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Delivery Gates

<!-- DERIVED -- read-only union of each delivery-NNN/STATE.md ## Delivery Gate section. -->

_None yet. Each delivery-NNN/STATE.md carries its own gate block._

## Cross-phase Q&A

<!-- DERIVED -- read-only union of each delivery-NNN/STATE.md ## Cross-phase Q&A section plus
     any work-owner-authored entries below this comment (work owner is the single writer here). -->

_None yet._

## Calibration Log

<!-- DERIVED -- read-only union of per-task ## Dispatch Log entries from
     delivery-NNN/tasks/task-NNN/STATE.md files (L1+L2+L3 traceability; always-on). -->

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Dispatches

<!-- DERIVED -- read-only union of per-task dispatch logs assembled from
     delivery-NNN/tasks/task-NNN/STATE.md ## Dispatch Log sections. -->

_None yet. Delivery task dispatch logs live in delivery-NNN/tasks/task-NNN/STATE.md._
