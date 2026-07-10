# Work State -- work-NNN-{name}

[!NOTE]
This is the WORK-LEVEL STATE.md template. It is divided into two zones:
  AUTHORED (single-writer) -- Pipeline State, Interview State, Lifecycle History,
    Deploy State, Delivery Lifecycle (incl. its Tasks lifecycle subsection), Delivery Gate.
  DERIVED (read-only, assembled at read time) -- Features State, Plan/Deliveries, Tasks State,
    Delivery Gates, Cross-phase Q&A, Calibration Log, Dispatches.
The DERIVED sections are NEVER written directly; they are union views over the per-delivery and
per-task STATE.md files. Agents that write state must target the per-unit STATE.md files instead.

The AUTHORED `## Delivery Lifecycle` / `### Tasks lifecycle` / `## Delivery Gate` sections
(singular) apply ONLY to single-delivery flattened works (no `deliveries/`/`delivery-NNN/`
wrapper -- see each section's own note). They are promoted verbatim from
`delivery-state-template.md` / `task-state-template.md` and are distinct from the plural DERIVED
`## Delivery Gates` / `## Plan / Deliveries` / `## Tasks State` union views below -- no heading
collision (singular vs. plural, and `### Tasks lifecycle` differs in both text and heading level
from `## Tasks State`). Left unused for full multi-delivery works, where each delivery's own
lifecycle/gate lives in its `delivery-NNN/STATE.md` and each task's own state lives in its
`delivery-NNN/tasks/task-NNN/STATE.md` instead.

<!-- STATE ADVANCEMENT ORDERING (authoritative source; schemas.md inline copy is downstream)

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
> **Minimum Grade:** {resolved at runtime by `bash .github/aid/scripts/config/read-setting.sh --skill {phase} --key minimum_grade --default A`; source is `.aid/settings.yml`}
> **Started:** {YYYY-MM-DD}
> **User Approved:** yes | no

This is the single state file for **this work** -- the full dev lifecycle from req to spec to plan
to impl to deploy. One STATE.md per `.aid/work-NNN-{name}/` directory. See also: per-delivery
`delivery-NNN/STATE.md` (delivery lifecycle + gate + delivery-scoped Q&A + derived task rollup)
and per-task `delivery-NNN/tasks/task-NNN/STATE.md` (mutable task cells).

Artifact files (REQUIREMENTS.md, per-feature SPEC.md, PLAN.md, per-task DETAIL.md) keep their
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

- **Lifecycle:** Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
- **Phase:** Interview | Specify | Plan | Detail | Execute | Deploy | Monitor
- **Active Skill:** aid-{skill} | none
- **Updated:** {YYYY-MM-DDTHH:MM:SSZ}
- **Pause Reason:** {short text} | --          (present only when Lifecycle = Paused-Awaiting-Input)
- **Block Reason:** {short text} | --          (present only when Lifecycle = Blocked)
- **Block Artifact:** {relative path} | --     (e.g. IMPEDIMENT-task-NNN.md, or the failed gate)

---

## Interview State

<!-- AUTHORED -- updated by `aid-describe` as each section is completed. -->

**State:** In Progress | Complete | Approved  **Grade:** {grade or Pending}

| # | Section | State | Last Updated |
|---|---------|-------|--------------|
| 1 | Objective | Pending | -- |
| 2 | Problem Statement | Pending | -- |
| 3 | Users & Stakeholders | Pending | -- |
| 4 | Scope | Pending | -- |
| 5 | Functional Requirements | Pending | -- |
| 6 | Non-Functional Requirements | Pending | -- |
| 7 | Constraints | Pending | -- |
| 8 | Assumptions & Dependencies | Pending | -- |
| 9 | Acceptance Criteria | Pending | -- |
| 10 | Priority | Pending | -- |

---

## Lifecycle History

<!-- AUTHORED -- written by the orchestrator on the work's active branch (single writer).
     Append-only audit trail of phase transitions and gate approvals.
     Newest entry last (append to bottom). -->

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| {YYYY-MM-DD} | Work created | -- | Initial scaffold by aid-config |

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

## Delivery Lifecycle

<!-- AUTHORED -- single-delivery FLATTENED works only (no `deliveries/`/`delivery-NNN/` wrapper;
     `tasks/task-NNN/DETAIL.md` directly under the work root). Promoted VERBATIM from
     `delivery-state-template.md ## Delivery Lifecycle` (A-8): with exactly one delivery there is
     exactly one writer, so the disjoint-write rule that forces a separate `delivery-NNN/STATE.md`
     no longer applies and this section is authored directly here instead. Single writer: this
     work's active branch only. Written by aid-plan, aid-specify, aid-execute across the delivery
     pipeline for the synthesized `delivery-001`. Never derived from task rollup. Left absent
     (section omitted) for full multi-delivery works, where each delivery's own lifecycle lives in
     its `delivery-NNN/STATE.md` instead (unioned by the DERIVED `## Plan / Deliveries` view
     below). The enum below is byte-identical to `delivery-state-template.md` -- both reader twins
     and `writeback-state.sh` bind to the exact strings (no byte-stability break). -->

- **State:** Pending-Spec | Specified | Executing | Gated | Done | Blocked
- **Updated:** {YYYY-MM-DDTHH:MM:SSZ}
- **Block Reason:** {short text} | --     (present only when State = Blocked)
- **Block Artifact:** {relative path} | --

### Tasks lifecycle

<!-- AUTHORED -- single-delivery FLATTENED works only (see ## Delivery Lifecycle note above).
     The single-writer home for per-task mutable state cells, REPLACING the now-absent per-task
     `STATE.md` (each task is `tasks/task-NNN/DETAIL.md` only -- immutable, no sibling STATE.md).
     Written by `writeback-state.sh --task-id NNN --field State --value V` (flattened branch),
     targeting this table instead of a `delivery-NNN/tasks/task-NNN/STATE.md`. Mirrors the REAL
     fields of `task-state-template.md ## Task State` (State/Review/Elapsed/Notes), one row per
     task-NNN. This is a `###` subsection of ## Delivery Lifecycle, distinct from the plural
     DERIVED `## Tasks State` view below (different heading text AND level -- no collision). Left
     absent (section omitted) for full multi-delivery works, where each task's own state lives in
     its `delivery-NNN/tasks/task-NNN/STATE.md` instead (unioned by that DERIVED view). The enum
     below is byte-identical to `task-state-template.md` -- no byte-stability break.

     State enum (closed; single source of truth):
       Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| Task | State | Review | Elapsed | Notes |
|------|-------|--------|---------|-------|
| _none yet_ | | | | |

---

## Delivery Gate

<!-- AUTHORED -- single-delivery FLATTENED works only (see ## Delivery Lifecycle note above).
     Promoted VERBATIM from `delivery-state-template.md ## Delivery Gate` (A-8). Single writer:
     the delivery-gate closing step of `aid-execute` on this work's active branch, written via
     `writeback-state.sh --delivery-id 001 --block ...`. Distinct from per-task quick-check
     findings -- the gate aggregates those deferred [HIGH] rows (via
     `.aid/{work}/delivery-001-issues.md`; see `.github/aid/templates/delivery-issues.md`) and runs
     a full grade.sh pass. The gate's criteria are read from this work's `BLUEPRINT.md § GATE
     CRITERIA`, NOT from this STATE.md. Left absent (section omitted) for full multi-delivery
     works, where each delivery-NNN/STATE.md carries its own gate block (unioned by the DERIVED
     ## Delivery Gates view below). The enum below is byte-identical to
     `delivery-state-template.md` -- no byte-stability break. -->

- **Reviewer Tier:** Small | Medium | Large
- **Grade:** {grade or Pending}
- **Issue List:** {inline severity-tagged list, or "none" if gate passed clean}
- **Timestamp:** {YYYY-MM-DDTHH:MM:SSZ}

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
     The state reader unions all delivery branches using the ordering (most-advanced wins).
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
     Delivery branches write Q&A into their OWN delivery-NNN/STATE.md, not here.
     The dashboard reader unions all delivery contributions plus (b) into this view.
     WORK-OWNER-AUTHORED entries may appear below this block (single writer, work active branch). -->

_None yet._

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
