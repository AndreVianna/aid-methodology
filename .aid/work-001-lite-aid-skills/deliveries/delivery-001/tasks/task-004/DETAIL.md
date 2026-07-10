# task-004: Dashboard reader twins flattened path (Python + Node)

**Type:** IMPLEMENT

**Source:** work-001-lite-aid-skills -> delivery-001

**Depends on:** task-001

**Scope:**
- `dashboard/reader/reader.py` (+ `parsers.py` if needed): extend `_detect_hierarchy` (or a sibling) to return true for the flat layout — a work-root `BLUEPRINT.md` + `tasks/task-NNN/DETAIL.md` directly under the work root (no `deliveries/` wrapper, no per-task `STATE.md`); add a flattened read path (adapt `_read_work_hierarchical`) that enumerates `tasks/task-NNN/`, reads each `DETAIL.md` (type/short-name) and the per-task state cells from the work-root `STATE.md § ### Tasks lifecycle`, synthesizes ONE `DeliverableRef` for `delivery-001` (`wave="delivery-001"`, `delivery=1`); parses `## Delivery Lifecycle`/`## Delivery Gate` from the work-root STATE via the existing `parse_delivery_state_md`; `read_repo_detail` resolves the `delivery-001` drilldown.
- `dashboard/server/reader.mjs`: mirror the four changes in lockstep (parity mandatory).
- Detection is presence-based and per-work; the twins support exactly the two amended layouts — the flat (short) layout here and the full `deliveries/` layout (feature-015) — with no old-nested / mixed-vintage detection path (A-10 clean switch).

**Acceptance Criteria:**
- [ ] Both twins detect + read a flattened work (delivery-001 synthesized; tasks resolved from `tasks/task-NNN/DETAIL.md` + the work-root `STATE.md § ### Tasks lifecycle` cells; `## Delivery Lifecycle`/`## Delivery Gate` parsed from work-root STATE) (AC-8).
- [ ] No old-nested / mixed-vintage detection path remains; the twins detect only the two amended layouts (flat + full `deliveries/`) (A-10 clean switch).
- [ ] `reader.py` and `reader.mjs` produce identical output for a flattened fixture (locked by task-005).
- [ ] All existing tests still pass.
- [ ] All §6 quality gates pass.
