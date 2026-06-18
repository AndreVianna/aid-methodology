# task-013: Idempotent migration helper (bash + PowerShell twin) + fixture

**Type:** MIGRATE

**Source:** work-004-worktree-tracking → delivery-001

**Depends on:** task-001, task-002

**Scope:**
- Write `migrate-work-hierarchy.sh` (bash) + a PowerShell twin that converts a monolithic `work-NNN-{name}/` to the hierarchy with no data loss:
  - for each task in `## Tasks Status` / each `tasks/task-NNN.md`, create `delivery-NNN/tasks/task-NNN/SPEC.md` (from the flat definition) + `STATE.md` (from the task's State/Review/Elapsed/Notes cells + its `### task-NNN` Quick Check Findings + Dispatches rows). **Derive the `delivery-NNN` token by parsing the task's `**Source:** ... → delivery-NNN` line in `tasks/task-NNN.md`** (the monolithic `## Tasks Status` table has NO delivery column — confirmed; the only task→delivery linkage is the Source line, present in work-001/002/003). Mirror exactly the parse task-003 uses for `--field` delivery resolution. If a task has no parseable Source→delivery token, default to `delivery-001` (the lite-path single delivery) and emit a warning row;
  - for each delivery, create `delivery-NNN/SPEC.md` + `STATE.md` (set the SD-8 lifecycle enum — derive a best-effort initial value from the legacy gate/task state, defaulting to `Executing` for a delivery with tasks or `Pending-Spec` for one with none; carry the `### delivery-NNN` gate block + a `## Cross-phase Q&A` section seeded from any legacy work-level Q&A entries that are delivery-scoped + derived rollup);
  - rewrite the work `STATE.md` so the former `## Tasks Status`/`## Delivery Gates`/`## Quick Check Findings`/`## Dispatches`/`## Cross-phase Q&A` become the derived-view placeholders, only AFTER the per-unit files verify non-empty. Work-level Q&A entries with no clear delivery scope stay in the work `## Cross-phase Q&A` (work-owner-authored) rather than being lost.
- IDEMPOTENT: if the hierarchy already exists, re-running is a no-op (detect per-task STATE.md presence). Honor "state" naming on output; tolerate legacy "Status" on input.
- Provide a migration FIXTURE (a copy of a monolithic work) the helper runs against; do NOT auto-migrate the repo's real works (SD-6).
- ASCII-only; bash + PS in lockstep.

**Acceptance Criteria:**
- [ ] The helper converts a monolithic work fixture to the hierarchy with task/delivery SPEC.md+STATE.md created and no data loss (every task row, gate block, finding, and dispatch is preserved in the per-unit files).
- [ ] Each task is placed under its correct delivery by parsing the `**Source:** ... → delivery-NNN` line of `tasks/task-NNN.md` (same parse as task-003); tasks lacking a parseable token default to `delivery-001` with a warning.
- [ ] Re-running on an already-migrated work is a no-op (idempotent).
- [ ] bash + PowerShell twins produce equivalent results; both ASCII-only.
- [ ] The repo's real existing works are not auto-migrated.
- [ ] All §6 quality gates pass.
