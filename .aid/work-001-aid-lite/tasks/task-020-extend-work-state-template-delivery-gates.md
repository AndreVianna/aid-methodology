# task-020: Extend `work-state-template.md` with `## Delivery Gates` + create `delivery-issues.md` template + `data-model.md §2.3`

**Type:** CONFIGURE

**Source:** feature-004-two-tier-review → delivery-003

**Depends on:** —

**Scope:**
- Add a `## Delivery Gates` section to `canonical/templates/work-state-template.md`.
- Schema: one block per delivery, keyed by `delivery-NNN`, containing reviewer tier / grade / issue list / timestamp.
- Update `.aid/knowledge/data-model.md §2.3` to list `## Delivery Gates` among the work STATE.md sections.
- Add explicit note that `delivery-NNN-issues.md` (instance file for deferred-`[HIGH]` log) coexists distinctly with this section's gate issue list.
- **Author `canonical/templates/delivery-issues.md` template** (the deferred-`[HIGH]` log template that feature-004 SPEC L250-269 mandates; instances render to `.aid/{work}/delivery-NNN-issues.md` per quick-check). Template carries: header + per-task deferred-`[HIGH]` row schema (task-id / severity / description / source-file:line / deferral-timestamp / status).

**Acceptance Criteria:**
- [ ] `canonical/templates/work-state-template.md` contains the `## Delivery Gates` section with documented schema.
- [ ] `canonical/templates/delivery-issues.md` template exists with the documented row schema per feature-004 SPEC L250-269.
- [ ] `.aid/knowledge/data-model.md §2.3` lists `## Delivery Gates` and references the new `delivery-issues.md` template.
- [ ] Generator re-renders both templates into all 3 install trees byte-identically.
- [ ] Existing work-area `STATE.md` instances continue to validate (additive change).
- [ ] Configuration is idempotent.
- [ ] All §6 quality gates pass.
