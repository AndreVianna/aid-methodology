# Full-Path Pipeline Structural Rename

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-08 | Feature created from the STRUCTURE/NAMING amendment (§5.7 FR-15/FR-16, §9 AC-15/AC-16, §8 A-10, §4 Scope). Owns the shipped full-path pipeline rename — delivery `SPEC.md` → `BLUEPRINT.md`, task `SPEC.md` → `DETAIL.md`, deliveries grouped under `deliveries/` — plus the shipped delivery-gate criteria mis-wire fix. Clean switch, no migration (A-10). Seam with feature-001 (short/flat layout) | /aid-specify (user amendment) |

## Source

- REQUIREMENTS.md §5.7 (FR-15, FR-16)
- REQUIREMENTS.md §9 (AC-15 — full-path half; AC-16)
- REQUIREMENTS.md §4 (In Scope — Full-path pipeline structural rename)
- REQUIREMENTS.md §8 A-10 (no migration / no backward-compatibility)
- REQUIREMENTS.md C-1, C-4, C-5, C-8, NFR-1, NFR-3, D-1

## Description

The shipped full-path pipeline (`aid-plan` → `aid-detail` → `aid-execute`, plus the dashboard
reader twins) writes and reads three definition documents all named `SPEC.md` — feature, delivery,
and task — an overload that collided in the dashboard readers (a `SPEC.md` could be any of the
three). Adopt one naming convention across the full path: feature definitions stay `SPEC.md`,
delivery definitions become `BLUEPRINT.md`, task definitions become `DETAIL.md`; and group each
work's deliveries under a `deliveries/` wrapper so a work is
`deliveries/delivery-NNN/{BLUEPRINT.md, STATE.md, tasks/task-NNN/{DETAIL.md, STATE.md}}`.

This refactors the shipped `aid-plan`, `aid-detail`, `aid-execute`, the delivery/task templates,
both dashboard reader twins (`reader.py` + `reader.mjs`), and the existing canonical tests, and
fixes the shipped **delivery-gate criteria mis-wire** — the gate now reads its criteria from
`BLUEPRINT.md § GATE CRITERIA` (the delivery definition already carries them), not from a
non-existent `PLAN.md` criteria block.

Per **A-10** this is a **clean switch**: the consumers adopt the new layout and drop the old nested
`delivery-NNN/SPEC.md` / task `SPEC.md`; no migration, no dual old/new code path, no mixed-vintage
fixtures, no MIGRATE-type work. Coordinated with **feature-001**: feature-001 owns the **short/flat**
layout (`BLUEPRINT.md`/`DETAIL.md` at the work root, promoted `STATE.md` blocks) and its reader
support; feature-015 owns the **full** layout rename and its reader support — together the reader
twins support both new layouts and no others.

## User Stories

- As an AID maintainer, I want the full path to name delivery defs `BLUEPRINT.md` and task defs
  `DETAIL.md` (feature defs stay `SPEC.md`) so the dashboard readers stop colliding on the
  `SPEC.md` overload.
- As an AID maintainer, I want each work's deliveries grouped under `deliveries/` so the on-disk
  hierarchy is unambiguous and both reader twins resolve it cleanly.
- As an AID maintainer, I want the delivery gate to read its criteria from
  `BLUEPRINT.md § GATE CRITERIA` so the shipped mis-wire (reading a non-existent `PLAN.md` criteria
  block) is fixed and the gate grades against the criteria the delivery actually declares.

## Priority

Must

## Acceptance Criteria

- [ ] Given the full path, when a work is planned, detailed, and executed, then it produces
  `deliveries/delivery-NNN/{BLUEPRINT.md, STATE.md, tasks/task-NNN/{DETAIL.md, STATE.md}}`, and
  `aid-plan` / `aid-detail` / `aid-execute`, the templates, both dashboard reader twins, and the
  existing tests resolve the new paths with **no** reference to the old `delivery-NNN/SPEC.md` or
  task `SPEC.md`. (AC-16 — structure half; FR-16)
- [ ] Given the full path, when the delivery gate runs, then it reads its criteria from
  `BLUEPRINT.md § GATE CRITERIA` (not a `PLAN.md` block); `tests/run-all.sh` + `render-drift` are
  green. (AC-16 — gate-criteria-fix half; FR-16)
