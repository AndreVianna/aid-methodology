# Work State -- work-NNN-{name}

[!NOTE]
This is the WORK-LEVEL STATE.md template. It is divided into two zones:
  AUTHORED (single-writer) -- Pipeline State, Triage, Escalation Carry, Interview State, Lifecycle History,
    Deploy State.
  DERIVED (read-only, assembled at read time) -- Features State, Plan/Deliveries, Tasks State,
    Delivery Gates, Cross-phase Q&A, Calibration Log, Dispatches.
The DERIVED sections are NEVER written directly; they are union views over the per-delivery and
per-task STATE.md files. Agents that write state must target the per-unit STATE.md files instead.

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
> **Minimum Grade:** {resolved at runtime by `bash .codex/aid/scripts/config/read-setting.sh --skill {phase} --key minimum_grade --default A`; source is `.aid/settings.yml`}
> **Started:** {YYYY-MM-DD}
> **User Approved:** yes | no

This is the single state file for **this work** -- the full dev lifecycle from req to spec to plan
to impl to deploy. One STATE.md per `.aid/work-NNN-{name}/` directory.

**Full path:** delivery/task state lives in per-delivery `deliveries/delivery-NNN/STATE.md`
(delivery lifecycle + gate + delivery-scoped Q&A + derived task rollup) and per-task
`deliveries/delivery-NNN/tasks/task-NNN/STATE.md` (mutable task cells). This file's
`## Plan / Deliveries`, `## Tasks State`, `## Delivery Gates`, and the DERIVED half of
`## Cross-phase Q&A` are read-only unions over those per-delivery files.

**Lite path:** a lite work has exactly one delivery and no `deliveries/` folder at all --
the work IS the delivery. Its gate result and delivery-scoped Q&A are AUTHORED directly in
THIS file (see `## Delivery Lifecycle` and `## Delivery Gate` below, and the lite-path note
under `## Cross-phase Q&A`); its tasks live directly at `tasks/task-NNN/STATE.md` (no
delivery layer), and `## Tasks State` below derives from those files directly.

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

- **Lifecycle:** Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
- **Phase:** Interview | Specify | Plan | Detail | Execute | Deploy | Monitor
- **Active Skill:** aid-{skill} | none
- **Updated:** {YYYY-MM-DDTHH:MM:SSZ}
- **Pause Reason:** {short text} | --          (present only when Lifecycle = Paused-Awaiting-Input)
- **Block Reason:** {short text} | --          (present only when Lifecycle = Blocked)
- **Block Artifact:** {relative path} | --     (e.g. IMPEDIMENT-task-NNN.md, or the failed gate)

---

## Triage

<!-- AUTHORED -- populated by `aid-describe` TRIAGE state for lite-path works.
     Left empty for full-path works (aid-describe runs the full interview flow instead). -->

- **Path:** lite | full
- **Work Type:** bug-fix | new-feature | refactor | {omitted for full path}
- **Sub-path:** LITE-BUG-FIX | LITE-REFACTOR | LITE-FEATURE | -- (absent for full path)
- **Sub-path (auto):** {auto-detected sub-path label, or -- if overridden or full path}
- **Decision rationale:** {one sentence: why this path/sub-path was selected}
- **Override:** yes | no (yes = human changed auto-detected sub-path)
- **Recipe:** {recipe-name} | none

---

## Delivery Lifecycle

<!-- AUTHORED -- LITE PATH ONLY. Absent entirely for full-path works (their delivery
     lifecycle lives in the per-delivery `deliveries/delivery-NNN/STATE.md ## Delivery
     Lifecycle` block instead). A lite work has exactly one delivery and no `deliveries/`
     folder -- the work IS the delivery, so its lifecycle is authored directly here.
     Same enum + writer contract as the delivery-level block (delivery-state-template.md):
     written by `aid-describe` TASK-BREAKDOWN (initial State: Executing -- lite tasks are
     already approved by the time this section is written, so Pending-Spec/Specified are
     skipped) and advanced by `aid-execute` (Executing -> Gated -> Done, or Blocked).
     `writeback-state.sh --delivery-id NNN --lifecycle VALUE` targets THIS file's section
     for a lite work (resolved automatically -- no `deliveries/` folder present). -->

- **State:** Pending-Spec | Specified | Executing | Gated | Done | Blocked
- **Updated:** {YYYY-MM-DDTHH:MM:SSZ}
- **Block Reason:** {short text} | --     (present only when State = Blocked)
- **Block Artifact:** {relative path} | --

---

## Delivery Gate

