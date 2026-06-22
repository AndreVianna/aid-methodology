# Work State -- work-NNN-{name}

[!NOTE]
This is the WORK-LEVEL STATE.md template. It is divided into two zones:
  AUTHORED (single-writer) -- Pipeline State, Triage, Escalation Carry, Interview State, Lifecycle History,
    Deploy State.
  DERIVED (read-only, assembled at read time) -- Features State, Plan/Deliveries, Tasks State,
    Delivery Gates, Cross-phase Q&A, Calibration Log, Dispatches.
The DERIVED sections are NEVER written directly; they are union views over the per-delivery and
per-task STATE.md files. Agents that write state must target the per-unit STATE.md files instead.

<!-- SD-2 STATE ADVANCEMENT ORDERING (authoritative source; schemas.md inline copy is downstream)

Ordered from most-advanced to least-advanced:
  1. Done           -- task completed and accepted; all subtasks resolved
  2. Canceled       -- resolved terminal (explicitly abandoned); ranks just below Done
  3. In Review      -- work submitted; awaiting reviewer decision
  4. In Progress    -- actively being executed on its delivery branch
  5. Blocked        -- attempted but impeded; recoverable-in-place; more actionable than Failed
  6. Failed         -- completed attempt rejected; a parallel branch may have superseded
  7. Pending        -- not yet started

Rationale: the dashboard "most-advanced wins" reconcile answers "how far has this work
gotten across all worktree branches." Done/Canceled are terminal-resolved and rank highest.
In Review outranks In Progress (review is a later pipeline stage). Blocked outranks Failed
because a blocked task is recoverable-in-place and signals "needs attention now," whereas a
failed task represents a completed-but-rejected attempt that a parallel branch may have already
superseded -- surfacing "blocked" is the more actionable signal. Both Blocked and Failed rank
above Pending because they represent work that was attempted and surfaced information (more
informative than "not started").

Closed enum VALUES (unchanged): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled

This ordering is encoded ONCE here. Both reader twins (Python + Node) reference schemas.md for
the ordered list at runtime; schemas.md carries an inline copy derived from this source.
-->

> **State:** Interview Complete | Specifying | Planning | Detailing | Executing | Deployed
> **Phase:** Interview | Specify | Plan | Detail | Execute | Deploy
> **Minimum Grade:** {resolved at runtime by `bash .claude/aid/scripts/config/read-setting.sh --skill {phase} --key minimum_grade --default A`; source is `.aid/settings.yml`}
> **Started:** 2026-06-22
> **User Approved:** yes | no

This is the single state file for **this work** -- the full dev lifecycle from req to spec to plan
to impl to deploy. One STATE.md per `.aid/work-NNN-{name}/` directory. See also: per-delivery
`delivery-NNN/STATE.md` (delivery lifecycle + gate + delivery-scoped Q&A + derived task rollup)
and per-task `delivery-NNN/tasks/task-NNN/STATE.md` (mutable task cells).

Artifact files (REQUIREMENTS.md, per-feature SPEC.md, PLAN.md, per-task SPEC.md) keep their
inline `## Change Log` sections -- that is content history (what changed in the document),
distinct from process state (where are we in the workflow). Both are useful; they live in
different places.

---

## Pipeline State

<!-- AUTHORED -- written ONLY by `writeback-state.sh --pipeline ...` at every phase/state
     transition the pipeline performs. Never hand-edited. All values are closed enums so a
     deterministic reader needs no inference. -->
>
> Lifecycle enum:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
> Phase enum:        Interview | Specify | Plan | Detail | Execute | Deploy | Monitor
> Active Skill enum: aid-{skill} | none

- **Lifecycle:** Running
- **Phase:** Interview
- **Active Skill:** aid-interview
- **Updated:** 2026-06-22T18:07:43Z
- **Pause Reason:** —
- **Block Reason:** —
- **Block Artifact:** —

---

## Triage

<!-- AUTHORED -- populated by `aid-interview` TRIAGE state for lite-path works.
     Left empty for full-path works (aid-interview runs the full interview flow instead). -->

