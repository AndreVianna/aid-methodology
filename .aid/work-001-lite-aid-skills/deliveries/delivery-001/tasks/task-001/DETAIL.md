# task-001: Flattened-layout templates (work-state delivery blocks + single-delivery PLAN.md)

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** -- (none)

> **Scope amendment (2026-07-08, aid-execute):** the third promoted block `### Tasks lifecycle`
> was added to scope here after task-001's developer surfaced that feature-001 SPEC (§ Data Model
> item 2 + Layers & Components table) + AC-17 require ALL THREE promoted blocks in this template
> file, and downstream tasks (002/004/005/008) assume it exists. Home confirmed = this template
> (task-008 is the runtime writer, not the template author). Field shape resolved: mirror the real
> `task-state-template.md` mutable cells (`State | Review | Elapsed | Notes`) keyed by `task-NNN`,
> since the block REPLACES the per-task `STATE.md`; the SPEC's "(`State`, `Grade`, `Updated`, …)"
> is illustrative. Downstream implication recorded for task-003 (writeback must target all three
> blocks) in the work STATE.

**Scope:**
- Edit `canonical/aid/templates/work-state-template.md`: add the three AUTHORED blocks `## Delivery Lifecycle` (State enum `Pending-Spec | Specified | Executing | Gated | Done | Blocked`; `Updated`; conditional `Block Reason`/`Block Artifact`) and `## Delivery Gate` (`Reviewer Tier`; `Grade`; `Issue List`; `Timestamp`), promoted verbatim from `canonical/aid/templates/delivery-state-template.md`, plus `### Tasks lifecycle` (per-task mutable cells keyed by `task-NNN`, mirroring `task-state-template.md`'s `State | Review | Elapsed | Notes` with the byte-identical closed task-state enum `Pending | In Progress | In Review | Blocked | Done | Failed | Canceled`), for single-delivery flattened works. Keep all enum strings byte-identical (no byte-stability break). The SINGULAR authored blocks must not collide with the existing PLURAL DERIVED `## Delivery Gates` / `## Plan / Deliveries` / `## Tasks State` views.
- Do NOT remove the `## Triage` / `## Escalation Carry` blocks here -- feature-002 (task-030) owns that removal in the cutover; coordinate the shared file.
- Create the flattened single-delivery `PLAN.md` template under `canonical/aid/templates/delivery-plans/`: `## Deliverables` (one entry) + a top-level `## Execution Graph` carrying `### Task Dependencies` (`| Task | Depends On |`) and `### Can Be Done In Parallel` (`| Wave | Tasks |`); emit ZERO `### delivery-NNN` subsection headings (keeps `complexity-score.sh`/`compute-block-radius.sh` on their no-`--delivery-id` path).
- The single feature `SPEC.md` reuses `canonical/aid/templates/specs/spec-template.md` (no new template).

**Acceptance Criteria:**
- [ ] `work-state-template.md` carries AUTHORED `## Delivery Lifecycle` + `## Delivery Gate` + `### Tasks lifecycle` with the byte-identical closed enums from `delivery-state-template.md` / `task-state-template.md` (A-8 promotion; feature-001 AC-17 three-block requirement).
- [ ] The new flattened `PLAN.md` template emits a top-level `## Execution Graph` with `### Task Dependencies` + `### Can Be Done In Parallel` and NO `### delivery-` heading.
- [ ] `run_generator.py` renders both templates to all 5 profiles; `render-drift` green; dogfood `.claude/` byte-identical.
- [ ] All existing tests still pass (`tests/run-all.sh` green).
- [ ] All §6 quality gates pass.