<!-- AUTHORED -- LITE PATH ONLY. Absent entirely for full-path works (their gate lives in
     the per-delivery `deliveries/delivery-NNN/STATE.md ## Delivery Gate` block instead;
     the work-level `## Delivery Gates` DERIVED section below unions those). Written by
     `aid-describe` LITE-REVIEW (pre-execution gate) and updated by `aid-execute`
     DELIVERY-GATE (post-execution gate) via `writeback-state.sh --delivery-id NNN
     --block ...`, which targets THIS file's section for a lite work. -->

- **Reviewer Tier:** Small | Medium | Large
- **Grade:** {grade or Pending}
- **Issue List:** {inline severity-tagged list, or "none" if gate passed clean}
- **Timestamp:** {YYYY-MM-DDTHH:MM:SSZ}

---

## Escalation Carry

<!-- AUTHORED -- written by `aid-describe` lite to full escalation (Steps 3-9 of
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

<!-- DERIVED -- FULL PATH ONLY. Read-only view assembled from deliveries/delivery-NNN/STATE.md
     lifecycle fields. Never written here; the delivery-level STATE.md is the authoritative
     source. One row per delivery from PLAN.md. Omitted / stays "_none yet_" for lite works --
     a lite work has no PLAN.md and no multi-delivery structure; its single delivery's
     lifecycle is AUTHORED directly above in `## Delivery Lifecycle`, not derived here. -->

| Delivery | State | Tasks | Notes |
|----------|-------|-------|-------|
| _none yet_ | | | |

## Tasks State

<!-- DERIVED -- read-only view assembled at read time from per-task STATE.md files.
     Never written directly into this file. The state reader unions all delivery branches
     using the ordering (most-advanced wins). One row per task.
     Full path: source files are `deliveries/delivery-NNN/tasks/task-NNN/STATE.md`; one row
       per task from PLAN.md execution graph.
     Lite path: source files are `tasks/task-NNN/STATE.md` directly under the work folder
       (no delivery layer); one row per task from the work-root SPEC.md `## Execution Graph`.
     State enum (closed): Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Delivery Gates

<!-- DERIVED -- FULL PATH ONLY. Read-only union of each deliveries/delivery-NNN/STATE.md
     ## Delivery Gate section. The per-delivery gate block is the authoritative source
     (single writer per delivery branch). Never written here. Omitted / stays "_none yet_"
     for lite works -- a lite work's single gate is AUTHORED directly above in this file's
     own `## Delivery Gate` section (singular), not derived here. -->

_None yet. Each deliveries/delivery-NNN/STATE.md carries its own gate block (full path);
lite works author their single gate directly in this file's `## Delivery Gate` section above._

## Cross-phase Q&A

<!-- DERIVED for full-path works -- read-only union of:
       (a) each deliveries/delivery-NNN/STATE.md ## Cross-phase Q&A section (delivery-gate Q&A), and
       (b) any work-owner-authored Q&A entries in this work's active branch (written below
           this comment by the work owner only; the work owner is the single writer here).
     Delivery branches write Q&A into their OWN deliveries/delivery-NNN/STATE.md, not here.
     The dashboard reader unions all delivery contributions plus (b) into this view.
     WORK-OWNER-AUTHORED entries may appear below this block (single writer, work active branch).

     AUTHORED for lite-path works -- a lite work has no delivery-level STATE.md to derive
     (a) from, so the single delivery's Q&A is written DIRECTLY into this section (same
     per-Q block shape as the delivery-level template) by `aid-execute` DELIVERY-GATE (SPEC
     loopback) and any other downstream phase. There is no separate (a)/(b) split for lite --
     this section IS the delivery's Q&A. -->

_None yet._

## Calibration Log

<!-- DERIVED -- read-only union of per-task ## Dispatch Log entries.
     Full path: deliveries/delivery-NNN/tasks/task-NNN/STATE.md files.
     Lite path: tasks/task-NNN/STATE.md files directly under the work folder.
     Appended by dispatchers at subagent completion (L1+L2+L3 traceability; always-on).
     One row per dispatch. Never written directly here; assemble from per-task logs at read time. -->

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Dispatches

<!-- DERIVED -- read-only union of per-task dispatch logs assembled from
     ## Dispatch Log sections in the per-task STATE.md files (full path:
     deliveries/delivery-NNN/tasks/task-NNN/STATE.md; lite path: tasks/task-NNN/STATE.md).
     Never written here; one sub-section per task that triggered at least one dispatch.
     Updated by the dispatcher on subagent completion alongside the Calibration Log row. -->

_None yet. Full path: task dispatch logs live in deliveries/delivery-NNN/tasks/task-NNN/STATE.md.
Lite path: task dispatch logs live in tasks/task-NNN/STATE.md directly._
