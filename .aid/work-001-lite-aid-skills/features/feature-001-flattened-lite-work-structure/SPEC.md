# Flattened Lite Work Structure

## Change Log

| Date | Change | Source |
|------|--------|--------|
| 2026-07-07 | Feature identified from REQUIREMENTS.md §5.5 (FR-8, FR-9), §4 (Lite-path adjustments), C-8, A-1 | /aid-define |
| 2026-07-08 | STRUCTURE/NAMING amendment cascade: flat layout adopts `BLUEPRINT.md` at the work root (holds GATE CRITERIA), task defs become `DETAIL.md`-only (no per-task `STATE.md`), and `## Delivery Lifecycle` / `## Delivery Gate` / `### Tasks lifecycle` promote into the work `STATE.md`; reader/`aid-execute` adjustments target ONLY the new short layout (A-10 clean switch — no old-nested support, no mixed-vintage fixtures); the full-path rename + its reader/execute support split to feature-015 | /aid-specify (user amendment) |

## Source

- REQUIREMENTS.md §5.5 (FR-8, FR-9, FR-17)
- REQUIREMENTS.md §5.7 (FR-15 — short-path half)
- REQUIREMENTS.md §4 (In Scope — Lite-path adjustments)
- REQUIREMENTS.md §9 (AC-8, AC-15 short half, AC-17)
- REQUIREMENTS.md C-8, A-1, A-8, A-10

## Description

Define the flattened work layout a shortcut-generated Lite work lives in: a single
`REQUIREMENTS.md`, a single `SPEC.md` (one feature — no `features/` folder), a single `PLAN.md`
plus a single `BLUEPRINT.md` (one delivery — no `deliveries/`/`delivery-NNN/` folder), and tasks
placed directly under `tasks/task-NNN/DETAIL.md` (**no** per-task `STATE.md`). The single delivery's
lifecycle, gate, and per-task lifecycle are promoted into the work-root `STATE.md`
(`## Delivery Lifecycle` / `## Delivery Gate` / `### Tasks lifecycle`), and the delivery's gate
criteria live in `BLUEPRINT.md § GATE CRITERIA`. The two consumers of this short layout — the
`/aid-execute` runner and the dashboard state readers — must be adjusted to read and correctly
resolve it. Per **A-10** the consumers switch cleanly to the new layout: no support for the
pre-rename nested `delivery-NNN/SPEC.md` layout, no mixed-vintage fixtures. This feature owns the
**short/flat** layout and its reader/execute support; the **full-path** rename (`deliveries/`
wrapper + the `BLUEPRINT.md`/`DETAIL.md` rename across the shipped pipeline) and its reader/execute
support live in **feature-015**, and together the two make the readers support both new layouts.

## User Stories

- As an AID adopter who knows their change-type, I want my generated work to sit in one
  predictable flat structure so I can review the requirements, spec, plan, and tasks without
  navigating extra `features/` and `deliveries/`/`delivery-NNN/` folders.
- As an AID maintainer dogfooding AID on itself, I want `/aid-execute` and the dashboard to
  correctly consume the flattened single-delivery layout so existing tooling keeps working on
  shortcut-generated works.

## Priority

Must

## Acceptance Criteria

- [ ] Given a shortcut-generated Lite work, when I inspect the work folder, then it contains
  `REQUIREMENTS.md` + `SPEC.md` + `PLAN.md` + `BLUEPRINT.md` + `tasks/task-NNN/DETAIL.md` with
  **no** `features/` folder and **no** `deliveries/`/`delivery-NNN/` folder. (AC-2 — structure
  half; FR-8)
- [ ] Given a flattened single-delivery work, when it is produced, then `BLUEPRINT.md` sits at the
  work root, the `## Delivery Lifecycle` / `## Delivery Gate` / `### Tasks lifecycle` blocks live in
  the work `STATE.md`, and each task is `tasks/task-NNN/DETAIL.md` with **no** per-task `STATE.md`.
  (AC-17; FR-8, FR-17)
- [ ] Given the short layout, when a grep checks artifact naming, then no `SPEC.md` names a delivery
  or a task — the delivery definition is `BLUEPRINT.md`, task definitions are `DETAIL.md`, and the
  feature definition stays `SPEC.md`. (AC-15 — short-path half; FR-15)