- [ ] Given a produced full-path work, when a grep checks artifact naming, then no `SPEC.md` names
  a delivery or a task — delivery definitions are `BLUEPRINT.md`, task definitions are `DETAIL.md`,
  feature definitions remain `SPEC.md`. (AC-15 — full-path half; FR-15)
- [ ] Given A-10, when the consumers/tests are inspected, then none retains support for the
  pre-rename nested `delivery-NNN/SPEC.md` layout — a clean switch with no migration, no dual
  old/new path, and no mixed-vintage reader fixtures. (A-10; FR-16)
- [ ] Given `aid-plan` / `aid-detail` / `aid-execute` are skills deliberately changed under §5.7,
  when `aid-reviewer` reviews them, then each scores >= the resolved `minimum_grade` (A+) before
  shipping; `run_generator.py` re-renders clean and the dogfood `.claude/` is byte-identical.
  (AC-7 — subset; AC-6)

---

## Technical Specification

> Grounded by grep against the shipped pipeline (paths/symbols cited inline are on-disk today).
> This feature owns the **full-path** rename + `deliveries/` grouping + the delivery-gate
> criteria-home fix. It coordinates the seam with **feature-001** (short/flat layout + its reader
> support). The `aid-describe` **lite** reference files that also carry old `delivery-NNN/` paths
> (`state-condensed-intake.md`, `state-lite-*.md`, `state-triage.md`, `state-task-breakdown.md`)
> are **feature-002/013**'s (deleted/rewired there), **not** renamed here. KB prose that names the
> old paths (`pipeline-contracts.md § The On-Disk Work Hierarchy`, `artifact-schemas.md § Task
> SPEC.md` / `§ Delivery STATE.md`) is a **flagged KB/tech-writer follow-up** (same treatment as
> feature-002's KB churn), out of this feature's code scope.

### The rename (semantics)

| Definition | Old (shipped) | New | Location (full path) |
|---|---|---|---|
| Feature | `SPEC.md` | `SPEC.md` (unchanged) | `features/feature-NNN-<name>/SPEC.md` |
| Delivery | `delivery-NNN/SPEC.md` | `BLUEPRINT.md` | `deliveries/delivery-NNN/BLUEPRINT.md` |
| Task | `delivery-NNN/tasks/task-NNN/SPEC.md` | `DETAIL.md` | `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` |

The delivery `STATE.md` and per-task `STATE.md` keep their names; only the **definition** files are
renamed and the delivery folders gain the `deliveries/` parent. The new full-path work hierarchy:

```
.aid/work-NNN-<name>/
  STATE.md
  REQUIREMENTS.md
  features/feature-NNN-<name>/SPEC.md
  PLAN.md                     deliverables + per-delivery #### Execution Graph
  deliveries/
    delivery-NNN/
      BLUEPRINT.md            objective, scope, GATE CRITERIA, tasks, deps
      STATE.md                delivery lifecycle + Delivery Gate + Q&A + Tasks State (DERIVED)
      tasks/task-NNN/{DETAIL.md, STATE.md}
```

### Templates (`canonical/aid/templates/`)

| File | Change |
|---|---|
| `delivery-spec-template.md` → **`delivery-blueprint-template.md`** | rename the file; retitle the H1/`[!NOTE]` from "Delivery SPEC" to "Delivery BLUEPRINT"; keep the `## Gate Criteria` section (this is `BLUEPRINT.md § GATE CRITERIA` — the gate reads it); update its two internal path references ("full SPEC.md at tasks/task-NNN/SPEC.md" and "detailed design belongs in task SPEC.md files") to `tasks/task-NNN/DETAIL.md` |
| `task-spec-template.md` → **`task-detail-template.md`** | rename the file; retitle from "Task SPEC" to "Task DETAIL"; the `**Type:** / **Source:** / **Depends on:** / **Scope:** / **Acceptance Criteria:**` body is unchanged (the schema is stable; only the filename/title move) |

*(Design note — flag, not invented: the file base-names `delivery-blueprint-template.md` /
`task-detail-template.md` keep the existing `delivery-`/`task-` scoping prefix; a plain
`blueprint-template.md` / `detail-template.md` is an equally valid choice. Confirm the exact
base-names at build time — every consumer path below must match whichever is chosen.)*

### `aid-plan` (writes `deliveries/delivery-NNN/BLUEPRINT.md` + `STATE.md`)

| File (durable anchor) | Edit |
|---|---|
| `canonical/skills/aid-plan/SKILL.md` | Workspace diagram (`delivery-NNN/` → `deliveries/delivery-NNN/`; its `SPEC.md <- OUTPUT: delivery definition (scope, gate criteria, tasks, dependencies)` line → `BLUEPRINT.md`); State Detection `DONE` rule (`delivery-NNN/SPEC.md` + `delivery-NNN/STATE.md` → `deliveries/delivery-NNN/BLUEPRINT.md` + `.../STATE.md`); the `### 2. .aid/{work}/delivery-NNN/SPEC.md (delivery definition)` output section → `deliveries/delivery-NNN/BLUEPRINT.md`; the completion checklist (`delivery-NNN/SPEC.md written for every delivery`) → `BLUEPRINT.md`. The `features/*/SPEC.md` scan (Check 2) is the **feature** spec — **unchanged**. |
| `canonical/skills/aid-plan/references/first-run-loop.md` | repoint the `delivery-spec-template.md` reference to `delivery-blueprint-template.md`; `delivery-NNN/SPEC.md` write paths → `deliveries/delivery-NNN/BLUEPRINT.md` |
| `canonical/skills/aid-plan/references/review-deliverables.md` | `delivery-NNN/` path references → `deliveries/delivery-NNN/`; delivery-def reads → `BLUEPRINT.md` |

### `aid-detail` (writes `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`)

| File (durable anchor) | Edit |
|---|---|
| `canonical/skills/aid-detail/SKILL.md` | State Detection (`No delivery-NNN/tasks/task-NNN/SPEC.md → FIRST-RUN`; `At least one … SPEC.md → REVIEW`) → `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`; the `--reset` `argument-hint` (`clear delivery-NNN/tasks/`) → `deliveries/delivery-NNN/tasks/` |
| `canonical/skills/aid-detail/references/first-run.md` | task-def write path `delivery-NNN/tasks/task-NNN/SPEC.md` → `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`; repoint the task template to `task-detail-template.md` |
| `canonical/skills/aid-detail/references/task-decomposition.md` | same task-def path + template repoint |
| `canonical/skills/aid-detail/references/review.md` | task-def read path → `.../DETAIL.md` under `deliveries/` |
| `canonical/skills/aid-detail/references/reviewer-brief.md` | task-def path in the reviewer brief → `.../DETAIL.md` under `deliveries/` |

### `aid-execute` (reads the new paths; delivery gate reads `BLUEPRINT.md § GATE CRITERIA`)

| File (durable anchor) | Edit |
|---|---|
| `canonical/skills/aid-execute/SKILL.md` | every `delivery-NNN/tasks/task-NNN/SPEC.md` (task-def read; `§ Check 1/2`, the Inputs list, the workspace diagram `SPEC.md ← PRIMARY INPUT`, the completion checklist `Task Type read correctly from …`) → `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`; the workspace diagram `delivery-NNN/` → `deliveries/delivery-NNN/`. The `features/{feature}/SPEC.md` architectural-spec read is the **feature** spec — **unchanged** (drop the parallel "or work-root SPEC.md (lite path)" wording — the short-path resolution lives in feature-001) |
| `canonical/skills/aid-execute/references/state-execute.md` | `delivery-NNN/` task-def paths → `deliveries/delivery-NNN/…/DETAIL.md` |
| `canonical/skills/aid-execute/references/state-delivery-gate.md` | (1) `§ Gate Reviewer Inputs`: `All delivery-NNN/tasks/task-NNN/SPEC.md files` → `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md`; (2) **the mis-wire fix** — `Delivery-level acceptance criteria: Full path: from PLAN.md (the delivery's acceptance criteria block)` → `from the delivery's BLUEPRINT.md § Gate Criteria`; (3) `§ Step 1: SCORE` risk-scan path → `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` |

> **Mis-wire being fixed (grep-confirmed):** `state-delivery-gate.md § Delivery-level acceptance
> criteria` currently reads *"Full path: from `PLAN.md` (the delivery's acceptance criteria
> block)"*, but the delivery's criteria live in the **delivery definition** (`delivery-spec-template.md
> § Gate Criteria` — *"The grade.sh pass uses these as the rubric"*), and `PLAN.md` has no such
> per-delivery criteria block. FR-16 repoints the gate to `BLUEPRINT.md § GATE CRITERIA`, the file
> that actually declares them. (The short-path equivalent is feature-001's flat delivery gate,
> reading the work-root `BLUEPRINT.md § GATE CRITERIA`.)

### Dashboard reader twins (`reader.py` + `reader.mjs`, lockstep)

Both twins detect and read the hierarchical (full) layout; feature-015 repoints them to the new
`deliveries/…/{BLUEPRINT,DETAIL}.md` paths. Symbols (grep-confirmed):

| Symbol / anchor | `reader.py` | `reader.mjs` | Edit |
|---|---|---|---|
| Hierarchy detector | `_detect_hierarchy` (keys on `delivery-NNN/tasks/task-NNN/STATE.md`, "Pillar 6") | `_detectHierarchy` | detect `deliveries/delivery-NNN/tasks/task-NNN/STATE.md` (add the `deliveries/` parent) |
| Directory regexes | `_RE_DELIVERY_DIR` / `_RE_TASK_DIR` | (inline dir walk) | enumerate `deliveries/delivery-NNN/` (the `delivery-NNN` name pattern is unchanged; only the parent dir is added) |
| Hierarchical read | `_read_work_hierarchical` (reads `delivery-NNN/SPEC.md`, `delivery-NNN/tasks/task-NNN/SPEC.md`) | `_readWorkHierarchical` | read `deliveries/delivery-NNN/BLUEPRINT.md` (delivery title / task listing) and `deliveries/delivery-NNN/tasks/task-NNN/DETAIL.md` (task short-name / type) |
| Task short-name / type extractors | `_parse_task_spec_short_name` (reader.py) | `_parseTaskSpecShortName` (reader.mjs) / task-type extractor ("from a task-level SPEC.md") | read from `DETAIL.md` |
| Delivery-title extractor | (in `_read_work_hierarchical`) | delivery-title extractor ("from a delivery-level SPEC.md", `# … delivery-NNN: Title`) | read from `BLUEPRINT.md` |
| Task-file join | (path build in read path) | `taskSpecPath = join(taskDir, "SPEC.md")` | → `join(taskDir, "DETAIL.md")` |
| Drilldown | `read_repo_detail` | (mjs equivalent) | delivery/task paths under `deliveries/…`; delivery-def read → `BLUEPRINT.md` |

