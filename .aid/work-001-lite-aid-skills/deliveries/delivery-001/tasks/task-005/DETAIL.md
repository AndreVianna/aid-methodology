# task-005: Reader-parity flattened fixture test

**Type:** TEST

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-004

**Scope:**
- Add a flattened work fixture under `dashboard/reader/tests/` (REQUIREMENTS + SPEC + PLAN + work-root `BLUEPRINT.md` + `tasks/task-NNN/DETAIL.md` (no per-task `STATE.md`) + work-root `STATE.md` carrying the promoted `## Delivery Lifecycle`/`## Delivery Gate` blocks and the `### Tasks lifecycle` task cells) plus the Node parity test.
- Assert `reader.py` and `reader.mjs` read the fixture identically: tasks resolved from `DETAIL.md` + the `### Tasks lifecycle` cells, `delivery-001` synthesized, `## Delivery Lifecycle`/`## Delivery Gate` parsed from the work-root STATE.

**Acceptance Criteria:**
- [ ] Flattened fixture read identically by both twins (AC-8).
- [ ] No old-nested / mixed-vintage fixture is added — only the two amended layouts (flat + full `deliveries/`) are exercised (A-10 clean switch).
- [ ] Test is deterministic with clean setup/teardown.
- [ ] Covers feature-001 AC-8 (flattened consumption) under the A-10 clean switch.
- [ ] All §6 quality gates pass.