- [ ] Given a flattened single-delivery work, when `/aid-execute` and the dashboard state readers
  consume it, then they correctly resolve its tasks and state — the `DETAIL.md` task defs, the
  promoted `STATE.md` blocks, and the synthesized single delivery — without a `features/` or
  `deliveries/`/`delivery-NNN/` folder. (AC-8; FR-9)
- [ ] Given the flattened short-path layout change, when it is applied, then skills **not** named
  in §5.6 and the (renamed) full-path pipeline have **no regression** (additive changes such as
  `/aid-execute` reading the new layout per AC-8 are permitted) and `tests/run-all.sh` is green.
  (AC-9 — pipeline no-regression half)

---

## Technical Specification

> Grounded in `research/spec-grounding.md § Q-A8` (delivery-scoped state) and `§ Q-cutover`
> (task-def shape + the execute-graph parsers). This feature defines the on-disk shape the
> **shortcut engine (feature-003)** writes, and adjusts the two consumers of that shape —
> `/aid-execute` and the dashboard state readers — to resolve it. Per **A-10** it is a clean
> switch: the consumers do **not** support the pre-rename nested layout. The **full-path** rename
> (the `deliveries/` wrapper + the pipeline-wide `BLUEPRINT.md`/`DETAIL.md` rename) and its
> reader/execute support are **feature-015**'s; together the two features make the readers support
> both new layouts.

### Data Model / Schemas

**1. The flattened work contract (FR-8, FR-15, FR-17).** Exactly one feature and one delivery, so
the `features/` and `deliveries/`/`delivery-NNN/` wrappers collapse away:

```
.aid/work-NNN-<name>/
  STATE.md            work state + the three promoted delivery/task blocks (see 2)
  REQUIREMENTS.md     the requirements (all 10 numbered sections)
  SPEC.md             the single feature spec        (no features/ folder)
  PLAN.md             the single delivery plan (Deliverables + top-level ## Execution Graph)
  BLUEPRINT.md        the single delivery definition (objective, scope, GATE CRITERIA, tasks, deps)
  tasks/
    task-001/DETAIL.md    (task def; NO per-task STATE.md — task cells live in STATE.md ### Tasks lifecycle)
    task-002/DETAIL.md
    ...
```

This is the sole short (flat) layout going forward. Per **A-10** the consumers do **not** support
the pre-rename lite layout (a work-root `SPEC.md` plus a `delivery-001/tasks/…` hierarchy, no
`REQUIREMENTS.md`/`PLAN.md`/`BLUEPRINT.md`) — that layout is dropped, not migrated. The flat layout
adds `REQUIREMENTS.md` + `PLAN.md` + `BLUEPRINT.md` at the root, names the single feature spec
`SPEC.md` (unchanged), the delivery definition `BLUEPRINT.md`, and task defs `DETAIL.md`, drops the
per-task `STATE.md`, and has no `deliveries/`/`delivery-NNN/` wrapper.

> Doc-vs-code note for the reviewer: `artifact-schemas.md § REQUIREMENTS.md` says REQUIREMENTS.md
> lives at `.aid/knowledge/REQUIREMENTS.md`, but the live works, `pipeline-contracts.md § The
> On-Disk Work Hierarchy` (`work-NNN-{slug}/REQUIREMENTS.md`), and the reader (`reader.py`
> grep `req_path = work_dir / "REQUIREMENTS.md"`) all put it at the **work root**. The flattened
> layout uses the work root; the schemas-doc line is stale (flagged for a tech-writer follow-up).