The work-root `SPEC.md` **fallback** for identity fields (`reader.py` `spec_path = work_dir /
"SPEC.md"`, PF-8; `reader.mjs` `const specPath = join(workDir, "SPEC.md")`) is the **feature/lite
work-root** spec — **unchanged**. Parity is enforced by the reader parity tests; the twins move in
lockstep (`artifact-schemas.md § Conventions` "update the Node reader twin"). Per A-10 neither twin
retains a `delivery-NNN/SPEC.md` (old-nested) code path.

### Existing canonical + reader tests (switch to the new layout — A-10 clean switch)

| File | Edit |
|---|---|
| `tests/canonical/test-work-state-template.sh` | the assertions that reference `delivery-spec-template.md` / `task-spec-template.md` → the renamed `delivery-blueprint-template.md` / `task-detail-template.md` |
| `tests/canonical/test-writeback-state.sh` | fixture `delivery-NNN/…` paths → `deliveries/delivery-NNN/…`; delivery-def / task-def filenames → `BLUEPRINT.md` / `DETAIL.md` |
| `tests/canonical/test-delivery-gate-aggregate.sh` | same fixture path/name switch; assert the gate reads criteria from `BLUEPRINT.md § Gate Criteria` |
| `tests/canonical/test-disjoint-merge.sh` | fixture `delivery-NNN/…/SPEC.md` → `deliveries/delivery-NNN/…/DETAIL.md` |
| `tests/canonical/test-actback-fixtures.sh` | same fixture path/name switch |
| `dashboard/reader/tests/test_fixtures.py`, `test_reader.py`, `test_task014_fixtures.py` | hierarchical fixtures → `deliveries/…/{BLUEPRINT,DETAIL}.md`; **no** mixed-vintage old-nested fixture (A-10) |
| `dashboard/server/tests/test_server_node.mjs` (+ its `fixtures/`) | Node-twin hierarchical fixtures → the new paths (the short/flat `work-006-lite-sample` fixture is **feature-001**'s) |
| `tests/canonical/test-migrate-hierarchy.sh` + `tests/canonical/fixtures/migrate/…/work-999-migration-test/` | **FLAG — design judgment (see below):** this exercises the *pre-existing* monolithic→hierarchical migration, distinct from the A-10-forbidden pre-rename→post-rename migration. Its hierarchical target must at minimum repoint to `deliveries/…/{BLUEPRINT,DETAIL}.md`; whether the monolithic→hierarchical capability itself survives A-10 needs an owner decision. |

### A-10 — clean switch (no migration, no dual path)

All of the above **replace** old paths with new; none adds an old-vs-new branch. There is no
MIGRATE task, no code that reads `delivery-NNN/SPEC.md`, and no mixed-vintage fixture. Existing
pre-rename works on disk are **not** migrated (they are simply no longer produced or read); the
consumers support exactly the two current layouts — the full path here and the short/flat path
(feature-001).

### Seam with feature-001

- **feature-001** owns the **short/flat** layout (`BLUEPRINT.md`/`DETAIL.md` at the work root, the
  promoted `## Delivery Lifecycle` / `## Delivery Gate` / `### Tasks lifecycle` STATE blocks, no
  `deliveries/` wrapper, no per-task `STATE.md`) and adds the readers' **flat** detection/read path.
- **feature-015** owns the **full** layout (`deliveries/delivery-NNN/…`) and repoints the readers'
  **hierarchical** detection/read path + the pipeline skills + the templates + the gate-criteria
  home.
- Both features rename delivery→`BLUEPRINT.md` and task→`DETAIL.md`; both point the delivery gate at
  `BLUEPRINT.md § GATE CRITERIA`. The renamed templates are **owned here** (feature-015) and
  **reused** by feature-001's engine at the work root. Together the reader twins support both new
  layouts and no others (A-10).

### Testing strategy

- **Full-path structure (canonical, AC-16):** a planned→detailed work produces
  `deliveries/delivery-NNN/{BLUEPRINT.md, STATE.md, tasks/task-NNN/{DETAIL.md, STATE.md}}`; a grep
  asserts no `delivery-NNN/SPEC.md` and no task `SPEC.md` anywhere in the produced work (AC-15
  full half).
- **Gate-criteria fix (canonical):** `state-delivery-gate.md` resolves the delivery's criteria from
  `BLUEPRINT.md § Gate Criteria`; a fixture with distinct criteria in `BLUEPRINT.md` (and none in
  `PLAN.md`) grades against the `BLUEPRINT.md` set — proving the mis-wire is fixed.
- **Reader parity (both twins):** a hierarchical fixture on the new paths is read identically by
  `reader.py` and `reader.mjs` (deliveries enumerated, delivery title from `BLUEPRINT.md`, task
  type/short-name from `DETAIL.md`); with feature-001's flat fixture, the twins prove both new
  layouts render. No old-nested fixture (A-10).
- **No-dangling-reference (grep, A-10):** no surviving `canonical/` skill/template or reader twin
  references `delivery-spec-template.md`, `task-spec-template.md`, `delivery-NNN/SPEC.md`, or task
  `SPEC.md` (scoped to full-path files — the `aid-describe` lite refs are feature-002/013's).
- **Render / regression:** `run_generator.py` re-renders clean; `render-drift` + dogfood
  byte-identity green (AC-6); `tests/run-all.sh` green; `aid-reviewer` grades each changed skill
  ≥ A+ (AC-7 subset).
