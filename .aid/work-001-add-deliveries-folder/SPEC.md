# Delivery-Folder Layout — Refactor

- **Name:** Rationalize Delivery-Folder Layout — Nest for Full, Flatten for Lite
- **Description:** Relocate full-path `delivery-NNN/` folders into a new `deliveries/` parent mirroring `features/`, and for the single-delivery lite path drop the delivery folder entirely so tasks live directly under `work-NNN/tasks/`, while `PLAN.md` stays at the work root
- **Work:** work-001-add-deliveries-folder
- **Created:** 2026-07-08
- **Source:** /aid-describe lite path — LITE-REFACTOR
- **Status:** Ready

## Goal

Two related fixes to the per-work delivery-folder layout:

1. **Full path — nest under `deliveries/`.** Today `/aid-plan` creates `delivery-NNN/`
   folders **flat** at the work root (`.aid/work-NNN/delivery-NNN/`), while features live
   tidily under a `features/` parent. This refactor moves delivery folders into a new
   `deliveries/` parent (`.aid/work-NNN/deliveries/delivery-NNN/`), exactly parallel to
   `features/`.
2. **Lite path — drop the redundant delivery layer.** A lite work always has **exactly one
   delivery** (`delivery-001`), so the delivery folder is pure ceremony. For lite works,
   tasks move **directly under the work folder** (`.aid/work-NNN/tasks/task-NNN/`) — no
   `deliveries/` and no `delivery-NNN/`. The single delivery's gate result and delivery-scoped
   Q&A are authored in the **work-root `STATE.md`** (for a lite work, the work *is* the
   delivery), and the tasks rollup derives from `work-NNN/tasks/*`.

`PLAN.md` — the work-level roadmap — stays at the work root as the counterpart to
`REQUIREMENTS.md` (which sits above `features/`). The change is a **clean cutover**: every
consumer is updated to the new layout, the old flat `delivery-NNN/`-at-work-root layout is
not retrofitted, and there is no new data migration.

## Context

**Scope** — everywhere the per-work delivery-folder location is created, traversed, or
documented, update it to the new layout (full → `deliveries/delivery-NNN/`; lite →
`tasks/` directly under the work folder):

