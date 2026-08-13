# task-002: Widen and rename the field — frontmatter-schema + review-rubric item 3

> **Execution protocol:** whoever executes this task writes its `State` at every
> transition (`In Progress` at start, `In Review` before the reviewer, terminal
> `Done`/`Failed` at end) in this task's `STATE.md`. Binds the main agent executing
> directly, not only a dispatched sub-agent.

**Type:** IMPLEMENT

**Source:** work-004-frontmatter-review-criteria -> delivery-001

**Depends on:** task-001

**Scope:**
- `canonical/aid/templates/kb-authoring/frontmatter-schema.md`: rename `contracts:` → `review-criteria:`;
  define the field (object shape `id`/`kind`/`criterion`/`severity`/`why`) for all four trees, not KB
  docs alone; split the "stay fully exempt" legacy sentence so `review-criteria:` becomes graded content
  while `intent:` and `changelog:` keep their exemption.
- `canonical/aid/templates/kb-authoring/review-rubric.md`: generalize item 3 beyond `.aid/knowledge/`;
  teach it to resolve the three levels (global → type → file) against the registry; add the rule that a
  finding cites the criterion `id` as a `Description`-cell prefix (no `Rule` column, 7-column ledger,
  `grade.sh` untouched).
- Update the sibling cites (`principles.md`, `tier-model.md`) that reference the old field name.

**Acceptance Criteria:**
- [ ] `review-criteria:` is defined for skills, agents, templates and KB docs; the field is no longer in
      the "fully exempt" list, and `intent:`/`changelog:` still are.
- [ ] `review-rubric.md` item 3 resolves all three levels and is no longer scoped to `.aid/knowledge/`.
- [ ] The `id`-as-`Description`-prefix convention is documented; ledger stays 7 columns; no `grade.sh`
      change and no new column.
- [ ] `principles.md` and `tier-model.md` cite the new field name; no dangling `contracts:` reference in
      the four `kb-authoring/` docs.
- [ ] Additive/localized (NFR-3); no new script or gate (C-1). All §6 quality gates pass.
