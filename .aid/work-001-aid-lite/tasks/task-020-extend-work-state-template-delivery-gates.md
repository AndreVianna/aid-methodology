# task-020: Extend `work-state-template.md` with `## Delivery Gates` + `## Quick Check Findings` + create `delivery-issues.md` template + `data-model.md §2.3`

**Type:** CONFIGURE

**Source:** feature-004-two-tier-review → delivery-003

**Depends on:** —

**Scope:**
- Add a `## Delivery Gates` section to `canonical/templates/work-state-template.md`.
- Schema: one block per delivery, keyed by `delivery-NNN`, containing reviewer tier / grade / issue list / timestamp.
- **Add a `## Quick Check Findings` section** to the same template, keyed by task-id (one block per task). Schema: Reviewer Tier + Findings list (severity-tagged). Written by task-021 via the `writeback-task-status.sh --findings` arg mode.
- Update `.aid/knowledge/data-model.md §2.3` to list **both** `## Delivery Gates` AND `## Quick Check Findings` among the work STATE.md sections.
- Add explicit note that `delivery-NNN-issues.md` (instance file for deferred-`[HIGH]` log) coexists distinctly with this section's gate issue list.
- **Author `canonical/templates/delivery-issues.md` template** (the deferred-`[HIGH]` log template that feature-004 SPEC L250-269 mandates; instances render to `.aid/{work}/delivery-NNN-issues.md` per quick-check). Template carries: header + per-task deferred-`[HIGH]` row schema (task-id / severity / description / source-file:line / deferral-timestamp / status).

**Acceptance Criteria:**
- [ ] `canonical/templates/work-state-template.md` contains the `## Delivery Gates` section with documented schema.
- [ ] `canonical/templates/work-state-template.md` contains the `## Quick Check Findings` section with documented schema (keyed by task-id; Reviewer Tier + Findings list).
- [ ] `canonical/templates/delivery-issues.md` template exists with the documented row schema per feature-004 SPEC L250-269.
- [ ] `.aid/knowledge/data-model.md §2.3` lists **both** `## Delivery Gates` and `## Quick Check Findings`, and references the new `delivery-issues.md` template.
- [ ] Generator re-renders both templates into all 3 install trees byte-identically.
- [ ] Existing work-area `STATE.md` instances continue to validate (additive change).
- [ ] Configuration is idempotent.
- [ ] All §6 quality gates pass.