- **`canonical/` (single source of truth; renders into 5 profiles + dogfood `.claude/`):**
  - *Full-path creators/readers* — aid-plan (`first-run-loop.md`, `SKILL.md`,
    `review-deliverables.md`, `reviewer-brief.md`), aid-detail delivery-hierarchy generation
    (`task-decomposition.md`, `first-run.md`, `execution-graph-generation.md`, `review.md`,
    `reviewer-brief.md`, `SKILL.md`) → `deliveries/delivery-NNN/`.
  - *Lite-path creators* — aid-describe lite path, **including `aid-describe/SKILL.md`** (whose
    State Detection + dispatch logic keys off `delivery-001/tasks/` — e.g. "delivery-001/tasks/
    absent → TASK-BREAKDOWN", "writes delivery-001/ hierarchy") plus `state-task-breakdown.md`,
    recipe-emit scaffold in `state-triage.md`, `state-condensed-intake.md`, `state-lite-*` refs:
    emit `work-NNN/tasks/task-NNN/` and author the single gate/Q&A in the work-root `STATE.md`
    (no `delivery-001/` folder).
  - *Readers/traversers* — aid-execute (`state-execute.md`, `state-review.md`,
    `state-delivery-gate.md`, `reviewer-brief.md`, `README.md`, `SKILL.md`), aid-deploy
    (`state-packaging.md`, `state-selecting.md`, `README.md`), aid-housekeep, aid-monitor.
    aid-execute gates a lite work at the **work level** (no delivery-001 close). Grep broadly
    (`delivery-\d`, `delivery-*`, `delivery-NNN`, folder-traversal globs).
  - *Templates* — work-state, delivery-spec, delivery-state, task-spec, task-state, package,
    delivery-issues, `delivery-plans/task-template`, lite-spec.
  - *Scripts* — `writeback-state.sh`, `complexity-score.sh`, `compute-block-radius.sh`, and
    `migrate-work-hierarchy.sh/.ps1` (emitted target string only — a code edit, NOT a new
    data migration).
  - *Agents* — aid-architect boilerplate.
- **Dashboard reader twins** — `dashboard/reader/*.py` (locator/parsers/reader) +
  `dashboard/server/reader.mjs`: detect **both** enumeration shapes — lite-flat
  (`work-NNN/tasks/task-NNN/`) and full-nested (`work-NNN/deliveries/delivery-NNN/tasks/…`).
  Both twins change in lockstep and remain byte-parity.
- **`profiles/` (5 trees) + dogfood `.claude/`** — re-rendered via `generate-profile`; dogfood
  resynced from `profiles/claude-code/` (`test-dogfood-byte-identity` enforces).
- **Tests** — new fixtures in both layouts; update existing dashboard/parse tests **and the
  execute-phase script tests that embed flat delivery fixtures** (`tests/canonical/test-writeback-state.sh`,
  `test-delivery-gate-aggregate.sh`, and any `complexity-score`/`compute-block-radius` tests).
- **KB docs** — `project-structure.md`, `artifact-schemas.md`, `pipeline-contracts.md`.

**Before:** `features/` holds `feature-NNN/`, but deliveries are dumped flat at the work root
(`work-NNN/delivery-NNN/`) — and even the lite path, which only ever has one delivery, carries
a redundant `delivery-001/` folder. `PLAN.md` is at the work root.

**After:**
- **Full:** `work-NNN/deliveries/delivery-NNN/tasks/task-NNN/`, mirroring `features/feature-NNN/`.
  `deliveries/` holds only the `delivery-NNN/` subfolders.
- **Lite:** `work-NNN/tasks/task-NNN/` — no `deliveries/`, no `delivery-NNN/`; the single gate
  result + delivery Q&A are authored in the work-root `STATE.md`.
- `PLAN.md` stays at `work-NNN/PLAN.md`; `delivery-NNN-issues.md` stays a work-root sibling file
  (only the folder moves).
- Consumers understand **only** the new layouts (clean cutover); no new migration; pre-upgrade
  in-flight works are not retrofitted (the repo has zero in-flight works, so this is a no-op).

**KB references:** `project-structure.md` (workspace layout), `artifact-schemas.md`
(delivery/task artifact locations), `pipeline-contracts.md` (inter-phase path contracts).

## Acceptance Criteria

**Full path — nesting:**
- [ ] `/aid-plan` and the full path emit delivery folders at `work-NNN/deliveries/delivery-NNN/` (never flat at the work root).
- [ ] `PLAN.md` stays at `work-NNN/PLAN.md`; `delivery-NNN-issues.md` stays a work-root sibling file.

**Lite path — flatten:**
- [ ] The lite path emits tasks directly at `work-NNN/tasks/task-NNN/` — no `deliveries/` and no `delivery-NNN/` folder for lite works.
- [ ] For lite works, the single delivery's gate result + delivery-scoped Q&A are authored in the work-root `STATE.md`; the tasks rollup derives from `work-NNN/tasks/*`.

**Consumers & cutover:**
- [ ] All pipeline consumers (aid-detail, aid-execute, aid-deploy, aid-housekeep, aid-monitor) traverse the correct location per path (full → `deliveries/delivery-NNN/`, lite → `tasks/`); aid-execute gates a lite work at the work level.
- [ ] Dashboard reader twins (Python `dashboard/reader/*` + Node `dashboard/server/reader.mjs`) detect BOTH enumeration shapes (lite-flat and full-nested), stay in byte-parity, and new fixtures for both layouts pass in both.
- [ ] Templates, scripts (`writeback-state`, `complexity-score`, `compute-block-radius`, `migrate-work-hierarchy`), agent boilerplate, and KB docs (`project-structure`, `artifact-schemas`, `pipeline-contracts`) reflect the new layouts.
- [ ] Clean cutover: no new data migration; the old flat `delivery-NNN/`-at-work-root layout is not supported.

**Build, sweep & gates:**
- [ ] `generate-profile` re-renders all 5 profiles from `canonical/`; dogfood `.claude/` resynced from `profiles/claude-code/`; `test-dogfood-byte-identity` passes.
- [ ] Grep-clean (fix-everywhere): no lingering references to the old flat `work-NNN/delivery-NNN/` folder convention (excluding the legitimate `delivery-NNN-issues.md` sibling file).
- [ ] All existing tests pass (no behavior regression).
- [ ] All project quality gates pass.

## Tasks

> Tasks live under `tasks/task-NNN/SPEC.md` directly under the work folder (lite layout — no
> `delivery-001/` folder); each task folder also contains `STATE.md` for mutable task state.
> The table below is the navigational index.
>
> _(This work was migrated to the new lite-flat layout it introduces — dogfooding the change;
> the single delivery's lifecycle + gate are authored in the work-root STATE.md.)_

| Task | Type | Title |
|------|------|-------|
| task-001 | REFACTOR | Relocate delivery-folder layout across canonical + KB (nest full, flatten lite), then re-render |
| task-002 | REFACTOR | Update dashboard reader twins for both delivery-folder layouts |
| task-003 | TEST | Fixtures + tests for both delivery-folder layouts |

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | — (none) |
| task-003 | task-001, task-002 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001, task-002 |
| 2 | task-003 |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-07-08 | Initial lite-path SPEC created | /aid-describe LITE-REFACTOR |
| 2026-07-08 | Added lite-path flatten (drop redundant delivery-001 folder; single gate/Q&A → work-root STATE.md) | /aid-describe TASK-BREAKDOWN (user scope addition) |
