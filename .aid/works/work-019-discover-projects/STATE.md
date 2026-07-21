---
pipeline:
  path: lite
  initiator: aid-update-cli
started: "2026-07-21"
minimum_grade: "A+"
user_approved: no
lifecycle: Paused-Awaiting-Input
phase: Detail
active_skill: aid-update-cli
updated: '2026-07-21T22:19:41Z'
pause_reason: 'GATE cleared (revised plan A+); awaiting user approval before /aid-execute'
block_reason: --
block_artifact: --
ticket_ref: --
# --- Flattened single-delivery works only (see `## Delivery Lifecycle` below);
#     omit these 4 keys entirely for full multi-delivery works. ---
delivery_state: Specified
gate_tier: Pending
gate_grade: Pending
gate_timestamp: --
---

# Work State -- work-019-discover-projects

[!NOTE]
This is the WORK-LEVEL STATE.md template. It is divided into three zones:
  FRONTMATTER (single-writer, machine-parsed scalars) -- the YAML block above: pipeline
    identity, work-level lifecycle/phase/approval scalars, and (for flattened single-delivery
    works only) the delivery lifecycle/gate scalars. Written ONLY by `writeback-state.sh`
    (surgical YAML-block rewrite; the markdown body is never touched by that write).
  AUTHORED (single-writer, markdown body) -- Interview State, Lifecycle History,
    Deploy State, the narrative remainder of Delivery Lifecycle (incl. its Tasks lifecycle
    subsection) and Delivery Gate (Updated/Block Reason/Block Artifact/Issue List -- the
    values that don't fit a flat frontmatter scalar).
  DERIVED (read-only, assembled at read time) -- Features State, Plan/Deliveries, Tasks State,
    Delivery Gates, Cross-phase Q&A, Calibration Log, Dispatches.
The DERIVED sections are NEVER written directly; they are union views over the per-delivery and
per-task STATE.md files. Agents that write state must target the per-unit STATE.md files instead.
Inferred values (`number` from the folder name, `branch` from the git worktree,
`title`/`description`/`objective` from REQUIREMENTS/SPEC content files) and derived values
(counts, readiness/execution %, `source_mode`) are NEVER authored here -- computed at read time.

The AUTHORED `## Delivery Lifecycle` / `### Tasks lifecycle` / `## Delivery Gate` sections
(singular) apply ONLY to single-delivery flattened works (no `deliveries/`/`delivery-NNN/`
wrapper -- see each section's own note). They are promoted verbatim from
`delivery-state-template.md` / `task-state-template.md` and are distinct from the plural DERIVED
`## Delivery Gates` / `## Plan / Deliveries` / `## Tasks State` union views below -- no heading
collision (singular vs. plural, and `### Tasks lifecycle` differs in both text and heading level
from `## Tasks State`). Left unused for full multi-delivery works, where each delivery's own
lifecycle/gate lives in its `delivery-NNN/STATE.md` and each task's own state lives in its
`delivery-NNN/tasks/task-NNN/STATE.md` instead.

Optional `ticket_ref` scalar (frontmatter, top-level, both layouts): links this work to an
external tracker item (`<connector-stem>:<external-id>`, e.g. `jira:PROJ-123`). Left `--` when
this work is not linked; readers/dashboard ignore it. Nearest-ancestor resolution + MCP-first
consumption contract: `.claude/aid/templates/connectors/consumption-protocol.md`. Coordinate
with the in-flight `work-003-state-schema` frontmatter conventions when both touch this file's
frontmatter block. `ticket_ref` is a lifecycle-unit field only -- the connector descriptor schema
is unchanged.

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

> **State:** Describing | Defining | Specifying | Planning | Detailing | Executing
> **Phase:** Describe | Define | Specify | Plan | Detail | Execute

This is the single state file for **this work** -- the full dev lifecycle from req to spec to plan
to impl to deploy. One STATE.md per `.aid/works/work-NNN-{name}/` directory. See also: per-delivery
`delivery-NNN/STATE.md` (delivery lifecycle + gate + delivery-scoped Q&A + derived task rollup)
and per-task `delivery-NNN/tasks/task-NNN/STATE.md` (mutable task cells).

Artifact files (REQUIREMENTS.md, per-feature SPEC.md, PLAN.md, per-task DETAIL.md) keep their
inline `## Change Log` sections -- that is content history (what changed in the document),
distinct from process state (where are we in the workflow). Both are useful; they live in
different places.

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
| 2026-07-21 | Work created | -- | Initial scaffold by aid-update-cli (shortcut: change/cli) |
| 2026-07-21 | CAPTURE complete -- REQUIREMENTS.md written | -- | /aid-update-cli CAPTURE |
| 2026-07-21 | SPEC complete -- SPEC.md written | -- | /aid-update-cli SPEC |
| 2026-07-21 | PLAN complete -- PLAN.md + BLUEPRINT.md written | -- | /aid-update-cli PLAN |
| 2026-07-21 | DETAIL complete -- 4 task(s) written | -- | /aid-update-cli DETAIL |
| 2026-07-21 | Renumbered work-002 -> work-019 (work-002 collided with a shipped, pruned work; PR #133) | -- | orchestrator |
| 2026-07-21 | GATE cycle 1 -- reviewer found 10 findings (1 CRIT / 4 HIGH / 4 MED / 1 LOW); architect fixed all | -- | /aid-update-cli GATE |
| 2026-07-21 | GATE cleared -- 8 artifacts re-reviewed clean (grade.sh) | A+ | /aid-update-cli GATE |
| 2026-07-21 | Scope redesign (user) -- default=home, --path <folder>, --all; revising + re-gating | -- | /aid-update-cli |
| 2026-07-21 | Scan-behavior rules (user) -- subtree prune, exclusion list, eval order, dedupe, depth cap; NFR-9/NFR-10 + AC-14/15/16 | -- | /aid-update-cli |
| 2026-07-21 | GATE re-review -- 4 findings (1 CRIT / 1 HIGH / 2 MED-LOW); fixed | -- | /aid-update-cli GATE |
| 2026-07-21 | GATE cleared (revised plan) -- verified clean + SPEC Source-range fix (grade.sh) | A+ | /aid-update-cli GATE |

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
     and `writeback-state.sh` bind to the exact strings (no byte-stability break).

     The **State** scalar lives in the YAML frontmatter block at the top of this file
     (`delivery_state`) -- see the frontmatter's "Flattened single-delivery works only" group.
     Updated/Block Reason/Block Artifact stay here as markdown body (not relocated by
     work-003-state-schema task-001; see the task's schema note). -->

- **Updated:** 2026-07-21T19:40:19Z
- **Block Reason:** --
- **Block Artifact:** --

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
       Pending | In Progress | In Review | Blocked | Done | Failed | Canceled

     MANDATORY (aid-execute/references/state-execute.md § State-Write Protocol):
     each row's State cell MUST be written the INSTANT that task's state
     changes -- In Progress before work starts, In Review before the reviewer
     is dispatched, a terminal value (Done/Failed) when finished. Binds
     whoever executes the task -- the main/orchestrator agent running it
     directly, or a dispatched sub-agent -- with no exception either way.
     (Blocked is a distinct, orchestrator-assigned value for a different,
     downstream task that depends on a failed one -- never self-written by
     the task being executed.) -->

| Task | State | Review | Elapsed | Notes | Name |
|------|-------|--------|---------|-------|------|
| task-001 | Pending | -- | -- | -- | Implement the scan subcommand in the Bash twin (bin/aid) |
| task-002 | Pending | -- | -- | -- | Mirror the scan subcommand in the PowerShell twin (bin/aid.ps1) |
| task-003 | Pending | -- | -- | -- | Parity + guardrail coverage in test-aid-cli-parity.sh |
| task-004 | Pending | -- | -- | -- | Help text, user docs, and release-tracking entry |

---

## Delivery Gate

<!-- AUTHORED -- single-delivery FLATTENED works only (see ## Delivery Lifecycle note above).
     Promoted VERBATIM from `delivery-state-template.md ## Delivery Gate` (A-8). Single writer:
     the delivery-gate closing step of `aid-execute` on this work's active branch, written via
     `writeback-state.sh --delivery-id 001 --block ...`. Distinct from per-task quick-check
     findings -- the gate aggregates those deferred [HIGH] rows (via
     `.aid/works/{work}/delivery-001-issues.md`; see `.claude/aid/templates/delivery-issues.md`) and runs
     a full grade.sh pass. The gate's criteria are read from this work's `BLUEPRINT.md § GATE
     CRITERIA`, NOT from this STATE.md. Left absent (section omitted) for full multi-delivery
     works, where each delivery-NNN/STATE.md carries its own gate block (unioned by the DERIVED
     ## Delivery Gates view below). The enum below is byte-identical to
     `delivery-state-template.md` -- no byte-stability break.

     Reviewer Tier / Grade / Timestamp live in the YAML frontmatter block at the top of this
     file (`gate_tier`, `gate_grade`, `gate_timestamp`) -- see the frontmatter's "Flattened
     single-delivery works only" group. Issue List stays here as markdown body (a
     variable-length inline list doesn't fit a flat frontmatter scalar). -->

- **Issue List:** {inline severity-tagged list, or "none" if gate passed clean}

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