- **Path:** full
- **Decision rationale:** large multi-skill effort (5 KB-facing skills + new aid-update-kb) with multiple sub-features; no single lite recipe fits + user-directed full path

---

## Escalation Carry

<!-- AUTHORED -- written by `aid-interview` lite to full escalation (Steps 3-9 of
     `lite-to-full-escalation.md`). Present only when a work started on the lite path
     and was escalated to full. The CONTINUE state reads this section to avoid re-asking
     questions already answered during the lite-path session. See
     `references/state-continue.md # Escalation Carry`. -->

- **Escalated from:** {state name} (Sub-path: {sub-path value})
- **Escalated at:** {YYYY-MM-DDTHH:MM:SSZ}
- **Escalation rationale:** {one sentence}

### Captured Slot Values

- **{slot-name}:** {slot-value}
- (no slots captured -- escalation before CONDENSED-INTAKE)

### Artifacts at Escalation

- **SPEC.md:** present | absent -- {notes on content available for seeding}
- **tasks/:** {N} task files present | absent

---

## Interview State

<!-- AUTHORED -- updated by `aid-interview` as each section is completed. -->

**State:** Approved  **Grade:** Pending

| # | Section | State | Last Updated |
|---|---------|-------|--------------|
| 1 | Objective | Complete | 2026-06-22 |
| 2 | Problem Statement | Complete | 2026-06-22 |
| 3 | Users & Stakeholders | Complete | 2026-06-22 |
| 4 | Scope | Complete | 2026-06-22 |
| 5 | Functional Requirements | Complete | 2026-06-22 |
| 6 | Non-Functional Requirements | Complete | 2026-06-22 |
| 7 | Constraints | Complete | 2026-06-22 |
| 8 | Assumptions & Dependencies | Complete | 2026-06-22 |
| 9 | Acceptance Criteria | Complete | 2026-06-22 |
| 10 | Priority | Complete | 2026-06-22 |

---

## Lifecycle History

<!-- AUTHORED -- written by the orchestrator on the work's active branch (single writer).
     Append-only audit trail of phase transitions and gate approvals.
     Newest entry last (append to bottom). -->

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-06-22 | Work created | -- | Initial scaffold by aid-interview |
| 2026-06-22 | Interview approved | -- | Requirements ready; 10 sections Complete; full path |
| 2026-06-22 | Feature decomposition | -- | 12 features created (f001–f012) |
| 2026-06-22 | Cross-reference validation | C | Grade C (min A); 2 MEDIUM → Q1/Q2 raised (Pending); LOW/MINOR fixes to fold inline |
| 2026-06-22 | Cross-reference re-grade | A+ | Q1/Q2 answered + folded; LOW fixed/accepted; migrate-name verified; clears the A bar |

---

## Deploy State

<!-- AUTHORED -- written ONLY by `aid-deploy` at each delivery deploy (single writer; one row
     per delivery). Never derived from child files; aid-deploy is the sole author. Future work
     may migrate this to a per-delivery hierarchy view, but until then it is AUTHORED here.
     One row per delivery from /aid-deploy. -->

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|-----|-------|
| _none yet_ | | | | | |

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS
     The sections below are assembled at READ TIME from per-delivery and per-task STATE.md files.
     They are NEVER written directly. Agents MUST target the per-unit STATE.md files instead.
     Dashboard readers union the child contributions; no agent writes to these sections.
     ============================================================ -->

## Features State

<!-- DERIVED -- read-only view assembled from features/{feature}/SPEC.md progress.
     Never written here; feature progress is tracked via /aid-specify per-feature.
     One row per feature. Tracks /aid-specify progress per feature. -->

| # | Feature | Spec State | Spec Grade | Q&A Count | Notes |
|---|---------|------------|------------|-----------|-------|
| _none yet_ | | | | | |

## Plan / Deliveries

<!-- DERIVED -- read-only view assembled from delivery-NNN/STATE.md lifecycle fields.
     Never written here; the delivery-level STATE.md is the authoritative source.
     One row per delivery from PLAN.md. -->

| Delivery | State | Tasks | Notes |
|----------|-------|-------|-------|
| _none yet_ | | | |

