# Work State -- work-003-state-schema

<!-- WORK-LEVEL STATE.md (flattened single-delivery work). Two zones:
  AUTHORED (single-writer) -- Pipeline State, Interview State, Lifecycle History, Deploy State,
    Delivery Lifecycle (incl. its ### Tasks lifecycle subsection), Delivery Gate.
  DERIVED (read-only) -- Features State, Plan/Deliveries, Tasks State, Delivery Gates,
    Cross-phase Q&A, Calibration Log, Dispatches.
  The AUTHORED `## Delivery Lifecycle` / `### Tasks lifecycle` / `## Delivery Gate` (singular)
  apply to this single-delivery FLATTENED work (no `deliveries/`/`delivery-NNN/` wrapper;
  `tasks/task-NNN/DETAIL.md` directly under the work root, no per-task STATE.md). They are promoted
  verbatim from delivery-state-template.md / task-state-template.md and are distinct from the
  plural DERIVED union views below. -->

<!-- STATE ADVANCEMENT ORDERING (closed enum, most→least advanced):
     Done | Canceled | In Review | In Progress | Blocked | Failed | Pending -->

> **State:** Detailing
> **Phase:** Detail
> **Minimum Grade:** A+ (resolved at runtime via `read-setting.sh`; source `.aid/settings.yml`)
> **Started:** 2026-07-09
> **User Approved:** no

This is the single state file for **this work** -- a flattened single-delivery Lite work
(no `features/` folder, no `deliveries/`/`delivery-NNN/` wrapper). Artifact files
(SPEC.md, PLAN.md, BLUEPRINT.md, per-task DETAIL.md) carry their own content; this file carries
process state only. (No `REQUIREMENTS.md` for this flattened Lite work — requirements live in
SPEC.md + BLUEPRINT.md.)

---

## Pipeline State

<!-- AUTHORED -- closed enums; deterministic reader needs no inference. -->
>
> Lifecycle enum:    Running | Paused-Awaiting-Input | Blocked | Completed | Canceled
> Phase enum:        Interview | Specify | Plan | Detail | Execute | Deploy | Monitor
> Active Skill enum: aid-{skill} | none

- **Lifecycle:** Paused-Awaiting-Input
- **Phase:** Detail
- **Active Skill:** none
- **Updated:** 2026-07-10T17:34:53Z
- **Pause Reason:** Definition complete (8 tasks: 5 STATE-frontmatter + 3 folded-in maintenance) at the v2.1.0 base; delivery gate A+; awaiting /aid-execute work-003-state-schema task-001
- **Block Reason:** --
- **Block Artifact:** --

---

## Interview State

<!-- AUTHORED. Flattened Lite work — no elicitation interview ran; requirements were captured
     directly into REQUIREMENTS.md/SPEC.md/BLUEPRINT.md/PLAN.md. Kept as a terminal placeholder. -->

**State:** Complete  **Grade:** — (flattened work — requirements captured in BLUEPRINT.md/PLAN.md, not an interview)

---

## Lifecycle History

<!-- AUTHORED -- append-only audit trail. Newest last. -->

| Date | Phase Transition / Gate | Grade | Notes |
|------|------------------------|-------|-------|
| 2026-07-09 | Work created | -- | Initial scaffold (then-current lite path via aid-describe) |
| 2026-07-09 | Definition + task breakdown | -- | 5 sequential tasks (schema → reader read → ship → writers → migrate) |
| 2026-07-09 | Pre-execution gate (old lite LITE-REVIEW) | A+ | Task set graded A+ (D+ → fixed 1H+2M+2L → A+) against the pre-merge codebase |
| 2026-07-10 | Reconciled to flattened Lite-work conventions | -- | After 70895e8b master merge deleted the old lite path + rewrote the reader twins; re-validated plan vs new reader (bug still reproduces; frontmatter+SourceMode still fits), migrated scaffold: tasks/*/SPEC→DETAIL, dropped per-task STATE, created PLAN.md + BLUEPRINT.md, reshaped STATE.md; folded 4 reader-plan updates into DETAILs |
| 2026-07-10 | Flattened gate review — Grade: A+ | A+ | 2-pass gate (doc consistency + task↔gate-criteria) clean on load-bearing invariants; 2 LOW + 2 MINOR fixed (uniform BLUEPRINT trace anchor, task-003→CONFIGURE, stale REQUIREMENTS mention, pause-reason wording); re-gated A+; reader-parse verified |
| 2026-07-10 | Folded in 3 hygiene fixes + pulled v2.1.0 | -- | Added task-006 (§6/section-6 refs) / task-007 (KB closure hygiene) / task-008 (aid --version) per user; merged master v2.1.0 (PR #139) into branch (VERSION+packages=2.1.0) |
| 2026-07-10 | 8-task re-gate — Grade: A+ | A+ | Expanded set re-gated: 1 MED + 3 LOW + 1 MINOR fixed — task-006 re-scoped validate-first/surgical (the "section-6 quality gates" ref is a real concept in authored-visual-catalog, not uniformly dangling); task-007 canonical-edit + re-render discipline; task-008 --version collision (vs existing `--version <v>` pin) + VERSION-file path; STATE pause-reason → 8 tasks; uniform trace annotations; re-gated A+ |
| 2026-07-10 | Schema-enrichment re-gate — Grade: A+ | A+ | STATE frontmatter schema expanded per audit (pipeline{path,initiator} + started/user_approved + KB kb_status/kb_grade/last_kb_review as newly-captured; minimum_grade + KB summary_approved/last_summary as behavior-preserving relocations); task-001/002/004/005 + BLUEPRINT enriched (gate criteria #13/#14). Re-gate caught 1 HIGH + 2 MED (I'd mis-classified minimum_grade + KB approval fields as "never parsed"; task-004 "only Pipeline State" premise was false) + 3 MINOR — all fixed; re-gated A+ |

---

## Deploy State

<!-- AUTHORED by aid-deploy; one row per delivery. -->

| Delivery | State | PR | KB Updated | Tag | Notes |
|----------|-------|----|-----------|-----|-------|
| _none yet_ | | | | | |

---

## Delivery Lifecycle

<!-- AUTHORED -- single-delivery FLATTENED work only. Promoted verbatim from
     delivery-state-template.md. Single writer: this work's active branch. State halts at
     `Specified` pre-execute; aid-execute advances it (Executing → Gated → Done). -->

- **State:** Specified
- **Updated:** 2026-07-10T17:34:53Z
- **Block Reason:** --
- **Block Artifact:** --

### Tasks lifecycle

<!-- AUTHORED -- single-delivery FLATTENED work only. Single-writer home for per-task mutable
     cells, REPLACING the now-absent per-task STATE.md (each task is tasks/task-NNN/DETAIL.md
     only). State enum: Pending | In Progress | In Review | Blocked | Done | Failed | Canceled -->

| Task | State | Review | Elapsed | Notes |
|------|-------|--------|---------|-------|
| task-001 | Pending | -- | -- | -- |
| task-002 | Pending | -- | -- | -- |
| task-003 | Pending | -- | -- | -- |
| task-004 | Pending | -- | -- | -- |
| task-005 | Pending | -- | -- | -- |
| task-006 | Pending | -- | -- | -- |
| task-007 | Pending | -- | -- | -- |
| task-008 | Pending | -- | -- | -- |

---

## Delivery Gate

<!-- AUTHORED -- single-delivery FLATTENED work only. The gate's criteria are read from this
     work's BLUEPRINT.md § Gate Criteria, NOT from this STATE.md. Grade set by the delivery-gate
     review. -->

- **Reviewer Tier:** Small
- **Grade:** A+
- **Issue List:** none
- **Timestamp:** 2026-07-10T17:34:53Z

---

<!-- ============================================================
     DERIVED / READ-ONLY VIEWS -- assembled at read time; never written directly.
     ============================================================ -->

## Features State

<!-- DERIVED -- one row per feature (flattened work has the single implicit feature-001). -->

| # | Feature | Spec State | Spec Grade | Q&A Count | Notes |
|---|---------|------------|------------|-----------|-------|
| _none yet_ | | | | | |

## Plan / Deliveries

<!-- DERIVED -- union of delivery-NNN/STATE.md lifecycle fields. Flattened work authors its single
     delivery's lifecycle directly above in `## Delivery Lifecycle`, not here. -->

| Delivery | State | Tasks | Notes |
|----------|-------|-------|-------|
| _none yet_ | | | |

## Tasks State

<!-- DERIVED -- read-time union. Flattened work: authored cells live above in `### Tasks lifecycle`. -->

| # | Task | Type | Wave | State | Review | Elapsed | Notes |
|---|------|------|------|-------|--------|---------|-------|
| _none yet_ | | | | | | | |

## Delivery Gates

<!-- DERIVED -- union of per-delivery gate blocks. Flattened work's single gate is authored above. -->

_None yet. Flattened work authors its single gate directly above in `## Delivery Gate`._

## Cross-phase Q&A

<!-- DERIVED / work-owner-authored. -->

_None yet._

## Calibration Log

<!-- DERIVED -- union of per-task dispatch logs (L1+L2+L3 traceability). -->

| Date | Agent | Task / Cycle | ETA Band | Actual | Notes |
|------|-------|-------------|----------|--------|-------|

## Dispatches

<!-- DERIVED -- union of per-task dispatch logs. -->

_None yet._
