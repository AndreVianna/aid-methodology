# task-003: writeback-state.sh flattened STATE targeting

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-001

**Scope:**
- Edit `canonical/aid/scripts/execute/writeback-state.sh` so that when the layout is flattened and `--delivery-id 001`, it writes `## Delivery Lifecycle` / `## Delivery Gate` into the work-root `STATE.md` (rather than a `delivery-NNN/STATE.md`), targeting those exact headings with byte-stable enums.
- Keep the nested-path `--delivery-id` write behavior unchanged.

**Acceptance Criteria:**
- [ ] `writeback-state.sh --delivery-id 001` on a flattened work updates the work-root `STATE.md` `## Delivery Lifecycle`/`## Delivery Gate` in place, enums byte-stable.
- [ ] Nested-layout writeback behavior unchanged.
- [ ] Unit/canonical coverage for the new branch; all existing tests still pass (`tests/run-all.sh` green).
- [ ] Ships with `render-drift` green; dogfood byte-identical.
- [ ] All §6 quality gates pass.