## Tasks State

<!-- DERIVED -- read-only view assembled at read time from per-task STATE.md files
     (delivery-NNN/tasks/task-NNN/STATE.md). Never written directly into this file.
     The state reader unions all delivery branches using the SD-2 ordering (most-advanced wins).
     One row per task from PLAN.md execution graph.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Delivery Gates

<!-- DERIVED -- read-only union of each delivery-NNN/STATE.md ## Delivery Gate section.
     The per-delivery gate block is the authoritative source (single writer per delivery branch).
     Never written here. -->

_None yet. Each delivery-NNN/STATE.md carries its own gate block._

## Cross-phase Q&A

<!-- DERIVED -- read-only union of:
       (a) each delivery-NNN/STATE.md ## Cross-phase Q&A section (delivery-gate Q&A), and
       (b) any work-owner-authored Q&A entries in this work's active branch (written below
           this comment by the work owner only; the work owner is the single writer here).
     Delivery branches write Q&A into their OWN delivery-NNN/STATE.md, not here (SD-5).
     The dashboard reader unions all delivery contributions plus (b) into this view.
     WORK-OWNER-AUTHORED entries may appear below this block (single writer, work active branch). -->

### Q1

- **Category:** Architecture (Freshness)
- **Impact:** Required
- **Status:** Answered (2026-06-22)
- **Answer:** (a) — a NEW per-doc **`approved_at_commit:`** frontmatter stamp, written on approval by `aid-discover`/`aid-update-kb`; FR-4 adds the field, FR-5 compares each doc's `sources:` against it. Folded into REQUIREMENTS.
- **Context:** Cross-reference (2026-06-22) found FR-5 / feature-007 per-doc staleness compares each doc's `sources:` against "that doc's **approval commit**," but **no per-doc approval-commit primitive exists or is created by any FR/feature** (`state-kb-delta.md` notes "no `Approved-At-Commit:` field"). The comparator's baseline is unbuilt and unowned — MEDIUM, grade-driving. Must be resolved before feature-007 is specifiable.
- **Suggested:** (a) a NEW per-doc `approved_at_commit:` frontmatter stamp written on KB approval by aid-discover/aid-update-kb.
- **Question:** How should FR-5's freshness comparator establish each doc's baseline — (a) a new per-doc `approved_at_commit:` frontmatter stamp, (b) git-blame of the doc's last approval commit, or (c) reuse the existing whole-KB `kb_baseline.tip_date`?

### Q2

- **Category:** Constraints (Packaging)
- **Impact:** Medium
- **Status:** Answered (2026-06-22)
- **Answer:** Yes — the new mechanical KB scripts are shipped/vendored → the ASCII-only guard applies (bash, so PS-5.1 N/A). Folded into C2.
- **Context:** Cross-reference (2026-06-22) — C2 (ASCII-only + WinPS-5.1) scope is ambiguous for the NEW mechanical KB scripts (coined-term scan, closure self-containment check, salience). They are bash (so PS-5.1 is N/A), but it is undecided whether they count as "shipped/vendored scripts" under the ASCII-only guard.
- **Suggested:** yes — if vendored into the install bundles they are "shipped" and the ASCII-only guard applies.
- **Question:** Do the new KB mechanical scripts count as "shipped scripts" subject to the ASCII-only guard (C2), and are they vendored into the 5 install bundles?

## Calibration Log

<!-- DERIVED -- read-only union of per-task ## Dispatch Log entries from
     delivery-NNN/tasks/task-NNN/STATE.md files.
     Appended by dispatchers at subagent completion (L1+L2+L3 traceability; always-on).
     One row per dispatch. Never written directly here; assemble from per-task logs at read time. -->

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Dispatches

<!-- DERIVED -- read-only union of per-task dispatch logs assembled from
     delivery-NNN/tasks/task-NNN/STATE.md ## Dispatch Log sections.
     Never written here; one sub-section per task that triggered at least one dispatch.
     Updated by the dispatcher on subagent completion alongside the Calibration Log row. -->

_None yet. Delivery task dispatch logs live in delivery-NNN/tasks/task-NNN/STATE.md._