**2. Delivery + task state promoted into the work-root STATE.md (A-8 resolved; FR-8, FR-17).** With
exactly one delivery there is exactly one writer, so the disjoint-write rule that forced separate
`delivery-NNN/STATE.md` and per-task `STATE.md` files (`artifact-schemas.md § Contracts` "DERIVED
sections are read-only … disjoint-write property") no longer applies. Three AUTHORED blocks are
promoted **verbatim** into the work-root `STATE.md`:

- `## Delivery Lifecycle` — `State: Pending-Spec | Specified | Executing | Gated | Done |
  Blocked`; `Updated`; conditional `Block Reason`/`Block Artifact` (from `delivery-state-template.md`).
- `## Delivery Gate` — `Reviewer Tier: Small | Medium | Large`; `Grade`; `Issue List`;
  `Timestamp` (from `delivery-state-template.md`).
- `### Tasks lifecycle` — the per-task mutable cells (`State`, `Grade`, `Updated`, …) that would
  otherwise live in a per-task `STATE.md`, keyed by `task-NNN`, using the byte-identical closed
  task-state enum (`Pending | In Progress | In Review | Blocked | Done | Failed | Canceled`). This
  is the single-writer home that **replaces** the now-absent per-task `STATE.md` (FR-17).

The delivery's **GATE CRITERIA** live in `BLUEPRINT.md § GATE CRITERIA` (**not** in `STATE.md`) —
that is where the flat delivery gate reads them, resolving the old flat layout's missing
gate-criteria home. The **enum strings stay byte-identical**, so `writeback-state.sh` and both
dashboard reader twins parse them unchanged — no byte-stability break (`artifact-schemas.md §
Contracts` "Closed STATE enums are byte-stable"). (`grade.sh` does not parse STATE.md — it reads
only the reviewer-ledger Severity/Status columns — so it is not a consumer here.) These new
**singular** authored `## Delivery Lifecycle` / `## Delivery Gate` sections and the `### Tasks
lifecycle` subsection are distinct from the existing **plural** DERIVED `## Delivery Gates` /
`## Plan / Deliveries` / `## Tasks State` union views in `work-state-template.md`, so there is no
heading collision. (The post-execution `## Delivery Gate` grade here is written later by
`/aid-execute`; feature-004's *definition-phase* gates are separate and recorded in Lifecycle
History — see feature-004.)

**3. Task DETAIL shape.** Tasks use the canonical task-DETAIL template shape at
`tasks/task-NNN/DETAIL.md` (the `task-spec-template.md` → task-DETAIL-template rename is
**feature-015**'s) — `**Type:**` (one of the 8), `**Source:** work-NNN-<name> -> delivery-001`,
`**Depends on:**`, `**Scope:**`, `**Acceptance Criteria:**`. There is **no** per-task `STATE.md`;
each task's mutable cells live in the work-root `STATE.md § ### Tasks lifecycle` (section 2). The
synthesized `delivery-001` label in `Source` (the existing lite precedent — the "lite path always
uses delivery-001" convention) is what lets the executor's branch derivation work unchanged (see
5). The recipe "flat `- Type:`" form is retired with the recipes (feature-002); the flat layout
standardizes on the bold `**Type:**` shape.

**4. PLAN.md shape (single delivery).** `## Deliverables` (one entry) + a top-level
`## Execution Graph` carrying `### Task Dependencies` (`| Task | Depends On |`) and
`### Can Be Done In Parallel` (`| Wave | Tasks |`) — the shape already proven in the lite plan,
now hosted in `PLAN.md`. **Critically, the two execute-graph parsers already accept this**:
`compute-block-radius.sh` and `complexity-score.sh` match the Execution Graph header at ANY
heading level and treat a graph with no `### delivery-` sections as the "lite/recipe SPEC" case
needing no `--delivery-id` (`compute-block-radius.sh` grep `Execution Graph header at ANY level`;
`complexity-score.sh` grep `Lite/recipe SPEC — top-level`; both grep `— (none)` for the no-deps
form). So feature-001 emits a shape they parse as-is. The delivery's objective / scope / GATE
CRITERIA / task listing live in the sibling `BLUEPRINT.md` (delivery definition), **not** in
`PLAN.md`.

**Constraint (required for the parsers' no-delivery-id branch):** the flattened `PLAN.md`
carries **zero `### delivery-NNN` subsection headings** — the single delivery is implicit and the
graph sits under a top-level `## Execution Graph`. This matters because `complexity-score.sh`
errors on *any* `^### delivery-` match without `--delivery-id`, and `compute-block-radius.sh`
requires `--delivery-id` only when it sees `>= 2` such headings. Emitting no `### delivery-`
heading keeps both parsers on their no-delivery-id path. The `delivery-001` label is carried
only by each task's `**Source:** ... -> delivery-001` field (used for the branch/lifecycle),
never by a PLAN heading.

**5. Git branch: synthesize `delivery-001`.** With no `deliveries/delivery-NNN/` dir the branch
derivation `aid/{work}-delivery-NNN` (`aid-execute/SKILL.md § Check 5` grep
`aid/{work}-delivery-NNN`) has no NNN. Synthesize `delivery-001` so the branch is
`aid/{work}-delivery-001` and the existing derivation (fed by the task `Source` field's
`-> delivery-001`) needs no new scheme.

### Feature Flow — the consumer adjustments (Build)

**A. `/aid-execute` (the runner).** feature-015 rewrites `/aid-execute`'s **full-path** resolution
to the new `deliveries/delivery-NNN/…/{BLUEPRINT.md, DETAIL.md}` paths; this feature adds the
**flat (short-layout) branch** (detected by: no `deliveries/` dir under the work root **and**
`tasks/task-NNN/DETAIL.md` present). The flat branch resolves:

| Touch-point (durable anchor) | Flat (short) resolution |
|---|---|
| Task definition (`SKILL.md § Check 1/2`) | `.aid/{work}/tasks/task-NNN/DETAIL.md` (no per-task `STATE.md`; task cells read from work-root `STATE.md § ### Tasks lifecycle`) |
| Execution Graph (`state-execute.md § Locate the Execution Graph`) | work-root `PLAN.md` `## Execution Graph` |
| Feature / architectural spec (`SKILL.md § Workspace`) | work-root `SPEC.md` (single feature) |
| Delivery lifecycle/gate read+write (`SKILL.md § Check-*`; `writeback-state.sh --delivery-id`) | work-root `STATE.md` `## Delivery Lifecycle` / `## Delivery Gate` |
| Delivery gate criteria (`state-delivery-gate.md § Gate Reviewer Inputs`) | work-root `BLUEPRINT.md § GATE CRITERIA` |
| Branch (`SKILL.md § Check 5`) | `aid/{work}-delivery-001` (synthesized) |
| SCORE risk-scan path (`state-delivery-gate.md § Step 1: SCORE`) | `tasks/task-NNN/DETAIL.md` |

The execute-graph **scripts need no change** (they already parse the top-level graph); the edits
are the SKILL.md/reference **prose paths** that route to them, teaching `writeback-state.sh` to
target the work-root STATE.md blocks (`## Delivery Lifecycle` / `## Delivery Gate` / `### Tasks
lifecycle`) when `--delivery-id 001` and the layout is flat, and pointing the delivery gate at
`BLUEPRINT.md § GATE CRITERIA`. (feature-015 applies the **same** gate-criteria-home fix on the
full path — the shipped mis-wire that read the criteria from a non-existent `PLAN.md` block; see
feature-015.)

**B. Dashboard state readers (Python + Node twins, in lockstep).** feature-015 repoints the
hierarchical detector/reader (`reader.py` `_detect_hierarchy` / `_read_work_hierarchical`;
`reader.mjs` `_detectHierarchy` / `_readWorkHierarchical`) to the new full paths
(`deliveries/delivery-NNN/…/{BLUEPRINT.md, DETAIL.md}`). This feature adds the **flat
(short-layout)** path:

1. **Detection.** Add a flat detector (sibling to `_detect_hierarchy`) that returns true when
   `work_dir/tasks/task-NNN/DETAIL.md` exists directly under the work root (no `deliveries/`
   wrapper, no per-task `STATE.md`).
2. **Read.** A flat read path (adapting `_read_work_hierarchical`): enumerate
   `work_dir/tasks/task-NNN/`, read per-task `DETAIL.md` (type / short-name); read each task's
   mutable cells from the **work-root** `STATE.md § ### Tasks lifecycle` (there is no per-task
   `STATE.md`); synthesize **one** `DeliverableRef` for `delivery-001`; set each `TaskModel.wave =
   "delivery-001"`, `delivery = 1`.
3. **Delivery lifecycle/gate.** Parse `## Delivery Lifecycle` + `## Delivery Gate` from the
   **work-root** `STATE.md` text via the existing `parse_delivery_state_md` (`parsers.py` grep
   `parse_delivery_state_md`) — it keys on those exact headings and the byte-identical enum
   (`parsers.py` grep `_DELIVERY_STATE_VALUES`), so it works unchanged on the work-STATE text;
   only the file it is pointed at changes.
4. **Drilldown.** `read_repo_detail` (`reader.py`) resolves `delivery_id = delivery-001` from
   `task.delivery` and reads `.aid/{work}/delivery-001-issues.md` — consistent with the
   synthesized label; the plural `## Delivery Gates` parse (`parse_delivery_gate`) is unaffected.
5. **Node twin.** Mirror 1-4 in `dashboard/server/reader.mjs` (the whole `reader.py` is ported to
   `reader.mjs`; `artifact-schemas.md § Conventions` "update the Node reader twin" is mandatory —
   parity is enforced by the reader parity tests).

Detection is **presence-based and per-work** (`reader.py § _detect_hierarchy` docstring), so a
repo containing **both new layouts** (full `deliveries/…` works + flat lite works) renders all of
them. Per **A-10** there is **no** old-nested (`delivery-NNN/SPEC.md`) detection and **no**
mixed-vintage fixtures — the readers support exactly the two new layouts (flat here + full via
feature-015). This is the NFR-7 no-regression guarantee at the reader level, scoped to the current
(post-rename) layouts.

### Layers & Components (exact files)

| File | Change |
|---|---|
| `canonical/aid/templates/work-state-template.md` | add AUTHORED `## Delivery Lifecycle` + `## Delivery Gate` + `### Tasks lifecycle` sections (single-delivery flattened works); (feature-002 removes the orphaned `## Triage` Recipe/Path-Selection + `## Escalation Carry` blocks — coordinate the single edit) |
| `canonical/aid/templates/delivery-plans/` (new flattened `PLAN.md` template) | define the single-delivery `PLAN.md` shape (Deliverables + `## Execution Graph`); the flat `BLUEPRINT.md` reuses **feature-015**'s renamed delivery-BLUEPRINT template placed at the work root; the single feature `SPEC.md` reuses `specs/spec-template.md`; `specs/lite-spec-template.md` is superseded (retired with feature-002 cutover) |
| `canonical/skills/aid-execute/SKILL.md` + `references/state-execute.md` + `references/state-delivery-gate.md` | add the flat branch to task/graph/spec/branch/lifecycle resolution + SCORE risk path; point the flat delivery gate at `BLUEPRINT.md § GATE CRITERIA` |
| `canonical/aid/scripts/execute/writeback-state.sh` | write `## Delivery Lifecycle` / `## Delivery Gate` / `### Tasks lifecycle` into the work-root STATE.md when flattened (`--delivery-id 001`) |
| `dashboard/reader/reader.py` (+ `parsers.py` if needed) | flat detection + read path (`DETAIL.md` + task cells from work-STATE `### Tasks lifecycle`); synthesize delivery-001 |
| `dashboard/server/reader.mjs` | Node-twin mirror (lockstep) |
| `canonical/aid/scripts/execute/compute-block-radius.sh`, `complexity-score.sh` | **no change required** (already parse the top-level graph); optionally simplify the retired flat `- Type:` recipe branch |

Renders via the full `run_generator.py` to all five profiles; the dashboard reader/`.mjs` are
product code (not rendered from `canonical/`) but ship vendored — the twins move in lockstep.

### Testing strategy

- **Reader parity** (new fixture under `dashboard/reader/tests/` + the Node parity test): a
  flattened work fixture (REQUIREMENTS + SPEC + PLAN + BLUEPRINT + `tasks/task-NNN/DETAIL.md` +
  work-root STATE with the three promoted blocks, **no** per-task `STATE.md`) is read identically
  by `reader.py` and `reader.mjs` — tasks resolved from `DETAIL.md`, task cells read from
  `### Tasks lifecycle`, delivery-001 synthesized, `## Delivery Lifecycle` / `## Delivery Gate`
  parsed from the work-root STATE (AC-8, AC-17). Per **A-10** there is no mixed-vintage/old-nested
  fixture; a full-path (new `deliveries/…`) fixture is feature-015's, and the two together prove
  both new layouts render.
- **Executor graph** (canonical test): assert `compute-block-radius.sh --plan-file <flattened
  PLAN.md> --failed-task <task-id>` (the `--failed-task` arg is required — the script exits 5
  without it) and `complexity-score.sh --plan-file <flattened PLAN.md>` parse the top-level
  `## Execution Graph` with no `--delivery-id` and return the expected radius/score (they
  already support this shape; the fixture locks it in).
- **No regression** (AC-9): `tests/run-all.sh` green; the (renamed) full-path pipeline unchanged
  in behavior.

Seams: the **shortcut engine (feature-003)** writes every shape defined here; **feature-004**
writes the post-detail gate grades into Lifecycle History (its definition-gate) — the `## Delivery
Gate` block here is filled later by `/aid-execute`; **feature-015** owns the parallel full-path
layout + its reader/execute support, so the readers end up supporting both new layouts.
