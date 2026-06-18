# work-004 — worktree-aware tracking + hierarchical state partition

- **Name:** Worktree-aware tracking + hierarchical state partition
- **Description:** Restructure AID work artifacts into a uniform work/delivery/task folder hierarchy where every unit owns a `SPEC.md` (definition) + `STATE.md` (mutable state); make every `STATE.md` written by exactly one branch (parents derive); rename "status" to "state" throughout; teach the dashboard reader to discover persistent git worktrees and merge same-work pipelines with no winner.
- **Work:** work-004-worktree-tracking
- **Created:** 2026-06-18
- **Source:** /aid-interview lite path — LITE-FEATURE
- **Status:** Draft

## Goal

Two coupled problems break parallel branch-isolated AID work (confirmed in `ANALYSIS.md`):

1. **Worktree blindness.** The dashboard reader resolves exactly ONE `.aid/` per registered repo root (`dashboard/reader/locator.py:46,85`) and never enumerates git worktrees. Work that lives only on a worktree branch (e.g. mas's `.claude/worktrees/<name>/.aid/work-*`) is invisible on the dashboard.
2. **Monolithic STATE.md collides cross-branch.** The whole `## Tasks Status` + `## Pipeline Status` + `## Quick Check Findings` + `## Calibration Log` + `## Dispatches` + `## Delivery Gates` live in one per-work file that every task of every delivery writes via `writeback-state.sh --field` (`canonical/scripts/execute/writeback-state.sh:197-351`). Two delivery branches → divergent copies + a guaranteed git merge conflict on merge-back. The intra-process sentinel lock (`:156-188`) only serializes the same filesystem; it cannot help cross-branch.

Success: the AID work-artifact layout is a uniform unit hierarchy (work → delivery → task, each a folder with `SPEC.md` + `STATE.md`); each `STATE.md` is written by exactly one branch so merge-back never conflicts on state; parent state is a derived read-only view; the dashboard reader (Python + the Node twin) discovers persistent worktrees and merges same-work pipelines with an explicit no-winner reconcile rule; existing monolithic works (work-001/002/003 + mas's worktree works) keep working unchanged. Minimum grade: A+ (user directive).

## Context

Grounded map and blast radius are in `.aid/work-004-worktree-tracking/ANALYSIS.md`. KB references by INDEX.md doc name: `schemas.md` (§4 Work State, §11 Task File), `project-structure.md`. This SPEC supersedes the ANALYSIS "minimal" placement recommendation (per-task `.status.md` + derived table); the user LOCKED a fuller uniform folder hierarchy instead. The ANALYSIS reconcile-ordering, worktree-discovery (option A `git worktree list --porcelain`), and migration/coexistence recommendations are ADOPTED.

### Design — Pillar 1: Uniform unit hierarchy

Every unit is a FOLDER containing its own `SPEC.md` (immutable definition) + `STATE.md` (mutable state). Tasks nest under their delivery.

```
work-NNN-{name}/
  SPEC.md                              # work-level definition (see mapping below)
  STATE.md                             # work-level state: header + DERIVED views only
  REQUIREMENTS.md                      # full path only — retained unchanged
  PLAN.md                              # full + lite — retained (execution graph lives here)
  features/{feature}/SPEC.md           # full path only — retained unchanged (see mapping)
  delivery-NNN/
    SPEC.md                            # delivery definition (scope, gate criteria)
    STATE.md                           # delivery state: lifecycle + gate + derived task view
    delivery-NNN-issues.md             # retained unchanged (already disjoint, one branch)
    tasks/
      task-NNN/
        SPEC.md                        # task definition (the former tasks/task-NNN.md)
        STATE.md                       # task mutable cells: State/Review/Elapsed/Notes + per-task logs
```

**Mapping of existing work-level artifacts into the uniform pattern (Spec Decision SD-1):**

- **Work `SPEC.md` vs REQUIREMENTS.md + PLAN.md.** Do NOT collapse or rename these. The work-folder `SPEC.md` is the unit's *definition slot* and is what the uniform pattern requires; on the **lite path** it already exists (this work's own SPEC.md) and is the single definition. On the **full path** REQUIREMENTS.md + PLAN.md remain the definition artifacts; the work-folder `SPEC.md` is OPTIONAL there (the reader already resolves identity from REQUIREMENTS.md first, SPEC.md fallback — `reader.py:391-409`). The uniform rule is "a unit MAY have a `SPEC.md` definition slot and MUST have a `STATE.md`"; the work unit's definition may be satisfied by REQUIREMENTS.md+PLAN.md (full) or SPEC.md (lite). No new unit type; no forced migration of full-path definition artifacts.
- **`features/{feature}/` vs `delivery-NNN/`.** These are NOT the same axis and are NOT merged. `features/` is a *specification* decomposition (one SPEC.md per feature, produced by /aid-specify on the full path); `delivery-NNN/` is an *execution* decomposition (one delivery = one mergeable branch, produced by /aid-plan). A feature can span deliveries and a delivery can pull from multiple features. The uniform folder pattern applies to the **execution hierarchy only** (work → delivery → task), because that is where branch-disjoint state lives. `features/{feature}/SPEC.md` stays as-is and gains no `STATE.md` (features have no per-branch mutable state — their progress is tracked in the work-level derived `## Features State` view). This is the boundary that keeps us from inventing extra unit types.

### Design — Pillar 2: Disjoint writes, derived parents

- Each unit's `STATE.md` is written by exactly ONE branch — the branch that owns that delivery/task. A task lives on exactly one delivery branch; a delivery lives on exactly one branch. Therefore no two branches ever write the same `STATE.md`. Merge-back is conflict-free on state because the files are disjoint by construction.
- **Parents carry OWN state + an additive derived child view — they are NOT a pure derivation.** A parent unit's `STATE.md` has two distinct parts: (1) its OWN AUTHORED lifecycle/header state, written by the single branch that owns the unit; (2) an OPTIONAL derived read-only view of its children, assembled at READ time. The two never overlap as write targets, and the derived view is never written.
  - The **delivery `STATE.md` authors the delivery's independent lifecycle** (SD-8 enum: `Pending-Spec | Specified | Executing | Gated | Done | Blocked`) across `aid-plan → aid-specify → aid-execute`. This authored state is the SOURCE of delivery state; the per-task rollup it also carries is ADDITIVE, not the source. **Motivating scenario (why a rollup alone is insufficient — SD-9):** a SPIKE `delivery-001` defines `delivery-002`; `delivery-002` then sits at `Pending-Spec` with ZERO tasks while `delivery-001`'s tasks execute, and is specified (`aid-specify`) only after `delivery-001` concludes. A task-rollup derivation cannot represent a task-less but in-flight delivery — there are no task states to roll up — so the delivery's lifecycle MUST be independently authored.
  - The **work-level `STATE.md`** `## Tasks State` view and the `## Plan / Deliveries` rollup are DERIVED read-only views over the child units; the work header (`## Pipeline State`, Triage, Lifecycle History) is the work owner's OWN authored state. Nothing writes the same cell in two places (kills the drift/double-write smell the ANALYSIS warned about).
  - **Disjoint-write property preserved.** Each delivery writes ONLY its own `delivery-NNN/STATE.md` (+ its tasks' STATE); no two delivery branches write the same file. The work-level pipeline/header is authored solely by the work owner on the work's active branch (or derived), never co-written by sibling deliveries.
- `writeback-state.sh --field` retargets: instead of editing a row in the work `STATE.md` `## Tasks Status` table, it writes the named field into `delivery-NNN/tasks/task-NNN/STATE.md`. `--findings` retargets to the task's `STATE.md`. `--delivery-id --block` (gate) retargets to `delivery-NNN/STATE.md`. `--pipeline` continues to target the work `STATE.md` header (work-level lifecycle, one writer at a time — the orchestrator on the work's active branch). `--append-issue` is unchanged (already disjoint).
- **Cross-phase Q&A is partitioned per delivery.** The work-level `## Cross-phase Q&A` is a SECOND multi-writer hazard: the aid-execute delivery-gate, running on a delivery branch, writes SPEC Q&A entries to it (`state-delivery-gate.md:278`). Two delivery branches appending Q&A to the shared work file collide exactly like the Tasks table. Fix: the delivery gate writes its Q&A into the delivery's OWN `STATE.md` (`delivery-NNN/STATE.md` `## Cross-phase Q&A` section — one writer per branch); the work-level `## Cross-phase Q&A` view is DERIVED at read time as the union of each delivery's Q&A plus any work-owner-authored entries (the work owner may still author work-level Q&A on the active branch — single writer). KB Q&A is untouched (it targets `.aid/knowledge/STATE.md`, a separate file). This keeps the disjoint-write property: no two delivery branches write the same file.

### Design — Pillar 3: "state", not "status"

- Files are `STATE.md` (already true). Sections/fields use "state": the old `## Tasks Status` → derived `## Tasks State`; `## Pipeline Status` → `## Pipeline State`; `## Features Status` → `## Features State`; `## Interview Status` → `## Interview State`; `## Deploy Status` → `## Deploy State`; per-task field "Status" → "State". The closed enum VALUES are unchanged (Pending | In Progress | In Review | Blocked | Done | Failed | Canceled). Applied across `work-state-template.md` (split into per-level templates), the EXECUTE `writeback-state.sh` (`canonical/scripts/execute/writeback-state.sh` + its 5 generated profile copies under `profiles/*/.../aid/scripts/execute/` + the `.claude/aid/scripts/execute/` dogfood copy; nested under `aid/` since work-003 #93), `schemas.md`, `project-structure.md`, and the reader (Python + Node parsers and emitted field names).
- **The summarize `writeback-state.sh` is EXCLUDED.** `canonical/scripts/summarize/writeback-state.sh` (and its profile/dogfood copies) is a DIFFERENT, much smaller script (~5 KB vs ~34 KB): it only appends `## Summarization History` entries to `.aid/knowledge/STATE.md` and has none of the `--field`/`--findings`/`--block`/`--task-id`/`--pipeline` modes. It does not touch the work `## Tasks Status` table or any renamed section, so it receives NO part of the task-003 retarget or the state-naming change. The two scripts are not twins; treating them as byte-identical would corrupt the summarize path.

### Design — Pillar 4: Worktree-aware discovery

- For each registered repo root, run read-only `git -C <root> worktree list --porcelain`. Parse `worktree <path>` and `branch refs/heads/<branch>` lines. For each worktree path, locate its `.aid/` and enumerate `work-*` folders; aggregate all pipelines under the project, each labeled by branch.
- **Invocation pattern (matches the existing KB-freshness git path).** The new `worktree list` call uses the SAME read-only, fixed-args, no-shell subprocess pattern the reader already uses for KB freshness: Python `subprocess.run(["git", "-C", root, "worktree", "list", "--porcelain"], ...)` (twin of `derivation.py` `_run_git_log`), Node `runGitCommand(["-C", root, "worktree", "list", "--porcelain"], ...)` via `execFileSync` (`reader.mjs:525-544`). The verb is HARD-CODED in the argv; there is no shell and no user-supplied verb, so the call is safe by construction — independent of any allow-list.
- **Allow-list status (corrects an earlier false premise).** There is currently NO ENFORCED git-verb allow-list to extend: the Node `runGitCommand` has none, and Python's `_GIT_ALLOWED_VERBS` (`derivation.py:101`) is *defined but never referenced* (documentary only). So worktree discovery does NOT depend on adding `worktree` to an allow-list. IF a verb-guard is wanted as hardening (defense-in-depth so future edits can't smuggle a write verb), task-010 must FIRST make it real: in Python, actually enforce `_GIT_ALLOWED_VERBS` at the call site and add `worktree` to it; in Node, introduce an equivalent guarded runner and add `worktree`. Either way the discovery call's correctness rests on the fixed-argv pattern, not on the guard's prior existence. Precedent: the reader already shells out read-only git for KB freshness (rev-parse/symbolic-ref/log).
- `locator.py`'s "stat+iterdir only" contract (`:1-7`) is relaxed to "stat+iterdir + read-only `git worktree list` enumeration"; the comment is updated. The locator emits a list of `(branch_label, aid_dir)` roots; `read_repo` reads each root and merges (server unchanged — enumeration lives in the locator/read_repo layer).
- **Degrade:** if git is unavailable, the root is not a git repo, or the subprocess times out (2 s bound, same as KB freshness) → fall back to the main root only (current behavior). Never throws.
- Target the worktrees that `git worktree list` reports (the PERSISTENT host worktrees like mas's `.claude/worktrees/<name>`). The ephemeral per-task `.aid/.worktrees/task-NNN/` are NOT special-cased — `git worktree list` reports whatever git tracks, and same-work reconcile (Pillar 5) collapses duplicates, so an ephemeral worktree that still has a registered branch merges into its work harmlessly.
- **Node twin parity:** `dashboard/server/reader.mjs` mirrors the enumeration (same fixed-argv `worktree list --porcelain` call), the degradation matrix, the merge, and — IF the hardening guard is adopted — the equivalent guarded runner; byte-for-byte equivalent model output (existing parity test gate).

### Design — Pillar 5: Same-work reconcile (merge, no winner)

When a `work_id` appears in N worktrees + main, the reader UNIONS them into one work model:

- **Per task:** take the MOST-ADVANCED `State` across all copies of that task row.
- **Work-level `## Pipeline State`:** take the copy with the newest `Updated:` timestamp; on a timestamp tie, break deterministically by a stable secondary key (branch-label lexical sort, main root first) so the merge is order-independent.
- **Derived views (`## Tasks State`, gates, findings):** union the per-task/per-delivery contributions across worktrees; there is no winner, the view is the union.

**State advancement ordering (Spec Decision SD-2 — LOCKED):**

```
Done  >  In Review  >  In Progress  >  Blocked  >  Failed  >  Pending
```

Rationale: the dashboard answers "how far has this work gotten across all branches"; advancement is forward progress, so a task that reached `Done` on one branch outranks a copy still `In Progress` elsewhere. `In Review` is past `In Progress`. `Blocked` and `Failed` are ranked ABOVE `Pending` because they represent work that was attempted and surfaced a problem (more informative than "not started"); `Blocked` outranks `Failed` because a blocked task is recoverable-in-place whereas a failed task implies a completed-but-rejected attempt that a parallel branch may already have superseded — surfacing "blocked, needs attention" is the more actionable signal than a stale "failed". `Canceled` is treated as terminal-equal-to-`Done` for ordering (a canceled task is resolved, not pending) but retains its own label; ranked just below `Done`. This ordering is encoded once and shared by both reader twins (Spec Decision: ship it as a single ordered enum list each twin reads).

### Design — Pillar 6: Migration / coexistence

- **Reader tolerance (both twins):** for each work, if the hierarchy is present (a `delivery-NNN/tasks/task-NNN/STATE.md` exists) → derive views from the per-unit files. ELSE parse the legacy monolithic `STATE.md` inline tables (current behavior; reader is already fallback-tolerant — `reader.py:363-377`). Detection is presence-based and per-work, so a repo with mixed-vintage works renders all of them.
- **Migration helper (idempotent):** a script `migrate-work-hierarchy.sh` (bash + PowerShell twin) that, given a monolithic `work-NNN-{name}/`, creates `delivery-NNN/tasks/task-NNN/{SPEC,STATE}.md` from the existing flat `tasks/task-NNN.md` + the rows of `## Tasks Status` / `## Quick Check Findings` / `## Dispatches`, and rewrites the work `STATE.md` derived sections. Re-running is a no-op when the hierarchy already exists. No data loss: the source files are moved (task definition) / copied-then-derived (state cells); the legacy monolithic sections are replaced by the derived views only after the per-unit files verify non-empty. Existing works (work-001/002/003) are NOT auto-migrated by this SPEC's tasks — migration is opt-in/idempotent and validated on a fixture; new works adopt the hierarchy via /aid-detail and /aid-plan.

### Append-only logs

Per-unit `STATE.md` owns its own log; aggregate at read (consistent with Pillar 2, no overbuild):

- `## Calibration Log` and `## Dispatches`: a per-task dispatch produces rows that belong to that task → they live in the task's `STATE.md` (`## Dispatch Log` per-task section). The work-level `## Calibration Log` / `## Dispatches` views are DERIVED (union of child logs) at read time. No cross-branch append-merge needed.
- `## Lifecycle History`: phase transitions are work-level events written by the orchestrator on the work's active branch (one writer) → stays in the work `STATE.md`, append-only, no partition needed (the work header is already single-writer, newest-`Updated:`-wins on reconcile).

## Acceptance Criteria

- [ ] Every new unit (work/delivery/task) created by the AID skills is a folder with a `STATE.md`; delivery and task units additionally carry a `SPEC.md` definition. (AC-Hierarchy)
- [ ] No two branches write the same `STATE.md` file: the task `STATE.md` is written only by its delivery branch; the delivery `STATE.md` only by its delivery branch (including the delivery gate's `## Cross-phase Q&A` and gate block); the work header only by the work's active branch. No work-level multi-writer section remains: the delivery-gate-written `## Cross-phase Q&A` is moved to `delivery-NNN/STATE.md`, `## Delivery Gates` to `delivery-NNN/STATE.md` (SD-5), and Calibration/Dispatch logs derive (SD-4). Demonstrated by a two-branch fixture (each branch with its own delivery Q&A + gate) that merges back with zero conflict on state files. (AC-Disjoint)
- [ ] The work-level `## Tasks State`, `## Plan / Deliveries` rollup, `## Cross-phase Q&A`, and `## Delivery Gates` are DERIVED at read time (union of per-delivery/per-task contributions plus work-owner-authored work-level Q&A) and are never a write target. No field is stored in two places. (AC-Derived)
- [ ] The delivery `STATE.md` authors an INDEPENDENT lifecycle (SD-8 enum `Pending-Spec | Specified | Executing | Gated | Done | Blocked`) written across `aid-plan → aid-specify → aid-execute`, distinct from (not derived from) its task rollup. A delivery can be `Pending-Spec` with ZERO tasks while a sibling delivery's tasks are `In Progress`; both render correctly with NO shared-file write (the SPIKE-defines-sibling scenario). (AC-DeliveryLifecycle)
- [ ] All section/field naming uses "state" not "status" across templates, the EXECUTE `writeback-state.sh` (canonical + 5 profile copies + the `.claude/` dogfood copy), `schemas.md`, `project-structure.md`, `dashboard/home.html` user-facing labels, and both reader twins. The summarize `writeback-state.sh` is EXCLUDED (different script; only `## Summarization History`). Closed enum VALUES unchanged. (AC-Naming)
- [ ] The dashboard reader enumerates persistent worktrees via read-only `git -C <root> worktree list --porcelain` using the existing fixed-argv / no-shell subprocess pattern (twin of the KB-freshness git call), aggregates each worktree's `.aid/work-*` pipelines labeled by branch, and degrades to the main root when git is unavailable/non-git/times out. The verb is hard-coded in argv (safe by construction); no pre-existing allow-list is assumed. IF the optional hardening verb-guard is adopted, it is actually ENFORCED at the call site in both twins with `worktree` permitted. (AC-Worktree)
- [ ] When a `work_id` appears across N worktrees/main, the reader merges with no winner: per-task most-advanced State by the SD-2 ordering; work-level Pipeline State by newest `Updated:`, ties broken by a stable branch-label secondary key (order-independent). (AC-Reconcile)
- [ ] The reader (both twins) renders BOTH legacy monolithic works and new hierarchical works in the same repo, detected per-work by presence of the per-task `STATE.md`. (AC-Coexist)
- [ ] An idempotent migration helper (bash + PS) converts a monolithic work to the hierarchy with no data loss; re-running is a no-op. Validated on a fixture. (AC-Migrate)
- [ ] Node↔Python reader parity holds (identical model output) on the new fixtures. (AC-Parity)
- [ ] `tests/run-all.sh` is green; render-drift is clean via the full generator (`run_generator.py`); shipped scripts are ASCII-only; bash and PowerShell twins stay in lockstep. (AC-Gates)

## Spec Decisions

- **SD-1 (work-level artifact mapping):** Do not collapse REQUIREMENTS.md/PLAN.md/features into the uniform pattern. The uniform pattern governs the execution hierarchy (work → delivery → task). A unit MUST have `STATE.md` and MAY have a `SPEC.md` definition; the work unit's definition is satisfied by SPEC.md (lite) or REQUIREMENTS.md+PLAN.md (full). `features/{feature}/` is a spec-axis decomposition, keeps its `SPEC.md`, gains no `STATE.md`; feature progress is a work-level derived `## Features State` view. No new unit types.
- **SD-2 (state advancement ordering — LOCKED):** `Done > In Review > In Progress > Blocked > Failed > Pending`; `Canceled` ranks just below `Done` (terminal-resolved). Rationale in Pillar 5.
- **SD-3 (worktree discovery — adopt ANALYSIS option A):** `git worktree list --porcelain` via the existing fixed-argv / no-shell subprocess pattern (verb hard-coded, safe by construction), additive enumeration in the locator/read_repo layer, 2 s timeout, degrade to main root. There is no enforced git-verb allow-list today (Node has none; Python `_GIT_ALLOWED_VERBS` is documentary, never referenced); discovery does not depend on one. Adding/enforcing an allow-list is OPTIONAL hardening owned by task-010/task-012 — if taken, the guard must be made real (enforced at the call site) in both twins, with `worktree` permitted.
- **SD-4 (append-only logs):** per-unit `STATE.md` owns its own log; work-level Calibration/Dispatch views derive at read. Lifecycle History stays work-level (single writer).
- **SD-5 (delivery STATE.md content):** the delivery `STATE.md` carries the delivery's INDEPENDENT lifecycle state (SD-8 enum) + the gate block (former `## Delivery Gates ### delivery-NNN`) + its `## Cross-phase Q&A` (the delivery-gate's SPEC Q&A, moved off the shared work file) + a DERIVED task rollup. This makes `--delivery-id --block` and the gate's Q&A write both retarget to a single-writer file and removes the gate + delivery-scoped Q&A from the shared work file. `delivery-NNN-issues.md` stays as the deferred-[HIGH] log (already disjoint). The work-level `## Cross-phase Q&A` and `## Delivery Gates` become DERIVED unions of the per-delivery contributions (plus work-owner-authored work-level Q&A).
- **SD-6 (migration is opt-in):** this work ships the idempotent helper + reader tolerance; it does NOT auto-migrate the repo's existing works. New works adopt the hierarchy.
- **SD-7 (work-004's own task files use the CURRENT flat layout):** the hierarchy is what this work BUILDS; the task files for work-004 live at `.aid/work-004-worktree-tracking/tasks/task-NNN.md` (flat). Do not bootstrap into the not-yet-existent structure.
- **SD-8 (delivery lifecycle enum — the delivery's OWN authored state):** the delivery `STATE.md` authors an independent delivery-state enum, written across the pipeline: `Pending-Spec | Specified | Executing | Gated | Done | Blocked`. `aid-plan` creates the delivery folder with state `Pending-Spec` (a delivery may exist with ZERO tasks, awaiting `aid-specify`); `aid-specify` advances it to `Specified`; `aid-execute` advances `Executing` → `Gated` (delivery gate running) → `Done`, or `Blocked` on an impediment. This authored state is NOT a derivation of child task states — see SD-9.
- **SD-9 (deliveries have an INDEPENDENT lifecycle — refinement):** the per-delivery `STATE.md` is justified by independent delivery state, NOT by a derived task rollup. A parent unit's `STATE.md` = its own authored lifecycle PLUS an optional additive derived child view. The canonical case the model must represent: a SPIKE delivery defining a sibling delivery that is `Pending-Spec` with zero tasks while the first delivery's tasks are `In Progress` — both render correctly with no shared-file write. A pure task-rollup cannot express a task-less in-flight delivery; hence delivery state is independently authored across `aid-plan → aid-specify → aid-execute`, and the rollup is additive.

## Tasks

> Each `tasks/task-NNN.md` uses `**Source:** work-004-worktree-tracking → delivery-001` (lite path uses `delivery-001`). Single-typed, dependency-ordered.

| Task | Type | Title |
|------|------|-------|
| task-001 | DESIGN | Per-level STATE/SPEC template set + naming contract (state-not-status) |
| task-002 | DOCUMENT | KB update: schemas.md + project-structure.md for the hierarchy + naming |
| task-003 | REFACTOR | writeback-state.sh canonical: retarget --field/--findings/--block to per-unit STATE; state naming |
| task-004 | REFACTOR | Propagate EXECUTE writeback-state.sh to its 5 profile copies + dogfood copy (render-drift); summarize EXCLUDED |
| task-005 | REFACTOR | aid-detail: create task folders (SPEC.md + STATE.md) under delivery; new paths |
| task-006 | REFACTOR | aid-plan: create delivery folders (SPEC.md + STATE.md); Plan/Deliveries derived view |
| task-007 | REFACTOR | aid-execute: read task SPEC at new path, write task STATE, STATE-detection routing |
| task-008 | REFACTOR | aid-interview lite path: scaffold work folder per uniform pattern |
| task-009 | IMPLEMENT | Reader (Python): hierarchical per-unit STATE derivation + legacy fallback |
| task-010 | IMPLEMENT | Reader (Python): worktree enumeration (git worktree list, fixed-argv) + degrade + optional verb-guard |
| task-011 | IMPLEMENT | Reader (Python): same-work reconcile (SD-2 ordering, newest-Updated) |
| task-012 | IMPLEMENT | Reader (Node twin reader.mjs): mirror tasks 009-011 for parity |
| task-013 | MIGRATE | Idempotent migration helper (bash + PowerShell twin) + fixture |
| task-014 | TEST | Reader test fixtures: hierarchical work, legacy work, multi-worktree, reconcile |
| task-015 | TEST | Cross-cutting: two-branch disjoint-merge proof, parity, render-drift, run-all green |

## Execution Graph

### Task Dependencies

| Task | Depends On |
|------|------------|
| task-001 | — (none) |
| task-002 | task-001 |
| task-003 | task-001 |
| task-004 | task-003 |
| task-005 | task-001, task-002 |
| task-006 | task-001, task-002 |
| task-007 | task-003, task-005, task-006 |
| task-008 | task-005, task-006 |
| task-009 | task-001, task-002 |
| task-010 | task-009 |
| task-011 | task-009, task-010 |
| task-012 | task-009, task-010, task-011 |
| task-013 | task-001, task-002 |
| task-014 | task-009, task-010, task-011, task-013 |
| task-015 | task-004, task-007, task-008, task-012, task-013, task-014 |

### Can Be Done In Parallel

| Wave | Tasks |
|------|-------|
| 1 | task-001 |
| 2 | task-002, task-003 |
| 3 | task-004, task-005, task-006, task-009, task-013 |
| 4 | task-007, task-008, task-010 |
| 5 | task-011 |
| 6 | task-012, task-014 |
| 7 | task-015 |

## Revision History

| Date | Change | Source |
|------|--------|--------|
| 2026-06-18 | Initial lite-path SPEC created (LITE-FEATURE) | /aid-interview → architect; locked decisions from design discussion |
| 2026-06-18 | A+ pre-execution fix cycle: summarize EXCLUDED from writeback propagation (#1); corrected the false git-verb-allow-list premise to a fixed-argv pattern + optional hardening (#2); partitioned Cross-phase Q&A to delivery STATE (#3); re-waved task-014 to W6 (#4); task-013 delivery derivation from Source line (#5); home.html consumer added (#6); Pipeline-State tie-break (#7); lock-scope note (#8). Folded user refinement: SD-8 delivery lifecycle enum + SD-9 independent delivery lifecycle (SPIKE-defines-sibling). | architect, against A+ ledger `work-004-design.md` + user design refinement |
