# Plan — work-001-aid-lite

> **Status:** Approved sequence (2026-05-24), reviewer pass pending
> **Minimum Grade:** A+ (per `.aid/knowledge/STATE.md`)
> **Total deliveries:** 5
> **Open IQs:** 0 — all 3 resolved at /aid-plan (see § IQ Resolutions)

## Deliverables

### delivery-001: Skill Footprint Refactor (foundation)

- **What it delivers:** Every AID skill becomes a thin router — frontmatter +
  pre-flight + state detection + dispatch table only — with per-state heavy
  detail moved to `references/state-{name}.md` loaded on demand. No
  user-facing behavior change; the methodology is identical before and after.
  This is the maintainability + load-weight foundation downstream deliveries
  build on.
- **Features:** `feature-002-skill-footprint-refactor`
- **Depends on:** `work-002-canonical-generator` (already shipped; provides the
  canonical/ source-of-truth + generator that renders the install trees)
- **Priority:** Must
- **Why first:** REQUIREMENTS §10 explicit recommended build order — "FR3
  (feature-002) before FR1/FR2 — it refactors the skills the others modify."
  Landing it first avoids double work (modifying monolithic SKILL.md bodies
  that would then need to be re-decomposed).
- **Standalone value:** Lighter per-invocation loading across all 10 skills;
  uniform skill structure for maintainability; CR6 canonical state-id format
  (UPPERCASE-with-hyphens) becomes enforced; `implementation-state.md`
  template retired (its purpose absorbed by work-003's per-area STATE rule).
- **Scope of skill-body edits:** All 10 skills under `canonical/skills/`
  (aid-init, aid-discover, aid-interview, aid-summarize, aid-specify,
  aid-plan, aid-detail, aid-execute, aid-deploy, aid-monitor). Generator
  re-renders three install trees from canonical source.
- **Notes:** CR7 (two-zone task-template.md) was retired per the 2026-05-24
  REQUIREMENTS refresh; this delivery does NOT change `task-template.md`.

### delivery-002: Lite Path with Type-Aware Routing

- **What it delivers:** `/aid-interview` gains an early triage fork that
  routes small work to a **lite path** (one consolidated work-root
  `SPEC.md` + `tasks/task-NNN.md` files — no per-feature folders, no
  separate PLAN.md). The triage's (c) type-of-work answer selects one of
  four sub-paths (LITE-BUG-FIX / LITE-DOC / LITE-REFACTOR / LITE-FEATURE)
  tuned to that work-type's ceremony floor. User can override the
  auto-selected sub-path on the same triage turn. Lite work that proves
  large escalates to full path without losing captured info.
- **Features:** `feature-005-lite-path` (FR1 + FR1 type-aware extension)
- **Depends on:** delivery-001 (thin-router refactor of aid-interview)
- **Priority:** Must
- **Why second:** Biggest user-visible AID-Lite win (pain point #1 — heavy
  pipeline for small work). Also unblocks delivery-004 (recipes need the
  workType signal this delivery emits).
- **Standalone value:** Small work (bug fixes, single docs, small
  refactors, small new features) now flows through a fast condensed path
  instead of the full Interview → Specify → Plan → Detail pipeline.
- **Coordination notes:**
  - Adds `## Triage` section to `work-state-template.md` (per the
    Migration Plan addition in the SPEC) with bullet-list fields: Path,
    Work Type, Sub-path, Sub-path (auto), Decision rationale, Override,
    Recipe (reserved for delivery-004).
  - Extends `data-model.md §2.3` (Work-area STATE.md schema) to list the
    `## Triage` section.
  - `INTERVIEW-STATE.md` (as a separate file) is **not** created — the
    triage block lives in the consolidated work-area `STATE.md` per
    work-003's FR2 area-STATE rule (already shipped).

### delivery-003: Two-Tier Review Model

- **What it delivers:** `aid-execute` replaces today's per-task full review
  loop (review → fix → review until grade A on every task) with a two-tier
  model: per-task **quick check** (one pass, no grade loop, cheap-tier
  reviewer, surfacing only `[CRITICAL]` + `[HIGH]` issues — critical gets
  one immediate fix; the rest is deferred to the per-delivery gate) +
  per-delivery **quality gate** (one rigorous review → fix → review loop
  per delivery, with reviewer tier proportional to delivery complexity).
  Deterministic grading (`grade.sh`) preserved at the gate.
- **Features:** `feature-004-two-tier-review` (FR2)
- **Depends on:** delivery-001 (thin-router refactor of aid-execute)
- **Priority:** Must
- **Why third:** Second-biggest user-visible AID-Lite win (pain point #2 —
  slow per-task execution). Lands before delivery-005 (parallel pool)
  because the pool model relies on the per-delivery gate-fires-once contract
  this delivery defines.
- **Standalone value:** `aid-execute` becomes faster on every delivery —
  the rigorous review loop moves from N-times-per-delivery to once.
- **Coordination notes:**
  - Per-task quick-check records and per-delivery gate records write to
    the per-work `STATE.md` (specifically: quick-check rows under each
    task's `## Tasks Status` row; gate records under a new
    `## Delivery Gates` section keyed by `delivery-NNN`) per the
    Alignment Update. `task-NNN.md` Execution Record zone framing is
    retired; `task-NNN.md` stays 6-section flat.
  - Adds `## Delivery Gates` section to `work-state-template.md` and
    extends `data-model.md §2.3` accordingly.
  - The deferred-`[HIGH]` log per delivery still lives in a separate
    `delivery-NNN-issues.md` instance file (distinct from the gate's
    fresh issue list in `## Delivery Gates`).
  - **Implements `writeback-task-status.sh`** (IQ7 resolution) for
    row-level concurrent writes to work `STATE.md`. delivery-005
    consumes this helper.

### delivery-004: Recipes Catalog

- **What it delivers:** A `canonical/recipes/` directory of pre-filled
  lite-path templates the user can instantiate by name. Seed catalog
  ships 5 recipes (`bug-fix`, `method-refactor`, `add-crud-endpoint`,
  `write-release-note`, `add-unit-test`). The lite-path triage offers a
  matching recipe after the sub-path is selected and before the sub-path's
  condensed interview runs — instantiation collapses the lite path to
  slot-filling (under one minute of user time). Recipe-instantiated work
  can escalate to standard lite-path interview without losing slot values.
- **Features:** `feature-011-recipes` (FR8)
- **Depends on:** delivery-002 (workType signal from feature-005's triage;
  recipe-offer step in the lite-path triage); **work-002 back-port**
  (resolved at this delivery — see IQ8 resolution below)
- **Priority:** Should
- **Why fourth:** Ships adjacent to delivery-002 to keep the lite-path /
  pain-point-1 work clustered. Substantial standalone value — recipes
  unlock the **steady-state** speed-for-small-work case (repetitive
  patterns) that the lite-path interview still has to derive each time.
- **Standalone value:** Frequent small-work patterns (bug fixes,
  refactors, etc.) collapse to slot-filling. The catalog is open;
  projects add their own recipes as patterns emerge.
- **Coordination notes:**
  - Adds `Recipe:` line to the `## Triage` block schema feature-005
    introduced.
  - Adds `## Recipe Slots` block to work-area `STATE.md` for escalation
    fallback (slot values preserved when user escalates to standard
    lite-path interview).
  - Creates `canonical/skills/aid-interview/scripts/` directory (first
    script for that skill — `parse-recipe.sh`).
  - Creates `canonical/templates/recipe-template.md` (meta-template).
  - Requires **work-002 back-port** (IQ8, resolved): new `recipe`
    asset-kind renderer (passthrough), `recipes` entry in each profile's
    `layout`, `canonical/EMISSION-MANIFEST.md` extension. Back-port is
    a coordinated sub-step of this delivery (~30 LOC across 3-4 files
    in work-002).

### delivery-005: Parallel Pool Execution

- **What it delivers:** `aid-execute` runs independent tasks concurrently
  by default through a continuous agent pool. `MaxConcurrent` parameter
  (default 5, configurable via a new `aid-init` question stored in
  `.aid/knowledge/STATE.md`) caps simultaneously in-flight tasks. The
  pool admits the next ready task the instant any in-flight task
  completes (no wave-barrier idle time). Failed task blocks only its
  transitive descendants in the dependency graph; unrelated chains
  continue. Wave barriers (when wanted) are expressed as graph
  dependencies, not first-class executor concepts.
- **Features:** `feature-009-parallel-task-execution` (FR6, pool model)
- **Depends on:** delivery-001 (thin-router refactor of aid-execute and
  aid-init); delivery-003 (per-delivery gate-fires-once contract +
  `writeback-task-status.sh` helper)
- **Priority:** Should
- **Why fifth:** Smallest user-visible standalone win (REQUIREMENTS
  explicitly notes "wall-time gain from parallelism alone was modest";
  FR6 is in the Should bucket). Lands last so the row-level write
  coordination work (IQ7) only needs solving once with both 004 and 009
  in place. The Agent tool wait-for-any mechanism (IQ6 resolution) is
  validated here.
- **Standalone value:** Parallel-by-default for graph-independent tasks;
  faster wall-time for deliveries with mutually independent task chains.
- **Coordination notes:**
  - Uses the **Agent tool with `run_in_background: true`** as the parallel
    dispatch primitive (IQ6 resolution).
  - Per-task Status / Blocked / dispatch history written through the
    `writeback-task-status.sh` row-level helper (IQ7 resolution,
    implemented by delivery-003).
  - Adds `## Max Parallel Tasks:` metadata line to
    `.aid/knowledge/STATE.md` (template + existing instance).
  - Inserts new `aid-init` question between Heartbeat Interval (Q6) and
    Commit AID Workspace (Q7 → Q8).

## IQ Resolutions

The 3 open IQs carried into /aid-plan are resolved here. /aid-detail and
/aid-execute treat these resolutions as firm contracts.

### IQ6 — Task-tool wait-for-any semantic for FR6 pool

**Resolution: Use the Agent tool with `run_in_background: true`.**

The original feature-009 spec framed FR6 as a Task-tool dispatch. Investigation
during /aid-plan establishes that the **Agent tool** (with
`run_in_background: true` + completion notifications) is the correct primitive
for parallel pool dispatch — it is the same pattern `aid-discover` already
uses for parallel sub-agents, and the same pattern this very project's
methodology has been exercising during reviewer dispatches. The Agent tool
provides:

- Per-task fresh context (clean-context per executor — preserves the existing
  per-task isolation contract);
- `run_in_background: true` mode that returns immediately + notifies on
  completion (the wait-for-any-of-N semantic naturally);
- Cross-tool availability gated by work-002's `background_execution`
  capability flag (graceful degradation to sequential when absent — per
  feature-009 SPEC's NFR4 framing).

**Impact on delivery-005:** Implementation reads as straightforward — pool
maintains an "in-flight" set of agent-IDs; on each completion notification,
update task status + readiness set + dispatch the next ready task if a slot
is free. No new platform-API exploration needed.

### IQ7 — Row-level write coordination under FR6 × per-area STATE

**Resolution: Adapt `writeback-state.sh` to `writeback-task-status.sh`
with file-level lock + per-task row scope.**

Under FR6 pool + per-area STATE rule, N parallel tasks each want to update
their own row in the shared work `STATE.md ## Tasks Status` table. The
contract:

- **Single-writer per task by construction:** the executor for `task-NNN` is
  the sole writer of `task-NNN`'s row. No two executors contend for the
  same row.
- **File lock for write serialization:** the row-update step takes a
  file-level lock (POSIX `flock` / Windows `LockFileEx` via the helper) so
  the actual write is serialized across all tasks. Contention window is
  tiny (~milliseconds per row update).
- **Helper:** `canonical/templates/scripts/writeback-task-status.sh`
  (new — mirrors work-003's existing `writeback-state.sh` pattern), takes
  `--task-id NNN --field <field> --value <value>`, updates that row's
  cell, releases lock.
- **Same helper for `## Delivery Gates` block:** the gate's `AGGREGATE`
  step is single-writer for the `## Delivery Gates` block; helper takes
  `--delivery-id NNN --block <block>` for that case.

**Impact on delivery-003 and delivery-005:** delivery-003 implements the
helper (used for per-task quick-check writes); delivery-005 consumes it
(used for per-task Status updates from the pool).

### IQ8 — work-002 backport for FR8 recipes generator support

**Resolution: Coordinated change-set against work-002's
`feature-001-profile-driven-generator`, attributed to FR8 implementation.**

The back-port is 3 small additions:

1. **Recipe renderer:** add a `recipe` asset-kind to work-002's renderer
   registry. Since recipes are plain Markdown with YAML front-matter,
   passthrough rendering is sufficient (the renderer's job is just to
   copy + validate per-profile).
2. **Profile layout entry:** add `recipes` to the `layout` field of each
   profile (`claude-code`, `codex`, `cursor`) declaring the install-tree
   path.
3. **Emission manifest extension:** extend `canonical/EMISSION-MANIFEST.md`
   to own paths under `recipes/` (otherwise work-002's
   mirror-deletion logic would ignore them).

**Process:**

- Land as a coordinated PR titled
  `feat(work-002): add recipes asset kind (back-port for work-001 FR8)`.
- Record in work-002's `STATE.md` Lifecycle History as a back-port row.
- Sequenced as a sub-step of delivery-004 (delivery-004 cannot ship until
  the back-port is in place).

**Impact on delivery-004:** Adds the work-002 back-port as a prerequisite
sub-step of delivery-004. The back-port itself is small (~30 LOC across
3-4 files); should fit in the same /aid-execute session as the canonical
recipes catalog.

## Cross-Cutting Risks

| # | Risk | Impact | Mitigation |
|---|------|--------|------------|
| 1 | Row-level write coordination (IQ7) is novel for this project — the writeback helper has no precedent at row-scope (work-003's `writeback-state.sh` operates at section-scope). First implementation in delivery-003 could surface unexpected platform quirks (POSIX flock vs Windows LockFileEx on the Bash-on-Windows host the project uses). | Medium | delivery-003 should ship `writeback-task-status.sh` with a small smoke-test harness (~5-row concurrent-write test). delivery-005 consumes the validated helper. If platform-quirk issues surface, IMPEDIMENT raises them; delivery-003 can iterate before delivery-005 lands. |
| 2 | delivery-001 (thin-router refactor) touches all 10 skills; mid-cutover state could leave some skills refactored and others not, causing inconsistent skill UX during the rollout. | Medium | delivery-001's SPEC § Migration Plan specifies incremental cutover (smallest skills first — aid-deploy, aid-monitor — then mid-size, then aid-discover last). Each skill's cutover is a single task; the pipeline behaves identically before and after each per-skill cutover (the structural invariant). Acceptable transient state. |
| 3 | Cross-feature scope addition: delivery-002 + delivery-003 + delivery-005 each extend `work-state-template.md` (adding `## Triage`, `## Delivery Gates`, and `## Max Parallel Tasks:` metadata respectively). Three independent template edits could collide if delivered concurrently. | Low | Sequential delivery order resolves this naturally — each delivery's `work-state-template.md` edit lands on top of the previous one. data-model.md §2.3 updates similarly serialised. |
| 4 | IQ6 resolution (Agent tool, not Task tool) means feature-009's SPEC body's "Task-tool dispatch" framing is technically inaccurate. The Alignment Update covers the per-task state contract change but not this primitive-name change. | Low (cosmetic) | Body wording can be polished at /aid-detail when feature-009 decomposes into tasks (one task is "implement pool dispatch using Agent tool with run_in_background"). Not a /aid-plan blocker. |

## Deferred

*(none — all 5 ready features assigned to deliveries)*

## Summary

```
delivery-001: Skill Footprint Refactor       → feature-002         (Must)
delivery-002: Lite Path with Type-Aware       → feature-005         (Must)
delivery-003: Two-Tier Review                 → feature-004         (Must)
delivery-004: Recipes Catalog                 → feature-011         (Should)
delivery-005: Parallel Pool Execution         → feature-009         (Should)
```

Hard partial order satisfied: 001 → (002, 003) → 004; 003 → 005.
Soft sequencing follows REQUIREMENTS §10 build order (FR3 first; FR1/FR2 next; FR6/FR8 with FR8 after FR1).

All 3 IQs (IQ6, IQ7, IQ8) resolved at /aid-plan; /aid-detail consumes the
resolutions as firm contracts.

5 of 5 deliveries are standalone-functional and testable independently.
Methodology preservation invariant (REQUIREMENTS §7) holds across all
deliveries.
