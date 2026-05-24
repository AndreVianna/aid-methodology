# task-020: Extend `work-state-template.md` with `## Delivery Gates` + `data-model.md §2.3`

**Type:** CONFIGURE

**Source:** feature-004-two-tier-review → delivery-003

**Depends on:** —

**Scope:**
- Add a `## Delivery Gates` section to `canonical/templates/work-state-template.md`.
- Schema: one block per delivery, keyed by `delivery-NNN`, containing reviewer tier / grade / issue list / timestamp.
- Update `.aid/knowledge/data-model.md §2.3` to list `## Delivery Gates` among the work STATE.md sections.
- Add explicit note that `delivery-NNN-issues.md` (instance file for deferred-`[HIGH]` log) coexists distinctly with this section's gate issue list.

**Acceptance Criteria:**
- [ ] `canonical/templates/work-state-template.md` contains the `## Delivery Gates` section with documented schema.
- [ ] `.aid/knowledge/data-model.md §2.3` lists `## Delivery Gates`.
- [ ] Generator re-renders the template into all 3 install trees byte-identically.
- [ ] Existing work-area `STATE.md` instances continue to validate (additive change).
- [ ] Configuration is idempotent.
- [ ] All §6 quality gates pass.
